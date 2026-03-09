import '../../core/errors/result.dart';
import '../../core/errors/failures.dart';
import '../entities/category_entity.dart';
import '../repositories/category_repository.dart';

class GetCategories {
  const GetCategories(this._repository);
  final ICategoryRepository _repository;

  Future<Result<List<CategoryEntity>>> call(int userId) async {
    try {
      return Success(await _repository.getByUser(userId));
    } catch (e) {
      return Err(ServerFailure(e.toString()));
    }
  }
}

class AddCategory {
  const AddCategory(this._repository);
  final ICategoryRepository _repository;

  Future<Result<int>> call(int userId, String name) async {
    try {
      return Success(await _repository.create(userId, name));
    } catch (e) {
      return Err(ServerFailure(e.toString()));
    }
  }
}

class RenameCategory {
  const RenameCategory(this._repository);
  final ICategoryRepository _repository;

  Future<Result<void>> call(int id, String newName) async {
    try {
      await _repository.rename(id, newName);
      return const Success(null);
    } catch (e) {
      return Err(ServerFailure(e.toString()));
    }
  }
}

class DeleteCategory {
  const DeleteCategory(this._repository);
  final ICategoryRepository _repository;

  Future<Result<void>> call(int id) async {
    try {
      await _repository.delete(id);
      return const Success(null);
    } catch (e) {
      return Err(ServerFailure(e.toString()));
    }
  }
}
