import '../entities/dashboard_entity.dart';

abstract class IDashboardRepository {
  Future<DashboardEntity> getDashboardData({required int year, required int month, required int cycle});
}
