import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../config/constants.dart';
import '../../utils/currency_formatter.dart';

class PieChartWidget extends StatelessWidget {
  const PieChartWidget({
    super.key,
    required this.catTotals,
    required this.categoriesById,
    this.height = 320,
  });

  final Map<int, double> catTotals;
  final Map<int, String> categoriesById;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (catTotals.isEmpty) {
      return const Center(
        child: Text('Sin gastos para graficar'),
      );
    }

    final entries = catTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final colors = <Color>[
      AppColors.primary,
      AppColors.success,
      AppColors.error,
      AppColors.warn,
      const Color(0xFF8E24AA),
      const Color(0xFF00897B),
      const Color(0xFFF4511E),
      const Color(0xFF3949AB),
      const Color(0xFFC0CA33),
      const Color(0xFF6D4C41),
    ];

    final total = entries.fold<double>(0, (sum, e) => sum + e.value);

    final sections = <PieChartSectionData>[];
    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      sections.add(
        PieChartSectionData(
          value: max(e.value, 0.000001),
          color: colors[i % colors.length],
          radius: 150,
          title: '',
          borderSide: const BorderSide(color: Colors.white, width: 3),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 6,
          child: Center(
            child: SizedBox(
              height: height,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 0,
                  centerSpaceRadius: 55,
                  sections: sections,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Leyenda',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < entries.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _LegendItem(
                      color: colors[i % colors.length],
                      label: categoriesById[entries[i].key] ??
                          'Cat ${entries[i].key}',
                      value: entries[i].value,
                      percent:
                          total <= 0 ? 0 : (entries[i].value / total) * 100,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
    required this.percent,
  });

  final Color color;
  final String label;
  final double value;
  final double percent;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '$label: ${percent.toStringAsFixed(1)}% (${formatCurrency(value)})',
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }
}
