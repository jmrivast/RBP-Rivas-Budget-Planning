class SavingsGoal {
  const SavingsGoal({
    this.id,
    required this.userId,
    required this.name,
    required this.targetAmount,
    this.createdAt,
  });

  final int? id;
  final int userId;
  final String name;
  final double targetAmount;
  final String? createdAt;

  factory SavingsGoal.fromMap(Map<String, Object?> map) {
    return SavingsGoal(
      id: map['id'] as int?,
      userId: (map['user_id'] as num).toInt(),
      name: (map['name'] ?? '') as String,
      targetAmount: (map['target_amount'] as num).toDouble(),
      createdAt: map['created_at'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'target_amount': targetAmount,
      'created_at': createdAt,
    };
  }
}
