import '../entities/income_entity.dart';

abstract class IIncomeRepository {
  Future<List<IncomeEntity>> getByPeriod(int userId, int year, int month, int cycle);
  Future<int> create({required int userId, required double amount, required String description, required String date});
  Future<void> update(int id, {double? amount, String? description, String? date});
  Future<void> delete(int id);
}
