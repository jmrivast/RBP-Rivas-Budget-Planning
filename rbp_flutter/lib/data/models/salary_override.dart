class SalaryOverride {
  const SalaryOverride({
    this.id,
    required this.userId,
    required this.year,
    required this.month,
    required this.cycle,
    required this.amount,
    this.updatedAt,
  });

  final int? id;
  final int userId;
  final int year;
  final int month;
  final int cycle;
  final double amount;
  final String? updatedAt;

  factory SalaryOverride.fromMap(Map<String, Object?> map) {
    return SalaryOverride(
      id: map['id'] as int?,
      userId: (map['user_id'] as num).toInt(),
      year: (map['year'] as num).toInt(),
      month: (map['month'] as num).toInt(),
      cycle: (map['cycle'] as num).toInt(),
      amount: (map['amount'] as num).toDouble(),
      updatedAt: map['updated_at'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'year': year,
      'month': month,
      'cycle': cycle,
      'amount': amount,
      'updated_at': updatedAt,
    };
  }
}
