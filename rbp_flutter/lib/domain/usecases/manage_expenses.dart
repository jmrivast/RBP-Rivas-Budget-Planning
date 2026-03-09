import '../../core/errors/result.dart';
import '../../core/errors/failures.dart';
import '../entities/expense_entity.dart';
import '../repositories/expense_repository.dart';
import '../repositories/savings_repository.dart';

class AddExpenseParams {
  const AddExpenseParams({
    required this.userId, required this.amount, required this.description,
    required this.date, required this.categoryId, required this.cycle,
    this.source = 'sueldo',
  });
  final int userId;
  final double amount;
  final String description;
  final String date;
  final int categoryId;
  final int cycle;
  final String source;
}

class AddExpense {
  const AddExpense(this._expenseRepo, this._savingsRepo);
  final IExpenseRepository _expenseRepo;
  final ISavingsRepository _savingsRepo;

  Future<Result<int>> call(AddExpenseParams params) async {
    try {
      if (params.source == 'ahorro') {
        final ok = await _savingsRepo.withdrawSavings(params.userId, params.amount);
        if (!ok) return const Err(InsufficientFundsFailure('Fondos insuficientes en ahorro.'));
      }
      final id = await _expenseRepo.create(
        userId: params.userId, amount: params.amount,
        description: params.description, date: params.date,
        cycle: params.cycle, source: params.source,
      );
      return Success(id);
    } catch (e) {
      return Err(ServerFailure(e.toString()));
    }
  }
}

class UpdateExpenseParams {
  const UpdateExpenseParams({required this.id, this.amount, this.description, this.date, this.categoryId});
  final int id;
  final double? amount;
  final String? description;
  final String? date;
  final int? categoryId;
}

class UpdateExpense {
  const UpdateExpense(this._repository);
  final IExpenseRepository _repository;

  Future<Result<void>> call(UpdateExpenseParams params) async {
    try {
      await _repository.update(params.id,
        amount: params.amount, description: params.description,
        date: params.date, categoryId: params.categoryId,
      );
      return const Success(null);
    } catch (e) {
      return Err(ServerFailure(e.toString()));
    }
  }
}

class DeleteExpense {
  const DeleteExpense(this._repository);
  final IExpenseRepository _repository;

  Future<Result<void>> call(int expenseId) async {
    try {
      await _repository.delete(expenseId);
      return const Success(null);
    } catch (e) {
      return Err(ServerFailure(e.toString()));
    }
  }
}

class GetExpensesByPeriod {
  const GetExpensesByPeriod(this._repository);
  final IExpenseRepository _repository;

  Future<Result<List<ExpenseEntity>>> call(int userId, String start, String end) async {
    try {
      final list = await _repository.getByPeriod(userId, start, end);
      return Success(list);
    } catch (e) {
      return Err(ServerFailure(e.toString()));
    }
  }
}
