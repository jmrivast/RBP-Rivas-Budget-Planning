import 'package:flutter/material.dart';

import '../../config/constants.dart';

class AppIconButton extends StatefulWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.color,
    this.hoverColor,
    this.size = 18,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;
  final Color? hoverColor;
  final double size;

  @override
  State<AppIconButton> createState() => _AppIconButtonState();
}

class _AppIconButtonState extends State<AppIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final iconColor = widget.color ?? AppColors.iconNeutral;
    final hoverBg = widget.hoverColor ?? AppColors.hoverPrimary;
    final enabled = widget.onPressed != null;

    final core = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: widget.onPressed,
          customBorder: const CircleBorder(),
          splashColor: hoverBg.withAlpha(110),
          highlightColor: hoverBg.withAlpha(90),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 90),
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (enabled && _hovered) ? hoverBg : Colors.transparent,
            ),
            child: Icon(
              widget.icon,
              size: widget.size,
              color: enabled ? iconColor : iconColor.withAlpha(120),
            ),
          ),
        ),
      ),
    );

    if ((widget.tooltip ?? '').trim().isEmpty) {
      return core;
    }
    return Tooltip(message: widget.tooltip!, child: core);
  }
}
