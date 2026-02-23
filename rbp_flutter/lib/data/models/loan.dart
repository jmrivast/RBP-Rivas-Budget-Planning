class Loan {
  const Loan({
    this.id,
    required this.userId,
    required this.person,
    required this.amount,
    this.description,
    required this.date,
    this.isPaid = 0,
    this.paidDate,
    this.deductionType = 'ninguno',
    this.createdAt,
  });

  final int? id;
  final int userId;
  final String person;
  final double amount;
  final String? description;
  final String date;
  final int isPaid;
  final String? paidDate;
  final String deductionType;
  final String? createdAt;

  bool get isPaidBool => isPaid == 1;

  factory Loan.fromMap(Map<String, Object?> map) {
    return Loan(
      id: map['id'] as int?,
      userId: (map['user_id'] as num).toInt(),
      person: (map['person'] ?? '') as String,
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] as String?,
      date: (map['date'] ?? '') as String,
      isPaid: (map['is_paid'] as num?)?.toInt() ?? 0,
      paidDate: map['paid_date'] as String?,
      deductionType: (map['deduction_type'] ?? 'ninguno') as String,
      createdAt: map['created_at'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'person': person,
      'amount': amount,
      'description': description,
      'date': date,
      'is_paid': isPaid,
      'paid_date': paidDate,
      'deduction_type': deductionType,
      'created_at': createdAt,
    };
  }
}
