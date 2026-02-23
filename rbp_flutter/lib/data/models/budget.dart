class Budget {
  const Budget({
    this.id,
    required this.userId,
    required this.categoryId,
    required this.amount,
    required this.quincenalCycle,
    required this.year,
    required this.month,
    this.createdAt,
  });

  final int? id;
  final int userId;
  final int categoryId;
  final double amount;
  final int quincenalCycle;
  final int year;
  final int month;
  final String? createdAt;

  factory Budget.fromMap(Map<String, Object?> map) {
    return Budget(
      id: map['id'] as int?,
      userId: (map['user_id'] as num).toInt(),
      categoryId: (map['category_id'] as num).toInt(),
      amount: (map['amount'] as num).toDouble(),
      quincenalCycle: (map['quincenal_cycle'] as num).toInt(),
      year: (map['year'] as num).toInt(),
      month: (map['month'] as num).toInt(),
      createdAt: map['created_at'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'amount': amount,
      'quincenal_cycle': quincenalCycle,
      'year': year,
      'month': month,
      'created_at': createdAt,
    };
  }
}
