import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../providers/finance_provider.dart';
import '../theme/app_icon_button.dart';

class ExpenseTab extends StatefulWidget {
  const ExpenseTab({super.key});

  @override
  State<ExpenseTab> createState() => _ExpenseTabState();
}

class _ExpenseTabState extends State<ExpenseTab> {
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _dateCtrl = TextEditingController(
    text: DateTime.now().toIso8601String().split('T').first,
  );
  int? _categoryId;
  String _source = 'sueldo';

  @override
  void dispose() {
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
    final amount = double.tryParse(_amountCtrl.text.trim());
    final desc = _descCtrl.text.trim();
    final date = _dateCtrl.text.trim();
    if (amount == null ||
        amount <= 0 ||
        desc.isEmpty ||
        _categoryId == null ||
        date.isEmpty) {
      _show('Completa todo.');
      return;
    }
    try {
      await finance.addExpense(
        amount,
        desc,
        _categoryId!,
        date,
        source: _source,
      );
      _amountCtrl.clear();
      _descCtrl.clear();
      _dateCtrl.text = DateTime.now().toIso8601String().split('T').first;
      setState(() {
        _categoryId = null;
        _source = 'sueldo';
      });
      _show('Gasto guardado.');
    } catch (e) {
      _show('No se pudo guardar el gasto: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, finance, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
          child: Align(
            alignment: Alignment.topLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Registrar gasto',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: AppColors.cardBg,
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 260,
                          child: TextField(
                            controller: _amountCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
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
                                labelText: 'Descripcion',
                                hintText: 'Supermercado'),
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
                          child: DropdownButtonFormField<int>(
                            initialValue: _categoryId,
                            items: finance.categories
                                .where((c) => c.id != null)
                                .map(
                                  (cat) => DropdownMenuItem<int>(
                                    value: cat.id,
                                    child: Text(cat.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) =>
                                setState(() => _categoryId = value),
                            decoration:
                                const InputDecoration(labelText: 'Categoria'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: 260,
                          child: DropdownButtonFormField<String>(
                            initialValue: _source,
                            items: const [
                              DropdownMenuItem(
                                  value: 'sueldo',
                                  child: Text('Sueldo del periodo')),
                              DropdownMenuItem(
                                  value: 'ahorro', child: Text('Ahorro total')),
                            ],
                            onChanged: (value) =>
                                setState(() => _source = value ?? 'sueldo'),
                            decoration: const InputDecoration(
                                labelText: 'Descontar de'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: FilledButton.icon(
                            onPressed:
                                finance.isLoading ? null : () => _save(finance),
                            icon: const Icon(Icons.save),
                            label: const Text('Guardar gasto'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
