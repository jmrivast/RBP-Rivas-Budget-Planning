import '../entities/expense_entity.dart';

abstract class IExpenseRepository {
  Future<int> create({
    required int userId, required double amount, required String description,
    required String date, required int cycle, String source,
  });
  Future<List<ExpenseEntity>> getByPeriod(int userId, String startDate, String endDate);
  Future<void> update(int id, {double? amount, String? description, String? date, int? categoryId});
  Future<void> delete(int id);
}
