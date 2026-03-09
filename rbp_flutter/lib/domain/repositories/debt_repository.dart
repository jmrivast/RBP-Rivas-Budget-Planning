import '../entities/debt_entity.dart';

abstract class IDebtRepository {
  Future<List<DebtEntity>> getByUser(int userId, {bool includeClosed});
  Future<int> create({
    required int userId, required String name, required double principalAmount,
    required double annualRate, required int termMonths, required String startDate,
    required int paymentDay,
  });
  Future<void> update(int id, {String? name, double? annualRate, int? termMonths, int? paymentDay});
  Future<void> delete(int id);
  Future<List<DebtPaymentEntity>> getPayments(int debtId);
  Future<void> registerPayment({
    required int debtId, required String paymentDate,
    required double totalAmount, required double interestAmount,
    required double capitalAmount, String? notes,
  });
}
