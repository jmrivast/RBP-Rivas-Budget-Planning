import 'package:flutter/material.dart';

import '../../config/constants.dart';
import '../../data/models/dashboard_data.dart';
import '../theme/app_icon_button.dart';
import '../../utils/currency_formatter.dart';

class FixedPaymentItem extends StatelessWidget {
  const FixedPaymentItem({
    super.key,
    required this.payment,
    required this.onTogglePaid,
    required this.onEdit,
    required this.onDelete,
  });

  final FixedPaymentWithStatus payment;
  final ValueChanged<bool> onTogglePaid;
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
          Tooltip(
            message: 'Marcar como pagado en este periodo',
            child: Checkbox(
              value: payment.isPaid,
              onChanged: (v) => onTogglePaid(v ?? false),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(payment.name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  payment.dueDay <= 0
                      ? 'Pago manual Sin fecha fija'
                      : (payment.dueDate.isEmpty
                          ? 'Fecha ${payment.dueDay}'
                          : 'Fecha ${payment.dueDate}'),
                  style: TextStyle(fontSize: 12, color: AppColors.subtitle),
                ),
              ],
            ),
          ),
          Text(
            formatCurrency(payment.amount),
            style: const TextStyle(fontWeight: FontWeight.w700),
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
