import '../database/database_helper.dart';
import '../models/fixed_payment.dart';

class FixedPaymentRepository {
  FixedPaymentRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _dbHelper;

  Future<int> create({
    required int userId,
    required String name,
    required double amount,
    required int dueDay,
    int? categoryId,
    String frequency = 'monthly',
  }) async {
    return _dbHelper.insert('fixed_payments', {
      'user_id': userId,
      'name': name,
      'amount': amount,
      'category_id': categoryId,
      'due_day': dueDay,
      'frequency': frequency,
    });
  }

  Future<List<FixedPayment>> getActiveByUser(int userId) async {
    final rows = await _dbHelper.query(
      'fixed_payments',
      where: 'user_id = ? AND is_active = 1',
      whereArgs: [userId],
      orderBy: 'due_day',
    );
    return rows.map(FixedPayment.fromMap).toList();
  }

  Future<int> update(
    int paymentId, {
    String? name,
    double? amount,
    int? dueDay,
    int? categoryId,
    bool updateCategory = false,
  }) async {
    final values = <String, Object?>{};
    if (name != null) {
      values['name'] = name;
    }
    if (amount != null) {
      values['amount'] = amount;
    }
    if (dueDay != null) {
      values['due_day'] = dueDay;
    }
    if (updateCategory || categoryId != null) {
      values['category_id'] = categoryId;
    }
    if (values.isEmpty) {
      return 0;
    }
    values['updated_at'] = DateTime.now().toIso8601String();
    return _dbHelper.update(
      'fixed_payments',
      values,
      where: 'id = ?',
      whereArgs: [paymentId],
    );
  }

  Future<int> softDelete(int paymentId) async {
    return _dbHelper.update(
      'fixed_payments',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [paymentId],
    );
  }

  Future<String> getRecordStatus(
    int fixedPaymentId,
    int year,
    int month,
    int cycle, {
    String defaultStatus = 'pending',
  }) async {
    final rows = await _dbHelper.query(
      'fixed_payment_records',
      columns: ['status'],
      where:
          'fixed_payment_id = ? AND year = ? AND month = ? AND quincenal_cycle = ?',
      whereArgs: [fixedPaymentId, year, month, cycle],
      orderBy: 'id DESC',
      limit: 1,
    );
    if (rows.isEmpty || rows.first['status'] == null) {
      return defaultStatus;
    }
    return (rows.first['status'] as String).trim().toLowerCase();
  }

  Future<void> setRecordStatus(
    int fixedPaymentId,
    int year,
    int month,
    int cycle,
    bool paid,
  ) async {
    final status = paid ? 'paid' : 'pending';
    final paidDate =
        paid ? DateTime.now().toIso8601String().split('T').first : null;
    final rows = await _dbHelper.query(
      'fixed_payment_records',
      columns: ['id'],
      where:
          'fixed_payment_id = ? AND year = ? AND month = ? AND quincenal_cycle = ?',
      whereArgs: [fixedPaymentId, year, month, cycle],
      orderBy: 'id DESC',
      limit: 1,
    );

    if (rows.isNotEmpty) {
      await _dbHelper.update(
        'fixed_payment_records',
        {
          'status': status,
          'paid_date': paidDate,
        },
        where: 'id = ?',
        whereArgs: [rows.first['id']],
      );
      return;
    }

    await _dbHelper.insert('fixed_payment_records', {
      'fixed_payment_id': fixedPaymentId,
      'year': year,
      'month': month,
      'quincenal_cycle': cycle,
      'status': status,
      'paid_date': paidDate,
    });
  }

  Future<int> countActiveCategoryUsage(int categoryId) async {
    final rows = await _dbHelper.rawQuery(
      'SELECT COUNT(*) AS c FROM fixed_payments WHERE category_id = ? AND is_active = 1',
      [categoryId],
    );
    return (rows.first['c'] as num).toInt();
  }
}
