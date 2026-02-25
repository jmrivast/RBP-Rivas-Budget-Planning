import 'package:flutter/material.dart';

import '../../config/constants.dart';
import '../../data/models/extra_income.dart';
import '../../utils/currency_formatter.dart';
import '../theme/app_icon_button.dart';

class IncomeItem extends StatelessWidget {
  const IncomeItem({
    super.key,
    required this.income,
    required this.onEdit,
    required this.onDelete,
  });

  final ExtraIncome income;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.mutedSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(income.description,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(income.date,
                    style: TextStyle(fontSize: 12, color: AppColors.subtitle)),
              ],
            ),
          ),
          Text(
            formatCurrency(income.amount),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.success,
            ),
          ),
          AppIconButton(
            onPressed: onEdit,
            icon: Icons.edit_outlined,
            color: AppColors.primary,
            hoverColor: AppColors.hoverPrimary,
            tooltip: 'Editar',
          ),
          AppIconButton(
            onPressed: onDelete,
            icon: Icons.delete_outline,
            color: AppColors.error,
            hoverColor: AppColors.hoverError,
            tooltip: 'Eliminar',
          ),
        ],
      ),
    );
  }
}
