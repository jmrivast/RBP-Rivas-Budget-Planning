abstract class ISettingsRepository {
  Future<String> getSetting(String key, {String defaultValue});
  Future<void> setSetting(String key, String value);
  Future<double> getSalary();
  Future<void> setSalary(double amount);
  Future<String> getPeriodMode();
  Future<void> setPeriodMode(String mode);
  Future<double?> getSalaryOverride(int year, int month, int cycle);
  Future<void> setSalaryOverride(int year, int month, int cycle, double amount);
  Future<void> deleteSalaryOverride(int year, int month, int cycle);
}
