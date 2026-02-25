import 'package:flutter/material.dart';

import '../../data/models/savings_goal.dart';
import '../../providers/finance_provider.dart';

Future<void> showEditGoalDialog(
  BuildContext context, {
  required FinanceProvider finance,
  required SavingsGoal goal,
}) async {
  final nameCtrl = TextEditingController(text: goal.name);
  final amountCtrl = TextEditingController(text: goal.targetAmount.toString());

  await showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Editar meta'),
        content: SizedBox(
          width: 340,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nombre meta'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Meta RD\$'),
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
              final target = double.tryParse(amountCtrl.text.trim());
              if (target == null ||
                  target <= 0 ||
                  nameCtrl.text.trim().isEmpty) {
                return;
              }
              await finance.updateSavingsGoal(
                  goal.id!, nameCtrl.text.trim(), target);
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

  nameCtrl.dispose();
  amountCtrl.dispose();
}
