class Expense {
  const Expense({
    this.id,
    required this.userId,
    required this.amount,
    required this.description,
    required this.date,
    required this.quincenalCycle,
    this.status = 'pending',
    this.createdAt,
    this.updatedAt,
    this.categoryIds,
  });

  final int? id;
  final int userId;
  final double amount;
  final String description;
  final String date;
  final int quincenalCycle;
  final String status;
  final String? createdAt;
  final String? updatedAt;
  final String? categoryIds;

  factory Expense.fromMap(Map<String, Object?> map) {
    return Expense(
      id: map['id'] as int?,
      userId: (map['user_id'] as num).toInt(),
      amount: (map['amount'] as num).toDouble(),
      description: (map['description'] ?? '') as String,
      date: (map['date'] ?? '') as String,
      quincenalCycle: (map['quincenal_cycle'] as num).toInt(),
      status: (map['status'] ?? 'pending') as String,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
      categoryIds: map['category_ids'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'description': description,
      'date': date,
      'quincenal_cycle': quincenalCycle,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
