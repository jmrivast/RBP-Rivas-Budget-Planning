import 'expense.dart';

class FixedPaymentWithStatus {
  const FixedPaymentWithStatus({
    required this.id,
    required this.name,
    required this.amount,
    required this.dueDay,
    this.categoryId,
    required this.isPaid,
    required this.isOverdue,
    required this.dueDate,
  });

  final int id;
  final String name;
  final double amount;
  final int dueDay;
  final int? categoryId;
  final bool isPaid;
  final bool isOverdue;
  final String dueDate;
}

class RecentItem {
  const RecentItem({
    required this.date,
    required this.description,
    required this.amount,
    required this.categories,
    required this.type,
    this.id,
    this.fixedPaid = false,
    this.raw,
  });

  final String date;
  final String description;
  final double amount;
  final String categories;
  final String type;
  final int? id;
  final bool fixedPaid;
  final Object? raw;
}

class DashboardData {
  const DashboardData({
    required this.year,
    required this.month,
    required this.cycle,
    required this.periodMode,
    required this.salary,
    required this.extraIncome,
    required this.dineroInicial,
    required this.totalExpenses,
    required this.totalExpensesSalary,
    required this.totalExpensesSavings,
    required this.totalFixed,
    required this.totalLoans,
    required this.periodSavings,
    required this.totalSavings,
    required this.dineroDisponible,
    required this.avgDaily,
    required this.expenseCount,
    required this.fixedCount,
    required this.recentExpenses,
    required this.fixedPayments,
    required this.rawExpenses,
    required this.categoriesById,
    required this.catTotals,
    required this.quincenaRange,
  });

  final int year;
  final int month;
  final int cycle;
  final String periodMode;
  final double salary;
  final double extraIncome;
  final double dineroInicial;
  final double totalExpenses;
  final double totalExpensesSalary;
  final double totalExpensesSavings;
  final double totalFixed;
  final double totalLoans;
  final double periodSavings;
  final double totalSavings;
  final double dineroDisponible;
  final double avgDaily;
  final int expenseCount;
  final int fixedCount;
  final List<RecentItem> recentExpenses;
  final List<FixedPaymentWithStatus> fixedPayments;
  final List<Expense> rawExpenses;
  final Map<int, String> categoriesById;
  final Map<int, double> catTotals;
  final (String, String) quincenaRange;
}
