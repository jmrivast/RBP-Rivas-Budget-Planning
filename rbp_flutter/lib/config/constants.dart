import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF1565C0);
  static const secondary = Color(0xFF1565C0);
  static const primaryLight = Color(0xFFE3F2FD);
  static const cardBg = Color(0xFFFFFFFF);
  static const cardBorder = Color(0xFFE0E0E0);
  static const subtitle = Color(0xFF757575);
  static const success = Color(0xFF43A047);
  static const error = Color(0xFFE53935);
  static const warn = Color(0xFFFB8C00);
  static const pageBackground = Color(0xFFFAFAFA);
  static const mutedSurface = Color(0xFFF5F5F5);
}

class AppStrings {
  static const appTitle = 'RBP - Rivas Budget Planning';
  static const appSubtitle = 'Rivas Budget Planning';
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
  static const developerContact = 'WhatsApp: +1-809-000-0000';
  static const developerEmail = 'soporte@rivasbudget.com';
  static const trialExpenseLimit = 15;
  static const trialReminderInterval = 3;
}
