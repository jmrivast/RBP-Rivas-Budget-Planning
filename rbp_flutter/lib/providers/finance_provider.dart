import 'package:flutter/material.dart';

import '../config/constants.dart';
import '../data/database/database_helper.dart';
import '../data/models/category.dart';
import '../data/models/custom_quincena.dart';
import '../data/models/dashboard_data.dart';
import '../data/models/expense.dart';
import '../data/models/extra_income.dart';
import '../data/models/loan.dart';
import '../data/models/savings_goal.dart';
import '../services/finance_service.dart';
import '../utils/date_helpers.dart' as dh;

class FinanceProvider extends ChangeNotifier {
  FinanceProvider({FinanceService? service})
      : _service = service ?? FinanceService(db: DatabaseHelper.instance);

  final FinanceService _service;

  bool _initialized = false;
  bool _loading = false;
  String? _error;
  bool _licenseActivated = true;
  bool _trialMode = false;

  late int _year;
  late int _month;
  int _cycle = 1;
  String _periodMode = 'quincenal';

  DashboardData? _dashboard;
  List<Category> _categories = const [];
  List<ExtraIncome> _incomes = const [];
  List<Loan> _loans = const [];
  List<SavingsGoal> _goals = const [];
  List<Expense> _expenses = const [];

  bool get initialized => _initialized;
  bool get isLoading => _loading;
  String? get error => _error;
  bool get isLicenseActivated => _licenseActivated;
  bool get isTrialMode => _trialMode;
  int get year => _year;
  int get month => _month;
  int get cycle => _cycle;
  String get periodMode => _periodMode;
  DashboardData? get dashboard => _dashboard;
  List<Category> get categories => _categories;
  List<ExtraIncome> get incomes => _incomes;
  List<Loan> get loans => _loans;
  List<SavingsGoal> get goals => _goals;
  List<Expense> get expenses => _expenses;
  FinanceService get service => _service;

  void setLicenseState({required bool activated, required bool trialMode}) {
    if (_licenseActivated == activated && _trialMode == trialMode) {
      return;
    }
    _licenseActivated = activated;
    _trialMode = trialMode;
    notifyListeners();
  }

  Future<void> init() async {
    if (_initialized) {
      return;
    }
    _setLoading(true);
    try {
      await _service.init();
      final now = DateTime.now();
      _year = now.year;
      _month = now.month;
      _periodMode = await _service.getPeriodMode();
      _cycle =
          _periodMode == 'mensual' ? 1 : await _service.getCycleForDate(now);
      await refreshAll(notify: false);
      _initialized = true;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshAll({bool notify = true}) async {
    await refreshDashboard();
    await Future.wait([
      loadCategories(),
      loadIncomes(),
      loadLoans(),
      loadGoals(),
    ]);
    _expenses = _dashboard?.rawExpenses ?? const [];
    if (notify) {
      notifyListeners();
    }
  }

  Future<void> refreshDashboard() async {
    _dashboard = await _service.getDashboardData(
      year: _year,
      month: _month,
      cycle: _cycle,
    );
  }

  Future<void> loadCategories() async {
    _categories = await _service.getCategories();
  }

  Future<void> loadIncomes() async {
    _incomes = await _service.getIncomes(_year, _month, _cycle);
  }

  Future<void> loadLoans() async {
    _loans = await _service.getLoans(includePaid: true);
  }

  Future<void> loadGoals() async {
    _goals = await _service.getSavingsGoals();
  }

  Future<void> loadExpenses() async {
    _expenses = _dashboard?.rawExpenses ?? const [];
  }

  Future<void> goToPreviousPeriod() async {
    await _withMutation(() async {
      if (_periodMode == 'mensual') {
        final prev = dh.previousMonth(_year, _month);
        _year = prev.$1;
        _month = prev.$2;
      } else {
        final prev = dh.previousQuincena(_year, _month, _cycle);
        _year = prev.year;
        _month = prev.month;
        _cycle = prev.cycle;
      }
    }, refresh: _refreshPeriodViews);
  }

  Future<void> goToNextPeriod() async {
    await _withMutation(() async {
      if (_periodMode == 'mensual') {
        final next = dh.nextMonth(_year, _month);
        _year = next.$1;
        _month = next.$2;
      } else {
        final next = dh.nextQuincena(_year, _month, _cycle);
        _year = next.year;
        _month = next.month;
        _cycle = next.cycle;
      }
    }, refresh: _refreshPeriodViews);
  }

  Future<void> goToCurrentPeriod() async {
    await _withMutation(() async {
      final now = DateTime.now();
      _year = now.year;
      _month = now.month;
      _cycle =
          _periodMode == 'mensual' ? 1 : await _service.getCycleForDate(now);
    }, refresh: _refreshPeriodViews);
  }

  Future<void> addExpense(
    double amount,
    String description,
    int categoryId,
    String date, {
    String source = 'sueldo',
  }) async {
    if (_trialMode && _expenses.length >= AppLicense.trialExpenseLimit) {
      throw Exception(
        'Modo de prueba: maximo ${AppLicense.trialExpenseLimit} gastos por periodo.',
      );
    }
    await _withMutation(() async {
      final normalizedSource = source.trim().toLowerCase();
      var deductedFromSavings = false;
      if (normalizedSource == 'ahorro') {
        deductedFromSavings = await _service.withdrawSavings(amount);
        if (!deductedFromSavings) {
          throw Exception('Fondos insuficientes en ahorro.');
        }
      }
      try {
        await _service.addExpense(
          amount,
          description,
          categoryId,
          date,
          source: normalizedSource,
        );
      } catch (_) {
        if (deductedFromSavings) {
          await _service.addSavings(amount);
        }
        rethrow;
      }
    }, refresh: _refreshDashboardExpenses);
  }

  Future<void> updateExpense(
    int expenseId,
    double amount,
    String description,
    String date,
    int categoryId,
  ) async {
    await _withMutation(() async {
      await _service.updateExpense(
          expenseId, amount, description, date, categoryId);
    }, refresh: _refreshDashboardExpenses);
  }

  Future<void> deleteExpense(int expenseId) async {
    await _withMutation(() async {
      await _service.deleteExpense(expenseId);
    }, refresh: _refreshDashboardExpenses);
  }

  Future<void> addIncome(double amount, String description, String date) async {
    await _withMutation(() async {
      await _service.addIncome(amount, description, date);
    }, refresh: _refreshDashboardAndIncomes);
  }

  Future<void> updateIncome(
    int incomeId,
    double amount,
    String description,
    String date,
  ) async {
    await _withMutation(() async {
      await _service.updateIncome(incomeId, amount, description, date);
    }, refresh: _refreshDashboardAndIncomes);
  }

  Future<void> deleteIncome(int incomeId) async {
    await _withMutation(() async {
      await _service.deleteIncome(incomeId);
    }, refresh: _refreshDashboardAndIncomes);
  }

  Future<void> addFixedPayment(
    String name,
    double amount,
    int dueDay,
    int? categoryId, {
    bool noFixedDate = false,
  }) async {
    await _withMutation(() async {
      await _service.addFixedPayment(
        name,
        amount,
        dueDay,
        categoryId,
        noFixedDate: noFixedDate,
      );
    }, refresh: _refreshDashboardExpenses);
  }

  Future<void> updateFixedPayment(
    int paymentId,
    String name,
    double amount,
    int dueDay,
    int? categoryId,
  ) async {
    await _withMutation(() async {
      await _service.updateFixedPayment(
          paymentId, name, amount, dueDay, categoryId);
    }, refresh: _refreshDashboardExpenses);
  }

  Future<void> deleteFixedPayment(int paymentId) async {
    await _withMutation(() async {
      await _service.deleteFixedPayment(paymentId);
    }, refresh: _refreshDashboardExpenses);
  }

  Future<void> toggleFixedPaymentPaid(int paymentId, bool paid) async {
    await _withMutation(() async {
      await _service.setFixedPaymentPaid(
          paymentId, _year, _month, _cycle, paid);
    }, refresh: _refreshDashboardExpenses);
  }

  Future<void> addLoan(
    String person,
    double amount,
    String description,
    String date, {
    String deductionType = 'ninguno',
  }) async {
    await _withMutation(() async {
      final normalizedDeduction = deductionType.trim().toLowerCase();
      if (normalizedDeduction == 'ahorro') {
        final ok = await _service.withdrawSavings(amount);
        if (!ok) {
          throw Exception('Ahorro insuficiente para descontar.');
        }
      } else if (normalizedDeduction == 'gasto') {
        final cats = await _service.getCategories();
        final fallback = cats.isNotEmpty ? cats.last : null;
        Category? otros;
        for (final c in cats) {
          final name = c.name.trim().toLowerCase();
          if (name == 'otros' || name == 'prestamos') {
            otros = c;
            break;
          }
        }
        final cat = otros ?? fallback;
        if (cat?.id != null) {
          await _service.addExpense(
            amount,
            'Prestamo a $person',
            cat!.id!,
            date,
            source: 'sueldo',
          );
        }
      }
      await _service.addLoan(
        person,
        amount,
        description,
        date,
        deductionType: normalizedDeduction,
      );
    }, refresh: _refreshDashboardAndLoans);
  }

  Future<void> updateLoan(
    int loanId,
    String person,
    double amount,
    String description,
    String deductionType,
  ) async {
    await _withMutation(() async {
      await _service.updateLoan(
          loanId, person, amount, description, deductionType);
    }, refresh: _refreshDashboardAndLoans);
  }

  Future<void> markLoanPaid(int loanId) async {
    await _withMutation(() async {
      await _service.markLoanPaid(loanId);
    }, refresh: _refreshDashboardAndLoans);
  }

  Future<void> deleteLoan(int loanId) async {
    await _withMutation(() async {
      await _service.deleteLoan(loanId);
    }, refresh: _refreshDashboardAndLoans);
  }

  Future<void> addSavings(double amount) async {
    await _withMutation(() async {
      await _service.addSavings(amount);
    }, refresh: _refreshDashboardExpenses);
  }

  Future<void> addExtraSavings(double amount) async {
    await _withMutation(() async {
      await _service.addExtraSavings(amount);
    }, refresh: _refreshDashboardExpenses);
  }

  Future<bool> withdrawSavings(double amount) async {
    var ok = false;
    await _withMutation(() async {
      ok = await _service.withdrawSavings(amount);
      if (!ok) {
        throw Exception('Fondos insuficientes.');
      }
    }, keepError: true, refresh: _refreshDashboardExpenses);
    return ok;
  }

  Future<void> addSavingsGoal(String name, double target) async {
    await _withMutation(() async {
      await _service.addSavingsGoal(name, target);
    }, refresh: _refreshDashboardAndGoals);
  }

  Future<void> updateSavingsGoal(int goalId, String name, double target) async {
    await _withMutation(() async {
      await _service.updateSavingsGoal(goalId, name, target);
    }, refresh: _refreshDashboardAndGoals);
  }

  Future<void> deleteSavingsGoal(int goalId) async {
    await _withMutation(() async {
      await _service.deleteSavingsGoal(goalId);
    }, refresh: _refreshDashboardAndGoals);
  }

  Future<void> addCategory(String name) async {
    await _withMutation(() async {
      await _service.addCategory(name);
    }, refresh: _refreshDashboardAndCategories);
  }

  Future<void> renameCategory(int categoryId, String name) async {
    await _withMutation(() async {
      await _service.renameCategory(categoryId, name);
    }, refresh: _refreshDashboardAndCategories);
  }

  Future<void> deleteCategory(int categoryId) async {
    await _withMutation(() async {
      await _service.deleteCategory(categoryId);
    }, refresh: _refreshDashboardAndCategories);
  }

  Future<void> setSalary(double amount) async {
    await _withMutation(() async {
      await _service.setSalary(amount);
    }, refresh: _refreshDashboardOnly);
  }

  Future<double> getSalary() async {
    return _service.getSalary();
  }

  Future<void> setSalaryOverride(
    int year,
    int month,
    int cycle,
    double amount,
  ) async {
    await _withMutation(() async {
      await _service.setSalaryOverride(year, month, cycle, amount);
    }, refresh: _refreshDashboardOnly);
  }

  Future<double?> getSalaryOverride(int year, int month, int cycle) async {
    return _service.getSalaryOverride(year, month, cycle);
  }

  Future<void> deleteSalaryOverride(int year, int month, int cycle) async {
    await _withMutation(() async {
      await _service.deleteSalaryOverride(year, month, cycle);
    }, refresh: _refreshDashboardOnly);
  }

  Future<void> setPeriodMode(String mode) async {
    await _withMutation(() async {
      await _service.setPeriodMode(mode);
      _periodMode = await _service.getPeriodMode();
      if (_periodMode == 'mensual') {
        _cycle = 1;
      }
    }, refresh: _refreshPeriodViews);
  }

  Future<void> setSetting(String key, String value) async {
    await _service.setSetting(key, value);
  }

  Future<String> getSetting(String key, {String defaultValue = ''}) async {
    return _service.getSetting(key, defaultValue: defaultValue);
  }

  Future<void> setCustomQuincena(String start, String end) async {
    await _withMutation(() async {
      await _service.setCustomQuincena(_year, _month, _cycle, start, end);
    }, refresh: _refreshPeriodViews);
  }

  Future<CustomQuincena?> getCustomQuincena() async {
    return _service.getCustomQuincena(_year, _month, _cycle);
  }

  Future<void> deleteCustomQuincena(int customQuincenaId) async {
    await _withMutation(() async {
      await _service.deleteCustomQuincena(customQuincenaId);
    }, refresh: _refreshPeriodViews);
  }

  Future<String> exportPdf() async {
    if (_trialMode) {
      throw Exception('Modo de prueba: exportar PDF requiere licencia activa.');
    }
    return _service.generateReport(_year, _month, _cycle);
  }

  Future<String> exportCsv() async {
    if (_trialMode) {
      throw Exception('Modo de prueba: exportar CSV requiere licencia activa.');
    }
    return _service.exportCsv(_year, _month, _cycle);
  }

  Future<String> exportPdfForPeriod(int year, int month, int cycle) async {
    if (_trialMode) {
      throw Exception('Modo de prueba: exportar PDF requiere licencia activa.');
    }
    return _service.generateReport(year, month, cycle);
  }

  Future<String> exportCsvForPeriod(int year, int month, int cycle) async {
    if (_trialMode) {
      throw Exception('Modo de prueba: exportar CSV requiere licencia activa.');
    }
    return _service.exportCsv(year, month, cycle);
  }

  Future<List<int>> getPeriodStartDays(int year, int month) async {
    return _service.getPeriodStartDays(year, month);
  }

  Future<int> getCycleForDate(DateTime date) async {
    return _service.getCycleForDate(date);
  }

  Future<(String, String)> getPeriodRangeFor(
    int year,
    int month,
    int cycle,
  ) async {
    return _service.getPeriodRange(year, month, cycle);
  }

  String get periodTitle {
    final d = _dashboard;
    if (d == null) {
      return '';
    }
    return dh.formatPeriodLabel(
      year: d.year,
      month: d.month,
      cycle: d.cycle,
      periodMode: d.periodMode,
      startDate: d.quincenaRange.$1,
      endDate: d.quincenaRange.$2,
    );
  }

  Future<void> _withMutation(
    Future<void> Function() action, {
    bool keepError = false,
    Future<void> Function()? refresh,
  }) async {
    _setLoading(true);
    if (!keepError) {
      _error = null;
    }
    try {
      await action();
      if (refresh != null) {
        await refresh();
      } else {
        await refreshAll(notify: false);
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    if (_loading == value) {
      return;
    }
    _loading = value;
    notifyListeners();
  }

  Future<void> _refreshDashboardOnly() async {
    await refreshDashboard();
    _expenses = _dashboard?.rawExpenses ?? const [];
  }

  Future<void> _refreshDashboardExpenses() async {
    await _refreshDashboardOnly();
  }

  Future<void> _refreshDashboardAndIncomes() async {
    await _refreshDashboardOnly();
    await loadIncomes();
  }

  Future<void> _refreshDashboardAndLoans() async {
    await _refreshDashboardOnly();
    await loadLoans();
  }

  Future<void> _refreshDashboardAndGoals() async {
    await _refreshDashboardOnly();
    await loadGoals();
  }

  Future<void> _refreshDashboardAndCategories() async {
    await _refreshDashboardOnly();
    await loadCategories();
  }

  Future<void> _refreshPeriodViews() async {
    await _refreshDashboardOnly();
    await loadIncomes();
  }
}
