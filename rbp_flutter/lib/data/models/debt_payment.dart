class DebtPayment {
  const DebtPayment({
    this.id,
    required this.debtId,
    required this.paymentDate,
    required this.totalAmount,
    required this.interestAmount,
    required this.capitalAmount,
    this.notes,
    this.createdAt,
  });

  final int? id;
  final int debtId;
  final String paymentDate;
  final double totalAmount;
  final double interestAmount;
  final double capitalAmount;
  final String? notes;
  final String? createdAt;

  factory DebtPayment.fromMap(Map<String, Object?> map) {
    return DebtPayment(
      id: map['id'] as int?,
      debtId: (map['debt_id'] as num).toInt(),
      paymentDate: (map['payment_date'] ?? '') as String,
      totalAmount: (map['total_amount'] as num).toDouble(),
      interestAmount: (map['interest_amount'] as num).toDouble(),
      capitalAmount: (map['capital_amount'] as num).toDouble(),
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String?,
    );
  }
}
