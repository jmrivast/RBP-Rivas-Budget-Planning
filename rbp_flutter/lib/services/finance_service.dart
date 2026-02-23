import 'dart:collection';

import '../config/constants.dart';
import '../data/database/database_helper.dart';
import '../data/models/category.dart';
import '../data/models/custom_quincena.dart';
import '../data/models/dashboard_data.dart';
import '../data/models/extra_income.dart';
import '../data/models/loan.dart';
import '../data/models/savings_goal.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/expense_repository.dart';
import '../data/repositories/fixed_payment_repository.dart';
import '../data/repositories/income_repository.dart';
import '../data/repositories/loan_repository.dart';
import '../data/repositories/savings_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/user_repository.dart';
import 'csv_service.dart';
import 'pdf_service.dart';
import '../utils/date_helpers.dart' as dh;

class FinanceService {
  FinanceService({
    required this.db,
    UserRepository? userRepo,
    CategoryRepository? categoryRepo,
    ExpenseRepository? expenseRepo,
    FixedPaymentRepository? fixedPaymentRepo,
    LoanRepository? loanRepo,
    IncomeRepository? incomeRepo,
    SavingsRepository? savingsRepo,
    SettingsRepository? settingsRepo,
    CsvService? csvService,
    PdfService? pdfService,
  })  : userRepo = userRepo ?? UserRepository(dbHelper: db),
        categoryRepo = categoryRepo ?? CategoryRepository(dbHelper: db),
        expenseRepo = expenseRepo ?? ExpenseRepository(dbHelper: db),
        fixedPaymentRepo =
            fixedPaymentRepo ?? FixedPaymentRepository(dbHelper: db),
        loanRepo = loanRepo ?? LoanRepository(dbHelper: db),
        incomeRepo = incomeRepo ?? IncomeRepository(dbHelper: db),
        savingsRepo = savingsRepo ?? SavingsRepository(dbHelper: db),
        settingsRepo = settingsRepo ?? SettingsRepository(dbHelper: db),
        csvService = csvService ?? CsvService(),
        pdfService = pdfService ?? PdfService();

  final DatabaseHelper db;
  final UserRepository userRepo;
  final CategoryRepository categoryRepo;
  final ExpenseRepository expenseRepo;
  final FixedPaymentRepository fixedPaymentRepo;
  final LoanRepository loanRepo;
  final IncomeRepository incomeRepo;
  final SavingsRepository savingsRepo;
  final SettingsRepository settingsRepo;
  final CsvService csvService;
  final PdfService pdfService;

  int? userId;
  bool _initialized = false;
  String _periodMode = 'quincenal';
  int _qDay1 = 1;
  int _qDay2 = 16;
  int _monthlyPayday = 1;

  Future<void> init() async {
    if (_initialized) {
      return;
    }
    final users = await userRepo.getAllActive();
    if (users.isNotEmpty) {
      userId = users.first.id;
    } else {
      userId = await userRepo.ensureDefaultUser();
    }

    final categories = await categoryRepo.getByUser(userId!);
    if (categories.isEmpty) {
      for (final name in AppDefaults.defaultCategories) {
        await categoryRepo.create(userId!, name);
      }
    }

    await _reloadSettingsCache();
    _initialized = true;
  }

  Future<void> _ensureInit() async {
    if (!_initialized) {
      await init();
    }
  }

  Future<void> _reloadSettingsCache() async {
    final uid = userId!;
    _periodMode = await settingsRepo.getPeriodMode(uid);
    _qDay1 = _readInt(
        await settingsRepo.getSetting(uid, 'quincenal_pay_day_1',
            defaultValue: '1'),
        1);
    _qDay2 = _readInt(
        await settingsRepo.getSetting(uid, 'quincenal_pay_day_2',
            defaultValue: '16'),
        16);
    _monthlyPayday = _readInt(
        await settingsRepo.getSetting(uid, 'monthly_pay_day',
            defaultValue: '1'),
        1);
  }

  int _readInt(String value, int fallback) {
    final parsed = int.tryParse(value.trim());
    if (parsed == null) {
      return fallback;
    }
    return parsed.clamp(1, 31);
  }

  Future<List<Category>> getCategories() async {
    await _ensureInit();
    return categoryRepo.getByUser(userId!);
  }

  Future<void> addCategory(String name) async {
    await _ensureInit();
    await categoryRepo.create(userId!, name.trim());
  }

  Future<void> renameCategory(int categoryId, String newName) async {
    await _ensureInit();
    await categoryRepo.update(categoryId, name: newName.trim());
  }

  Future<void> deleteCategory(int categoryId) async {
    await _ensureInit();
    final usedInExpenses = await expenseRepo.countCategoryUsage(categoryId);
    final usedInFixed =
        await fixedPaymentRepo.countActiveCategoryUsage(categoryId);
    if (usedInExpenses > 0 || usedInFixed > 0) {
      throw Exception('No se puede eliminar una categoria en uso.');
    }
    await categoryRepo.delete(categoryId);
  }

  Future<void> addExpense(
    double amount,
    String description,
    int categoryId,
    String dateText, {
    String source = 'sueldo',
  }) async {
    await _ensureInit();
    final parsed = DateTime.parse(dateText);
    final cycle = await getCycleForDate(parsed);
    final normalizedSource = source.trim().toLowerCase();
    final status =
        normalizedSource == 'ahorro' ? 'completed_savings' : 'completed_salary';
    await expenseRepo.create(
      userId: userId!,
      amount: amount,
      description: description.trim(),
      date: dateText,
      quincenalCycle: cycle,
      categoryIds: [categoryId],
      status: status,
    );
  }

  Future<void> addFixedPayment(
    String name,
    double amount,
    int dueDay,
    int? categoryId, {
    bool noFixedDate = false,
  }) async {
    await _ensureInit();
    await fixedPaymentRepo.create(
      userId: userId!,
      name: name.trim(),
      amount: amount,
      dueDay: noFixedDate ? 0 : dueDay,
      categoryId: categoryId,
    );
  }

  Future<void> deleteFixedPayment(int paymentId) async {
    await _ensureInit();
    await fixedPaymentRepo.softDelete(paymentId);
  }

  Future<void> setFixedPaymentPaid(
      int paymentId, int year, int month, int cycle, bool paid) async {
    await _ensureInit();
    await fixedPaymentRepo.setRecordStatus(paymentId, year, month, cycle, paid);
  }

  Future<List<FixedPaymentWithStatus>> getFixedPaymentsForPeriod(
    int year,
    int month,
    int cycle,
  ) async {
    await _ensureInit();
    final base = await fixedPaymentRepo.getActiveByUser(userId!);
    final range = await getPeriodRange(year, month, cycle);
    final start = DateTime.parse(range.$1);
    final end = DateTime.parse(range.$2);
    final today = DateTime.now();

    final out = <FixedPaymentWithStatus>[];
    for (final payment in base) {
      final dueDay = payment.dueDay;
      if (dueDay <= 0) {
        final status = await fixedPaymentRepo.getRecordStatus(
          payment.id!,
          year,
          month,
          cycle,
          defaultStatus: 'pending',
        );
        out.add(
          FixedPaymentWithStatus(
            id: payment.id!,
            name: payment.name,
            amount: payment.amount,
            dueDay: payment.dueDay,
            categoryId: payment.categoryId,
            isPaid: status == 'paid',
            isOverdue: false,
            dueDate: '',
          ),
        );
        continue;
      }

      for (final (targetYear, targetMonth) in _iterateMonths(start, end)) {
        final due = DateTime(
          targetYear,
          targetMonth,
          dh.safeDay(targetYear, targetMonth, dueDay),
        );
        if (due.isBefore(start) || due.isAfter(end)) {
          continue;
        }
        final status = await fixedPaymentRepo.getRecordStatus(
          payment.id!,
          year,
          month,
          cycle,
          defaultStatus: 'paid',
        );
        out.add(
          FixedPaymentWithStatus(
            id: payment.id!,
            name: payment.name,
            amount: payment.amount,
            dueDay: payment.dueDay,
            categoryId: payment.categoryId,
            isPaid: status == 'paid',
            isOverdue:
                !due.isAfter(DateTime(today.year, today.month, today.day)),
            dueDate: _dateIso(due),
          ),
        );
        break;
      }
    }

    out.sort((a, b) {
      final aEmpty = a.dueDate.isEmpty;
      final bEmpty = b.dueDate.isEmpty;
      if (aEmpty != bEmpty) {
        return aEmpty ? -1 : 1;
      }
      final byDate = a.dueDate.compareTo(b.dueDate);
      if (byDate != 0) {
        return byDate;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return out;
  }

  Iterable<(int, int)> _iterateMonths(DateTime start, DateTime end) sync* {
    var y = start.year;
    var m = start.month;
    while (y < end.year || (y == end.year && m <= end.month)) {
      yield (y, m);
      final nm = dh.nextMonth(y, m);
      y = nm.$1;
      m = nm.$2;
    }
  }

  Future<void> addSavings(double amount) async {
    await _ensureInit();
    final now = DateTime.now();
    final cycle = await getCycleForDate(now);
    await savingsRepo.recordSavings(
        userId!, amount, now.year, now.month, cycle);
  }

  Future<void> addExtraSavings(double amount) async {
    await _ensureInit();
    final now = DateTime.now();
    final cycle = await getCycleForDate(now);
    await savingsRepo.addExtraSavings(
        userId!, amount, now.year, now.month, cycle);
  }

  Future<double> getPeriodSavings(int year, int month, int cycle) async {
    await _ensureInit();
    final row = await savingsRepo.getByPeriod(userId!, year, month, cycle);
    return row?.lastQuincenalSavings ?? 0;
  }

  Future<double> getTotalSavings() async {
    await _ensureInit();
    return savingsRepo.getTotalSavings(userId!);
  }

  Future<bool> withdrawSavings(double amount) async {
    await _ensureInit();
    return savingsRepo.withdrawSavings(userId!, amount);
  }

  Future<void> addSavingsGoal(String name, double target) async {
    await _ensureInit();
    await savingsRepo.createGoal(userId!, name, target);
  }

  Future<List<SavingsGoal>> getSavingsGoals() async {
    await _ensureInit();
    return savingsRepo.getGoals(userId!);
  }

  Future<void> deleteSavingsGoal(int goalId) async {
    await _ensureInit();
    await savingsRepo.deleteGoal(goalId);
  }

  Future<void> updateSavingsGoal(int goalId, String name, double target) async {
    await _ensureInit();
    await savingsRepo.updateGoal(goalId, name, target);
  }

  Future<void> setSalary(double amount) async {
    await _ensureInit();
    await settingsRepo.setSalary(userId!, amount);
  }

  Future<double> getSalary() async {
    await _ensureInit();
    return settingsRepo.getSalary(userId!);
  }

  Future<void> setSalaryOverride(
      int year, int month, int cycle, double amount) async {
    await _ensureInit();
    await settingsRepo.setSalaryOverride(userId!, year, month, cycle, amount);
  }

  Future<double?> getSalaryOverride(int year, int month, int cycle) async {
    await _ensureInit();
    return settingsRepo.getSalaryOverride(userId!, year, month, cycle);
  }

  Future<void> deleteSalaryOverride(int year, int month, int cycle) async {
    await _ensureInit();
    await settingsRepo.deleteSalaryOverride(userId!, year, month, cycle);
  }

  Future<double> getSalaryForPeriod(int year, int month, int cycle) async {
    final override = await getSalaryOverride(year, month, cycle);
    if (override != null) {
      return override;
    }
    return getSalary();
  }

  Future<void> setPeriodMode(String mode) async {
    await _ensureInit();
    await settingsRepo.setPeriodMode(userId!, mode);
    _periodMode =
        mode.trim().toLowerCase() == 'mensual' ? 'mensual' : 'quincenal';
  }

  Future<String> getPeriodMode() async {
    await _ensureInit();
    return _periodMode;
  }

  Future<void> setSetting(String key, String value) async {
    await _ensureInit();
    await settingsRepo.setSetting(userId!, key, value);
    if (key == 'quincenal_pay_day_1') {
      _qDay1 = _readInt(value, 1);
    } else if (key == 'quincenal_pay_day_2') {
      _qDay2 = _readInt(value, 16);
    } else if (key == 'monthly_pay_day') {
      _monthlyPayday = _readInt(value, 1);
    }
  }

  Future<String> getSetting(String key, {String defaultValue = ''}) async {
    await _ensureInit();
    return settingsRepo.getSetting(userId!, key, defaultValue: defaultValue);
  }

  (int, int) getQuincenalPaydays() {
    var d1 = _qDay1;
    var d2 = _qDay2;
    if (d1 == d2) {
      d2 = d1 == 16 ? 15 : 16;
    }
    return (d1, d2);
  }

  int getMonthlyPayday() => _monthlyPayday;

  Future<(String, String)> getQuincenaRange(
      int year, int month, int cycle) async {
    await _ensureInit();
    final custom =
        await settingsRepo.getCustomQuincenaRange(userId!, year, month, cycle);
    if (custom != null) {
      return custom;
    }
    final paydays = getQuincenalPaydays();
    final range = dh.getQuincenaRange(
      year,
      month,
      cycle,
      day1: paydays.$1,
      day2: paydays.$2,
    );
    return (range.start, range.end);
  }

  Future<(String, String)> getPeriodRange(
      int year, int month, int cycle) async {
    await _ensureInit();
    if (_periodMode == 'mensual') {
      final range = dh.getMonthRangeByPayday(year, month, getMonthlyPayday());
      return (range.start, range.end);
    }
    return getQuincenaRange(year, month, cycle);
  }

  Future<List<int>> getPeriodStartDays(int year, int month) async {
    await _ensureInit();
    if (_periodMode == 'mensual') {
      return [dh.safeDay(year, month, _monthlyPayday)];
    }
    final (d1, d2) = getQuincenalPaydays();
    return [dh.safeDay(year, month, d1), dh.safeDay(year, month, d2)];
  }

  Future<int> getCycleForDate(DateTime date) async {
    await _ensureInit();
    if (_periodMode == 'mensual') {
      return 1;
    }
    final q1 = await getQuincenaRange(date.year, date.month, 1);
    final startQ1 = DateTime.parse(q1.$1);
    final endQ1 = DateTime.parse(q1.$2);
    if (!date.isBefore(startQ1) && !date.isAfter(endQ1)) {
      return 1;
    }
    return 2;
  }

  Future<void> addIncome(
      double amount, String description, String dateText) async {
    await _ensureInit();
    await incomeRepo.create(
      userId: userId!,
      amount: amount,
      description: description,
      date: dateText,
    );
  }

  Future<List<ExtraIncome>> getIncomes(int year, int month, int cycle) async {
    await _ensureInit();
    final range = await getQuincenaRange(year, month, cycle);
    return incomeRepo.getByRange(userId!, range.$1, range.$2);
  }

  Future<double> getTotalIncome(int year, int month, int cycle) async {
    await _ensureInit();
    final range = await getQuincenaRange(year, month, cycle);
    return incomeRepo.getTotalByRange(userId!, range.$1, range.$2);
  }

  Future<void> deleteIncome(int incomeId) async {
    await _ensureInit();
    await incomeRepo.delete(incomeId);
  }

  Future<void> addLoan(
    String person,
    double amount,
    String description,
    String dateText, {
    String deductionType = 'ninguno',
  }) async {
    await _ensureInit();
    await loanRepo.create(
      userId: userId!,
      person: person,
      amount: amount,
      description: description,
      date: dateText,
      deductionType: deductionType,
    );
  }

  Future<List<Loan>> getLoans({bool includePaid = false}) async {
    await _ensureInit();
    return loanRepo.getByUser(userId!, includePaid: includePaid);
  }

  Future<void> markLoanPaid(int loanId) async {
    await _ensureInit();
    await loanRepo.markPaid(loanId);
  }

  Future<void> deleteLoan(int loanId) async {
    await _ensureInit();
    await loanRepo.delete(loanId);
  }

  Future<double> getTotalUnpaidLoans() async {
    await _ensureInit();
    return loanRepo.getTotalUnpaid(userId!);
  }

  Future<double> getTotalLoansAffectingBudget() async {
    await _ensureInit();
    return loanRepo.getTotalAffectingBudget(userId!);
  }

  Future<void> updateExpense(int expenseId, double amount, String description,
      String dateText, int categoryId) async {
    await _ensureInit();
    await expenseRepo.update(
      expenseId,
      amount: amount,
      description: description,
      date: dateText,
      categoryIds: [categoryId],
    );
  }

  Future<void> deleteExpense(int expenseId) async {
    await _ensureInit();
    await expenseRepo.delete(expenseId);
  }

  Future<void> updateFixedPayment(int paymentId, String name, double amount,
      int dueDay, int? categoryId) async {
    await _ensureInit();
    await fixedPaymentRepo.update(
      paymentId,
      name: name,
      amount: amount,
      dueDay: dueDay,
      categoryId: categoryId,
      updateCategory: true,
    );
  }

  Future<void> updateLoan(
    int loanId,
    String person,
    double amount,
    String description,
    String deductionType,
  ) async {
    await _ensureInit();
    await loanRepo.update(
      loanId,
      person: person,
      amount: amount,
      description: description,
      deductionType: deductionType,
    );
  }

  Future<void> updateIncome(
      int incomeId, double amount, String description, String dateText) async {
    await _ensureInit();
    await incomeRepo.update(
      incomeId,
      amount: amount,
      description: description,
      date: dateText,
    );
  }

  Future<void> setCustomQuincena(
      int year, int month, int cycle, String start, String end) async {
    await _ensureInit();
    await settingsRepo.setCustomQuincena(
        userId!, year, month, cycle, start, end);
  }

  Future<CustomQuincena?> getCustomQuincena(
      int year, int month, int cycle) async {
    await _ensureInit();
    return settingsRepo.getCustomQuincena(userId!, year, month, cycle);
  }

  Future<void> deleteCustomQuincena(int customQuincenaId) async {
    await _ensureInit();
    await settingsRepo.deleteCustomQuincena(customQuincenaId);
  }

  Future<DashboardData> getDashboardData(
      {int? year, int? month, int? cycle}) async {
    await _ensureInit();
    final now = DateTime.now();
    final y = year ?? now.year;
    final m = month ?? now.month;
    final c =
        cycle ?? (_periodMode == 'mensual' ? 1 : await getCycleForDate(now));

    final range = await getPeriodRange(y, m, c);
    final start = range.$1;
    final end = range.$2;

    final expenses = await expenseRepo.getByRange(userId!, start, end);
    final fixedPayments = await getFixedPaymentsForPeriod(y, m, c);
    final totalSavings = await getTotalSavings();
    final periodSavings = await getPeriodSavings(y, m, c);
    final totalLoans = await getTotalUnpaidLoans();
    final salary = _periodMode == 'mensual'
        ? await getSalary()
        : await getSalaryForPeriod(y, m, c);
    final extraIncome = await incomeRepo.getTotalByRange(userId!, start, end);

    final totalExpenses = expenses.fold<double>(0, (sum, e) => sum + e.amount);
    final totalExpensesSalary = expenses
        .where((e) => e.status.trim().toLowerCase() != 'completed_savings')
        .fold<double>(0, (sum, e) => sum + e.amount);
    final totalExpensesSavings = totalExpenses - totalExpensesSalary;
    final totalFixed =
        fixedPayments.fold<double>(0, (sum, p) => sum + p.amount);

    final dineroInicial = salary + extraIncome - periodSavings;
    final dineroDisponible =
        dineroInicial - totalExpensesSalary - totalFixed - totalLoans;

    final daily = <String, double>{};
    for (final expense in expenses) {
      daily.update(expense.date, (value) => value + expense.amount,
          ifAbsent: () => expense.amount);
    }
    final avgDaily = daily.isEmpty
        ? 0.0
        : daily.values.fold<double>(0, (sum, v) => sum + v) / daily.length;

    final categories = await getCategories();
    final categoriesById = {
      for (final category in categories) category.id!: category.name
    };
    final catTotals = HashMap<int, double>();
    for (final expense in expenses) {
      final ids = (expense.categoryIds ?? '')
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty);
      for (final cid in ids) {
        final parsed = int.tryParse(cid);
        if (parsed == null) {
          continue;
        }
        catTotals.update(parsed, (value) => value + expense.amount,
            ifAbsent: () => expense.amount);
      }
    }

    final recent = <RecentItem>[];
    for (final expense in expenses.take(12)) {
      final names = <String>[];
      final ids = (expense.categoryIds ?? '')
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty);
      for (final cid in ids) {
        final parsed = int.tryParse(cid);
        if (parsed != null && categoriesById.containsKey(parsed)) {
          names.add(categoriesById[parsed]!);
        }
      }
      recent.add(
        RecentItem(
          date: expense.date,
          description: expense.description,
          amount: expense.amount,
          categories: names.isEmpty ? 'Sin cat.' : names.join(', '),
          type: 'expense',
          id: expense.id,
          raw: expense,
        ),
      );
    }

    final todayIso = _dateIso(DateTime.now());
    for (final fixed in fixedPayments) {
      if (fixed.dueDay <= 0) {
        if (!fixed.isPaid) {
          continue;
        }
        recent.add(
          RecentItem(
            date: todayIso,
            description: 'Pago fijo pagado: ${fixed.name}',
            amount: fixed.amount,
            categories: 'Pago fijo',
            type: 'fixed_due',
            fixedPaid: true,
            id: fixed.id,
            raw: fixed,
          ),
        );
        continue;
      }
      if (fixed.dueDate.isNotEmpty &&
          fixed.dueDate.compareTo(todayIso) <= 0 &&
          fixed.isPaid) {
        recent.add(
          RecentItem(
            date: fixed.dueDate,
            description: 'Pago fijo: ${fixed.name}',
            amount: fixed.amount,
            categories: 'Pago fijo',
            type: 'fixed_due',
            fixedPaid: true,
            id: fixed.id,
            raw: fixed,
          ),
        );
      }
    }
    recent.sort((a, b) => b.date.compareTo(a.date));
    final recentLimited = recent.take(20).toList();

    return DashboardData(
      year: y,
      month: m,
      cycle: c,
      periodMode: _periodMode,
      salary: salary,
      extraIncome: extraIncome,
      dineroInicial: dineroInicial,
      totalExpenses: totalExpenses,
      totalExpensesSalary: totalExpensesSalary,
      totalExpensesSavings: totalExpensesSavings,
      totalFixed: totalFixed,
      totalLoans: totalLoans,
      periodSavings: periodSavings,
      totalSavings: totalSavings,
      dineroDisponible: dineroDisponible,
      avgDaily: avgDaily,
      expenseCount: expenses.length,
      fixedCount: fixedPayments.length,
      recentExpenses: recentLimited,
      fixedPayments: fixedPayments,
      rawExpenses: expenses,
      categoriesById: categoriesById,
      catTotals: catTotals,
      quincenaRange: (start, end),
    );
  }

  Future<String> generateReport(int year, int month, int cycle) async {
    await _ensureInit();
    final data = await getDashboardData(year: year, month: month, cycle: cycle);
    final loans = await getLoans(includePaid: true);
    final periodLabel = dh.formatPeriodLabel(
      year: data.year,
      month: data.month,
      cycle: data.cycle,
      periodMode: data.periodMode,
      startDate: data.quincenaRange.$1,
      endDate: data.quincenaRange.$2,
    );
    return pdfService.generateDashboardReport(
      dashboard: data,
      loans: loans,
      periodLabel: periodLabel,
    );
  }

  Future<String> exportCsv(int year, int month, int cycle) async {
    await _ensureInit();
    final data = await getDashboardData(year: year, month: month, cycle: cycle);
    final loans = await getLoans(includePaid: true);
    final periodLabel = dh.formatPeriodLabel(
      year: data.year,
      month: data.month,
      cycle: data.cycle,
      periodMode: data.periodMode,
      startDate: data.quincenaRange.$1,
      endDate: data.quincenaRange.$2,
    );
    return csvService.exportDashboardCsv(
      dashboard: data,
      loans: loans,
      periodLabel: periodLabel,
    );
  }

  String _dateIso(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

