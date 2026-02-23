import 'package:flutter/material.dart';

import '../../config/constants.dart';
import '../../data/models/savings_goal.dart';
import '../../utils/currency_formatter.dart';

class SavingsGoalItem extends StatelessWidget {
  const SavingsGoalItem({
    super.key,
    required this.goal,
    required this.totalSavings,
    required this.onEdit,
    required this.onDelete,
  });

  final SavingsGoal goal;
  final double totalSavings;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final target = goal.targetAmount;
    final pct = target <= 0 ? 0.0 : (totalSavings / target).clamp(0, 1).toDouble();
    final done = pct >= 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.mutedSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  goal.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '${formatCurrency(totalSavings)} / ${formatCurrency(target)}',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Editar',
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Eliminar',
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: pct,
            borderRadius: BorderRadius.circular(6),
            backgroundColor: AppColors.cardBorder,
            color: done ? AppColors.primary : AppColors.success,
            minHeight: 8,
          ),
          const SizedBox(height: 4),
          Text(
            '${(pct * 100).round()}% completado',
            style: TextStyle(
              fontSize: 11,
              color: done ? AppColors.success : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
