import '../../data/database/app_database.dart';
import '../../data/database/database_helper.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/debt_repository.dart';
import '../../data/repositories/expense_repository.dart';
import '../../data/repositories/fixed_payment_repository.dart';
import '../../data/repositories/income_repository.dart';
import '../../data/repositories/loan_repository.dart';
import '../../data/repositories/personal_debt_repository.dart';
import '../../data/repositories/savings_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../services/finance_service.dart';

/// Simple service locator (no external packages).
/// Call [setupDependencies] once at app startup.
class DI {
  DI._();
  static final _reg = <Type, Object>{};

  static void register<T extends Object>(T instance) => _reg[T] = instance;
  static T get<T extends Object>() {
    final instance = _reg[T];
    if (instance == null) throw StateError('DI: $T not registered. Call setupDependencies() first.');
    return instance as T;
  }
  static void reset() => _reg.clear();
}

/// Wire up all dependencies. Called once from main().
void setupDependencies() {
  final db = DatabaseHelper.instance;
  DI.register<AppDatabase>(db);

  // Data layer repositories (concrete implementations)
  final categoryRepo     = CategoryRepository(dbHelper: db);
  final expenseRepo      = ExpenseRepository(dbHelper: db);
  final fixedPaymentRepo = FixedPaymentRepository(dbHelper: db);
  final incomeRepo       = IncomeRepository(dbHelper: db);
  final loanRepo         = LoanRepository(dbHelper: db);
  final personalDebtRepo = PersonalDebtRepository(dbHelper: db);
  final debtRepo         = DebtRepository(dbHelper: db);
  final savingsRepo      = SavingsRepository(dbHelper: db);
  final settingsRepo     = SettingsRepository(dbHelper: db);
  final userRepo         = UserRepository(dbHelper: db);

  // Finance service (orchestrator — existing business logic)
  final financeService = FinanceService(
    db: db,
    userRepo: userRepo,
    categoryRepo: categoryRepo,
    expenseRepo: expenseRepo,
    fixedPaymentRepo: fixedPaymentRepo,
    loanRepo: loanRepo,
    personalDebtRepo: personalDebtRepo,
    debtRepo: debtRepo,
    incomeRepo: incomeRepo,
    savingsRepo: savingsRepo,
    settingsRepo: settingsRepo,
  );

  DI.register<FinanceService>(financeService);

  // NOTE: Use cases reference domain interfaces.
  // For now, FinanceService still does orchestration.
  // As repositories implement domain interfaces in a future phase,
  // these will be wired to actual interface implementations.
}

