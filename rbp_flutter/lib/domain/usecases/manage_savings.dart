import '../../core/errors/result.dart';
import '../../core/errors/failures.dart';
import '../entities/savings_entity.dart';
import '../repositories/savings_repository.dart';

class AddSavings {
  const AddSavings(this._repository);
  final ISavingsRepository _repository;

  Future<Result<void>> call(int userId, double amount) async {
    try {
      await _repository.addSavings(userId, amount);
      return const Success(null);
    } catch (e) {
      return Err(ServerFailure(e.toString()));
    }
  }
}

class WithdrawSavings {
  const WithdrawSavings(this._repository);
  final ISavingsRepository _repository;

  Future<Result<bool>> call(int userId, double amount) async {
    try {
      final ok = await _repository.withdrawSavings(userId, amount);
      if (!ok) return const Err(InsufficientFundsFailure());
      return const Success(true);
    } catch (e) {
      return Err(ServerFailure(e.toString()));
    }
  }
}

class GetSavingsGoals {
  const GetSavingsGoals(this._repository);
  final ISavingsRepository _repository;

  Future<Result<List<SavingsGoalEntity>>> call(int userId) async {
    try {
      return Success(await _repository.getGoals(userId));
    } catch (e) {
      return Err(ServerFailure(e.toString()));
    }
  }
}
