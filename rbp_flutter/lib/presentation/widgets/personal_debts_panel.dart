import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:rbp_flutter/utils/web_font.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../data/models/personal_debt.dart';
import '../providers/finance_provider.dart';
import '../../utils/currency_formatter.dart';
import '../dialogs/confirm_dialog.dart';
import '../theme/app_icon_button.dart';

class PersonalDebtsPanel extends StatefulWidget {
  const PersonalDebtsPanel({super.key});

  @override
  State<PersonalDebtsPanel> createState() => _PersonalDebtsPanelState();
}

class _PersonalDebtsPanelState extends State<PersonalDebtsPanel> {
  final _personCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _dateCtrl = TextEditingController(
    text: DateTime.now().toIso8601String().split('T').first,
  );

  @override
  void dispose() {
    _personCtrl.dispose();
    _amountCtrl.dispose();
    _descCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_dateCtrl.text) ?? DateTime.now(),
      firstDate: DateTime(2000, 1, 1),
      lastDate: DateTime(2100, 12, 31),
    );
    if (selected == null) {
      return;
    }
    _dateCtrl.text = selected.toIso8601String().split('T').first;
  }

  Future<void> _save(FinanceProvider finance) async {
    final person = _personCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.trim());
    final date = _dateCtrl.text.trim();
    if (person.isEmpty || amount == null || amount <= 0 || DateTime.tryParse(date) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa persona, monto y fecha validos.')),
      );
      return;
    }
    try {
      await finance.addPersonalDebt(person, amount, _descCtrl.text.trim(), date);
      _personCtrl.clear();
      _amountCtrl.clear();
      _descCtrl.clear();
      _dateCtrl.text = DateTime.now().toIso8601String().split('T').first;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deuda personal agregada.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo agregar deuda: $e')),
        );
      }
    }
  }

  double _fieldWidth(double maxWidth, double desktopWidth,
      {double minWidth = 180}) {
    if (maxWidth < 560) {
      return maxWidth;
    }
    if (maxWidth < 960) {
      return ((maxWidth - 8) / 2).clamp(minWidth, maxWidth);
    }
    return desktopWidth;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, finance, _) {
        final pending = finance.personalDebts.where((d) => !d.isPaidBool);
        final totalPending = pending.fold<double>(0, (sum, d) => sum + d.currentBalance);
        return LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = math.max(280.0, constraints.maxWidth);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nueva deuda personal',
                  style: TextStyle(fontSize: 16, fontWeight: fw700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    SizedBox(
                      width: _fieldWidth(maxWidth, 220),
                      child: TextField(
                        controller: _personCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Persona',
                          hintText: 'Quien te presto',
                        ),
                      ),
                    ),
                    SizedBox(
                      width: _fieldWidth(maxWidth, 180),
                      child: TextField(
                        controller: _amountCtrl,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Monto RD\$',
                        ),
                      ),
                    ),
                    SizedBox(
                      width: _fieldWidth(maxWidth, 320),
                      child: TextField(
                        controller: _descCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Descripcion (opc.)'),
                      ),
                    ),
                    SizedBox(
                      width: _fieldWidth(maxWidth, 190, minWidth: 160),
                      child: TextField(
                        controller: _dateCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Fecha',
                          hintText: 'YYYY-MM-DD',
                        ),
                      ),
                    ),
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
                  onPressed: finance.isLoading ? null : () => _save(finance),
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar deuda'),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _metric('Pendientes', '${pending.length}'),
                    _metric('Balance pendiente', formatCurrency(totalPending)),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: finance.personalDebts.isEmpty
                        ? Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              'Sin deudas personales.',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: AppColors.subtitle,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: finance.personalDebts.length,
                            itemBuilder: (context, index) {
                              final debt = finance.personalDebts[index];
                              return _PersonalDebtTile(debt: debt);
                            },
                          ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _metric(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: TextStyle(color: AppColors.subtitle)),
          Text(
            value,
            style:
                TextStyle(color: AppColors.primary, fontWeight: fw700),
          ),
        ],
      ),
    );
  }
}

class _PersonalDebtTile extends StatelessWidget {
  const _PersonalDebtTile({required this.debt});

  final PersonalDebt debt;

  @override
  Widget build(BuildContext context) {
    final finance = context.read<FinanceProvider>();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.mutedSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 240,
                child: Text(
                  debt.person,
                  style:
                      const TextStyle(fontSize: 15, fontWeight: fw700),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: debt.isPaidBool ? AppColors.success : AppColors.warn,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  debt.isPaidBool ? 'PAGADA' : 'PENDIENTE',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: fw700,
                  ),
                ),
              ),
              AppIconButton(
                onPressed: () => _showEditPersonalDebtDialog(context, debt),
                icon: Icons.edit_outlined,
                color: AppColors.primary,
                hoverColor: AppColors.hoverPrimary,
                tooltip: 'Editar deuda',
              ),
              AppIconButton(
                onPressed: () async {
                  final ok = await showConfirmDialog(
                    context,
                    title: 'Eliminar deuda personal',
                    message: 'Se eliminara la deuda y su historial de pagos.',
                    confirmLabel: 'Eliminar',
                  );
                  if (!ok) {
                    return;
                  }
                  await finance.deletePersonalDebt(debt.id!);
                },
                icon: Icons.delete_outline,
                color: AppColors.error,
                hoverColor: AppColors.hoverError,
                tooltip: 'Eliminar deuda',
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 10,
            runSpacing: 4,
            children: [
              Text('Fecha: ${debt.date}'),
              Text('Total: ${formatCurrency(debt.totalAmount)}'),
              Text('Pendiente: ${formatCurrency(debt.currentBalance)}'),
              if ((debt.description ?? '').trim().isNotEmpty)
                Text('Desc: ${debt.description!.trim()}'),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: debt.isPaidBool
                    ? null
                    : () => _showRegisterPersonalPaymentDialog(context, debt),
                icon: const Icon(Icons.payments_outlined),
                label: const Text('Registrar abono'),
              ),
              TextButton.icon(
                onPressed: () => _showPersonalDebtPaymentsDialog(context, debt),
                icon: const Icon(Icons.receipt_long),
                label: const Text('Ver historial'),
              ),
            ],
          )
        ],
      ),
    );
  }
}

Future<void> _showEditPersonalDebtDialog(
  BuildContext context,
  PersonalDebt debt,
) async {
  final personCtrl = TextEditingController(text: debt.person);
  final totalCtrl =
      TextEditingController(text: debt.totalAmount.toStringAsFixed(2));
  final descCtrl = TextEditingController(text: debt.description ?? '');

  await showDialog<void>(
    context: context,
    builder: (context) {
      final width = math.min(MediaQuery.of(context).size.width - 32, 520.0);
      return AlertDialog(
        title: const Text('Editar deuda personal'),
        content: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: personCtrl,
                  decoration: const InputDecoration(labelText: 'Persona'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: totalCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Monto total RD\$'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Descripcion (opc.)'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () async {
              final total = double.tryParse(totalCtrl.text.trim());
              if (personCtrl.text.trim().isEmpty || total == null || total <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Datos invalidos para editar.')),
                );
                return;
              }
              try {
                await context.read<FinanceProvider>().updatePersonalDebt(
                      debt.id!,
                      person: personCtrl.text.trim(),
                      totalAmount: total,
                      description: descCtrl.text.trim(),
                    );
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('No se pudo editar: $e')),
                  );
                }
              }
            },
            icon: const Icon(Icons.save),
            label: const Text('Guardar'),
          ),
        ],
      );
    },
  );

  personCtrl.dispose();
  totalCtrl.dispose();
  descCtrl.dispose();
}

Future<void> _showRegisterPersonalPaymentDialog(
  BuildContext context,
  PersonalDebt debt,
) async {
  final amountCtrl = TextEditingController();
  final dateCtrl = TextEditingController(
    text: DateTime.now().toIso8601String().split('T').first,
  );
  final notesCtrl = TextEditingController();

  await showDialog<void>(
    context: context,
    builder: (context) {
      final width = math.min(MediaQuery.of(context).size.width - 32, 520.0);
      return AlertDialog(
        title: Text('Abono - ${debt.person}'),
        content: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Abono RD\$'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: dateCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Fecha pago', hintText: 'YYYY-MM-DD'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(labelText: 'Notas (opc.)'),
                ),
              ],
            ),
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
              final date = dateCtrl.text.trim();
              if (amount == null ||
                  amount <= 0 ||
                  DateTime.tryParse(date) == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Datos de pago invalidos.')),
                );
                return;
              }
              try {
                await context.read<FinanceProvider>().registerPersonalDebtPayment(
                      debtId: debt.id!,
                      amount: amount,
                      paymentDate: date,
                      notes: notesCtrl.text.trim(),
                    );
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('No se pudo registrar abono: $e')),
                  );
                }
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
  dateCtrl.dispose();
  notesCtrl.dispose();
}

Future<void> _showPersonalDebtPaymentsDialog(
  BuildContext context,
  PersonalDebt debt,
) async {
  await showDialog<void>(
    context: context,
    builder: (context) {
      final screen = MediaQuery.of(context).size;
      final dialogWidth = math.min(screen.width - 32, 860.0);
      final dialogHeight = math.min(screen.height * 0.76, 460.0);
      return AlertDialog(
        title: Text('Historial - ${debt.person}'),
        content: SizedBox(
          width: dialogWidth,
          height: dialogHeight,
          child: FutureBuilder(
            future: context.read<FinanceProvider>().getPersonalDebtPayments(debt.id!),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text('No se pudo cargar historial: ${snapshot.error}'),
                );
              }
              final items = snapshot.data ?? const [];
              if (items.isEmpty) {
                return const Align(
                  alignment: Alignment.topLeft,
                  child: Text('Sin pagos registrados.'),
                );
              }
              return ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 12),
                itemBuilder: (context, index) {
                  final p = items[index];
                  return Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      SizedBox(width: 120, child: Text(p.paymentDate)),
                      SizedBox(
                        width: math.min(dialogWidth * 0.45, 320),
                        child: Text(
                          p.notes?.trim().isNotEmpty == true ? p.notes! : '-',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        formatCurrency(p.amount),
                        style: const TextStyle(fontWeight: fw700),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      );
    },
  );
}
