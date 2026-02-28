import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:rbp_flutter/data/models/dashboard_data.dart';
import 'package:rbp_flutter/data/models/expense.dart';
import 'package:rbp_flutter/data/models/loan.dart';
import 'package:rbp_flutter/services/csv_service.dart';
import 'package:rbp_flutter/services/pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory sandbox;
  late Directory docsDir;

  setUp(() async {
    sandbox = await Directory.systemTemp.createTemp('rbp_exports_test_');
    docsDir = Directory(p.join(sandbox.path, 'docs'));
    await docsDir.create(recursive: true);
  });

  tearDown(() async {
    if (await sandbox.exists()) {
      await sandbox.delete(recursive: true);
    }
  });

  DashboardData sampleDashboard() {
    const expense = Expense(
      id: 1,
      userId: 1,
      amount: 1250,
      description: 'Supermercado Jumbo',
      date: '2026-02-20',
      quincenalCycle: 2,
      status: 'completed_salary',
      categoryIds: '1',
    );

    const fixed = FixedPaymentWithStatus(
      id: 1,
      name: 'Netflix',
      amount: 270,
      dueDay: 24,
      categoryId: 1,
      isPaid: false,
      isOverdue: false,
      dueDate: '2026-02-24',
    );

    return const DashboardData(
      year: 2026,
      month: 2,
      cycle: 2,
      periodMode: 'quincenal',
      salary: 25000,
      extraIncome: 5000,
      dineroInicial: 30000,
      totalExpenses: 1250,
      totalExpensesSalary: 1250,
      totalExpensesSavings: 0,
      totalFixed: 270,
      totalLoans: 400,
      periodSavings: 0,
      totalSavings: 55000,
      dineroDisponible: 28080,
      avgDaily: 1250,
      expenseCount: 1,
      fixedCount: 1,
      recentExpenses: [],
      fixedPayments: [fixed],
      rawExpenses: [expense],
      categoriesById: {1: 'Supermercado'},
      catTotals: {1: 1250},
      quincenaRange: ('2026-02-14', '2026-02-28'),
    );
  }

  test('csv export creates file with expected rows', () async {
    final csvService =
        CsvService(documentsDirectoryProvider: () async => docsDir);
    final dashboard = sampleDashboard();

    final output = await csvService.exportDashboardCsv(
      dashboard: dashboard,
      loans: const [],
      periodLabel: '14-28 Feb 2026 (Q2)',
    );

    expect(File(output).existsSync(), isTrue);
    final raw = await File(output).readAsString();
    expect(raw.contains('Fecha,Descripcion,Categoria,Monto'), isTrue);
    expect(raw.contains('Supermercado Jumbo'), isTrue);
    expect(raw.contains('Supermercado'), isTrue);
  });

  test('pdf export creates non-empty report file', () async {
    final pdfService =
        PdfService(documentsDirectoryProvider: () async => docsDir);
    final dashboard = sampleDashboard();
    const loans = [
      Loan(
        id: 1,
        userId: 1,
        person: 'Pedro',
        amount: 400,
        description: 'Prestamo personal',
        date: '2026-02-18',
        isPaid: 0,
        deductionType: 'ninguno',
      ),
    ];

    final output = await pdfService.generateDashboardReport(
      dashboard: dashboard,
      loans: loans,
      periodLabel: '14-28 Feb 2026 (Q2)',
    );

    final file = File(output);
    expect(file.existsSync(), isTrue);
    expect(await file.length(), greaterThan(1500));
    expect(p.basename(output), 'reporte_2026_02_Q2.pdf');
  });
}
