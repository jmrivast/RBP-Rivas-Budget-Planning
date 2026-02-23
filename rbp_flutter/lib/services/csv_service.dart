import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/models/dashboard_data.dart';
import '../data/models/loan.dart';

class CsvService {
  CsvService({
    Future<Directory> Function()? documentsDirectoryProvider,
  }) : _documentsDirectoryProvider =
            documentsDirectoryProvider ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _documentsDirectoryProvider;

  Future<String> exportDashboardCsv({
    required DashboardData dashboard,
    required List<Loan> loans,
    required String periodLabel,
  }) async {
    final reportsDir = await _ensureReportsDir();
    final suffix =
        dashboard.periodMode == 'mensual' ? 'M' : 'Q${dashboard.cycle}';
    final outputPath = p.join(
      reportsDir.path,
      'gastos_${dashboard.year}_${dashboard.month.toString().padLeft(2, '0')}_$suffix.csv',
    );

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
    final bytes = <int>[0xEF, 0xBB, 0xBF, ...utf8.encode(csv)];
    await File(outputPath).writeAsBytes(bytes, flush: true);
    return outputPath;
  }

  Future<Directory> _ensureReportsDir() async {
    final docs = await _documentsDirectoryProvider();
    final dir = Directory(p.join(docs.path, 'reportes'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
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
