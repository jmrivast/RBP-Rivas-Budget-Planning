import 'package:flutter/foundation.dart';

import '../config/constants.dart';
import 'finance_provider.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._financeProvider);

  final FinanceProvider _financeProvider;

  String _periodMode = 'quincenal';
  int _payDay1 = 1;
  int _payDay2 = 16;
  int _monthlyPayDay = 1;
  double _salary = 0;
  String _themePreset = AppColors.defaultPresetKey;
  bool _loading = false;

  String get periodMode => _periodMode;
  int get payDay1 => _payDay1;
  int get payDay2 => _payDay2;
  int get monthlyPayDay => _monthlyPayDay;
  double get salary => _salary;
  String get themePreset => _themePreset;
  bool get isLoading => _loading;

  Future<void> load() async {
    _setLoading(true);
    try {
      _periodMode = _financeProvider.periodMode;
      _payDay1 = int.tryParse(
            await _financeProvider.getSetting(
              'quincenal_pay_day_1',
              defaultValue: '1',
            ),
          ) ??
          1;
      _payDay2 = int.tryParse(
            await _financeProvider.getSetting(
              'quincenal_pay_day_2',
              defaultValue: '16',
            ),
          ) ??
          16;
      _monthlyPayDay = int.tryParse(
            await _financeProvider.getSetting(
              'monthly_pay_day',
              defaultValue: '1',
            ),
          ) ??
          1;
      _salary = await _financeProvider.getSalary();
      final savedPreset = await _financeProvider.getSetting(
        'theme_preset',
        defaultValue: AppColors.defaultPresetKey,
      );
      _themePreset = savedPreset;
      AppColors.applyPreset(_themePreset);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadThemePreset() async {
    final savedPreset = await _financeProvider.getSetting(
      'theme_preset',
      defaultValue: AppColors.defaultPresetKey,
    );
    _themePreset = savedPreset;
    AppColors.applyPreset(_themePreset);
    notifyListeners();
  }

  Future<void> updatePeriodMode(String mode) async {
    await _withReload(() async {
      await _financeProvider.setPeriodMode(mode);
    });
  }

  Future<void> updatePaydays({
    required int day1,
    required int day2,
    required int monthly,
  }) async {
    await _withReload(() async {
      await _financeProvider.setSetting('quincenal_pay_day_1', '$day1');
      await _financeProvider.setSetting('quincenal_pay_day_2', '$day2');
      await _financeProvider.setSetting('monthly_pay_day', '$monthly');
    });
  }

  Future<void> updateSalary(double value) async {
    await _withReload(() async {
      await _financeProvider.setSalary(value);
    });
  }

  Future<void> updateThemePreset(String presetKey) async {
    final nextPreset = AppColors.presets.any((p) => p.key == presetKey)
        ? presetKey
        : AppColors.defaultPresetKey;
    if (_themePreset == nextPreset) {
      return;
    }
    _themePreset = nextPreset;
    AppColors.applyPreset(_themePreset);
    await _financeProvider.setSetting('theme_preset', _themePreset);
    notifyListeners();
  }

  Future<void> _withReload(Future<void> Function() action) async {
    _setLoading(true);
    try {
      await action();
      await load();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    if (_loading == value) {
      return;
    }
    _loading = value;
    notifyListeners();
  }
}
