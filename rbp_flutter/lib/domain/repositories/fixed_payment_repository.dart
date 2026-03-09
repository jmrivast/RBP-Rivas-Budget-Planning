import '../entities/fixed_payment_entity.dart';

abstract class IFixedPaymentRepository {
  Future<List<FixedPaymentEntity>> getByUser(int userId);
  Future<int> create({
    required int userId, required String name, required double amount,
    required int dueDay, int? categoryId, bool noFixedDate,
  });
  Future<void> update(int id, {String? name, double? amount, int? dueDay, int? categoryId});
  Future<void> delete(int id);
  Future<void> setPaid(int paymentId, int year, int month, int cycle, bool paid);
}
