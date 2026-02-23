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
  var noFixedDate = payment.dueDay <= 0;
  final dayCtrl = TextEditingController(
      text: '${payment.dueDay <= 0 ? 1 : payment.dueDay}');
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
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Monto RD\$'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: dayCtrl,
                    keyboardType: TextInputType.number,
                    enabled: !noFixedDate,
                    decoration: const InputDecoration(labelText: 'Dia (1-31)'),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    value: noFixedDate,
                    onChanged: (value) =>
                        setState(() => noFixedDate = value ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                        'Sin fecha fija (marcar pagado manualmente)'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int?>(
                    initialValue: selectedCategory,
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Sin categoria'),
                      ),
                      ...categories.where((c) => c.id != null).map(
                            (cat) => DropdownMenuItem<int?>(
                              value: cat.id,
                              child: Text(cat.name),
                            ),
                          ),
                    ],
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
                  final day =
                      noFixedDate ? 0 : int.tryParse(dayCtrl.text.trim());
                  if (amount == null || amount <= 0) {
                    return;
                  }
                  if (!noFixedDate && (day == null || day < 1 || day > 31)) {
                    return;
                  }
                  if (nameCtrl.text.trim().isEmpty) {
                    return;
                  }
                  await finance.updateFixedPayment(
                    payment.id,
                    nameCtrl.text.trim(),
                    amount,
                    day ?? 0,
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
