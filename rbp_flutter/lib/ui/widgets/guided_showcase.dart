import 'package:flutter/material.dart';

class GuidedShowcase extends StatelessWidget {
  const GuidedShowcase({
    super.key,
    required this.showcaseKey,
    required this.title,
    required this.description,
    required this.child,
    this.onNext,
    this.onPrevious,
    this.showPrevious = true,
    this.showNext = true,
    this.nextLabel = 'Siguiente',
  });

  final GlobalKey showcaseKey;
  final String title;
  final String description;
  final Widget child;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final bool showPrevious;
  final bool showNext;
  final String nextLabel;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
