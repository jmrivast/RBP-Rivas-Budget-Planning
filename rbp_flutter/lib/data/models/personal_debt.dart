class PersonalDebt {
  const PersonalDebt({
    this.id,
    required this.userId,
    required this.person,
    required this.totalAmount,
    required this.currentBalance,
    this.description,
    required this.date,
    this.isPaid = 0,
    this.paidDate,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final int userId;
  final String person;
  final double totalAmount;
  final double currentBalance;
  final String? description;
  final String date;
  final int isPaid;
  final String? paidDate;
  final String? createdAt;
  final String? updatedAt;

  bool get isPaidBool => isPaid == 1;

  factory PersonalDebt.fromMap(Map<String, Object?> map) {
    return PersonalDebt(
      id: map['id'] as int?,
      userId: (map['user_id'] as num).toInt(),
      person: (map['person'] ?? '') as String,
      totalAmount: (map['total_amount'] as num).toDouble(),
      currentBalance: (map['current_balance'] as num).toDouble(),
      description: map['description'] as String?,
      date: (map['date'] ?? '') as String,
      isPaid: (map['is_paid'] as num?)?.toInt() ?? 0,
      paidDate: map['paid_date'] as String?,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }
}
