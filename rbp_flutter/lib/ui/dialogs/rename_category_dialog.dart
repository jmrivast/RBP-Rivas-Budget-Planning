import 'package:flutter/material.dart';

import '../../data/models/category.dart';
import '../../providers/finance_provider.dart';

Future<void> showRenameCategoryDialog(
  BuildContext context, {
  required FinanceProvider finance,
  required Category category,
}) async {
  final nameCtrl = TextEditingController(text: category.name);

  await showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Renombrar categoria'),
        content: SizedBox(
          width: 320,
          child: TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(labelText: 'Nuevo nombre'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty || category.id == null) {
                return;
              }
              await finance.renameCategory(category.id!, name);
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
}
