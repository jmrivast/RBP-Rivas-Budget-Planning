import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rbp_flutter/config/constants.dart';
import 'package:rbp_flutter/presentation/providers/finance_provider.dart';
import 'package:rbp_flutter/presentation/dialogs/confirm_dialog.dart';
import 'package:rbp_flutter/presentation/dialogs/edit_loan_dialog.dart';
import 'package:rbp_flutter/presentation/theme/app_icon_button.dart';
import 'package:rbp_flutter/presentation/widgets/loan_item.dart';
import 'package:rbp_flutter/presentation/widgets/bank_debts_panel.dart';
import 'package:rbp_flutter/presentation/widgets/personal_debts_panel.dart';

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
    final selector = SegmentedButton<_LoansSection>(
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

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: selector,
    );
  }

  Widget _buildLentSection(FinanceProvider finance) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        final primaryWidth = compact ? double.infinity : 260.0;
        final amountWidth = compact ? double.infinity : 200.0;
        final descWidth = compact ? double.infinity : 320.0;
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
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: primaryWidth,
                  child: TextField(
                    controller: _personCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Persona', hintText: 'Nombre'),
                  ),
                ),
                SizedBox(
                  width: amountWidth,
                  child: TextField(
                    controller: _amountCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: 'Monto RD\$', hintText: '500'),
                  ),
                ),
                SizedBox(
                  width: descWidth,
                  child: TextField(
                    controller: _descCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Motivo (opc.)', hintText: 'gasolina'),
                  ),
                ),
                SizedBox(
                  width: amountWidth,
                  child: TextField(
                    controller: _dateCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Fecha', hintText: 'YYYY-MM-DD'),
                  ),
                ),
                AppIconButton(
                  onPressed: _pickDate,
                  icon: Icons.calendar_month,
                  color: AppColors.primary,
                  hoverColor: AppColors.hoverPrimary,
                  tooltip: 'Elegir fecha',
                ),
                SizedBox(
                  width: primaryWidth,
                  child: DropdownButtonFormField<String>(
                    initialValue: _deduction,
                    items: const [
                      DropdownMenuItem(
                          value: 'ninguno', child: Text('No descontar')),
                      DropdownMenuItem(
                          value: 'gasto', child: Text('Descontar como gasto')),
                      DropdownMenuItem(
                          value: 'ahorro', child: Text('Descontar del ahorro')),
                    ],
                    onChanged: (value) =>
                        setState(() => _deduction = value ?? 'ninguno'),
                    decoration:
                        const InputDecoration(labelText: 'Descontar de...'),
                  ),
                ),
                FilledButton.icon(
                  onPressed: finance.isLoading ? null : () => _save(finance),
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildPersonalDebtSection(FinanceProvider finance) {
    return const PersonalDebtsPanel();
  }

  Widget _buildBankDebtSection(FinanceProvider finance) {
    return const BankDebtsPanel();
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
