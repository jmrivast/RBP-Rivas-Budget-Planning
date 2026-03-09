import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../providers/finance_provider.dart';
import 'dashboard_tab.dart';
import 'expense_tab.dart';
import 'fixed_payments_tab.dart';
import 'income_tab.dart';
import 'loans_tab.dart';
import 'savings_tab.dart';
import 'settings_tab.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onOpenActivation,
  });

  final VoidCallback onOpenActivation;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 7,
      child: Consumer<FinanceProvider>(
        builder: (context, finance, _) {
          final isCompact = MediaQuery.of(context).size.width < 900;
          final activeProfile = finance.activeProfile?.username;

          return Scaffold(
            backgroundColor: AppColors.pageBackground,
            body: SafeArea(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(
                      isCompact ? 12 : 18,
                      12,
                      isCompact ? 12 : 18,
                      10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: AppColors.cardBorder),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: isCompact ? 38 : 44,
                              height: isCompact ? 38 : 44,
                              decoration: const BoxDecoration(
                                image: DecorationImage(
                                  image: AssetImage('assets/Untitled.png'),
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'RBP - Finanzas Personales',
                                    style: TextStyle(
                                      fontSize: isCompact ? 18 : 22,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF202124),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    activeProfile == null
                                        ? 'Controla tus finanzas personales'
                                        : 'Perfil activo: $activeProfile',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.subtitle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (finance.isTrialMode) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.trialBannerBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Wrap(
                              spacing: 10,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: AppColors.trialBannerText,
                                ),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 640),
                                  child: Text(
                                    'Modo de prueba activo. Puedes usar la app con limites y activar la licencia cuando quieras.',
                                    style: TextStyle(
                                      color: AppColors.trialBannerText,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                FilledButton.icon(
                                  onPressed: onOpenActivation,
                                  icon: const Icon(Icons.lock_open),
                                  label: const Text('Activar ahora'),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        TabBar(
                          isScrollable: true,
                          tabAlignment: TabAlignment.start,
                          dividerColor: Colors.transparent,
                          splashBorderRadius: BorderRadius.circular(10),
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                          tabs: const [
                            Tab(icon: Icon(Icons.grid_view_rounded), text: 'Resumen'),
                            Tab(icon: Icon(Icons.attach_money_rounded), text: 'Ingresos'),
                            Tab(icon: Icon(Icons.add_circle_outline), text: 'Nuevo gasto'),
                            Tab(icon: Icon(Icons.swap_horiz_rounded), text: 'Pagos fijos'),
                            Tab(icon: Icon(Icons.money_off_csred_rounded), text: 'Prestamos'),
                            Tab(icon: Icon(Icons.savings_outlined), text: 'Ahorro'),
                            Tab(icon: Icon(Icons.settings_outlined), text: 'Configuracion'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: TabBarView(
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          const DashboardTab(),
                          const IncomeTab(),
                          const ExpenseTab(),
                          const FixedPaymentsTab(),
                          const LoansTab(),
                          const SavingsTab(),
                          SettingsTab(onOpenActivation: onOpenActivation),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}


