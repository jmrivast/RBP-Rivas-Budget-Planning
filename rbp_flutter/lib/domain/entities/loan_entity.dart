class LoanEntity {
  const LoanEntity({
    required this.id,
    required this.person,
    required this.amount,
    this.description,
    required this.date,
    this.isPaid = false,
    this.paidDate,
    this.deductionType = 'ninguno',
  });
  final int id;
  final String person;
  final double amount;
  final String? description;
  final String date;
  final bool isPaid;
  final String? paidDate;
  final String deductionType;
}
