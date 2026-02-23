class ExtraIncome {
  const ExtraIncome({
    this.id,
    required this.userId,
    required this.amount,
    required this.description,
    required this.date,
    this.incomeType = 'bonus',
    this.createdAt,
  });

  final int? id;
  final int userId;
  final double amount;
  final String description;
  final String date;
  final String incomeType;
  final String? createdAt;

  factory ExtraIncome.fromMap(Map<String, Object?> map) {
    return ExtraIncome(
      id: map['id'] as int?,
      userId: (map['user_id'] as num).toInt(),
      amount: (map['amount'] as num).toDouble(),
      description: (map['description'] ?? '') as String,
      date: (map['date'] ?? '') as String,
      incomeType: (map['income_type'] ?? 'bonus') as String,
      createdAt: map['created_at'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'description': description,
      'date': date,
      'income_type': incomeType,
      'created_at': createdAt,
    };
  }
}
