class PersonalDebtPayment {
  const PersonalDebtPayment({
    this.id,
    required this.personalDebtId,
    required this.paymentDate,
    required this.amount,
    this.notes,
    this.createdAt,
  });

  final int? id;
  final int personalDebtId;
  final String paymentDate;
  final double amount;
  final String? notes;
  final String? createdAt;

  factory PersonalDebtPayment.fromMap(Map<String, Object?> map) {
    return PersonalDebtPayment(
      id: map['id'] as int?,
      personalDebtId: (map['personal_debt_id'] as num).toInt(),
      paymentDate: (map['payment_date'] ?? '') as String,
      amount: (map['amount'] as num).toDouble(),
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String?,
    );
  }
}
