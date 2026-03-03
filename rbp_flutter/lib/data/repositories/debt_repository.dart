import '../database/database_helper.dart';
import '../models/debt.dart';
import '../models/debt_payment.dart';

class DebtRepository {
  DebtRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _dbHelper;

  Future<int> createDebt({
    required int userId,
    required String name,
    required double principalAmount,
    required double annualRate,
    required int termMonths,
    required String startDate,
    required int paymentDay,
    required double monthlyPayment,
  }) async {
    return _dbHelper.insert('debts', {
      'user_id': userId,
      'name': name,
      'principal_amount': principalAmount,
      'annual_rate': annualRate,
      'term_months': termMonths,
      'start_date': startDate,
      'payment_day': paymentDay,
      'monthly_payment': monthlyPayment,
      'current_balance': principalAmount,
      'is_active': 1,
    });
  }

  Future<List<Debt>> getDebtsByUser(
    int userId, {
    bool includeClosed = true,
  }) async {
    final rows = await _dbHelper.query(
      'debts',
      where: includeClosed ? 'user_id = ?' : 'user_id = ? AND is_active = 1',
      whereArgs: [userId],
      orderBy: 'is_active DESC, created_at DESC',
    );
    return rows.map(Debt.fromMap).toList();
  }

  Future<Debt?> getDebtById(int debtId) async {
    final rows = await _dbHelper.query(
      'debts',
      where: 'id = ?',
      whereArgs: [debtId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return Debt.fromMap(rows.first);
  }

  Future<int> updateDebt(
    int debtId, {
    String? name,
    double? annualRate,
    int? termMonths,
    int? paymentDay,
    double? monthlyPayment,
    double? currentBalance,
    int? isActive,
  }) async {
    final values = <String, Object?>{};
    if (name != null) {
      values['name'] = name;
    }
    if (annualRate != null) {
      values['annual_rate'] = annualRate;
    }
    if (termMonths != null) {
      values['term_months'] = termMonths;
    }
    if (paymentDay != null) {
      values['payment_day'] = paymentDay;
    }
    if (monthlyPayment != null) {
      values['monthly_payment'] = monthlyPayment;
    }
    if (currentBalance != null) {
      values['current_balance'] = currentBalance;
    }
    if (isActive != null) {
      values['is_active'] = isActive;
    }
    if (values.isEmpty) {
      return 0;
    }
    values['updated_at'] = DateTime.now().toIso8601String();
    return _dbHelper.update(
      'debts',
      values,
      where: 'id = ?',
      whereArgs: [debtId],
    );
  }

  Future<int> deleteDebt(int debtId) async {
    await _dbHelper.delete(
      'debt_payments',
      where: 'debt_id = ?',
      whereArgs: [debtId],
    );
    return _dbHelper.delete('debts', where: 'id = ?', whereArgs: [debtId]);
  }

  Future<int> createDebtPayment({
    required int debtId,
    required String paymentDate,
    required double totalAmount,
    required double interestAmount,
    required double capitalAmount,
    String? notes,
  }) async {
    return _dbHelper.insert('debt_payments', {
      'debt_id': debtId,
      'payment_date': paymentDate,
      'total_amount': totalAmount,
      'interest_amount': interestAmount,
      'capital_amount': capitalAmount,
      'notes': notes,
    });
  }

  Future<List<DebtPayment>> getDebtPayments(int debtId) async {
    final rows = await _dbHelper.query(
      'debt_payments',
      where: 'debt_id = ?',
      whereArgs: [debtId],
      orderBy: 'payment_date DESC, id DESC',
    );
    return rows.map(DebtPayment.fromMap).toList();
  }

  Future<int> countDebtPayments(int debtId) async {
    final rows = await _dbHelper.rawQuery(
      'SELECT COUNT(*) AS c FROM debt_payments WHERE debt_id = ?',
      [debtId],
    );
    return (rows.first['c'] as num?)?.toInt() ?? 0;
  }
}
