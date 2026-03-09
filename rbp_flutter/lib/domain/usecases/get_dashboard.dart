import '../../core/errors/result.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/dashboard_entity.dart';
import '../repositories/dashboard_repository.dart';

class GetDashboardParams {
  const GetDashboardParams({required this.year, required this.month, required this.cycle});
  final int year;
  final int month;
  final int cycle;
}

class GetDashboard implements UseCase<DashboardEntity, GetDashboardParams> {
  const GetDashboard(this._repository);
  final IDashboardRepository _repository;

  @override
  Future<Result<DashboardEntity>> call(GetDashboardParams params) async {
    try {
      final data = await _repository.getDashboardData(
        year: params.year, month: params.month, cycle: params.cycle,
      );
      return Success(data);
    } catch (e) {
      return Err(ServerFailure(e.toString()));
    }
  }
}
