import 'package:flutter/material.dart';

import '../../config/constants.dart';
import '../theme/app_icon_button.dart';

class PeriodNavBar extends StatelessWidget {
  const PeriodNavBar({
    super.key,
    required this.label,
    required this.onPrev,
    required this.onToday,
    required this.onNext,
    this.onCalendar,
    this.onChart,
    this.onPdf,
    this.onCsv,
    this.isMonthly = false,
  });

  final String label;
  final VoidCallback onPrev;
  final VoidCallback onToday;
  final VoidCallback onNext;
  final VoidCallback? onCalendar;
  final VoidCallback? onChart;
  final VoidCallback? onPdf;
  final VoidCallback? onCsv;
  final bool isMonthly;

  @override
  Widget build(BuildContext context) {
    final actionButtonStyle = OutlinedButton.styleFrom(
      shape: const StadiumBorder(),
      side: BorderSide(color: AppColors.outline),
      foregroundColor: AppColors.primary,
      overlayColor: AppColors.hoverPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      minimumSize: const Size(0, 38),
      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _periodControls(),
              if (onCalendar != null)
                _compactIconButton(
                  onPressed: onCalendar,
                  icon: Icons.calendar_month,
                  color: AppColors.primary,
                  hoverColor: AppColors.hoverPrimary,
                  tooltip:
                      isMonthly ? 'Modo mensual' : 'Ajustar fechas de quincena',
                ),
              if (onChart != null)
                OutlinedButton.icon(
                  style: actionButtonStyle,
                  onPressed: onChart,
                  icon: const Icon(Icons.pie_chart),
                  label: const Text('Grafico'),
                ),
              if (onPdf != null)
                OutlinedButton.icon(
                  style: actionButtonStyle,
                  onPressed: onPdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('PDF'),
                ),
              if (onCsv != null)
                OutlinedButton.icon(
                  style: actionButtonStyle,
                  onPressed: onCsv,
                  icon: const Icon(Icons.table_chart),
                  label: const Text('CSV'),
                ),
            ],
          );
        }

        return Row(
          children: [
            _periodControls(),
            const Spacer(),
            if (onCalendar != null)
              _compactIconButton(
                onPressed: onCalendar,
                icon: Icons.calendar_month,
                color: AppColors.primary,
                hoverColor: AppColors.hoverPrimary,
                tooltip:
                    isMonthly ? 'Modo mensual' : 'Ajustar fechas de quincena',
              ),
            if (onChart != null)
              OutlinedButton.icon(
                style: actionButtonStyle,
                onPressed: onChart,
                icon: const Icon(Icons.pie_chart),
                label: const Text('Grafico'),
              ),
            if (onPdf != null)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: OutlinedButton.icon(
                  style: actionButtonStyle,
                  onPressed: onPdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('PDF'),
                ),
              ),
            if (onCsv != null)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: OutlinedButton.icon(
                  style: actionButtonStyle,
                  onPressed: onCsv,
                  icon: const Icon(Icons.table_chart),
                  label: const Text('CSV'),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _periodControls() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIconButton(
          onPressed: onPrev,
          icon: Icons.chevron_left,
          color: AppColors.iconNeutral,
          hoverColor: AppColors.hoverPrimary,
          tooltip: isMonthly ? 'Mes anterior' : 'Quincena anterior',
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: AppColors.primaryLight,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
        AppIconButton(
          onPressed: onNext,
          icon: Icons.chevron_right,
          color: AppColors.iconNeutral,
          hoverColor: AppColors.hoverPrimary,
          tooltip: isMonthly ? 'Mes siguiente' : 'Quincena siguiente',
        ),
        TextButton(onPressed: onToday, child: const Text('Hoy')),
      ],
    );
  }

  Widget _compactIconButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required Color color,
    required Color hoverColor,
    required String tooltip,
  }) {
    return AppIconButton(
      onPressed: onPressed,
      icon: icon,
      color: color,
      hoverColor: hoverColor,
      tooltip: tooltip,
    );
  }
}
