import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:rbp_flutter/data/database/database_helper.dart';
import 'package:rbp_flutter/providers/finance_provider.dart';
import 'package:rbp_flutter/services/finance_service.dart';

void main() {
  late DatabaseHelper dbHelper;
  late FinanceProvider provider;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dbHelper = DatabaseHelper(
      databaseName: inMemoryDatabasePath,
      useDocumentsDirectory: false,
    );
    final service = FinanceService(db: dbHelper);
    provider = FinanceProvider(service: service);
    await provider.init();
  });

  tearDown(() async {
    await dbHelper.close();
  });

  test(
      'loan with ahorro deduction withdraws savings and does not reduce loan budget line',
      () async {
    final now = DateTime.now();
    final date =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    await provider.setSalary(10000);
    await provider.addSavings(2000);
    await provider.addLoan(
      'Ana',
      500,
      'Prestamo descontado del ahorro',
      date,
      deductionType: 'ahorro',
    );

    final data = provider.dashboard!;
    expect(data.totalSavings, 1500);
    expect(data.totalLoans, 0);
    expect(data.dineroInicial, 8000);
    expect(data.dineroDisponible, 8000);
  });

  test(
      'loan with gasto deduction creates expense and not pending-loan budget impact',
      () async {
    final now = DateTime.now();
    final date =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    await provider.setSalary(5000);
    await provider.addLoan(
      'Pedro',
      600,
      'Prestamo descontado como gasto',
      date,
      deductionType: 'gasto',
    );

    final data = provider.dashboard!;
    expect(data.totalLoans, 0);
    expect(data.totalExpensesSalary, 600);
    expect(data.dineroInicial, 5000);
    expect(data.dineroDisponible, 4400);
  });
}
