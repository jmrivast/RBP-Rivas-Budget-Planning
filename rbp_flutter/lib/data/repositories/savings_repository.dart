import '../database/database_helper.dart';
import '../models/savings.dart';
import '../models/savings_goal.dart';

class SavingsRepository {
  SavingsRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _dbHelper;

  Future<void> recordSavings(
    int userId,
    double amount,
    int year,
    int month,
    int quincenalCycle,
  ) async {
    await _dbHelper.rawExecute(
      '''
INSERT OR REPLACE INTO savings
(user_id, last_quincenal_savings, total_saved, year, month, quincenal_cycle)
VALUES (?, ?,
  COALESCE((SELECT total_saved FROM savings WHERE user_id = ? ORDER BY created_at DESC LIMIT 1), 0) + ?,
  ?, ?, ?)
''',
      [userId, amount, userId, amount, year, month, quincenalCycle],
    );
  }

  Future<void> addExtraSavings(
    int userId,
    double amount,
    int year,
    int month,
    int quincenalCycle,
  ) async {
    final rows = await _dbHelper.query(
      'savings',
      columns: ['id'],
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (rows.isNotEmpty) {
      await _dbHelper.rawExecute(
        'UPDATE savings SET total_saved = total_saved + ? WHERE id = ?',
        [amount, rows.first['id']],
      );
      return;
    }
    await _dbHelper.insert('savings', {
      'user_id': userId,
      'last_quincenal_savings': 0,
      'total_saved': amount,
      'year': year,
      'month': month,
      'quincenal_cycle': quincenalCycle,
    });
  }

  Future<double> getTotalSavings(int userId) async {
    final rows = await _dbHelper.rawQuery(
      'SELECT total_saved FROM savings WHERE user_id = ? ORDER BY created_at DESC LIMIT 1',
      [userId],
    );
    if (rows.isEmpty) {
      return 0;
    }
    return (rows.first['total_saved'] as num?)?.toDouble() ?? 0;
  }

  Future<bool> withdrawSavings(int userId, double amount) async {
    final current = await getTotalSavings(userId);
    if (amount > current) {
      return false;
    }
    await _dbHelper.rawExecute(
      '''
UPDATE savings SET total_saved = total_saved - ?
WHERE user_id = ? AND id = (
  SELECT id FROM savings WHERE user_id = ? ORDER BY created_at DESC LIMIT 1
)
''',
      [amount, userId, userId],
    );
    return true;
  }

  Future<Savings?> getByPeriod(
      int userId, int year, int month, int cycle) async {
    final rows = await _dbHelper.query(
      'savings',
      where: 'user_id = ? AND year = ? AND month = ? AND quincenal_cycle = ?',
      whereArgs: [userId, year, month, cycle],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return Savings.fromMap(rows.first);
  }

  Future<int> createGoal(int userId, String name, double targetAmount) async {
    return _dbHelper.insert('savings_goals', {
      'user_id': userId,
      'name': name,
      'target_amount': targetAmount,
    });
  }

  Future<List<SavingsGoal>> getGoals(int userId) async {
    final rows = await _dbHelper.query(
      'savings_goals',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at',
    );
    return rows.map(SavingsGoal.fromMap).toList();
  }

  Future<int> deleteGoal(int goalId) async {
    return _dbHelper
        .delete('savings_goals', where: 'id = ?', whereArgs: [goalId]);
  }

  Future<int> updateGoal(int goalId, String name, double targetAmount) async {
    return _dbHelper.update(
      'savings_goals',
      {'name': name, 'target_amount': targetAmount},
      where: 'id = ?',
      whereArgs: [goalId],
    );
  }
}
