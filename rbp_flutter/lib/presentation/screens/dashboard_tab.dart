import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rbp_flutter/config/constants.dart';
import 'package:rbp_flutter/data/models/dashboard_data.dart';
import 'package:rbp_flutter/data/models/expense.dart';
import 'package:rbp_flutter/core/platform/app_capabilities.dart';
import 'package:rbp_flutter/presentation/providers/finance_provider.dart';
import 'package:rbp_flutter/services/export_delivery_service.dart';
import 'package:rbp_flutter/presentation/dialogs/confirm_dialog.dart';
import 'package:rbp_flutter/presentation/dialogs/custom_quincena_dialog.dart';
import 'package:rbp_flutter/presentation/dialogs/edit_expense_dialog.dart';
import 'package:rbp_flutter/presentation/widgets/expense_list_item.dart';
import 'package:rbp_flutter/presentation/widgets/pie_chart_widget.dart';
import 'package:rbp_flutter/presentation/widgets/period_nav_bar.dart';
import 'package:rbp_flutter/presentation/widgets/stat_card.dart';
import 'package:rbp_flutter/utils/currency_formatter.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});
  static final _exportDelivery = ExportDeliveryService();

  Future<void> _showChart(BuildContext context, FinanceProvider finance) async {
    final data = finance.dashboard;
    if (data == null) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) {
        final media = MediaQuery.of(context).size;
        final dialogWidth = (media.width - 32).clamp(320.0, 1080.0);
        final dialogHeight = (media.height - 32).clamp(360.0, 760.0);
        final compact = dialogWidth < 820;
        return Dialog(
          backgroundColor: AppColors.pageBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          child: SizedBox(
            width: dialogWidth,
            height: dialogHeight,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 16 : 28,
                compact ? 16 : 22,
                compact ? 16 : 28,
                18,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gastos por categoria',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: compact ? 26 : 44,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: PieChartWidget(
                      catTotals: data.catTotals,
                      categoriesById: data.categoriesById,
                      height: compact ? 280 : 520,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cerrar'),
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

  Future<void> _exportPdf(BuildContext context, FinanceProvider finance) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final path = await finance.exportPdf();
      final message = await _deliverExportedFile(path: path, label: 'PDF');
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      messenger
          .showSnackBar(SnackBar(content: Text('Error al generar PDF: $e')));
    }
  }

  Future<void> _exportCsv(BuildContext context, FinanceProvider finance) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final path = await finance.exportCsv();
      final message = await _deliverExportedFile(path: path, label: 'CSV');
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      messenger
          .showSnackBar(SnackBar(content: Text('Error al exportar CSV: $e')));
    }
  }

  Future<String> _deliverExportedFile({
    required String path,
    required String label,
  }) async {
    if (!AppCapabilities.current.supportsPdfCsvExport) {
      return '$label no esta disponible en esta plataforma.';
    }
    return _exportDelivery.deliverExportedFile(path, label: label);
  }
  @override
  Widget build(BuildContext context) {
    final finance = context.read<FinanceProvider>();
    final data =
        context.select<FinanceProvider, DashboardData?>((f) => f.dashboard);
    final periodTitle =
        context.select<FinanceProvider, String>((f) => f.periodTitle);
    final isMonthly =
        context.select<FinanceProvider, bool>((f) => f.periodMode == 'mensual');

    if (data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final cards = [
      StatCard(
        title: 'Dinero Inicial',
        value: formatCurrency(data.dineroInicial),
        icon: Icons.account_balance_wallet,
      ),
      StatCard(
        title: 'Total Gastado',
        value: formatCurrency(data.totalExpenses),
        icon: Icons.shopping_cart,
        color: AppColors.error,
      ),
      StatCard(
        title: 'Ahorro Total',
        value: formatCurrency(data.totalSavings),
        icon: Icons.savings,
        color: AppColors.success,
      ),
      StatCard(
        title: 'Dinero Disponible',
        value: formatCurrency(data.dineroDisponible),
        icon: Icons.check_circle,
        color: data.dineroDisponible >= 0 ? AppColors.success : AppColors.error,
      ),
      StatCard(
        title: 'Promedio Diario',
        value: formatCurrency(data.avgDaily),
        icon: Icons.calendar_view_day,
      ),
      StatCard(
        title: 'Prestamos Pend.',
        value: formatCurrency(data.totalLoans),
        icon: Icons.money_off,
        color: AppColors.warn,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PeriodNavBar(
            label: periodTitle,
            isMonthly: isMonthly,
            onPrev: finance.goToPreviousPeriod,
            onToday: finance.goToCurrentPeriod,
            onNext: finance.goToNextPeriod,
            onCalendar: !isMonthly
                ? () => showCustomQuincenaDialog(context, finance: finance)
                : null,
            onChart: () => _showChart(context, finance),
            onPdf: AppCapabilities.current.supportsPdfCsvExport
                ? () => _exportPdf(context, finance)
                : null,
            onCsv: AppCapabilities.current.supportsPdfCsvExport
                ? () => _exportCsv(context, finance)
                : null,
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 1200
                  ? 3
                  : constraints.maxWidth >= 760
                      ? 2
                      : 1;
              const spacing = 10.0;
              final itemWidth =
                  (constraints.maxWidth - ((columns - 1) * spacing)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final card in cards)
                    SizedBox(
                      width: itemWidth,
                      child: card,
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          const Text(
            'Ultimos gastos',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
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
              child: data.recentExpenses.isEmpty
                  ? const Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Text('Sin gastos',
                            style: TextStyle(fontStyle: FontStyle.italic)),
                      ),
                    )
                  : ListView.builder(
                      itemCount: data.recentExpenses.length,
                      itemBuilder: (context, index) {
                        final item = data.recentExpenses[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: ExpenseListItem(
                            item: item,
                            onEdit:
                                item.type == 'expense' && item.raw is Expense
                                    ? () => showEditExpenseDialog(
                                          context,
                                          finance: finance,
                                          expense: item.raw as Expense,
                                          categories: finance.categories,
                                        )
                                    : null,
                            onDelete: item.type == 'expense' && item.id != null
                                ? () async {
                                    final ok = await showConfirmDialog(
                                      context,
                                      title: 'Eliminar gasto',
                                      message:
                                          'Esta accion no se puede deshacer.',
                                      confirmLabel: 'Eliminar',
                                    );
                                    if (!ok) {
                                      return;
                                    }
                                    await finance.deleteExpense(item.id!);
                                  }
                                : null,
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

