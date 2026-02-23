import '../database/database_helper.dart';
import '../models/custom_quincena.dart';

class SettingsRepository {
  SettingsRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _dbHelper;

  Future<void> setPeriodMode(int userId, String mode) async {
    final normalized =
        (mode.trim().toLowerCase() == 'mensual') ? 'mensual' : 'quincenal';
    await _dbHelper.rawExecute(
      '''
INSERT INTO user_period_mode (user_id, mode, updated_at)
VALUES (?, ?, CURRENT_TIMESTAMP)
ON CONFLICT(user_id) DO UPDATE SET
  mode = excluded.mode,
  updated_at = CURRENT_TIMESTAMP
''',
      [userId, normalized],
    );
  }

  Future<String> getPeriodMode(int userId) async {
    final rows = await _dbHelper.query(
      'user_period_mode',
      columns: ['mode'],
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return 'quincenal';
    }
    final mode = ((rows.first['mode'] ?? 'quincenal') as String).toLowerCase();
    return (mode == 'mensual') ? 'mensual' : 'quincenal';
  }

  Future<void> setSetting(int userId, String key, String value) async {
    await _dbHelper.rawExecute(
      '''
INSERT INTO user_settings (user_id, setting_key, setting_value, updated_at)
VALUES (?, ?, ?, CURRENT_TIMESTAMP)
ON CONFLICT(user_id, setting_key) DO UPDATE SET
  setting_value = excluded.setting_value,
  updated_at = CURRENT_TIMESTAMP
''',
      [userId, key, value],
    );
  }

  Future<String> getSetting(int userId, String key,
      {String defaultValue = ''}) async {
    final rows = await _dbHelper.query(
      'user_settings',
      columns: ['setting_value'],
      where: 'user_id = ? AND setting_key = ?',
      whereArgs: [userId, key],
      limit: 1,
    );
    if (rows.isEmpty) {
      return defaultValue;
    }
    return (rows.first['setting_value'] ?? defaultValue) as String;
  }

  Future<void> setSalary(int userId, double amount) async {
    await _dbHelper.rawExecute(
      '''
INSERT INTO user_salary (user_id, amount, updated_at)
VALUES (?, ?, CURRENT_TIMESTAMP)
ON CONFLICT(user_id) DO UPDATE SET
  amount = excluded.amount,
  updated_at = CURRENT_TIMESTAMP
''',
      [userId, amount],
    );
  }

  Future<double> getSalary(int userId) async {
    final rows = await _dbHelper.query(
      'user_salary',
      columns: ['amount'],
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return 0;
    }
    return (rows.first['amount'] as num?)?.toDouble() ?? 0;
  }

  Future<void> setSalaryOverride(
    int userId,
    int year,
    int month,
    int cycle,
    double amount,
  ) async {
    await _dbHelper.rawExecute(
      '''
INSERT INTO salary_overrides (user_id, year, month, cycle, amount, updated_at)
VALUES (?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
ON CONFLICT(user_id, year, month, cycle) DO UPDATE SET
  amount = excluded.amount,
  updated_at = CURRENT_TIMESTAMP
''',
      [userId, year, month, cycle, amount],
    );
  }

  Future<double?> getSalaryOverride(
      int userId, int year, int month, int cycle) async {
    final rows = await _dbHelper.query(
      'salary_overrides',
      columns: ['amount'],
      where: 'user_id = ? AND year = ? AND month = ? AND cycle = ?',
      whereArgs: [userId, year, month, cycle],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return (rows.first['amount'] as num?)?.toDouble();
  }

  Future<int> deleteSalaryOverride(
      int userId, int year, int month, int cycle) async {
    return _dbHelper.delete(
      'salary_overrides',
      where: 'user_id = ? AND year = ? AND month = ? AND cycle = ?',
      whereArgs: [userId, year, month, cycle],
    );
  }

  Future<void> setCustomQuincena(
    int userId,
    int year,
    int month,
    int cycle,
    String startDate,
    String endDate,
  ) async {
    await _dbHelper.rawExecute(
      '''
INSERT INTO custom_quincena (user_id, year, month, cycle, start_date, end_date)
VALUES (?, ?, ?, ?, ?, ?)
ON CONFLICT(user_id, year, month, cycle) DO UPDATE SET
  start_date = excluded.start_date,
  end_date = excluded.end_date
''',
      [userId, year, month, cycle, startDate, endDate],
    );
  }

  Future<CustomQuincena?> getCustomQuincena(
      int userId, int year, int month, int cycle) async {
    final rows = await _dbHelper.query(
      'custom_quincena',
      where: 'user_id = ? AND year = ? AND month = ? AND cycle = ?',
      whereArgs: [userId, year, month, cycle],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return CustomQuincena.fromMap(rows.first);
  }

  Future<(String, String)?> getCustomQuincenaRange(
      int userId, int year, int month, int cycle) async {
    final custom = await getCustomQuincena(userId, year, month, cycle);
    if (custom == null) {
      return null;
    }
    return (custom.startDate, custom.endDate);
  }

  Future<int> deleteCustomQuincena(int customQuincenaId) async {
    return _dbHelper.delete(
      'custom_quincena',
      where: 'id = ?',
      whereArgs: [customQuincenaId],
    );
  }
}
