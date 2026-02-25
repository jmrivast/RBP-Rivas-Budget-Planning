import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../providers/finance_provider.dart';
import '../dialogs/confirm_dialog.dart';
import '../dialogs/edit_fixed_payment_dialog.dart';
import '../widgets/fixed_payment_item.dart';

class FixedPaymentsTab extends StatefulWidget {
  const FixedPaymentsTab({super.key});

  @override
  State<FixedPaymentsTab> createState() => _FixedPaymentsTabState();
}

class _FixedPaymentsTabState extends State<FixedPaymentsTab> {
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _dayCtrl = TextEditingController();
  int? _categoryId;
  bool _noFixedDate = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _dayCtrl.dispose();
    super.dispose();
  }

  void _show(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save(FinanceProvider finance) async {
    final name = _nameCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.trim());
    final day = int.tryParse(_dayCtrl.text.trim());
    if (name.isEmpty || amount == null || amount <= 0) {
      _show('Completa campos.');
      return;
    }
    if (!_noFixedDate && (day == null || day < 1 || day > 31)) {
      _show('Fecha (dia del mes) debe estar entre 1 y 31.');
      return;
    }
    try {
      await finance.addFixedPayment(
        name,
        amount,
        _noFixedDate ? 1 : (day ?? 1),
        _categoryId,
        noFixedDate: _noFixedDate,
      );
      _nameCtrl.clear();
      _amountCtrl.clear();
      _dayCtrl.clear();
      setState(() {
        _categoryId = null;
        _noFixedDate = false;
      });
      _show('Pago fijo guardado.');
    } catch (e) {
      _show('No se pudo guardar el pago fijo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, finance, _) {
        final fixed = finance.dashboard?.fixedPayments ?? const [];

        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pagos fijos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
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
                  child: fixed.isEmpty
                      ? Align(
                          alignment: Alignment.topLeft,
                          child: Text('Sin pagos fijos',
                              style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.subtitle)),
                        )
                      : ListView.builder(
                          itemCount: fixed.length,
                          itemBuilder: (context, index) {
                            final payment = fixed[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: FixedPaymentItem(
                                payment: payment,
                                onTogglePaid: (paid) => finance
                                    .toggleFixedPaymentPaid(payment.id, paid),
                                onEdit: () => showEditFixedPaymentDialog(
                                  context,
                                  finance: finance,
                                  payment: payment,
                                  categories: finance.categories,
                                ),
                                onDelete: () async {
                                  final ok = await showConfirmDialog(
                                    context,
                                    title: 'Eliminar pago fijo',
                                    message: 'Se marcara como inactivo.',
                                    confirmLabel: 'Eliminar',
                                  );
                                  if (!ok) {
                                    return;
                                  }
                                  await finance.deleteFixedPayment(payment.id);
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
              const Text('Agregar pago fijo',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SizedBox(
                width: 260,
                child: TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Nombre', hintText: 'Netflix'),
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
                      labelText: 'Monto RD\$', hintText: '270'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 170,
                child: TextField(
                  controller: _dayCtrl,
                  keyboardType: TextInputType.number,
                  enabled: !_noFixedDate,
                  decoration: const InputDecoration(
                      labelText: 'Fecha (dia del mes)', hintText: '1-31'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 320,
                child: CheckboxListTile(
                  value: _noFixedDate,
                  onChanged: (value) =>
                      setState(() => _noFixedDate = value ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Sin fecha fija (marcar pagado manualmente)'),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 260,
                child: DropdownButtonFormField<int?>(
                  initialValue: _categoryId,
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Sin categoria'),
                    ),
                    ...finance.categories.where((c) => c.id != null).map(
                          (cat) => DropdownMenuItem<int?>(
                            value: cat.id,
                            child: Text(cat.name),
                          ),
                        ),
                  ],
                  onChanged: (value) => setState(() => _categoryId = value),
                  decoration:
                      const InputDecoration(labelText: 'Categoria (opc.)'),
                ),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: finance.isLoading ? null : () => _save(finance),
                icon: const Icon(Icons.save),
                label: const Text('Guardar'),
              ),
            ],
          ),
        );
      },
    );
  }
}
