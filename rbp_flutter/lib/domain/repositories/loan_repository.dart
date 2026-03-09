import '../entities/loan_entity.dart';

abstract class ILoanRepository {
  Future<List<LoanEntity>> getByUser(int userId, {bool includePaid});
  Future<int> create({
    required int userId, required String person, required double amount,
    String? description, required String date, String deductionType,
  });
  Future<void> update(int id, {String? person, double? amount, String? description, String? deductionType});
  Future<void> markPaid(int id);
  Future<void> delete(int id);
}
