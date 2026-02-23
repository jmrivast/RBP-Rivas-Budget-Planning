class FixedPayment {
  const FixedPayment({
    this.id,
    required this.userId,
    required this.name,
    required this.amount,
    this.categoryId,
    required this.dueDay,
    this.frequency = 'monthly',
    this.isActive = 1,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final int userId;
  final String name;
  final double amount;
  final int? categoryId;
  final int dueDay;
  final String frequency;
  final int isActive;
  final String? createdAt;
  final String? updatedAt;

  factory FixedPayment.fromMap(Map<String, Object?> map) {
    return FixedPayment(
      id: map['id'] as int?,
      userId: (map['user_id'] as num).toInt(),
      name: (map['name'] ?? '') as String,
      amount: (map['amount'] as num).toDouble(),
      categoryId: (map['category_id'] as num?)?.toInt(),
      dueDay: (map['due_day'] as num).toInt(),
      frequency: (map['frequency'] ?? 'monthly') as String,
      isActive: (map['is_active'] as num?)?.toInt() ?? 1,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  bool get isActiveBool => isActive == 1;
  bool get noFixedDate => dueDay <= 0;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'amount': amount,
      'category_id': categoryId,
      'due_day': dueDay,
      'frequency': frequency,
      'is_active': isActive,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
