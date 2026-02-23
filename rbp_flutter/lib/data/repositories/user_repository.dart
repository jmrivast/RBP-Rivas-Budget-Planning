import '../database/database_helper.dart';
import '../models/user.dart';

class UserRepository {
  UserRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _dbHelper;

  Future<int> create(String username, {String? email}) async {
    return _dbHelper.insert('users', {
      'username': username,
      'email': email,
    });
  }

  Future<User?> getById(int userId) async {
    final rows = await _dbHelper.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return User.fromMap(rows.first);
  }

  Future<User?> getByUsername(String username) async {
    final rows = await _dbHelper.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return User.fromMap(rows.first);
  }

  Future<List<User>> getAllActive() async {
    final rows = await _dbHelper.query(
      'users',
      where: 'is_active = 1',
      orderBy: 'id',
    );
    return rows.map(User.fromMap).toList();
  }

  Future<int> ensureDefaultUser() async {
    final existing = await getByUsername('Jose');
    if (existing != null && existing.id != null) {
      return existing.id!;
    }
    return create('Jose', email: 'jose@example.com');
  }
}
