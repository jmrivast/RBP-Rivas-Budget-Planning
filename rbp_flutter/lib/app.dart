import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/constants.dart';
import 'providers/finance_provider.dart';
import 'providers/settings_provider.dart';
import 'ui/screens/app_entry_screen.dart';
import 'ui/theme/app_button_styles.dart';

class RbpApp extends StatelessWidget {
  const RbpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => FinanceProvider(),
        ),
        ChangeNotifierProxyProvider<FinanceProvider, SettingsProvider>(
          create: (context) =>
              SettingsProvider(context.read<FinanceProvider>()),
          update: (context, finance, previous) =>
              previous ?? SettingsProvider(finance),
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) => MaterialApp(
          title: AppStrings.appTitle,
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: false,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: AppColors.pageBackground,
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.subtitle,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
            ),
            tabBarTheme: TabBarThemeData(
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.subtitle,
              indicatorColor: AppColors.primary,
            ),
            cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: AppColors.cardBorder),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              isDense: true,
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                overlayColor: AppColors.hoverPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.outline),
                overlayColor: AppColors.hoverPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                overlayColor: AppColors.hoverPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            iconButtonTheme: IconButtonThemeData(
              style: AppButtonStyles.iconNeutral(),
            ),
            checkboxTheme: CheckboxThemeData(
              fillColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.primary;
                }
                return Colors.transparent;
              }),
              overlayColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.hovered) ||
                    states.contains(WidgetState.focused)) {
                  return AppColors.hoverPrimary;
                }
                if (states.contains(WidgetState.pressed)) {
                  return AppColors.hoverPrimary.withAlpha(110);
                }
                return Colors.transparent;
              }),
              checkColor: const WidgetStatePropertyAll<Color>(Colors.white),
            ),
            snackBarTheme: SnackBarThemeData(
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          home: const AppEntryScreen(),
        ),
      ),
    );
  }
}
