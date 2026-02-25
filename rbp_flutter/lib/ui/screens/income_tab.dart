import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../providers/finance_provider.dart';
import '../dialogs/confirm_dialog.dart';
import '../dialogs/edit_income_dialog.dart';
import '../theme/app_icon_button.dart';
import '../widgets/income_item.dart';

class IncomeTab extends StatefulWidget {
  const IncomeTab({super.key});

  @override
  State<IncomeTab> createState() => _IncomeTabState();
}

class _IncomeTabState extends State<IncomeTab> {
  final _salaryCtrl = TextEditingController();
  final _overrideCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _dateCtrl = TextEditingController(
    text: DateTime.now().toIso8601String().split('T').first,
  );

  String _periodKey = '';

  @override
  void dispose() {
    _salaryCtrl.dispose();
    _overrideCtrl.dispose();
    _amountCtrl.dispose();
    _descCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPeriodData(FinanceProvider finance) async {
    final key =
        '${finance.year}-${finance.month}-${finance.cycle}-${finance.periodMode}';
    if (_periodKey == key) {
      return;
    }
    _periodKey = key;
    final salary = await finance.getSalary();
    final override = await finance.getSalaryOverride(
        finance.year, finance.month, finance.cycle);
    if (!mounted) {
      return;
    }
    _salaryCtrl.text = salary == 0 ? '' : salary.toString();
    _overrideCtrl.text = override == null ? '' : override.toString();
  }

  void _show(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  DateTime _safeDate(String raw) {
    return DateTime.tryParse(raw) ?? DateTime.now();
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _safeDate(_dateCtrl.text),
      firstDate: DateTime(2000, 1, 1),
      lastDate: DateTime(2100, 12, 31),
    );
    if (selected == null || !mounted) {
      return;
    }
    _dateCtrl.text = selected.toIso8601String().split('T').first;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, finance, _) {
        return FutureBuilder<void>(
          future: _loadPeriodData(finance),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 980;

                final salaryPanel = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Salario',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SizedBox(
                          width: 260,
                          child: TextField(
                            controller: _salaryCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                              labelText:
                                  'Salario base ${finance.periodMode} RD\$',
                              hintText: '25000',
                            ),
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: () async {
                            final value =
                                double.tryParse(_salaryCtrl.text.trim());
                            if (value == null || value < 0) {
                              _show('Salario invalido.');
                              return;
                            }
                            await finance.setSalary(value);
                            _show('Salario base guardado correctamente.');
                          },
                          icon: const Icon(Icons.save),
                          label: const Text('Guardar'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Salario variable por quincena',
                      style: TextStyle(fontSize: 14, color: AppColors.subtitle),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SizedBox(
                          width: 330,
                          child: TextField(
                            controller: _overrideCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                              labelText:
                                  'Salario esta quincena (Q${finance.cycle} ${finance.month.toString().padLeft(2, '0')}/${finance.year}) RD\$',
                            ),
                            enabled: finance.periodMode != 'mensual',
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: finance.periodMode == 'mensual'
                              ? null
                              : () async {
                                  final value = double.tryParse(
                                      _overrideCtrl.text.trim());
                                  if (value == null || value < 0) {
                                    _show('Monto invalido.');
                                    return;
                                  }
                                  await finance.setSalaryOverride(
                                    finance.year,
                                    finance.month,
                                    finance.cycle,
                                    value,
                                  );
                                  _show('Salario de quincena guardado.');
                                },
                          icon: const Icon(Icons.event_available),
                          label: const Text('Guardar quincena'),
                        ),
                        OutlinedButton.icon(
                          onPressed: finance.periodMode == 'mensual'
                              ? null
                              : () async {
                                  await finance.deleteSalaryOverride(
                                    finance.year,
                                    finance.month,
                                    finance.cycle,
                                  );
                                  _overrideCtrl.clear();
                                  _show(
                                      'Salario de quincena restablecido al salario base.');
                                },
                          icon: const Icon(Icons.restart_alt),
                          label: const Text('Usar base'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      finance.periodMode == 'mensual'
                          ? 'En modo mensual se usa solo el salario base del mes.'
                          : 'En modo quincenal puedes ajustar montos por quincena.',
                      style: TextStyle(fontSize: 12, color: AppColors.subtitle),
                    ),
                  ],
                );

                final addIncomePanel = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Agregar ingreso',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 320,
                      child: TextField(
                        controller: _amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration:
                            const InputDecoration(labelText: 'Monto RD\$'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 440,
                      child: TextField(
                        controller: _descCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Descripcion'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 280,
                          child: TextField(
                            controller: _dateCtrl,
                            decoration: const InputDecoration(
                                labelText: 'Fecha', hintText: 'YYYY-MM-DD'),
                          ),
                        ),
                        const SizedBox(width: 6),
                        AppIconButton(
                          onPressed: _pickDate,
                          icon: Icons.calendar_month,
                          color: AppColors.primary,
                          hoverColor: AppColors.hoverPrimary,
                          tooltip: 'Elegir fecha',
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                        overlayColor: AppColors.hoverSuccess,
                      ),
                      onPressed: () async {
                        final amount = double.tryParse(_amountCtrl.text.trim());
                        final desc = _descCtrl.text.trim();
                        if (amount == null || amount <= 0 || desc.isEmpty) {
                          _show('Completa campos.');
                          return;
                        }
                        await finance.addIncome(
                            amount, desc, _dateCtrl.text.trim());
                        _amountCtrl.clear();
                        _descCtrl.clear();
                        _dateCtrl.text =
                            DateTime.now().toIso8601String().split('T').first;
                        _show('Ingreso registrado.');
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar'),
                    ),
                  ],
                );

                return Padding(
                  padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 7, child: salaryPanel),
                            const SizedBox(width: 12),
                            Expanded(flex: 5, child: addIncomePanel),
                          ],
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            salaryPanel,
                            const SizedBox(height: 12),
                            addIncomePanel,
                          ],
                        ),
                      const SizedBox(height: 14),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      const Text('Ingresos extras',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.cardBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: finance.incomes.isEmpty
                              ? Align(
                                  alignment: Alignment.topLeft,
                                  child: Text(
                                    'Sin ingresos extras',
                                    style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: AppColors.subtitle),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: finance.incomes.length,
                                  itemBuilder: (context, index) {
                                    final income = finance.incomes[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: IncomeItem(
                                        income: income,
                                        onEdit: () => showEditIncomeDialog(
                                            context,
                                            finance: finance,
                                            income: income),
                                        onDelete: () async {
                                          final ok = await showConfirmDialog(
                                            context,
                                            title: 'Eliminar ingreso',
                                            message:
                                                'Esta accion no se puede deshacer.',
                                            confirmLabel: 'Eliminar',
                                          );
                                          if (!ok) {
                                            return;
                                          }
                                          await finance
                                              .deleteIncome(income.id!);
                                        },
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
