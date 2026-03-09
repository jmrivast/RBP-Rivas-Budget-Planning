import '../entities/category_entity.dart';

abstract class ICategoryRepository {
  Future<List<CategoryEntity>> getByUser(int userId);
  Future<int> create(int userId, String name);
  Future<void> rename(int id, String newName);
  Future<void> delete(int id);
}
