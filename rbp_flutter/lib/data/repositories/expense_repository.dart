import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/expense.dart';

class ExpenseRepository {
  ExpenseRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _dbHelper;

  Future<int> create({
    required int userId,
    required double amount,
    required String description,
    required String date,
    required int quincenalCycle,
    required List<int> categoryIds,
    String status = 'pending',
  }) async {
    return _dbHelper.transaction<int>((txn) async {
      final expenseId = await txn.insert('expenses', {
        'user_id': userId,
        'amount': amount,
        'description': description,
        'date': date,
        'quincenal_cycle': quincenalCycle,
        'status': status,
      });

      for (final categoryId in categoryIds) {
        await txn.insert('expense_categories', {
          'expense_id': expenseId,
          'category_id': categoryId,
        });
      }
      return expenseId;
    });
  }

  Future<List<Expense>> getByUserAndPeriod(
    int userId,
    int year,
    int month, {
    int? quincenalCycle,
  }) async {
    final whereCycle =
        quincenalCycle != null ? ' AND e.quincenal_cycle = ?' : '';
    final args = <Object?>[
      userId,
      year.toString().padLeft(4, '0'),
      month.toString().padLeft(2, '0')
    ];
    if (quincenalCycle != null) {
      args.add(quincenalCycle);
    }
    final rows = await _dbHelper.rawQuery(
      '''
SELECT e.*, GROUP_CONCAT(ec.category_id, ',') AS category_ids
FROM expenses e
LEFT JOIN expense_categories ec ON e.id = ec.expense_id
WHERE e.user_id = ?
  AND strftime('%Y', e.date) = ?
  AND strftime('%m', e.date) = ?$whereCycle
GROUP BY e.id
ORDER BY e.date DESC
''',
      args,
    );
    return rows.map(Expense.fromMap).toList();
  }

  Future<List<Expense>> getByRange(
      int userId, String startDate, String endDate) async {
    final rows = await _dbHelper.rawQuery(
      '''
SELECT e.*, GROUP_CONCAT(ec.category_id, ',') AS category_ids
FROM expenses e
LEFT JOIN expense_categories ec ON e.id = ec.expense_id
WHERE e.user_id = ? AND e.date >= ? AND e.date <= ?
GROUP BY e.id
ORDER BY e.date DESC
''',
      [userId, startDate, endDate],
    );
    return rows.map(Expense.fromMap).toList();
  }

  Future<Expense?> getById(int expenseId) async {
    final rows = await _dbHelper.rawQuery(
      '''
SELECT e.*, GROUP_CONCAT(ec.category_id, ',') AS category_ids
FROM expenses e
LEFT JOIN expense_categories ec ON e.id = ec.expense_id
WHERE e.id = ?
GROUP BY e.id
LIMIT 1
''',
      [expenseId],
    );
    if (rows.isEmpty) {
      return null;
    }
    return Expense.fromMap(rows.first);
  }

  Future<void> update(
    int expenseId, {
    double? amount,
    String? description,
    String? date,
    String? status,
    List<int>? categoryIds,
  }) async {
    await _dbHelper.transaction<void>((txn) async {
      final values = <String, Object?>{};
      if (amount != null) {
        values['amount'] = amount;
      }
      if (description != null) {
        values['description'] = description;
      }
      if (date != null) {
        values['date'] = date;
      }
      if (status != null) {
        values['status'] = status;
      }
      if (values.isNotEmpty) {
        values['updated_at'] = DateTime.now().toIso8601String();
        await txn.update('expenses', values,
            where: 'id = ?', whereArgs: [expenseId]);
      }

      if (categoryIds != null) {
        await txn.delete('expense_categories',
            where: 'expense_id = ?', whereArgs: [expenseId]);
        for (final categoryId in categoryIds) {
          await txn.insert(
            'expense_categories',
            {'expense_id': expenseId, 'category_id': categoryId},
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
      }
    });
  }

  Future<int> delete(int expenseId) async {
    return _dbHelper
        .delete('expenses', where: 'id = ?', whereArgs: [expenseId]);
  }

  Future<int> countCategoryUsage(int categoryId) async {
    final rows = await _dbHelper.rawQuery(
      'SELECT COUNT(*) AS c FROM expense_categories WHERE category_id = ?',
      [categoryId],
    );
    return (rows.first['c'] as num).toInt();
  }
}
