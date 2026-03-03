import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../data/models/debt.dart';
import '../../providers/finance_provider.dart';
import '../../utils/currency_formatter.dart';
import '../theme/app_icon_button.dart';
import '../dialogs/confirm_dialog.dart';

class BankDebtsPanel extends StatefulWidget {
  const BankDebtsPanel({super.key});

  @override
  State<BankDebtsPanel> createState() => _BankDebtsPanelState();
}

class _BankDebtsPanelState extends State<BankDebtsPanel> {
  final _nameCtrl = TextEditingController();
  final _principalCtrl = TextEditingController();
  final _rateCtrl = TextEditingController(text: '18');
  final _termCtrl = TextEditingController(text: '24');
  final _startDateCtrl = TextEditingController(
    text: DateTime.now().toIso8601String().split('T').first,
  );
  final _paymentDayCtrl = TextEditingController(text: '${DateTime.now().day}');

  @override
  void dispose() {
    _nameCtrl.dispose();
    _principalCtrl.dispose();
    _rateCtrl.dispose();
    _termCtrl.dispose();
    _startDateCtrl.dispose();
    _paymentDayCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_startDateCtrl.text) ?? DateTime.now(),
      firstDate: DateTime(2000, 1, 1),
      lastDate: DateTime(2100, 12, 31),
    );
    if (selected == null) {
      return;
    }
    setState(() {
      _startDateCtrl.text = selected.toIso8601String().split('T').first;
      _paymentDayCtrl.text = '${selected.day}';
    });
  }

  Future<void> _saveDebt(FinanceProvider finance) async {
    final name = _nameCtrl.text.trim();
    final principal = double.tryParse(_principalCtrl.text.trim());
    final rate = double.tryParse(_rateCtrl.text.trim());
    final term = int.tryParse(_termCtrl.text.trim());
    final paymentDay = int.tryParse(_paymentDayCtrl.text.trim());
    final date = _startDateCtrl.text.trim();

    if (name.isEmpty ||
        principal == null ||
        principal <= 0 ||
        rate == null ||
        rate < 0 ||
        term == null ||
        term <= 0 ||
        paymentDay == null ||
        paymentDay < 1 ||
        paymentDay > 31 ||
        DateTime.tryParse(date) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Completa todos los campos de deuda correctamente.')),
      );
      return;
    }

    try {
      await finance.addDebt(
        name: name,
        principalAmount: principal,
        annualRate: rate,
        termMonths: term,
        startDate: date,
        paymentDay: paymentDay,
      );
      _nameCtrl.clear();
      _principalCtrl.clear();
      _rateCtrl.text = '18';
      _termCtrl.text = '24';
      _startDateCtrl.text = DateTime.now().toIso8601String().split('T').first;
      _paymentDayCtrl.text = '${DateTime.now().day}';
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Deuda creada.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo crear la deuda: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, finance, _) {
        final active = finance.debts.where((d) => d.isActiveBool).toList();
        final totalBalance =
            active.fold<double>(0, (sum, d) => sum + d.currentBalance);
        final totalInstallment =
            active.fold<double>(0, (sum, d) => sum + d.monthlyPayment);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nueva deuda bancaria',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: 220,
                  child: TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Entidad / deuda',
                      hintText: 'Tarjeta Banco X',
                    ),
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: TextField(
                    controller: _principalCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Capital RD\$',
                    ),
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: TextField(
                    controller: _rateCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Tasa anual %',
                    ),
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: TextField(
                    controller: _termCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Plazo (meses)',
                    ),
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: TextField(
                    controller: _startDateCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Fecha inicio',
                      hintText: 'YYYY-MM-DD',
                    ),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _paymentDayCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Dia pago',
                    ),
                  ),
                ),
                AppIconButton(
                  onPressed: _pickStartDate,
                  icon: Icons.calendar_month,
                  color: AppColors.primary,
                  hoverColor: AppColors.hoverPrimary,
                  tooltip: 'Elegir fecha',
                ),
              ],
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: finance.isLoading ? null : () => _saveDebt(finance),
              icon: const Icon(Icons.add),
              label: const Text('Agregar deuda'),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _metricChip('Deudas activas', '${active.length}'),
                _metricChip('Balance total', formatCurrency(totalBalance)),
                _metricChip(
                    'Cuota mensual total', formatCurrency(totalInstallment)),
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
                child: finance.debts.isEmpty
                    ? Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          'Sin deudas bancarias.',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: AppColors.subtitle,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: finance.debts.length,
                        itemBuilder: (context, index) {
                          final debt = finance.debts[index];
                          return _DebtTile(debt: debt);
                        },
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _metricChip(String label, String value) {
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
          Text(
            '$label: ',
            style: TextStyle(
              color: AppColors.subtitle,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DebtTile extends StatelessWidget {
  const _DebtTile({required this.debt});

  final Debt debt;

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
          Row(
            children: [
              Expanded(
                child: Text(
                  debt.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: debt.isActiveBool ? AppColors.warn : AppColors.success,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  debt.isActiveBool ? 'ACTIVA' : 'PAGADA',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              AppIconButton(
                onPressed: () => _showEditDebtDialog(context, debt),
                icon: Icons.edit_outlined,
                color: AppColors.primary,
                hoverColor: AppColors.hoverPrimary,
                tooltip: 'Editar deuda',
              ),
              AppIconButton(
                onPressed: () async {
                  final ok = await showConfirmDialog(
                    context,
                    title: 'Eliminar deuda',
                    message: 'Se eliminaran la deuda y sus pagos registrados.',
                    confirmLabel: 'Eliminar',
                  );
                  if (!ok) {
                    return;
                  }
                  await finance.deleteDebt(debt.id!);
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
              Text('Balance: ${formatCurrency(debt.currentBalance)}'),
              Text('Cuota: ${formatCurrency(debt.monthlyPayment)}'),
              Text('Tasa: ${debt.annualRate.toStringAsFixed(2)}%'),
              Text('Plazo: ${debt.termMonths} meses'),
              Text('Dia pago: ${debt.paymentDay}'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: debt.isActiveBool
                    ? () => _showRegisterPaymentDialog(context, debt)
                    : null,
                icon: const Icon(Icons.payments_outlined),
                label: const Text('Registrar pago'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => _showDebtPaymentsDialog(context, debt),
                icon: const Icon(Icons.receipt_long),
                label: const Text('Ver pagos'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> _showEditDebtDialog(BuildContext context, Debt debt) async {
  final nameCtrl = TextEditingController(text: debt.name);
  final rateCtrl =
      TextEditingController(text: debt.annualRate.toStringAsFixed(2));
  final termCtrl = TextEditingController(text: '${debt.termMonths}');
  final paymentDayCtrl = TextEditingController(text: '${debt.paymentDay}');

  await showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Editar deuda'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: rateCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Tasa anual %'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: termCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Plazo (meses)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: paymentDayCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Dia de pago'),
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
              final rate = double.tryParse(rateCtrl.text.trim());
              final term = int.tryParse(termCtrl.text.trim());
              final paymentDay = int.tryParse(paymentDayCtrl.text.trim());
              if (nameCtrl.text.trim().isEmpty ||
                  rate == null ||
                  rate < 0 ||
                  term == null ||
                  term <= 0 ||
                  paymentDay == null ||
                  paymentDay < 1 ||
                  paymentDay > 31) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Datos invalidos para editar.')),
                );
                return;
              }
              try {
                await context.read<FinanceProvider>().updateDebt(
                      debtId: debt.id!,
                      name: nameCtrl.text.trim(),
                      annualRate: rate,
                      termMonths: term,
                      paymentDay: paymentDay,
                    );
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Deuda actualizada.')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('No se pudo actualizar: $e')),
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

  nameCtrl.dispose();
  rateCtrl.dispose();
  termCtrl.dispose();
  paymentDayCtrl.dispose();
}

Future<void> _showRegisterPaymentDialog(BuildContext context, Debt debt) async {
  final totalCtrl =
      TextEditingController(text: debt.monthlyPayment.toStringAsFixed(2));
  final interestCtrl = TextEditingController(text: '0');
  final capitalCtrl =
      TextEditingController(text: debt.monthlyPayment.toStringAsFixed(2));
  final dateCtrl = TextEditingController(
    text: DateTime.now().toIso8601String().split('T').first,
  );
  final notesCtrl = TextEditingController();

  await showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Pago - ${debt.name}'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: totalCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Pago total RD\$'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: interestCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Interes RD\$'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: capitalCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Capital RD\$'),
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
                decoration: const InputDecoration(
                  labelText: 'Notas (opc.)',
                ),
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
              final total = double.tryParse(totalCtrl.text.trim());
              final interest = double.tryParse(interestCtrl.text.trim());
              final capital = double.tryParse(capitalCtrl.text.trim());
              final date = dateCtrl.text.trim();
              if (total == null ||
                  total <= 0 ||
                  interest == null ||
                  interest < 0 ||
                  capital == null ||
                  capital < 0 ||
                  DateTime.tryParse(date) == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Completa el pago con valores validos.'),
                  ),
                );
                return;
              }
              try {
                await context.read<FinanceProvider>().registerDebtPayment(
                      debtId: debt.id!,
                      paymentDate: date,
                      totalAmount: total,
                      interestAmount: interest,
                      capitalAmount: capital,
                      notes: notesCtrl.text.trim(),
                    );
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pago registrado.')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('No se pudo registrar pago: $e')),
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

  totalCtrl.dispose();
  interestCtrl.dispose();
  capitalCtrl.dispose();
  dateCtrl.dispose();
  notesCtrl.dispose();
}

Future<void> _showDebtPaymentsDialog(BuildContext context, Debt debt) async {
  await showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Pagos - ${debt.name}'),
        content: SizedBox(
          width: 720,
          height: 420,
          child: FutureBuilder(
            future: context.read<FinanceProvider>().getDebtPayments(debt.id!),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text('No se pudieron cargar pagos: ${snapshot.error}'),
                );
              }
              final payments = snapshot.data ?? const [];
              if (payments.isEmpty) {
                return const Align(
                  alignment: Alignment.topLeft,
                  child: Text('Sin pagos registrados.'),
                );
              }
              return ListView.separated(
                itemCount: payments.length,
                separatorBuilder: (_, __) => const Divider(height: 12),
                itemBuilder: (context, index) {
                  final p = payments[index];
                  return Row(
                    children: [
                      SizedBox(width: 110, child: Text(p.paymentDate)),
                      Expanded(
                        child: Text(
                          p.notes?.trim().isNotEmpty == true ? p.notes! : '-',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(
                        width: 140,
                        child: Text('Int: ${formatCurrency(p.interestAmount)}'),
                      ),
                      SizedBox(
                        width: 150,
                        child: Text('Cap: ${formatCurrency(p.capitalAmount)}'),
                      ),
                      SizedBox(
                        width: 150,
                        child: Text(
                          formatCurrency(p.totalAmount),
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
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
