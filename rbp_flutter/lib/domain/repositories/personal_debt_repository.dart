import '../entities/personal_debt_entity.dart';

abstract class IPersonalDebtRepository {
  Future<List<PersonalDebtEntity>> getByUser(int userId, {bool includePaid});
  Future<int> create({
    required int userId, required String person, required double amount,
    String? description, required String date,
  });
  Future<void> update(int id, {String? person, double? totalAmount, String? description});
  Future<void> delete(int id);
  Future<List<PersonalDebtPaymentEntity>> getPayments(int debtId);
  Future<void> registerPayment({required int debtId, required double amount, required String paymentDate, String? notes});
}
