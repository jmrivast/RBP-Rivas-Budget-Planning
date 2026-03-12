import 'dart:html' as html;
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:path/path.dart' as p;

import '../data/models/dashboard_data.dart';
import '../data/models/loan.dart';

class CsvService {
  CsvService();

  Future<String> exportDashboardCsv({
    required DashboardData dashboard,
    required List<Loan> loans,
    required String periodLabel,
  }) async {
    final suffix =
        dashboard.periodMode == 'mensual' ? 'M' : 'Q${dashboard.cycle}';
    final fileName =
        'gastos_${dashboard.year}_${dashboard.month.toString().padLeft(2, '0')}_$suffix.csv';

    final rows = <List<dynamic>>[];
    rows.add(['Fecha', 'Descripcion', 'Categoria', 'Monto']);
    for (final expense in dashboard.rawExpenses) {
      final catNames = _categoryNames(
        expense.categoryIds,
        dashboard.categoriesById,
      );
      rows.add([
        expense.date,
        expense.description,
        catNames,
        expense.amount,
      ]);
    }

    final csv = const ListToCsvConverter().convert(rows);
    final bytes = Uint8List.fromList(<int>[0xEF, 0xBB, 0xBF, ...csv.codeUnits]);
    _downloadBytes(
      fileName: fileName,
      bytes: bytes,
      mimeType: 'text/csv;charset=utf-8',
    );
    return fileName;
  }

  void _downloadBytes({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) {
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..download = p.basename(fileName)
      ..style.display = 'none';
    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
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
