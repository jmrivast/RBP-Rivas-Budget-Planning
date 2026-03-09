class ExpenseEntity {
  const ExpenseEntity({
    required this.id,
    required this.amount,
    required this.description,
    required this.date,
    required this.cycle,
    this.status = 'pending',
    this.categoryIds,
  });
  final int id;
  final double amount;
  final String description;
  final String date;
  final int cycle;
  final String status;
  final String? categoryIds;
}
