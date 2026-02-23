import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../providers/finance_provider.dart';
import '../../utils/currency_formatter.dart';
import '../dialogs/confirm_dialog.dart';
import '../dialogs/edit_goal_dialog.dart';
import '../widgets/savings_goal_item.dart';

class SavingsTab extends StatefulWidget {
  const SavingsTab({super.key});

  @override
  State<SavingsTab> createState() => _SavingsTabState();
}

class _SavingsTabState extends State<SavingsTab> {
  final _depositCtrl = TextEditingController();
  final _extraCtrl = TextEditingController();
  final _withdrawCtrl = TextEditingController();
  final _goalNameCtrl = TextEditingController();
  final _goalAmountCtrl = TextEditingController();

  @override
  void dispose() {
    _depositCtrl.dispose();
    _extraCtrl.dispose();
    _withdrawCtrl.dispose();
    _goalNameCtrl.dispose();
    _goalAmountCtrl.dispose();
    super.dispose();
  }

  void _show(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, finance, _) {
        final data = finance.dashboard;
        final totalSavings = data?.totalSavings ?? 0;
        final periodSavings = data?.periodSavings ?? 0;

        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ahorro', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 900;
                  final leftCard = Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Ahorro de este periodo', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text('Actual: ${formatCurrency(periodSavings)}', style: const TextStyle(color: Colors.black54)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            children: [
                              SizedBox(
                                width: 260,
                                child: TextField(
                                  controller: _depositCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(
                                    labelText: 'Depositar en este periodo RD\$',
                                    hintText: '7500',
                                  ),
                                ),
                              ),
                              FilledButton.icon(
                                onPressed: () async {
                                  final amount = double.tryParse(_depositCtrl.text.trim());
                                  if (amount == null || amount <= 0) {
                                    _show('Ingresa monto valido.');
                                    return;
                                  }
                                  await finance.addSavings(amount);
                                  _depositCtrl.clear();
                                  _show('Ahorro depositado.');
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Depositar'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );

                  final rightCard = Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Ahorro total', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text('Disponible: ${formatCurrency(totalSavings)}', style: const TextStyle(color: Colors.black54)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            children: [
                              SizedBox(
                                width: 260,
                                child: TextField(
                                  controller: _withdrawCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(
                                    labelText: 'Retirar del ahorro total RD\$',
                                    hintText: '2000',
                                  ),
                                ),
                              ),
                              FilledButton.icon(
                                onPressed: () async {
                                  final amount = double.tryParse(_withdrawCtrl.text.trim());
                                  if (amount == null || amount <= 0) {
                                    _show('Ingresa monto valido.');
                                    return;
                                  }
                                  final ok = await finance.withdrawSavings(amount);
                                  if (!ok) {
                                    _show('Fondos insuficientes.');
                                    return;
                                  }
                                  _withdrawCtrl.clear();
                                  _show('Retiro de ahorro exitoso.');
                                },
                                icon: const Icon(Icons.remove),
                                label: const Text('Retirar'),
                                style: FilledButton.styleFrom(backgroundColor: AppColors.warn),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );

                  final extraCard = Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Ahorro extra', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          const Text('Depositos adicionales que aumentan el ahorro del periodo.',
                              style: TextStyle(color: Colors.black54)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            children: [
                              SizedBox(
                                width: 260,
                                child: TextField(
                                  controller: _extraCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(
                                    labelText: 'Agregar ahorro extra RD\$',
                                    hintText: '1200',
                                  ),
                                ),
                              ),
                              FilledButton.icon(
                                onPressed: () async {
                                  final amount = double.tryParse(_extraCtrl.text.trim());
                                  if (amount == null || amount <= 0) {
                                    _show('Ingresa monto valido.');
                                    return;
                                  }
                                  await finance.addExtraSavings(amount);
                                  _extraCtrl.clear();
                                  _show('Ahorro extra registrado.');
                                },
                                icon: const Icon(Icons.savings_outlined),
                                label: const Text('Agregar extra'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );

                  if (isWide) {
                    return Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: leftCard),
                            const SizedBox(width: 12),
                            Expanded(child: rightCard),
                          ],
                        ),
                        const SizedBox(height: 10),
                        extraCard,
                      ],
                    );
                  }
                  return Column(
                    children: [
                      leftCard,
                      const SizedBox(height: 10),
                      rightCard,
                      const SizedBox(height: 10),
                      extraCard,
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              const Text('Metas de ahorro', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: finance.goals.isEmpty
                      ? const Align(
                          alignment: Alignment.topLeft,
                          child: Text('Sin metas de ahorro', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.black54)),
                        )
                      : ListView.builder(
                          itemCount: finance.goals.length,
                          itemBuilder: (context, index) {
                            final goal = finance.goals[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: SavingsGoalItem(
                                goal: goal,
                                totalSavings: totalSavings,
                                onEdit: () => showEditGoalDialog(context, finance: finance, goal: goal),
                                onDelete: () async {
                                  final ok = await showConfirmDialog(
                                    context,
                                    title: 'Eliminar meta',
                                    message: 'Esta accion no se puede deshacer.',
                                    confirmLabel: 'Eliminar',
                                  );
                                  if (!ok) {
                                    return;
                                  }
                                  await finance.deleteSavingsGoal(goal.id!);
                                },
                              ),
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              const Text('Agregar meta', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SizedBox(
                width: 260,
                child: TextField(
                  controller: _goalNameCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre meta', hintText: 'Viaje'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 200,
                child: TextField(
                  controller: _goalAmountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Meta RD\$', hintText: '100000'),
                ),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: () async {
                  final name = _goalNameCtrl.text.trim();
                  final amount = double.tryParse(_goalAmountCtrl.text.trim());
                  if (name.isEmpty || amount == null || amount <= 0) {
                    _show('Completa campos.');
                    return;
                  }
                  await finance.addSavingsGoal(name, amount);
                  _goalNameCtrl.clear();
                  _goalAmountCtrl.clear();
                  _show('Meta creada.');
                },
                icon: const Icon(Icons.flag),
                label: const Text('Crear meta'),
              ),
            ],
          ),
        );
      },
    );
  }
}
