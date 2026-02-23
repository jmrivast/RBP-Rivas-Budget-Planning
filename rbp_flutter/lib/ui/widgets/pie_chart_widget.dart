import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../config/constants.dart';

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
      AppColors.warn,
      const Color(0xFFB10DC9),
      AppColors.error,
      const Color(0xFF39CCCC),
      const Color(0xFFAAAAAA),
    ];

    final total = entries.fold<double>(0, (sum, e) => sum + e.value);

    final sections = <PieChartSectionData>[];
    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      final name = categoriesById[e.key] ?? 'Cat ${e.key}';
      final pct = total <= 0 ? 0 : (e.value / total) * 100;
      sections.add(
        PieChartSectionData(
          value: max(e.value, 0),
          color: colors[i % colors.length],
          radius: 68,
          title: pct >= 7 ? '${pct.toStringAsFixed(0)}%' : '',
          titleStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          badgeWidget: pct >= 12
              ? Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    name,
                    style: const TextStyle(fontSize: 10),
                  ),
                )
              : null,
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: height,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 36,
              sections: sections,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 6,
          children: [
            for (var i = 0; i < entries.length; i++)
              _LegendItem(
                color: colors[i % colors.length],
                label: categoriesById[entries[i].key] ?? 'Cat ${entries[i].key}',
                value: entries[i].value,
              ),
          ],
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
  });

  final Color color;
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text('$label (${value.toStringAsFixed(0)})'),
      ],
    );
  }
}
