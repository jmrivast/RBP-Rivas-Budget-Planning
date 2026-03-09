import '../../core/errors/result.dart';
import '../../core/errors/failures.dart';
import '../entities/income_entity.dart';
import '../repositories/income_repository.dart';

class AddIncomeParams {
  const AddIncomeParams({required this.userId, required this.amount, required this.description, required this.date});
  final int userId;
  final double amount;
  final String description;
  final String date;
}

class AddIncome {
  const AddIncome(this._repository);
  final IIncomeRepository _repository;

  Future<Result<int>> call(AddIncomeParams params) async {
    try {
      final id = await _repository.create(
        userId: params.userId, amount: params.amount,
        description: params.description, date: params.date,
      );
      return Success(id);
    } catch (e) {
      return Err(ServerFailure(e.toString()));
    }
  }
}

class GetIncomeByPeriod {
  const GetIncomeByPeriod(this._repository);
  final IIncomeRepository _repository;

  Future<Result<List<IncomeEntity>>> call(int userId, int year, int month, int cycle) async {
    try {
      return Success(await _repository.getByPeriod(userId, year, month, cycle));
    } catch (e) {
      return Err(ServerFailure(e.toString()));
    }
  }
}

class UpdateIncome {
  const UpdateIncome(this._repository);
  final IIncomeRepository _repository;

  Future<Result<void>> call(int id, {double? amount, String? description, String? date}) async {
    try {
      await _repository.update(id, amount: amount, description: description, date: date);
      return const Success(null);
    } catch (e) {
      return Err(ServerFailure(e.toString()));
    }
  }
}

class DeleteIncome {
  const DeleteIncome(this._repository);
  final IIncomeRepository _repository;

  Future<Result<void>> call(int id) async {
    try {
      await _repository.delete(id);
      return const Success(null);
    } catch (e) {
      return Err(ServerFailure(e.toString()));
    }
  }
}
