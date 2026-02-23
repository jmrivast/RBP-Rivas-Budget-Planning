import '../database/database_helper.dart';
import '../models/extra_income.dart';

class IncomeRepository {
  IncomeRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _dbHelper;

  Future<int> create({
    required int userId,
    required double amount,
    required String description,
    required String date,
    String incomeType = 'bonus',
  }) async {
    return _dbHelper.insert('extra_income', {
      'user_id': userId,
      'amount': amount,
      'description': description,
      'date': date,
      'income_type': incomeType,
    });
  }

  Future<List<ExtraIncome>> getByRange(
      int userId, String startDate, String endDate) async {
    final rows = await _dbHelper.query(
      'extra_income',
      where: 'user_id = ? AND date >= ? AND date <= ?',
      whereArgs: [userId, startDate, endDate],
      orderBy: 'date DESC',
    );
    return rows.map(ExtraIncome.fromMap).toList();
  }

  Future<double> getTotalByRange(
      int userId, String startDate, String endDate) async {
    final rows = await _dbHelper.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) AS total FROM extra_income WHERE user_id = ? AND date >= ? AND date <= ?',
      [userId, startDate, endDate],
    );
    return (rows.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<int> update(
    int incomeId, {
    double? amount,
    String? description,
    String? date,
  }) async {
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
    if (values.isEmpty) {
      return 0;
    }
    return _dbHelper
        .update('extra_income', values, where: 'id = ?', whereArgs: [incomeId]);
  }

  Future<int> delete(int incomeId) async {
    return _dbHelper
        .delete('extra_income', where: 'id = ?', whereArgs: [incomeId]);
  }
}
