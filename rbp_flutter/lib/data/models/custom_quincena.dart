class CustomQuincena {
  const CustomQuincena({
    this.id,
    required this.userId,
    required this.year,
    required this.month,
    required this.cycle,
    required this.startDate,
    required this.endDate,
    this.createdAt,
  });

  final int? id;
  final int userId;
  final int year;
  final int month;
  final int cycle;
  final String startDate;
  final String endDate;
  final String? createdAt;

  factory CustomQuincena.fromMap(Map<String, Object?> map) {
    return CustomQuincena(
      id: map['id'] as int?,
      userId: (map['user_id'] as num).toInt(),
      year: (map['year'] as num).toInt(),
      month: (map['month'] as num).toInt(),
      cycle: (map['cycle'] as num).toInt(),
      startDate: (map['start_date'] ?? '') as String,
      endDate: (map['end_date'] ?? '') as String,
      createdAt: map['created_at'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'year': year,
      'month': month,
      'cycle': cycle,
      'start_date': startDate,
      'end_date': endDate,
      'created_at': createdAt,
    };
  }
}
