import 'package:flutter/material.dart';

import '../../data/models/loan.dart';
import '../../providers/finance_provider.dart';

Future<void> showEditLoanDialog(
  BuildContext context, {
  required FinanceProvider finance,
  required Loan loan,
}) async {
  final personCtrl = TextEditingController(text: loan.person);
  final amountCtrl = TextEditingController(text: loan.amount.toString());
  final descCtrl = TextEditingController(text: loan.description ?? '');
  var deduction = loan.deductionType;

  await showDialog<void>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Editar prestamo'),
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: personCtrl,
                    decoration: const InputDecoration(labelText: 'Persona'),
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
                    controller: descCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Motivo (opc.)'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: deduction,
                    items: const [
                      DropdownMenuItem(
                          value: 'ninguno', child: Text('No descontar')),
                      DropdownMenuItem(
                          value: 'gasto', child: Text('Descontar como gasto')),
                      DropdownMenuItem(
                          value: 'ahorro', child: Text('Descontar del ahorro')),
                    ],
                    onChanged: (value) =>
                        setState(() => deduction = value ?? 'ninguno'),
                    decoration:
                        const InputDecoration(labelText: 'Descontar de...'),
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
                      personCtrl.text.trim().isEmpty) {
                    return;
                  }
                  await finance.updateLoan(
                    loan.id!,
                    personCtrl.text.trim(),
                    amount,
                    descCtrl.text.trim(),
                    deduction,
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

  personCtrl.dispose();
  amountCtrl.dispose();
  descCtrl.dispose();
}
