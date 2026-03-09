import 'expense_entity.dart';

/// Read-only aggregate for the dashboard view.
class DashboardEntity {
  const DashboardEntity({
    required this.year,
    required this.month,
    required this.cycle,
    required this.periodMode,
    required this.quincenaRange,
    required this.salary,
    this.salaryOverride,
    required this.totalExpenses,
    required this.totalIncome,
    required this.totalFixed,
    required this.totalFixedDue,
    required this.totalLoaned,
    required this.totalBankDebtPayment,
    required this.totalSaved,
    required this.lastQuincenalSavings,
    required this.categoryBreakdown,
    required this.rawExpenses,
  });
  final int year;
  final int month;
  final int cycle;
  final String periodMode;
  final (String, String) quincenaRange;
  final double salary;
  final double? salaryOverride;
  final double totalExpenses;
  final double totalIncome;
  final double totalFixed;
  final double totalFixedDue;
  final double totalLoaned;
  final double totalBankDebtPayment;
  final double totalSaved;
  final double lastQuincenalSavings;
  final Map<String, double> categoryBreakdown;
  final List<ExpenseEntity> rawExpenses;

  double get effectiveSalary => salaryOverride ?? salary;
  double get availableBalance =>
      effectiveSalary + totalIncome - totalExpenses;
}
