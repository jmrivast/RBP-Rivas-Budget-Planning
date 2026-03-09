import '../../core/errors/result.dart';
import '../../core/errors/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/user_repository.dart';

class GetProfiles {
  const GetProfiles(this._repository);
  final IUserRepository _repository;

  Future<Result<List<UserEntity>>> call() async {
    try {
      return Success(await _repository.getProfiles());
    } catch (e) {
      return Err(ServerFailure(e.toString()));
    }
  }
}

class SwitchProfile {
  const SwitchProfile(this._repository);
  final IUserRepository _repository;

  Future<Result<void>> call(int profileId, {String? pin}) async {
    try {
      await _repository.switchProfile(profileId, pin: pin);
      return const Success(null);
    } catch (e) {
      return Err(AuthFailure(e.toString()));
    }
  }
}
