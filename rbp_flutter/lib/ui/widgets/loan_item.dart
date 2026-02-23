import 'package:flutter/material.dart';

import '../../config/constants.dart';
import '../../data/models/loan.dart';
import '../../utils/currency_formatter.dart';

class LoanItem extends StatelessWidget {
  const LoanItem({
    super.key,
    required this.loan,
    required this.onEdit,
    required this.onDelete,
    required this.onMarkPaid,
  });

  final Loan loan;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onMarkPaid;

  @override
  Widget build(BuildContext context) {
    final paid = loan.isPaidBool;
    final badgeColor = paid ? AppColors.success : AppColors.warn;
    var deductionLabel = '';
    if (loan.deductionType == 'gasto') {
      deductionLabel = ' - Desc. gasto';
    } else if (loan.deductionType == 'ahorro') {
      deductionLabel = ' - Desc. ahorro';
    }
    final desc = (loan.description ?? '').trim();
    final subtitleParts = <String>[loan.date];
    if (desc.isNotEmpty) {
      subtitleParts.add(desc);
    }

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
                Text(loan.person, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  '${subtitleParts.join(' - ')}$deductionLabel',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              paid ? 'PAGADO' : 'PENDIENTE',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatCurrency(loan.amount),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (!paid)
            IconButton(
              onPressed: onMarkPaid,
              icon: const Icon(Icons.check_circle_outline),
              tooltip: 'Marcar pagado',
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
