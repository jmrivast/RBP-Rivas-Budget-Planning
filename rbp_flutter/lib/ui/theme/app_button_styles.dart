import 'package:flutter/material.dart';

import '../../config/constants.dart';

class AppButtonStyles {
  static const EdgeInsets _iconPadding = EdgeInsets.all(6);

  static ButtonStyle _iconStyle({
    required Color foreground,
    required Color hoverBg,
  }) {
    return ButtonStyle(
      foregroundColor: WidgetStatePropertyAll<Color>(foreground),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return hoverBg.withAlpha(90);
        }
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused)) {
          return hoverBg;
        }
        return Colors.transparent;
      }),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return hoverBg.withAlpha(110);
        }
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused)) {
          return hoverBg;
        }
        return Colors.transparent;
      }),
      splashFactory: InkRipple.splashFactory,
      visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
      padding: const WidgetStatePropertyAll<EdgeInsets>(_iconPadding),
      shape: const WidgetStatePropertyAll<OutlinedBorder>(CircleBorder()),
    );
  }

  static ButtonStyle iconNeutral() {
    return _iconStyle(
      foreground: AppColors.iconNeutral,
      hoverBg: AppColors.hoverPrimary,
    );
  }

  static ButtonStyle iconPrimary() {
    return _iconStyle(
      foreground: AppColors.primary,
      hoverBg: AppColors.hoverPrimary,
    );
  }

  static ButtonStyle iconSuccess() {
    return _iconStyle(
      foreground: AppColors.success,
      hoverBg: AppColors.hoverSuccess,
    );
  }

  static ButtonStyle iconWarn() {
    return _iconStyle(
      foreground: AppColors.warn,
      hoverBg: AppColors.hoverWarn,
    );
  }

  static ButtonStyle iconError() {
    return _iconStyle(
      foreground: AppColors.error,
      hoverBg: AppColors.hoverError,
    );
  }
}
