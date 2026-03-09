import '../entities/savings_entity.dart';

abstract class ISavingsRepository {
  Future<SavingsEntity?> getCurrent(int userId);
  Future<void> addSavings(int userId, double amount);
  Future<void> addExtraSavings(int userId, double amount);
  Future<bool> withdrawSavings(int userId, double amount);
  Future<List<SavingsGoalEntity>> getGoals(int userId);
  Future<int> createGoal(int userId, String name, double target);
  Future<void> updateGoal(int id, String name, double target);
  Future<void> deleteGoal(int id);
}
