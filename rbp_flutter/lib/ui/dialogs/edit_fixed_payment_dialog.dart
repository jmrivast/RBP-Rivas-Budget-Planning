import 'package:flutter/material.dart';

import '../../data/models/category.dart';
import '../../data/models/dashboard_data.dart';
import '../../providers/finance_provider.dart';

Future<void> showEditFixedPaymentDialog(
  BuildContext context, {
  required FinanceProvider finance,
  required FixedPaymentWithStatus payment,
  required List<Category> categories,
}) async {
  final nameCtrl = TextEditingController(text: payment.name);
  final amountCtrl = TextEditingController(text: payment.amount.toString());
  final dayCtrl = TextEditingController(text: '${payment.dueDay}');
  int? selectedCategory = payment.categoryId;

  await showDialog<void>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Editar pago fijo'),
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Monto RD\$'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: dayCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Dia (0-31)'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int?>(
                    initialValue: selectedCategory,
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Sin categoria'),
                      ),
                      ...categories
                          .where((c) => c.id != null)
                          .map(
                            (cat) => DropdownMenuItem<int?>(
                              value: cat.id,
                              child: Text(cat.name),
                            ),
                          ),
                    ],
                    onChanged: (value) => setState(() => selectedCategory = value),
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
                  final day = int.tryParse(dayCtrl.text.trim());
                  if (amount == null || amount <= 0 || day == null || day < 0 || day > 31) {
                    return;
                  }
                  if (nameCtrl.text.trim().isEmpty) {
                    return;
                  }
                  await finance.updateFixedPayment(
                    payment.id,
                    nameCtrl.text.trim(),
                    amount,
                    day,
                    selectedCategory,
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

  nameCtrl.dispose();
  amountCtrl.dispose();
  dayCtrl.dispose();
}
