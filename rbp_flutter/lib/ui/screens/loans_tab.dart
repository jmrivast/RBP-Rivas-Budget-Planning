import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rbp_flutter/config/constants.dart';
import 'package:rbp_flutter/providers/finance_provider.dart';
import 'package:rbp_flutter/ui/dialogs/confirm_dialog.dart';
import 'package:rbp_flutter/ui/dialogs/edit_loan_dialog.dart';
import 'package:rbp_flutter/ui/theme/app_icon_button.dart';
import 'package:rbp_flutter/ui/widgets/guided_showcase.dart';
import 'package:rbp_flutter/ui/widgets/loan_item.dart';

class LoansTab extends StatefulWidget {
  const LoansTab({
    super.key,
    this.guideKey,
    this.onGuideNext,
    this.onGuidePrevious,
  });
  final GlobalKey? guideKey;
  final VoidCallback? onGuideNext;
  final VoidCallback? onGuidePrevious;

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

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, finance, _) {
        final topSection = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dinero prestado',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SizedBox(
              height: 280,
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
                        child: Text('Sin prestamos',
                            style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: AppColors.subtitle)),
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
          ],
        );

        final guidedTopSection = widget.guideKey == null
            ? topSection
            : GuidedShowcase(
                showcaseKey: widget.guideKey!,
                title: 'Prestamos',
                description: '- Aqui ves prestamos pendientes y su estado.\n'
                    '- Registra persona, monto, fecha y motivo.\n'
                    '- En "Descontar de..." elige gasto, ahorro o ninguno.',
                onNext: widget.onGuideNext,
                onPrevious: widget.onGuidePrevious,
                child: topSection,
              );

        final content = Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              guidedTopSection,
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              const Text('Nuevo prestamo',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SizedBox(
                width: 260,
                child: TextField(
                  controller: _personCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Persona', hintText: 'Nombre'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 200,
                child: TextField(
                  controller: _amountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                      labelText: 'Monto RD\$', hintText: '500'),
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
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: finance.isLoading ? null : () => _save(finance),
                icon: const Icon(Icons.save),
                label: const Text('Guardar'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
        return SingleChildScrollView(child: content);
      },
    );
  }
}
