import 'package:flutter/material.dart';

import '../../config/constants.dart';
import '../../data/models/dashboard_data.dart';
import '../../utils/currency_formatter.dart';

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
        color: isFixedDue ? const Color(0xFFFFF8E1) : AppColors.mutedSurface,
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
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
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
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 18),
              tooltip: 'Editar',
            ),
          if (!isFixedDue && onDelete != null)
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
              tooltip: 'Eliminar',
            ),
          if (isFixedDue)
            const Padding(
              padding: EdgeInsets.only(left: 6),
              child: Icon(Icons.event, color: AppColors.warn, size: 18),
            ),
        ],
      ),
    );
  }
}
