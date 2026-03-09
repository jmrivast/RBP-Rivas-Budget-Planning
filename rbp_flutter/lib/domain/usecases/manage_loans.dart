import '../../core/errors/result.dart';
import '../../core/errors/failures.dart';
import '../entities/loan_entity.dart';
import '../repositories/loan_repository.dart';

class GetLoans {
  const GetLoans(this._repository);
  final ILoanRepository _repository;

  Future<Result<List<LoanEntity>>> call(int userId, {bool includePaid = true}) async {
    try {
      return Success(await _repository.getByUser(userId, includePaid: includePaid));
    } catch (e) {
      return Err(ServerFailure(e.toString()));
    }
  }
}

class AddLoanParams {
  const AddLoanParams({
    required this.userId, required this.person, required this.amount,
    this.description, required this.date, this.deductionType = 'ninguno',
  });
  final int userId;
  final String person;
  final double amount;
  final String? description;
  final String date;
  final String deductionType;
}

class AddLoan {
  const AddLoan(this._repository);
  final ILoanRepository _repository;

  Future<Result<int>> call(AddLoanParams params) async {
    try {
      final id = await _repository.create(
        userId: params.userId, person: params.person, amount: params.amount,
        description: params.description, date: params.date,
        deductionType: params.deductionType,
      );
      return Success(id);
    } catch (e) {
      return Err(ServerFailure(e.toString()));
    }
  }
}
