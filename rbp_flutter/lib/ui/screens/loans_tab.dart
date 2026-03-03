import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rbp_flutter/config/constants.dart';
import 'package:rbp_flutter/providers/finance_provider.dart';
import 'package:rbp_flutter/ui/dialogs/confirm_dialog.dart';
import 'package:rbp_flutter/ui/dialogs/edit_loan_dialog.dart';
import 'package:rbp_flutter/ui/dialogs/manage_debts_dialog.dart';
import 'package:rbp_flutter/ui/dialogs/manage_personal_debts_dialog.dart';
import 'package:rbp_flutter/ui/theme/app_icon_button.dart';
import 'package:rbp_flutter/ui/widgets/loan_item.dart';
import 'package:rbp_flutter/utils/currency_formatter.dart';

enum _LoansSection { lent, personalDebt, bankDebt }

class LoansTab extends StatefulWidget {
  const LoansTab({super.key});

  @override
  State<LoansTab> createState() => _LoansTabState();
}

class _LoansTabState extends State<LoansTab> {
  final _personCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _dateCtrl = TextEditingController(
    text: DateTime.now().toIso8601String().split('T').first,
  );
  String _deduction = 'ninguno';
  _LoansSection _section = _LoansSection.lent;

  @override
  void dispose() {
    _personCtrl.dispose();
    _amountCtrl.dispose();
    _descCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
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

  Future<void> _save(FinanceProvider finance) async {
    final person = _personCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.trim());
    final date = _dateCtrl.text.trim();
    if (person.isEmpty || amount == null || amount <= 0) {
      _show('Completa persona y monto.');
      return;
    }
    try {
      await finance.addLoan(
        person,
        amount,
        _descCtrl.text.trim(),
        date,
        deductionType: _deduction,
      );
      _personCtrl.clear();
      _amountCtrl.clear();
      _descCtrl.clear();
      _dateCtrl.text = DateTime.now().toIso8601String().split('T').first;
      setState(() => _deduction = 'ninguno');
      _show('Prestamo registrado.');
    } catch (e) {
      _show('No se pudo registrar el prestamo: $e');
    }
  }

  Widget _sectionSelector() {
    return SegmentedButton<_LoansSection>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(
          value: _LoansSection.lent,
          icon: Icon(Icons.call_made_outlined),
          label: Text('Prestamos dados'),
        ),
        ButtonSegment(
          value: _LoansSection.personalDebt,
          icon: Icon(Icons.handshake_outlined),
          label: Text('Deudas personales'),
        ),
        ButtonSegment(
          value: _LoansSection.bankDebt,
          icon: Icon(Icons.account_balance),
          label: Text('Deudas bancarias'),
        ),
      ],
      selected: {_section},
      onSelectionChanged: (selection) {
        if (selection.isEmpty) {
          return;
        }
        setState(() => _section = selection.first);
      },
    );
  }

  Widget _buildLentSection(FinanceProvider finance) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dinero prestado',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
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
            child: finance.loans.isEmpty
                ? Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      'Sin prestamos',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: AppColors.subtitle,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: finance.loans.length,
                    itemBuilder: (context, index) {
                      final loan = finance.loans[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: LoanItem(
                          loan: loan,
                          onMarkPaid: () => finance.markLoanPaid(loan.id!),
                          onEdit: () => showEditLoanDialog(context,
                              finance: finance, loan: loan),
                          onDelete: () async {
                            final ok = await showConfirmDialog(
                              context,
                              title: 'Eliminar prestamo',
                              message: 'Esta accion no se puede deshacer.',
                              confirmLabel: 'Eliminar',
                            );
                            if (!ok) {
                              return;
                            }
                            await finance.deleteLoan(loan.id!);
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
        const Text(
          'Nuevo prestamo',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 260,
          child: TextField(
            controller: _personCtrl,
            decoration:
                const InputDecoration(labelText: 'Persona', hintText: 'Nombre'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 200,
          child: TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration:
                const InputDecoration(labelText: 'Monto RD\$', hintText: '500'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 320,
          child: TextField(
            controller: _descCtrl,
            decoration: const InputDecoration(
                labelText: 'Motivo (opc.)', hintText: 'gasolina'),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 200,
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
        const SizedBox(height: 8),
        SizedBox(
          width: 260,
          child: DropdownButtonFormField<String>(
            initialValue: _deduction,
            items: const [
              DropdownMenuItem(value: 'ninguno', child: Text('No descontar')),
              DropdownMenuItem(
                  value: 'gasto', child: Text('Descontar como gasto')),
              DropdownMenuItem(
                  value: 'ahorro', child: Text('Descontar del ahorro')),
            ],
            onChanged: (value) =>
                setState(() => _deduction = value ?? 'ninguno'),
            decoration: const InputDecoration(labelText: 'Descontar de...'),
          ),
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: finance.isLoading ? null : () => _save(finance),
          icon: const Icon(Icons.save),
          label: const Text('Guardar'),
        ),
      ],
    );
  }

  Widget _buildPersonalDebtSection(FinanceProvider finance) {
    final pending = finance.personalDebts.where((d) => !d.isPaidBool).toList();
    final totalPending =
        pending.fold<double>(0, (sum, d) => sum + d.currentBalance);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Deudas personales (tu debes)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () =>
                  showManagePersonalDebtsDialog(context, finance: finance),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Gestionar'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _infoChip('Pendientes', '${pending.length}'),
            _infoChip('Balance pendiente', formatCurrency(totalPending)),
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
                      'Sin deudas personales registradas.',
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
                      final paid = debt.isPaidBool;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.mutedSurface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    debt.person,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    'Pendiente: ${formatCurrency(debt.currentBalance)}'
                                    '  |  Total: ${formatCurrency(debt.totalAmount)}'
                                    '  |  Fecha: ${debt.date}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.subtitle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    paid ? AppColors.success : AppColors.warn,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                paid ? 'PAGADA' : 'PENDIENTE',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildBankDebtSection(FinanceProvider finance) {
    final active = finance.debts.where((d) => d.isActiveBool).toList();
    final totalBalance =
        active.fold<double>(0, (sum, d) => sum + d.currentBalance);
    final totalInstallment =
        active.fold<double>(0, (sum, d) => sum + d.monthlyPayment);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Deudas bancarias',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => showManageDebtsDialog(context, finance: finance),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Gestionar'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _infoChip('Activas', '${active.length}'),
            _infoChip('Balance total', formatCurrency(totalBalance)),
            _infoChip('Cuota mensual total', formatCurrency(totalInstallment)),
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
                      'Sin deudas bancarias registradas.',
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
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.mutedSurface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    debt.name,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    'Balance: ${formatCurrency(debt.currentBalance)}'
                                    '  |  Cuota: ${formatCurrency(debt.monthlyPayment)}'
                                    '  |  Tasa: ${debt.annualRate.toStringAsFixed(2)}%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.subtitle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: debt.isActiveBool
                                    ? AppColors.warn
                                    : AppColors.success,
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
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _infoChip(String label, String value) {
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
                TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, finance, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionSelector(),
              const SizedBox(height: 12),
              Expanded(
                child: switch (_section) {
                  _LoansSection.lent => _buildLentSection(finance),
                  _LoansSection.personalDebt =>
                    _buildPersonalDebtSection(finance),
                  _LoansSection.bankDebt => _buildBankDebtSection(finance),
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
