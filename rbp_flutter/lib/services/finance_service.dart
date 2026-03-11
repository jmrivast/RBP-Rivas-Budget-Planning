import 'dart:collection';
import 'dart:convert';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';

import '../config/constants.dart';
import '../data/database/app_database.dart';
import '../data/database/database_helper.dart';
import '../data/models/category.dart';
import '../data/models/custom_quincena.dart';
import '../data/models/dashboard_data.dart';
import '../data/models/debt.dart';
import '../data/models/debt_payment.dart';
import '../data/models/extra_income.dart';
import '../data/models/loan.dart';
import '../data/models/personal_debt.dart';
import '../data/models/personal_debt_payment.dart';
import '../data/models/savings_goal.dart';
import '../data/models/user.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/debt_repository.dart';
import '../data/repositories/expense_repository.dart';
import '../data/repositories/fixed_payment_repository.dart';
import '../data/repositories/income_repository.dart';
import '../data/repositories/loan_repository.dart';
import '../data/repositories/personal_debt_repository.dart';
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
    PersonalDebtRepository? personalDebtRepo,
    DebtRepository? debtRepo,
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
        personalDebtRepo =
            personalDebtRepo ?? PersonalDebtRepository(dbHelper: db),
        debtRepo = debtRepo ?? DebtRepository(dbHelper: db),
        incomeRepo = incomeRepo ?? IncomeRepository(dbHelper: db),
        savingsRepo = savingsRepo ?? SavingsRepository(dbHelper: db),
        settingsRepo = settingsRepo ?? SettingsRepository(dbHelper: db),
        csvService = csvService ?? CsvService(),
        pdfService = pdfService ?? PdfService();

  final AppDatabase db;
  final UserRepository userRepo;
  final CategoryRepository categoryRepo;
  final ExpenseRepository expenseRepo;
  final FixedPaymentRepository fixedPaymentRepo;
  final LoanRepository loanRepo;
  final PersonalDebtRepository personalDebtRepo;
  final DebtRepository debtRepo;
  final IncomeRepository incomeRepo;
  final SavingsRepository savingsRepo;
  final SettingsRepository settingsRepo;
  final CsvService csvService;
  final PdfService pdfService;

  static const String _activeProfileKey = 'active_profile_id';
  static const String _profileSessionUserIdKey = 'profile_session_user_id';
  static const String _profileSessionExpiresAtKey =
      'profile_session_expires_at';

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
    await _resolveActiveUser();
    await _ensureDefaultCategoriesForCurrentUser();

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

  Future<void> _resolveActiveUser() async {
    final users = await userRepo.getAllActive();
    if (users.isEmpty) {
      userId = await userRepo.ensureDefaultUser();
      await settingsRepo.setAppSetting(_activeProfileKey, '$userId');
      return;
    }

    final saved = await settingsRepo.getAppSetting(
      _activeProfileKey,
      defaultValue: '',
    );
    final savedId = int.tryParse(saved.trim());
    if (savedId != null && users.any((u) => u.id == savedId)) {
      userId = savedId;
      return;
    }

    userId = users.first.id;
    await settingsRepo.setAppSetting(_activeProfileKey, '$userId');
  }

  Future<void> _ensureDefaultCategoriesForCurrentUser() async {
    final uid = userId!;
    final categories = await categoryRepo.getByUser(uid);
    if (categories.isNotEmpty) {
      return;
    }
    for (final name in AppDefaults.defaultCategories) {
      await categoryRepo.create(uid, name);
    }
  }

  String _hashPin(String pin) {
    final normalized = pin.trim();
    return sha256.convert(utf8.encode(normalized)).toString();
  }

  bool _isPinValid(String pin, int pinLength) {
    final value = pin.trim();
    if (pinLength != 4 && pinLength != 6) {
      return false;
    }
    if (value.length != pinLength) {
      return false;
    }
    return RegExp(r'^\d+$').hasMatch(value);
  }

  Future<List<User>> getProfiles() async {
    await _ensureInit();
    return userRepo.getAllActive();
  }

  Future<User?> getActiveProfile() async {
    await _ensureInit();
    final uid = userId;
    if (uid == null) {
      return null;
    }
    return userRepo.getById(uid);
  }

  Future<int> createProfile(
    String username, {
    String? pin,
    int pinLength = 4,
  }) async {
    await _ensureInit();
    final name = username.trim();
    if (name.isEmpty) {
      throw Exception('Nombre de perfil requerido.');
    }
    final existing = await userRepo.getByUsername(name);
    if (existing != null) {
      throw Exception('Ya existe un perfil con ese nombre.');
    }

    String? pinHash;
    var normalizedLength = 0;
    if (pin != null && pin.trim().isNotEmpty) {
      if (!_isPinValid(pin, pinLength)) {
        throw Exception('El PIN debe ser numerico de 4 o 6 digitos.');
      }
      pinHash = _hashPin(pin);
      normalizedLength = pinLength;
    }

    final id = await userRepo.create(
      name,
      pinHash: pinHash,
      pinLength: normalizedLength,
    );
    final previous = userId;
    userId = id;
    await _ensureDefaultCategoriesForCurrentUser();
    userId = previous;
    return id;
  }

  Future<void> switchProfile(
    int profileId, {
    String? pin,
  }) async {
    await _ensureInit();
    final profile = await userRepo.getById(profileId);
    if (profile == null || profile.isActive != 1) {
      throw Exception('Perfil no encontrado.');
    }
    if (profile.hasPin) {
      final provided = (pin ?? '').trim();
      if (!_isPinValid(provided, profile.pinLength)) {
        throw Exception('PIN invalido.');
      }
      final hash = _hashPin(provided);
      if (hash != profile.pinHash) {
        throw Exception('PIN incorrecto.');
      }
    }

    userId = profileId;
    await settingsRepo.setAppSetting(_activeProfileKey, '$profileId');
    await _ensureDefaultCategoriesForCurrentUser();
    await _reloadSettingsCache();
  }

  Future<void> setProfilePin(
    int profileId, {
    String? pin,
    int pinLength = 4,
  }) async {
    await _ensureInit();
    final profile = await userRepo.getById(profileId);
    if (profile == null || profile.isActive != 1) {
      throw Exception('Perfil no encontrado.');
    }
    if (pin == null || pin.trim().isEmpty) {
      await userRepo.setPin(profileId, pinHash: null, pinLength: 0);
      return;
    }
    if (!_isPinValid(pin, pinLength)) {
      throw Exception('El PIN debe ser numerico de 4 o 6 digitos.');
    }
    await userRepo.setPin(
      profileId,
      pinHash: _hashPin(pin),
      pinLength: pinLength,
    );
  }

  Future<void> renameProfile(int profileId, String newUsername) async {
    await _ensureInit();
    final profile = await userRepo.getById(profileId);
    if (profile == null || profile.isActive != 1) {
      throw Exception('Perfil no encontrado.');
    }
    final name = newUsername.trim();
    if (name.isEmpty) {
      throw Exception('Nombre de perfil requerido.');
    }
    final existing = await userRepo.getByUsername(name);
    if (existing != null && existing.id != profileId) {
      throw Exception('Ya existe un perfil con ese nombre.');
    }
    await userRepo.rename(profileId, name);
  }

  Future<void> deleteProfile(
    int profileId, {
    String? pin,
  }) async {
    await _ensureInit();
    final profiles = await userRepo.getAllActive();
    if (profiles.length <= 1) {
      throw Exception('Debe existir al menos un perfil activo.');
    }
    if (profileId == userId) {
      throw Exception(
          'No puedes eliminar el perfil activo. Cambia a otro perfil primero.');
    }
    final profile = await userRepo.getById(profileId);
    if (profile == null || profile.isActive != 1) {
      throw Exception('Perfil no encontrado.');
    }
    if (profile.hasPin) {
      final provided = (pin ?? '').trim();
      if (!_isPinValid(provided, profile.pinLength)) {
        throw Exception('PIN invalido.');
      }
      final hash = _hashPin(provided);
      if (hash != profile.pinHash) {
        throw Exception('PIN incorrecto.');
      }
    }
    await userRepo.softDelete(profileId);
  }

  Future<bool> shouldPromptProfileAccess({int sessionHours = 3}) async {
    await _ensureInit();
    final profiles = await userRepo.getAllActive();
    if (profiles.isEmpty) {
      return false;
    }
    if (profiles.length == 1) {
      // One profile without PIN: no prompt screen.
      return profiles.first.hasPin;
    }

    final active = await getActiveProfile();
    if (active?.id == null) {
      return true;
    }

    final savedSessionUser = await settingsRepo.getAppSetting(
      _profileSessionUserIdKey,
      defaultValue: '',
    );
    final savedSessionUserId = int.tryParse(savedSessionUser.trim());
    if (savedSessionUserId == null || savedSessionUserId != active!.id) {
      return true;
    }

    final expiresRaw = await settingsRepo.getAppSetting(
      _profileSessionExpiresAtKey,
      defaultValue: '',
    );
    final expiresAt = DateTime.tryParse(expiresRaw)?.toUtc();
    if (expiresAt == null) {
      return true;
    }

    final nowUtc = DateTime.now().toUtc();
    return !nowUtc.isBefore(expiresAt);
  }

  Future<void> markProfileSession({int sessionHours = 3}) async {
    await _ensureInit();
    final uid = userId;
    if (uid == null) {
      return;
    }
    final hours = sessionHours <= 0 ? 1 : sessionHours;
    final expiresAt = DateTime.now().toUtc().add(Duration(hours: hours));
    await settingsRepo.setAppSetting(_profileSessionUserIdKey, '$uid');
    await settingsRepo.setAppSetting(
      _profileSessionExpiresAtKey,
      expiresAt.toIso8601String(),
    );
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

  double calculateDebtMonthlyPayment(
    double principal,
    double annualRate,
    int termMonths,
  ) {
    final p = principal <= 0 ? 0.0 : principal;
    final n = termMonths <= 0 ? 1 : termMonths;
    final r = (annualRate <= 0 ? 0.0 : annualRate) / 100 / 12;
    if (p == 0) {
      return 0;
    }
    if (r == 0) {
      return p / n;
    }
    final denom = 1 - math.pow(1 + r, -n);
    if (denom == 0) {
      return p / n;
    }
    return p * r / denom;
  }

  Future<void> addDebt({
    required String name,
    required double principalAmount,
    required double annualRate,
    required int termMonths,
    required String startDate,
    required int paymentDay,
  }) async {
    await _ensureInit();
    final monthlyPayment =
        calculateDebtMonthlyPayment(principalAmount, annualRate, termMonths);
    await debtRepo.createDebt(
      userId: userId!,
      name: name.trim(),
      principalAmount: principalAmount,
      annualRate: annualRate,
      termMonths: termMonths,
      startDate: startDate,
      paymentDay: paymentDay,
      monthlyPayment: monthlyPayment,
    );
  }

  Future<List<Debt>> getDebts({bool includeClosed = true}) async {
    await _ensureInit();
    return debtRepo.getDebtsByUser(userId!, includeClosed: includeClosed);
  }

  Future<void> deleteDebt(int debtId) async {
    await _ensureInit();
    final debt = await debtRepo.getDebtById(debtId);
    if (debt == null || debt.userId != userId) {
      throw Exception('Deuda no encontrada.');
    }
    await debtRepo.deleteDebt(debtId);
  }

  Future<void> updateDebt({
    required int debtId,
    required String name,
    required double annualRate,
    required int termMonths,
    required int paymentDay,
  }) async {
    await _ensureInit();
    final debt = await debtRepo.getDebtById(debtId);
    if (debt == null || debt.userId != userId) {
      throw Exception('Deuda no encontrada.');
    }
    if (name.trim().isEmpty) {
      throw Exception('Nombre requerido.');
    }
    if (annualRate < 0 || termMonths <= 0 || paymentDay < 1 || paymentDay > 31) {
      throw Exception('Datos de deuda invalidos.');
    }

    final paymentCount = await debtRepo.countDebtPayments(debtId);
    final remainingMonths = math.max(1, termMonths - paymentCount).toInt();
    final recalculatedMonthly = debt.currentBalance <= 0
        ? 0.0
        : calculateDebtMonthlyPayment(debt.currentBalance, annualRate, remainingMonths);

    await debtRepo.updateDebt(
      debtId,
      name: name.trim(),
      annualRate: annualRate,
      termMonths: termMonths,
      paymentDay: paymentDay,
      monthlyPayment: recalculatedMonthly,
      isActive: debt.currentBalance > 0 ? 1 : 0,
    );
  }

  Future<void> addPersonalDebt(
    String person,
    double amount,
    String description,
    String dateText,
  ) async {
    await _ensureInit();
    await personalDebtRepo.create(
      userId: userId!,
      person: person.trim(),
      totalAmount: amount,
      currentBalance: amount,
      description: description.trim(),
      date: dateText,
    );
  }

  Future<List<PersonalDebt>> getPersonalDebts({bool includePaid = true}) async {
    await _ensureInit();
    return personalDebtRepo.getByUser(userId!, includePaid: includePaid);
  }

  Future<void> updatePersonalDebt(
    int debtId, {
    String? person,
    double? totalAmount,
    String? description,
  }) async {
    await _ensureInit();
    final current = await personalDebtRepo.getById(debtId);
    if (current == null || current.userId != userId) {
      throw Exception('Deuda personal no encontrada.');
    }
    final newTotal = totalAmount ?? current.totalAmount;
    final alreadyPaid = current.totalAmount - current.currentBalance;
    if (newTotal < alreadyPaid) {
      throw Exception('El total no puede ser menor a lo ya pagado.');
    }
    final newBalance = (newTotal - alreadyPaid).clamp(0.0, double.infinity).toDouble();
    final paid = newBalance <= 0;
    await personalDebtRepo.update(
      debtId,
      person: person?.trim(),
      totalAmount: newTotal,
      currentBalance: newBalance,
      description: description?.trim(),
      isPaid: paid ? 1 : 0,
      paidDate: paid ? _dateIso(DateTime.now()) : null,
    );
  }

  Future<void> deletePersonalDebt(int debtId) async {
    await _ensureInit();
    final current = await personalDebtRepo.getById(debtId);
    if (current == null || current.userId != userId) {
      throw Exception('Deuda personal no encontrada.');
    }
    await personalDebtRepo.delete(debtId);
  }

  Future<void> registerPersonalDebtPayment({
    required int debtId,
    required double amount,
    required String paymentDate,
    String? notes,
  }) async {
    await _ensureInit();
    final current = await personalDebtRepo.getById(debtId);
    if (current == null || current.userId != userId) {
      throw Exception('Deuda personal no encontrada.');
    }
    if (amount <= 0) {
      throw Exception('Monto invalido.');
    }
    final applied = amount > current.currentBalance ? current.currentBalance : amount;
    final newBalance =
        (current.currentBalance - applied).clamp(0.0, double.infinity).toDouble();

    await personalDebtRepo.addPayment(
      personalDebtId: debtId,
      paymentDate: paymentDate,
      amount: applied,
      notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
    );
    await personalDebtRepo.update(
      debtId,
      currentBalance: newBalance,
      isPaid: newBalance <= 0 ? 1 : 0,
      paidDate: newBalance <= 0 ? paymentDate : null,
    );
  }

  Future<List<PersonalDebtPayment>> getPersonalDebtPayments(int debtId) async {
    await _ensureInit();
    final current = await personalDebtRepo.getById(debtId);
    if (current == null || current.userId != userId) {
      throw Exception('Deuda personal no encontrada.');
    }
    return personalDebtRepo.getPayments(debtId);
  }

  Future<double> getTotalOutstandingPersonalDebts() async {
    await _ensureInit();
    return personalDebtRepo.getTotalOutstanding(userId!);
  }

  Future<List<DebtPayment>> getDebtPayments(int debtId) async {
    await _ensureInit();
    final debt = await debtRepo.getDebtById(debtId);
    if (debt == null || debt.userId != userId) {
      throw Exception('Deuda no encontrada.');
    }
    return debtRepo.getDebtPayments(debtId);
  }

  Future<void> registerDebtPayment({
    required int debtId,
    required String paymentDate,
    required double totalAmount,
    required double interestAmount,
    required double capitalAmount,
    String? notes,
  }) async {
    await _ensureInit();
    final debt = await debtRepo.getDebtById(debtId);
    if (debt == null || debt.userId != userId) {
      throw Exception('Deuda no encontrada.');
    }
    if (totalAmount <= 0) {
      throw Exception('Monto de pago invalido.');
    }
    if (interestAmount < 0 || capitalAmount < 0) {
      throw Exception('Interes/capital invalidos.');
    }
    if ((interestAmount + capitalAmount) > (totalAmount + 0.001)) {
      throw Exception('Interes + capital no puede exceder el pago total.');
    }

    final remainingBefore = debt.currentBalance < 0 ? 0.0 : debt.currentBalance;
    final appliedCapital = capitalAmount > remainingBefore
        ? remainingBefore
        : capitalAmount;
    final newBalance =
        (remainingBefore - appliedCapital).clamp(0.0, double.infinity).toDouble();

    await debtRepo.createDebtPayment(
      debtId: debtId,
      paymentDate: paymentDate,
      totalAmount: totalAmount,
      interestAmount: interestAmount,
      capitalAmount: appliedCapital,
      notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
    );

    final paymentCount = await debtRepo.countDebtPayments(debtId);
    final remainingMonths = math.max(1, debt.termMonths - paymentCount).toInt();
    final recalculatedMonthly = newBalance <= 0
        ? 0.0
        : calculateDebtMonthlyPayment(newBalance, debt.annualRate, remainingMonths);

    await debtRepo.updateDebt(
      debtId,
      currentBalance: newBalance,
      monthlyPayment: recalculatedMonthly,
      isActive: newBalance > 0 ? 1 : 0,
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
    final totalLoans = await getTotalLoansAffectingBudget();
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
    final debts = await getDebts(includeClosed: false);
    final personalDebts = await getPersonalDebts(includePaid: true);
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
      debts: debts,
      personalDebts: personalDebts,
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

