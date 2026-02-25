import 'package:flutter/material.dart';

import '../../data/models/category.dart';
import '../../data/models/expense.dart';
import '../../providers/finance_provider.dart';

Future<void> showEditExpenseDialog(
  BuildContext context, {
  required FinanceProvider finance,
  required Expense expense,
  required List<Category> categories,
}) async {
  final amountCtrl = TextEditingController(text: expense.amount.toString());
  final descCtrl = TextEditingController(text: expense.description);
  final dateCtrl = TextEditingController(text: expense.date);
  final firstCategoryId = (expense.categoryIds ?? '')
      .split(',')
      .map((e) => int.tryParse(e.trim()))
      .whereType<int>()
      .cast<int?>()
      .toList();
  int? selectedCategory =
      firstCategoryId.isEmpty ? null : firstCategoryId.first;

  await showDialog<void>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Editar gasto'),
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
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    initialValue: selectedCategory,
                    items: categories
                        .where((c) => c.id != null)
                        .map(
                          (cat) => DropdownMenuItem<int>(
                            value: cat.id,
                            child: Text(cat.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => selectedCategory = value),
                    decoration: const InputDecoration(labelText: 'Categoria'),
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
                  if (amount == null || amount <= 0) {
                    return;
                  }
                  if (descCtrl.text.trim().isEmpty ||
                      selectedCategory == null) {
                    return;
                  }
                  await finance.updateExpense(
                    expense.id!,
                    amount,
                    descCtrl.text.trim(),
                    dateCtrl.text.trim(),
                    selectedCategory!,
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
    },
  );

  amountCtrl.dispose();
  descCtrl.dispose();
  dateCtrl.dispose();
}
