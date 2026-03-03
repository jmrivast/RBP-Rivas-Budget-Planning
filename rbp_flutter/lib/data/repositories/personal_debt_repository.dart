import '../database/database_helper.dart';
import '../models/personal_debt.dart';
import '../models/personal_debt_payment.dart';

class PersonalDebtRepository {
  PersonalDebtRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _dbHelper;

  Future<int> create({
    required int userId,
    required String person,
    required double totalAmount,
    required double currentBalance,
    required String description,
    required String date,
  }) async {
    return _dbHelper.insert('personal_debts', {
      'user_id': userId,
      'person': person,
      'total_amount': totalAmount,
      'current_balance': currentBalance,
      'description': description,
      'date': date,
      'is_paid': 0,
    });
  }

  Future<List<PersonalDebt>> getByUser(
    int userId, {
    bool includePaid = true,
  }) async {
    final rows = await _dbHelper.query(
      'personal_debts',
      where: includePaid ? 'user_id = ?' : 'user_id = ? AND is_paid = 0',
      whereArgs: [userId],
      orderBy: includePaid ? 'is_paid ASC, date DESC' : 'date DESC',
    );
    return rows.map(PersonalDebt.fromMap).toList();
  }

  Future<PersonalDebt?> getById(int id) async {
    final rows = await _dbHelper.query(
      'personal_debts',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return PersonalDebt.fromMap(rows.first);
  }

  Future<int> update(
    int debtId, {
    String? person,
    double? totalAmount,
    double? currentBalance,
    String? description,
    int? isPaid,
    String? paidDate,
  }) async {
    final values = <String, Object?>{};
    if (person != null) {
      values['person'] = person;
    }
    if (totalAmount != null) {
      values['total_amount'] = totalAmount;
    }
    if (currentBalance != null) {
      values['current_balance'] = currentBalance;
    }
    if (description != null) {
      values['description'] = description;
    }
    if (isPaid != null) {
      values['is_paid'] = isPaid;
    }
    if (paidDate != null) {
      values['paid_date'] = paidDate;
    }
    if (values.isEmpty) {
      return 0;
    }
    values['updated_at'] = DateTime.now().toIso8601String();
    return _dbHelper.update(
      'personal_debts',
      values,
      where: 'id = ?',
      whereArgs: [debtId],
    );
  }

  Future<int> delete(int debtId) async {
    await _dbHelper.delete(
      'personal_debt_payments',
      where: 'personal_debt_id = ?',
      whereArgs: [debtId],
    );
    return _dbHelper.delete(
      'personal_debts',
      where: 'id = ?',
      whereArgs: [debtId],
    );
  }

  Future<int> addPayment({
    required int personalDebtId,
    required String paymentDate,
    required double amount,
    String? notes,
  }) async {
    return _dbHelper.insert('personal_debt_payments', {
      'personal_debt_id': personalDebtId,
      'payment_date': paymentDate,
      'amount': amount,
      'notes': notes,
    });
  }

  Future<List<PersonalDebtPayment>> getPayments(int personalDebtId) async {
    final rows = await _dbHelper.query(
      'personal_debt_payments',
      where: 'personal_debt_id = ?',
      whereArgs: [personalDebtId],
      orderBy: 'payment_date DESC, id DESC',
    );
    return rows.map(PersonalDebtPayment.fromMap).toList();
  }

  Future<double> getTotalOutstanding(int userId) async {
    final rows = await _dbHelper.rawQuery(
      '''
SELECT COALESCE(SUM(current_balance), 0) AS total
FROM personal_debts
WHERE user_id = ? AND is_paid = 0
''',
      [userId],
    );
    return (rows.first['total'] as num?)?.toDouble() ?? 0;
  }
}
