import '../database/database_helper.dart';
import '../models/category.dart';

class CategoryRepository {
  CategoryRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _dbHelper;

  Future<int> create(
    int userId,
    String name, {
    String? color,
    String? icon,
  }) async {
    return _dbHelper.insert('categories', {
      'user_id': userId,
      'name': name,
      'color': color,
      'icon': icon,
    });
  }

  Future<List<Category>> getByUser(int userId) async {
    final rows = await _dbHelper.query(
      'categories',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'name',
    );
    return rows.map(Category.fromMap).toList();
  }

  Future<int> update(
    int categoryId, {
    String? name,
    String? color,
    String? icon,
  }) async {
    final values = <String, Object?>{};
    if (name != null) {
      values['name'] = name;
    }
    if (color != null) {
      values['color'] = color;
    }
    if (icon != null) {
      values['icon'] = icon;
    }
    if (values.isEmpty) {
      return 0;
    }
    return _dbHelper.update(
      'categories',
      values,
      where: 'id = ?',
      whereArgs: [categoryId],
    );
  }

  Future<int> delete(int categoryId) async {
    return _dbHelper.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [categoryId],
    );
  }
}
