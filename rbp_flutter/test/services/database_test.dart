import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:rbp_flutter/data/database/database_helper.dart';
import 'package:rbp_flutter/data/repositories/category_repository.dart';
import 'package:rbp_flutter/data/repositories/expense_repository.dart';
import 'package:rbp_flutter/data/repositories/fixed_payment_repository.dart';
import 'package:rbp_flutter/data/repositories/income_repository.dart';
import 'package:rbp_flutter/data/repositories/loan_repository.dart';
import 'package:rbp_flutter/data/repositories/savings_repository.dart';
import 'package:rbp_flutter/data/repositories/settings_repository.dart';
import 'package:rbp_flutter/data/repositories/user_repository.dart';

void main() {
  late DatabaseHelper dbHelper;
  late UserRepository userRepository;
  late CategoryRepository categoryRepository;
  late ExpenseRepository expenseRepository;
  late FixedPaymentRepository fixedPaymentRepository;
  late IncomeRepository incomeRepository;
  late LoanRepository loanRepository;
  late SavingsRepository savingsRepository;
  late SettingsRepository settingsRepository;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    dbHelper = DatabaseHelper(
      databaseName: inMemoryDatabasePath,
      useDocumentsDirectory: false,
    );
    userRepository = UserRepository(dbHelper: dbHelper);
    categoryRepository = CategoryRepository(dbHelper: dbHelper);
    expenseRepository = ExpenseRepository(dbHelper: dbHelper);
    fixedPaymentRepository = FixedPaymentRepository(dbHelper: dbHelper);
    incomeRepository = IncomeRepository(dbHelper: dbHelper);
    loanRepository = LoanRepository(dbHelper: dbHelper);
    savingsRepository = SavingsRepository(dbHelper: dbHelper);
    settingsRepository = SettingsRepository(dbHelper: dbHelper);
  });

  tearDown(() async {
    await dbHelper.close();
  });

  test('CRUD operations for core tables', () async {
    final userId =
        await userRepository.create('Jose', email: 'jose@example.com');
    final categoryId = await categoryRepository.create(userId, 'Comida');

    final expenseId = await expenseRepository.create(
      userId: userId,
      amount: 1000,
      description: 'Supermercado',
      date: '2026-02-10',
      quincenalCycle: 1,
      categoryIds: [categoryId],
      status: 'completed_salary',
    );
    final expense = await expenseRepository.getById(expenseId);
    expect(expense, isNotNull);
    expect(expense!.categoryIds, isNotNull);

    final fixedPaymentId = await fixedPaymentRepository.create(
      userId: userId,
      name: 'Netflix',
      amount: 450,
      dueDay: 15,
      categoryId: categoryId,
    );
    expect(fixedPaymentId, greaterThan(0));
    await fixedPaymentRepository.setRecordStatus(
        fixedPaymentId, 2026, 2, 1, true);
    final fixedStatus = await fixedPaymentRepository.getRecordStatus(
      fixedPaymentId,
      2026,
      2,
      1,
    );
    expect(fixedStatus, 'paid');

    final loanId = await loanRepository.create(
      userId: userId,
      person: 'Juan',
      amount: 500,
      description: 'Prestamo',
      date: '2026-02-12',
      deductionType: 'ninguno',
    );
    expect(loanId, greaterThan(0));

    final incomeId = await incomeRepository.create(
      userId: userId,
      amount: 1200,
      description: 'Freelance',
      date: '2026-02-11',
    );
    expect(incomeId, greaterThan(0));

    await savingsRepository.recordSavings(userId, 3000, 2026, 2, 1);
    final savings = await savingsRepository.getByPeriod(userId, 2026, 2, 1);
    expect(savings, isNotNull);
    expect(savings!.lastQuincenalSavings, 3000);
  });

  test('foreign key constraints are enforced', () async {
    expect(
      () async => categoryRepository.create(99999, 'Invalida'),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('upsert behavior for settings and salary override', () async {
    final userId =
        await userRepository.create('Jose', email: 'jose@example.com');

    await settingsRepository.setSetting(userId, 'quincenal_pay_day_1', '1');
    await settingsRepository.setSetting(userId, 'quincenal_pay_day_1', '15');
    final q1 =
        await settingsRepository.getSetting(userId, 'quincenal_pay_day_1');
    expect(q1, '15');

    await settingsRepository.setSalaryOverride(userId, 2026, 2, 1, 25000);
    await settingsRepository.setSalaryOverride(userId, 2026, 2, 1, 28000);
    final override =
        await settingsRepository.getSalaryOverride(userId, 2026, 2, 1);
    expect(override, 28000);
  });

  test('custom quincena storage and retrieval', () async {
    final userId =
        await userRepository.create('Jose', email: 'jose@example.com');

    await settingsRepository.setCustomQuincena(
      userId,
      2026,
      2,
      1,
      '2026-02-01',
      '2026-02-14',
    );
    final custom =
        await settingsRepository.getCustomQuincena(userId, 2026, 2, 1);
    expect(custom, isNotNull);
    expect(custom!.startDate, '2026-02-01');
    expect(custom.endDate, '2026-02-14');
  });
}
