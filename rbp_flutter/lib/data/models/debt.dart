class Debt {
  const Debt({
    this.id,
    required this.userId,
    required this.name,
    required this.principalAmount,
    required this.annualRate,
    required this.termMonths,
    required this.startDate,
    required this.paymentDay,
    required this.monthlyPayment,
    required this.currentBalance,
    this.isActive = 1,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final int userId;
  final String name;
  final double principalAmount;
  final double annualRate;
  final int termMonths;
  final String startDate;
  final int paymentDay;
  final double monthlyPayment;
  final double currentBalance;
  final int isActive;
  final String? createdAt;
  final String? updatedAt;

  bool get isActiveBool => isActive == 1;

  factory Debt.fromMap(Map<String, Object?> map) {
    return Debt(
      id: map['id'] as int?,
      userId: (map['user_id'] as num).toInt(),
      name: (map['name'] ?? '') as String,
      principalAmount: (map['principal_amount'] as num).toDouble(),
      annualRate: (map['annual_rate'] as num).toDouble(),
      termMonths: (map['term_months'] as num).toInt(),
      startDate: (map['start_date'] ?? '') as String,
      paymentDay: (map['payment_day'] as num).toInt(),
      monthlyPayment: (map['monthly_payment'] as num).toDouble(),
      currentBalance: (map['current_balance'] as num).toDouble(),
      isActive: (map['is_active'] as num?)?.toInt() ?? 1,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }
}
