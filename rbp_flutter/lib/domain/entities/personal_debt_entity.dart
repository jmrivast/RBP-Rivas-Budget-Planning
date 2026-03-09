class PersonalDebtEntity {
  const PersonalDebtEntity({
    required this.id,
    required this.person,
    required this.totalAmount,
    required this.currentBalance,
    this.description,
    required this.date,
    this.isPaid = false,
  });
  final int id;
  final String person;
  final double totalAmount;
  final double currentBalance;
  final String? description;
  final String date;
  final bool isPaid;
}

class PersonalDebtPaymentEntity {
  const PersonalDebtPaymentEntity({
    required this.id,
    required this.personalDebtId,
    required this.paymentDate,
    required this.amount,
    this.notes,
  });
  final int id;
  final int personalDebtId;
  final String paymentDate;
  final double amount;
  final String? notes;
}
