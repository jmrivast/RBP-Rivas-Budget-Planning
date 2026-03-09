class DebtEntity {
  const DebtEntity({
    required this.id,
    required this.name,
    required this.principalAmount,
    required this.annualRate,
    required this.termMonths,
    required this.startDate,
    required this.paymentDay,
    required this.monthlyPayment,
    required this.currentBalance,
    this.isActive = true,
  });
  final int id;
  final String name;
  final double principalAmount;
  final double annualRate;
  final int termMonths;
  final String startDate;
  final int paymentDay;
  final double monthlyPayment;
  final double currentBalance;
  final bool isActive;
}

class DebtPaymentEntity {
  const DebtPaymentEntity({
    required this.id,
    required this.debtId,
    required this.paymentDate,
    required this.totalAmount,
    required this.interestAmount,
    required this.capitalAmount,
    this.notes,
  });
  final int id;
  final int debtId;
  final String paymentDate;
  final double totalAmount;
  final double interestAmount;
  final double capitalAmount;
  final String? notes;
}
