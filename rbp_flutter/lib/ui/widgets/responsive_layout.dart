import 'package:flutter/material.dart';

import '../../config/breakpoints.dart';

class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (Breakpoints.isDesktop(width)) {
          return desktop;
        }
        if (Breakpoints.isTablet(width)) {
          return tablet ?? mobile;
        }
        return mobile;
      },
    );
  }
}
