import 'package:flutter/material.dart';

import '../../config/constants.dart';
import '../../providers/finance_provider.dart';

Future<void> showCustomQuincenaDialog(
  BuildContext context, {
  required FinanceProvider finance,
}) async {
  final range = finance.dashboard?.quincenaRange;
  final startCtrl = TextEditingController(text: range?.$1 ?? '');
  final endCtrl = TextEditingController(text: range?.$2 ?? '');
  final custom = await finance.getCustomQuincena();
  if (!context.mounted) {
    return;
  }
  if (custom != null) {
    startCtrl.text = custom.startDate;
    endCtrl.text = custom.endDate;
  }

  await showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Calendario de quincena'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ajusta fechas de inicio y fin para la quincena visible.',
                style: TextStyle(fontSize: 12, color: AppColors.subtitle),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: startCtrl,
                decoration:
                    const InputDecoration(labelText: 'Inicio (YYYY-MM-DD)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: endCtrl,
                decoration:
                    const InputDecoration(labelText: 'Fin (YYYY-MM-DD)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          if (custom != null)
            OutlinedButton.icon(
              onPressed: () async {
                await finance.deleteCustomQuincena(custom.id!);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              icon: const Icon(Icons.restore),
              label: const Text('Restablecer'),
            ),
          FilledButton.icon(
            onPressed: () async {
              final start = startCtrl.text.trim();
              final end = endCtrl.text.trim();
              if (start.length != 10 || end.length != 10) {
                return;
              }
              await finance.setCustomQuincena(start, end);
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

  startCtrl.dispose();
  endCtrl.dispose();
}
