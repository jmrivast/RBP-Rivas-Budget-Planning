import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../data/models/dashboard_data.dart';
import '../data/models/loan.dart';

class PdfService {
  static const double _mm = PdfPageFormat.mm;
  static final PdfColor _primary = PdfColor.fromHex('#1565C0');
  static final PdfColor _primaryLight = PdfColor.fromHex('#E3F2FD');
  static final PdfColor _footerGray = PdfColor.fromHex('#757575');

  Future<String> generateDashboardReport({
    required DashboardData dashboard,
    required List<Loan> loans,
    required String periodLabel,
  }) async {
    final reportsDir = await _ensureReportsDir();
    final now = DateTime.now();
    final outputName = dashboard.periodMode == 'mensual'
        ? 'reporte_${dashboard.year}_${dashboard.month.toString().padLeft(2, '0')}_M.pdf'
        : 'reporte_${dashboard.year}_${dashboard.month.toString().padLeft(2, '0')}_Q${dashboard.cycle}.pdf';
    final outputPath = p.join(reportsDir.path, outputName);

    final logo = await _loadLogo();
    final pendingLoans = loans.where((loan) => !loan.isPaidBool).toList();
    // Legacy/Flet parity: keep the same report formulas as the previous app.
    final totalExpenses =
        dashboard.rawExpenses.fold<double>(0, (sum, e) => sum + e.amount);
    final totalFixed =
        dashboard.fixedPayments.fold<double>(0, (sum, f) => sum + f.amount);
    final totalLoans = pendingLoans.fold<double>(0, (sum, l) => sum + l.amount);
    final dineroInicial = dashboard.salary + dashboard.extraIncome - dashboard.totalSavings;
    final dineroDisponible =
        dineroInicial - totalExpenses - totalFixed - totalLoans;

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
        ),
        footer: (_) => pw.Center(
          child: pw.Text(
            'RBP - Rivas Budget Planning | Generado automaticamente',
            style: pw.TextStyle(
              color: _footerGray,
              fontSize: 8,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ),
        build: (_) => [
          _header(logo),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10 * _mm),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(
                  height: 7 * _mm,
                  child: pw.Center(
                    child: pw.Text(
                      periodLabel,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                pw.SizedBox(
                  height: 6 * _mm,
                  child: pw.Center(
                    child: pw.Text(
                      'Generado: ${_humanDate(now)}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                pw.SizedBox(height: 4 * _mm),
                _sectionTitle('Resumen Financiero'),
                _summaryRows([
                  ('Salario:', _currency(dashboard.salary), false),
                  ('Ingresos extras:', _currency(dashboard.extraIncome), false),
                  ('Ahorro total:', _currency(dashboard.totalSavings), false),
                  ('Dinero inicial:', _currency(dineroInicial), false),
                  ('Total gastos:', _currency(totalExpenses), false),
                  ('Pagos fijos:', _currency(totalFixed), false),
                  ('Prestamos pend.:', _currency(totalLoans), false),
                  ('Dinero disponible:', _currency(dineroDisponible), true),
                ]),
                pw.SizedBox(height: 3 * _mm),
                if (dashboard.rawExpenses.isNotEmpty) ...[
                  _sectionTitle('Gastos'),
                  _table(
                    headers: const ['Fecha', 'Descripcion', 'Categoria', 'Monto'],
                    widthsMm: const [28, 68, 38, 34],
                    rows: dashboard.rawExpenses.map((expense) {
                      final cats = _categoryNames(expense.categoryIds, dashboard.categoriesById);
                      return [
                        _clip(expense.date, 10),
                        _clip(expense.description, 35),
                        _clip(cats, 20),
                        _currency(expense.amount),
                      ];
                    }).toList(),
                    rightAlignCols: const {3},
                  ),
                  pw.SizedBox(height: 3 * _mm),
                ],
                if (dashboard.fixedPayments.isNotEmpty) ...[
                  _sectionTitle('Pagos Fijos'),
                  _table(
                    headers: const ['Nombre', 'Fecha', 'Monto'],
                    widthsMm: const [70, 28, 34],
                    rows: dashboard.fixedPayments.map((fixed) {
                      final due = fixed.dueDate.isNotEmpty
                          ? fixed.dueDate
                          : (fixed.dueDay > 0 ? '${fixed.dueDay}' : '-');
                      return [
                        _clip(fixed.name, 35),
                        _clip(due, 12),
                        _currency(fixed.amount),
                      ];
                    }).toList(),
                    rightAlignCols: const {2},
                  ),
                  pw.SizedBox(height: 3 * _mm),
                ],
                if (pendingLoans.isNotEmpty) ...[
                  _sectionTitle('Prestamos Pendientes'),
                  _table(
                    headers: const ['Persona', 'Descripcion', 'Monto'],
                    widthsMm: const [48, 58, 34],
                    rows: pendingLoans.map((loan) {
                      return [
                        _clip(loan.person, 25),
                        _clip((loan.description ?? '').trim(), 30),
                        _currency(loan.amount),
                      ];
                    }).toList(),
                    rightAlignCols: const {2},
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    await File(outputPath).writeAsBytes(await doc.save(), flush: true);
    return outputPath;
  }

  pw.Widget _header(pw.MemoryImage? logo) {
    return pw.Container(
      height: 28 * _mm,
      width: double.infinity,
      color: _primary,
      child: pw.Stack(
        children: [
          if (logo != null)
            pw.Positioned(
              left: 10 * _mm,
              top: 4 * _mm,
              child: pw.SizedBox(
                width: 20 * _mm,
                height: 20 * _mm,
                child: pw.Image(logo, fit: pw.BoxFit.contain),
              ),
            ),
          pw.Positioned(
            left: 35 * _mm,
            top: 6 * _mm,
            child: pw.Text(
              'RBP  -  Rivas Budget Planning',
              style: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _sectionTitle(String text) {
    return pw.Container(
      height: 9 * _mm,
      width: double.infinity,
      color: _primary,
      alignment: pw.Alignment.centerLeft,
      child: pw.Text(
        '  $text',
        style: pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  pw.Widget _summaryRows(List<(String, String, bool)> rows) {
    return pw.Column(
      children: rows
          .map(
            (row) => pw.SizedBox(
              height: 7 * _mm,
              child: pw.Row(
                children: [
                  pw.SizedBox(
                    width: 55 * _mm,
                    child: pw.Text(
                      row.$1,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      row.$2,
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: row.$3 ? pw.FontWeight.bold : pw.FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  pw.Widget _table({
    required List<String> headers,
    required List<double> widthsMm,
    required List<List<String>> rows,
    Set<int> rightAlignCols = const {},
  }) {
    final widths = <int, pw.TableColumnWidth>{
      for (var i = 0; i < widthsMm.length; i++) i: pw.FixedColumnWidth(widthsMm[i] * _mm),
    };

    final headerRow = pw.TableRow(
      decoration: pw.BoxDecoration(color: _primaryLight),
      children: [
        for (var i = 0; i < headers.length; i++)
          pw.Container(
            height: 7 * _mm,
            padding: const pw.EdgeInsets.symmetric(horizontal: 1.2 * _mm),
            alignment: rightAlignCols.contains(i) ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
            child: pw.Text(
              headers[i],
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
          ),
      ],
    );

    final bodyRows = rows
        .map(
          (row) => pw.TableRow(
            children: [
              for (var i = 0; i < headers.length; i++)
                pw.Container(
                  height: 6 * _mm,
                  padding: const pw.EdgeInsets.symmetric(horizontal: 1.2 * _mm),
                  alignment: rightAlignCols.contains(i) ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
                  child: pw.Text(
                    i < row.length ? row[i] : '',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
            ],
          ),
        )
        .toList();

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.6),
      columnWidths: widths,
      children: [headerRow, ...bodyRows],
    );
  }

  Future<pw.MemoryImage?> _loadLogo() async {
    try {
      final data = await rootBundle.load('assets/Untitled.png');
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  Future<Directory> _ensureReportsDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'reportes'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  String _humanDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yyyy = date.year.toString().padLeft(4, '0');
    final hh = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy $hh:$min';
  }

  String _currency(double value) {
    return 'RD\$${value.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+\.)'),
          (m) => '${m[1]},',
        )}';
  }

  String _clip(String input, int maxLen) {
    if (input.length <= maxLen) {
      return input;
    }
    return input.substring(0, maxLen);
  }

  String _categoryNames(String? ids, Map<int, String> categoriesById) {
    if (ids == null || ids.trim().isEmpty) {
      return '-';
    }
    final names = ids
        .split(',')
        .map((e) => int.tryParse(e.trim()))
        .whereType<int>()
        .map((id) => categoriesById[id])
        .whereType<String>()
        .toList();
    if (names.isEmpty) {
      return '-';
    }
    return names.join(', ');
  }
}
