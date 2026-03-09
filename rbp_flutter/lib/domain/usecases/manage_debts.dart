import '../../core/errors/result.dart';
import '../../core/errors/failures.dart';
import '../entities/debt_entity.dart';
import '../entities/personal_debt_entity.dart';
import '../repositories/debt_repository.dart';
import '../repositories/personal_debt_repository.dart';

class GetDebts {
  const GetDebts(this._repository);
  final IDebtRepository _repository;

  Future<Result<List<DebtEntity>>> call(int userId, {bool includeClosed = true}) async {
    try {
      return Success(await _repository.getByUser(userId, includeClosed: includeClosed));
    } catch (e) {
      return Err(ServerFailure(e.toString()));
    }
  }
}

class GetPersonalDebts {
  const GetPersonalDebts(this._repository);
  final IPersonalDebtRepository _repository;

  Future<Result<List<PersonalDebtEntity>>> call(int userId, {bool includePaid = true}) async {
    try {
      return Success(await _repository.getByUser(userId, includePaid: includePaid));
    } catch (e) {
      return Err(ServerFailure(e.toString()));
    }
  }
}
