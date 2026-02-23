import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:rbp_flutter/data/database/database_helper.dart';
import 'package:rbp_flutter/services/finance_service.dart';

void main() {
  late DatabaseHelper dbHelper;
  late FinanceService service;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dbHelper = DatabaseHelper(
      databaseName: inMemoryDatabasePath,
      useDocumentsDirectory: false,
    );
    service = FinanceService(db: dbHelper);
    await service.init();
  });

  tearDown(() async {
    await dbHelper.close();
  });

  test('dashboard calculation with known data', () async {
    final categories = await service.getCategories();
    final food = categories.first;
    final now = DateTime.now();
    final cycle = await service.getCycleForDate(now);
    final day = now.day.toString().padLeft(2, '0');
    final date =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-$day';

    await service.setSalary(25000);
    await service.addSavings(5000);
    await service.addIncome(2000, 'Freelance', date);
    await service.addExpense(1000, 'Compra', food.id!, date, source: 'sueldo');
    await service.addFixedPayment('Netflix', 500, now.day, food.id);
    await service.setFixedPaymentPaid(1, now.year, now.month, cycle, true);
    await service.addLoan('Pedro', 300, 'Prestamo', date);

    final data = await service.getDashboardData(
        year: now.year, month: now.month, cycle: cycle);
    expect(data.salary, 25000);
    expect(data.extraIncome, 2000);
    expect(data.periodSavings, 5000);
    expect(data.totalExpenses, 1000);
    expect(data.totalFixed, 500);
    expect(data.totalLoans, 300);
    expect(data.dineroInicial, 22000);
    expect(data.dineroDisponible, 20200);
  });

  test('expense source affects salary vs savings totals', () async {
    final category = (await service.getCategories()).first;
    final now = DateTime.now();
    final cycle = await service.getCycleForDate(now);
    final day = now.day.toString().padLeft(2, '0');
    final date1 =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-$day';
    final date2 = date1;
    await service.addSavings(4000);
    await service.addExpense(1000, 'Sueldo Expense', category.id!, date1,
        source: 'sueldo');
    await service.addExpense(500, 'Ahorro Expense', category.id!, date2,
        source: 'ahorro');

    final data = await service.getDashboardData(
        year: now.year, month: now.month, cycle: cycle);
    expect(data.totalExpenses, 1500);
    expect(data.totalExpensesSalary, 1000);
    expect(data.totalExpensesSavings, 500);
  });

  test('fixed payment period logic with due dates', () async {
    final category = (await service.getCategories()).first;
    final now = DateTime.now();
    final cycle = await service.getCycleForDate(now);
    await service.addFixedPayment('Gym', 800, now.day, category.id);
    final list =
        await service.getFixedPaymentsForPeriod(now.year, now.month, cycle);
    expect(list.length, 1);
    expect(list.first.dueDate,
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}');
  });

  test('loan deduction types are stored', () async {
    await service.addLoan('Juan', 500, 'Ninguno', '2026-02-10',
        deductionType: 'ninguno');
    await service.addLoan('Ana', 700, 'Gasto', '2026-02-11',
        deductionType: 'gasto');
    await service.addLoan('Leo', 300, 'Ahorro', '2026-02-12',
        deductionType: 'ahorro');

    final loans = await service.getLoans(includePaid: true);
    final types = loans.map((e) => e.deductionType).toSet();
    expect(types.contains('ninguno'), isTrue);
    expect(types.contains('gasto'), isTrue);
    expect(types.contains('ahorro'), isTrue);
  });

  test('savings deposit and withdrawal, including insufficient funds',
      () async {
    await service.addSavings(2000);
    final ok = await service.withdrawSavings(1500);
    final fail = await service.withdrawSavings(1000);

    expect(ok, isTrue);
    expect(fail, isFalse);
  });

  test('salary override takes precedence over base salary', () async {
    await service.setSalary(25000);
    await service.setSalaryOverride(2026, 2, 1, 30000);

    final effective = await service.getSalaryForPeriod(2026, 2, 1);
    expect(effective, 30000);
  });
}
