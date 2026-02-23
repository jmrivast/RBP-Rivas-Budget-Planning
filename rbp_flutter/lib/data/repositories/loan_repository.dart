import '../database/database_helper.dart';
import '../models/loan.dart';

class LoanRepository {
  LoanRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _dbHelper;

  Future<int> create({
    required int userId,
    required String person,
    required double amount,
    required String description,
    required String date,
    String deductionType = 'ninguno',
  }) async {
    return _dbHelper.insert('loans', {
      'user_id': userId,
      'person': person,
      'amount': amount,
      'description': description,
      'date': date,
      'deduction_type': deductionType,
    });
  }

  Future<List<Loan>> getByUser(int userId, {bool includePaid = false}) async {
    final rows = await _dbHelper.query(
      'loans',
      where: includePaid ? 'user_id = ?' : 'user_id = ? AND is_paid = 0',
      whereArgs: [userId],
      orderBy: includePaid ? 'is_paid ASC, date DESC' : 'date DESC',
    );
    return rows.map(Loan.fromMap).toList();
  }

  Future<int> markPaid(int loanId) async {
    return _dbHelper.update(
      'loans',
      {
        'is_paid': 1,
        'paid_date': DateTime.now().toIso8601String().split('T').first,
      },
      where: 'id = ?',
      whereArgs: [loanId],
    );
  }

  Future<int> delete(int loanId) async {
    return _dbHelper.delete('loans', where: 'id = ?', whereArgs: [loanId]);
  }

  Future<int> update(
    int loanId, {
    String? person,
    double? amount,
    String? description,
    String? deductionType,
  }) async {
    final values = <String, Object?>{};
    if (person != null) {
      values['person'] = person;
    }
    if (amount != null) {
      values['amount'] = amount;
    }
    if (description != null) {
      values['description'] = description;
    }
    if (deductionType != null) {
      values['deduction_type'] = deductionType;
    }
    if (values.isEmpty) {
      return 0;
    }
    return _dbHelper
        .update('loans', values, where: 'id = ?', whereArgs: [loanId]);
  }

  Future<double> getTotalUnpaid(int userId) async {
    final rows = await _dbHelper.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) AS total FROM loans WHERE user_id = ? AND is_paid = 0',
      [userId],
    );
    return (rows.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<double> getTotalAffectingBudget(int userId) async {
    final rows = await _dbHelper.rawQuery(
      '''
SELECT COALESCE(SUM(amount), 0) AS total
FROM loans
WHERE user_id = ?
  AND is_paid = 0
  AND (deduction_type IS NULL OR deduction_type = 'ninguno')
''',
      [userId],
    );
    return (rows.first['total'] as num?)?.toDouble() ?? 0;
  }
}
