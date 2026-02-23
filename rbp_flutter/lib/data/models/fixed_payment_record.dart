class FixedPaymentRecord {
  const FixedPaymentRecord({
    this.id,
    required this.fixedPaymentId,
    this.expenseId,
    required this.year,
    required this.month,
    this.quincenalCycle,
    this.status = 'pending',
    this.paidDate,
    this.createdAt,
  });

  final int? id;
  final int fixedPaymentId;
  final int? expenseId;
  final int year;
  final int month;
  final int? quincenalCycle;
  final String status;
  final String? paidDate;
  final String? createdAt;

  factory FixedPaymentRecord.fromMap(Map<String, Object?> map) {
    return FixedPaymentRecord(
      id: map['id'] as int?,
      fixedPaymentId: (map['fixed_payment_id'] as num).toInt(),
      expenseId: (map['expense_id'] as num?)?.toInt(),
      year: (map['year'] as num).toInt(),
      month: (map['month'] as num).toInt(),
      quincenalCycle: (map['quincenal_cycle'] as num?)?.toInt(),
      status: (map['status'] ?? 'pending') as String,
      paidDate: map['paid_date'] as String?,
      createdAt: map['created_at'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'fixed_payment_id': fixedPaymentId,
      'expense_id': expenseId,
      'year': year,
      'month': month,
      'quincenal_cycle': quincenalCycle,
      'status': status,
      'paid_date': paidDate,
      'created_at': createdAt,
    };
  }
}
