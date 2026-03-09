import '../../core/errors/result.dart';
import '../../core/errors/failures.dart';
import '../entities/fixed_payment_entity.dart';
import '../repositories/fixed_payment_repository.dart';

class GetFixedPayments {
  const GetFixedPayments(this._repository);
  final IFixedPaymentRepository _repository;

  Future<Result<List<FixedPaymentEntity>>> call(int userId) async {
    try {
      return Success(await _repository.getByUser(userId));
    } catch (e) {
      return Err(ServerFailure(e.toString()));
    }
  }
}

class AddFixedPaymentParams {
  const AddFixedPaymentParams({
    required this.userId, required this.name, required this.amount,
    required this.dueDay, this.categoryId, this.noFixedDate = false,
  });
  final int userId;
  final String name;
  final double amount;
  final int dueDay;
  final int? categoryId;
  final bool noFixedDate;
}

class AddFixedPayment {
  const AddFixedPayment(this._repository);
  final IFixedPaymentRepository _repository;

  Future<Result<int>> call(AddFixedPaymentParams params) async {
    try {
      final id = await _repository.create(
        userId: params.userId, name: params.name, amount: params.amount,
        dueDay: params.dueDay, categoryId: params.categoryId,
        noFixedDate: params.noFixedDate,
      );
      return Success(id);
    } catch (e) {
      return Err(ServerFailure(e.toString()));
    }
  }
}

class ToggleFixedPaymentPaid {
  const ToggleFixedPaymentPaid(this._repository);
  final IFixedPaymentRepository _repository;

  Future<Result<void>> call(int paymentId, int year, int month, int cycle, bool paid) async {
    try {
      await _repository.setPaid(paymentId, year, month, cycle, paid);
      return const Success(null);
    } catch (e) {
      return Err(ServerFailure(e.toString()));
    }
  }
}
