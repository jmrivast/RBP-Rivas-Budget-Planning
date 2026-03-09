class FixedPaymentEntity {
  const FixedPaymentEntity({
    required this.id,
    required this.name,
    required this.amount,
    this.categoryId,
    required this.dueDay,
    this.frequency = 'monthly',
    this.isActive = true,
  });
  final int id;
  final String name;
  final double amount;
  final int? categoryId;
  final int dueDay;
  final String frequency;
  final bool isActive;

  bool get noFixedDate => dueDay <= 0;
}
