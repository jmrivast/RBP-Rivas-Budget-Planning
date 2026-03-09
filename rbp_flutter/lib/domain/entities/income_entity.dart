class IncomeEntity {
  const IncomeEntity({
    required this.id,
    required this.amount,
    required this.description,
    required this.date,
    this.incomeType = 'bonus',
  });
  final int id;
  final double amount;
  final String description;
  final String date;
  final String incomeType;
}
