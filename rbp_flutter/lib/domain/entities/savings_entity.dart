class SavingsEntity {
  const SavingsEntity({
    required this.totalSaved,
    this.lastQuincenalSavings,
    required this.year,
    required this.month,
    required this.cycle,
  });
  final double totalSaved;
  final double? lastQuincenalSavings;
  final int year;
  final int month;
  final int cycle;
}

class SavingsGoalEntity {
  const SavingsGoalEntity({required this.id, required this.name, required this.targetAmount});
  final int id;
  final String name;
  final double targetAmount;
}
