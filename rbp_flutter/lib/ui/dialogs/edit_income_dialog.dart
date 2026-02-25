import 'package:flutter/material.dart';

import '../../data/models/extra_income.dart';
import '../../providers/finance_provider.dart';

Future<void> showEditIncomeDialog(
  BuildContext context, {
  required FinanceProvider finance,
  required ExtraIncome income,
}) async {
  final amountCtrl = TextEditingController(text: income.amount.toString());
  final descCtrl = TextEditingController(text: income.description);
  final dateCtrl = TextEditingController(text: income.date);

  await showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Editar ingreso'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Monto RD\$'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Descripcion'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: dateCtrl,
                decoration:
                    const InputDecoration(labelText: 'Fecha (YYYY-MM-DD)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () async {
              final amount = double.tryParse(amountCtrl.text.trim());
              if (amount == null ||
                  amount <= 0 ||
                  descCtrl.text.trim().isEmpty) {
                return;
              }
              await finance.updateIncome(
                income.id!,
                amount,
                descCtrl.text.trim(),
                dateCtrl.text.trim(),
              );
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            icon: const Icon(Icons.save),
            label: const Text('Guardar'),
          ),
        ],
      );
    },
  );

  amountCtrl.dispose();
  descCtrl.dispose();
  dateCtrl.dispose();
}
