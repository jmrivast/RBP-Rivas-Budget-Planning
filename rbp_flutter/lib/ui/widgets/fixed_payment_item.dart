import 'package:flutter/material.dart';

import '../../data/models/dashboard_data.dart';
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
        color: const Color(0xFFF5F5F5),
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
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          Text(
            formatCurrency(payment.amount),
            style: const TextStyle(fontWeight: FontWeight.w700),
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
    );
  }
}
