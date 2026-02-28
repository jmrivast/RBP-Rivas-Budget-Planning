import 'package:flutter/material.dart';

class AppThemePreset {
  const AppThemePreset({
    required this.key,
    required this.label,
    required this.primary,
    required this.primaryLight,
    required this.cardBg,
    required this.cardBorder,
    required this.subtitle,
    required this.iconNeutral,
    required this.success,
    required this.error,
    required this.warn,
    required this.pageBackground,
    required this.mutedSurface,
    required this.fixedDueSurface,
    required this.trialBannerBg,
    required this.trialBannerText,
    required this.outline,
  });

  final String key;
  final String label;
  final Color primary;
  final Color primaryLight;
  final Color cardBg;
  final Color cardBorder;
  final Color subtitle;
  final Color iconNeutral;
  final Color success;
  final Color error;
  final Color warn;
  final Color pageBackground;
  final Color mutedSurface;
  final Color fixedDueSurface;
  final Color trialBannerBg;
  final Color trialBannerText;
  final Color outline;
}

class AppColors {
  static const String defaultPresetKey = 'classic_flet';

  static const List<AppThemePreset> presets = [
    AppThemePreset(
      key: 'classic_flet',
      label: 'Classic Flet',
      primary: Color(0xFF1565C0),
      primaryLight: Color(0xFFE3F2FD),
      cardBg: Color(0xFFFFFFFF),
      cardBorder: Color(0xFFE0E0E0),
      subtitle: Color(0xFF757575),
      iconNeutral: Color(0xFF616161),
      success: Color(0xFF43A047),
      error: Color(0xFFE53935),
      warn: Color(0xFFFB8C00),
      pageBackground: Color(0xFFF5F5F5),
      mutedSurface: Color(0xFFF5F5F5),
      fixedDueSurface: Color(0xFFFFF8E1),
      trialBannerBg: Color(0xFFFFF3CD),
      trialBannerText: Color(0xFF8A6D3B),
      outline: Color(0xFF9E9E9E),
    ),
    AppThemePreset(
      key: 'minimal_blue',
      label: 'Minimal Blue',
      primary: Color(0xFF1E88E5),
      primaryLight: Color(0xFFE8F2FD),
      cardBg: Color(0xFFFFFFFF),
      cardBorder: Color(0xFFE5E7EB),
      subtitle: Color(0xFF6B7280),
      iconNeutral: Color(0xFF6B7280),
      success: Color(0xFF2E7D32),
      error: Color(0xFFD32F2F),
      warn: Color(0xFFEF6C00),
      pageBackground: Color(0xFFF7F8FA),
      mutedSurface: Color(0xFFF3F4F6),
      fixedDueSurface: Color(0xFFFFF7E6),
      trialBannerBg: Color(0xFFFFF2CC),
      trialBannerText: Color(0xFF8A6D3B),
      outline: Color(0xFFA1A1AA),
    ),
    AppThemePreset(
      key: 'neutral_slate',
      label: 'Neutral Slate',
      primary: Color(0xFF455A64),
      primaryLight: Color(0xFFECF0F2),
      cardBg: Color(0xFFFFFFFF),
      cardBorder: Color(0xFFDDE3E6),
      subtitle: Color(0xFF6B7280),
      iconNeutral: Color(0xFF5F6368),
      success: Color(0xFF2E7D32),
      error: Color(0xFFC62828),
      warn: Color(0xFFEF6C00),
      pageBackground: Color(0xFFF4F6F8),
      mutedSurface: Color(0xFFF1F3F5),
      fixedDueSurface: Color(0xFFFFF7E1),
      trialBannerBg: Color(0xFFFFF3CD),
      trialBannerText: Color(0xFF8A6D3B),
      outline: Color(0xFF9CA3AF),
    ),
  ];

  static AppThemePreset _activePreset = presets.first;
  static String activePresetKey = defaultPresetKey;

  static Color primary = _activePreset.primary;
  static Color secondary = _activePreset.primary;
  static Color primaryLight = _activePreset.primaryLight;
  static Color cardBg = _activePreset.cardBg;
  static Color cardBorder = _activePreset.cardBorder;
  static Color subtitle = _activePreset.subtitle;
  static Color iconNeutral = _activePreset.iconNeutral;
  static Color success = _activePreset.success;
  static Color error = _activePreset.error;
  static Color warn = _activePreset.warn;
  static Color pageBackground = _activePreset.pageBackground;
  static Color mutedSurface = _activePreset.mutedSurface;
  static Color fixedDueSurface = _activePreset.fixedDueSurface;
  static Color trialBannerBg = _activePreset.trialBannerBg;
  static Color trialBannerText = _activePreset.trialBannerText;
  static Color outline = _activePreset.outline;
  static Color hoverPrimary = const Color(0x331565C0);
  static Color hoverSuccess = const Color(0x3343A047);
  static Color hoverError = const Color(0x33E53935);
  static Color hoverWarn = const Color(0x33FB8C00);

  static void applyPreset(String presetKey) {
    final preset = presets.firstWhere(
      (p) => p.key == presetKey,
      orElse: () => presets.first,
    );
    _activePreset = preset;
    activePresetKey = preset.key;
    primary = preset.primary;
    secondary = preset.primary;
    primaryLight = preset.primaryLight;
    cardBg = preset.cardBg;
    cardBorder = preset.cardBorder;
    subtitle = preset.subtitle;
    iconNeutral = preset.iconNeutral;
    success = preset.success;
    error = preset.error;
    warn = preset.warn;
    pageBackground = preset.pageBackground;
    mutedSurface = preset.mutedSurface;
    fixedDueSurface = preset.fixedDueSurface;
    trialBannerBg = preset.trialBannerBg;
    trialBannerText = preset.trialBannerText;
    outline = preset.outline;

    hoverPrimary = primary.withAlpha(51);
    hoverSuccess = success.withAlpha(51);
    hoverError = error.withAlpha(51);
    hoverWarn = warn.withAlpha(51);
  }
}

class AppStrings {
  static const appTitle = 'RBP - Finanzas Personales';
  static const appSubtitle = 'Finanzas Personales';
}

class AppDefaults {
  static const defaultUsername = 'Jose';
  static const defaultCategories = <String>[
    'Comida',
    'Combustible',
    'Uber/Taxi',
    'Subscripciones',
    'Varios/Snacks',
    'Otros',
  ];
}

class LicenseConfig {
  // Replace from build env in production.
  static const secretSaltPlaceholder = 'RBP_SECRET_SALT_CHANGE_ME';
}

class AppLicense {
  static const developerContact = 'WhatsApp: +1 829 222 2172';
  static const developerEmail = 'jmrivast0110@gmail.com';
  static const trialExpenseLimit = 15;
  static const trialReminderInterval = 3;
}
