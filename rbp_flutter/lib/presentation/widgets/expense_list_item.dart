import 'package:flutter/material.dart';

import '../../config/constants.dart';
import '../../data/models/dashboard_data.dart';
import '../../utils/currency_formatter.dart';
import '../theme/app_icon_button.dart';

class ExpenseListItem extends StatelessWidget {
  const ExpenseListItem({
    super.key,
    required this.item,
    this.onEdit,
    this.onDelete,
  });

  final RecentItem item;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final isFixedDue = item.type == 'fixed_due';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isFixedDue ? AppColors.fixedDueSurface : AppColors.mutedSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.description,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${item.date}  ·  ${item.categories}',
                  style: TextStyle(fontSize: 12, color: AppColors.subtitle),
                ),
              ],
            ),
          ),
          Text(
            formatCurrency(item.amount),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isFixedDue ? AppColors.warn : AppColors.error,
            ),
          ),
          if (!isFixedDue && onEdit != null)
            AppIconButton(
              onPressed: onEdit,
              icon: Icons.edit_outlined,
              color: AppColors.primary,
              hoverColor: AppColors.hoverPrimary,
              tooltip: 'Editar',
            ),
          if (!isFixedDue && onDelete != null)
            AppIconButton(
              onPressed: onDelete,
              icon: Icons.delete_outline,
              color: AppColors.error,
              hoverColor: AppColors.hoverError,
              tooltip: 'Eliminar',
            ),
          if (isFixedDue)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Icon(Icons.event, color: AppColors.warn, size: 18),
            ),
        ],
      ),
    );
  }
}
