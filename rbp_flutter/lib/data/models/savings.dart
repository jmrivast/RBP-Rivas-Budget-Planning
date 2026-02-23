class Savings {
  const Savings({
    this.id,
    required this.userId,
    this.totalSaved = 0,
    this.lastQuincenalSavings,
    required this.year,
    required this.month,
    required this.quincenalCycle,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final int userId;
  final double totalSaved;
  final double? lastQuincenalSavings;
  final int year;
  final int month;
  final int quincenalCycle;
  final String? createdAt;
  final String? updatedAt;

  factory Savings.fromMap(Map<String, Object?> map) {
    return Savings(
      id: map['id'] as int?,
      userId: (map['user_id'] as num).toInt(),
      totalSaved: (map['total_saved'] as num?)?.toDouble() ?? 0,
      lastQuincenalSavings: (map['last_quincenal_savings'] as num?)?.toDouble(),
      year: (map['year'] as num).toInt(),
      month: (map['month'] as num).toInt(),
      quincenalCycle: (map['quincenal_cycle'] as num).toInt(),
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'total_saved': totalSaved,
      'last_quincenal_savings': lastQuincenalSavings,
      'year': year,
      'month': month,
      'quincenal_cycle': quincenalCycle,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
