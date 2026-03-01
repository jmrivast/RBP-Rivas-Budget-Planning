import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../config/constants.dart';
import '../../providers/finance_provider.dart';
import '../../services/update_service.dart';
import '../../utils/date_helpers.dart' as dh;
import '../dialogs/update_available_dialog.dart';
import '../widgets/guided_showcase.dart';
import 'dashboard_tab.dart';
import 'expense_tab.dart';
import 'fixed_payments_tab.dart';
import 'income_tab.dart';
import 'loans_tab.dart';
import 'savings_tab.dart';
import 'settings_tab.dart';

class _GuideStep {
  const _GuideStep({
    required this.key,
    this.tabIndex,
  });

  final GlobalKey key;
  final int? tabIndex;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onOpenActivation,
  });

  final VoidCallback onOpenActivation;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  static const int _tabCount = 7;

  final _updateService = UpdateService();
  final _tabsGuideKey = GlobalKey();
  final _dashboardGuideKey = GlobalKey();
  final _dashboardAmountsGuideKey = GlobalKey();
  final _incomeGuideKey = GlobalKey();
  final _expenseGuideKey = GlobalKey();
  final _fixedGuideKey = GlobalKey();
  final _loanGuideKey = GlobalKey();
  final _savingsGuideKey = GlobalKey();
  final _settingsGuideKey = GlobalKey();

  bool _startupChecksScheduled = false;
  bool _guideRunning = false;
  bool _markGuideSeenOnFinish = false;
  int _guideStepIndex = 0;
  int _guideStepRetries = 0;
  BuildContext? _showcaseContext;
  late final TabController _tabController;
  late final List<Widget> _tabViews;
  int _selectedTab = 0;

  List<_GuideStep> get _guideSteps => [
        _GuideStep(key: _tabsGuideKey, tabIndex: 0),
        _GuideStep(key: _dashboardGuideKey, tabIndex: 0),
        _GuideStep(key: _dashboardAmountsGuideKey, tabIndex: 0),
        _GuideStep(key: _incomeGuideKey, tabIndex: 1),
        _GuideStep(key: _expenseGuideKey, tabIndex: 2),
        _GuideStep(key: _fixedGuideKey, tabIndex: 3),
        _GuideStep(key: _loanGuideKey, tabIndex: 4),
        _GuideStep(key: _savingsGuideKey, tabIndex: 5),
        _GuideStep(key: _settingsGuideKey, tabIndex: 6),
      ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabCount, vsync: this);
    _tabController.addListener(() {
      if (!mounted) {
        return;
      }
      final idx = _tabController.index;
      if (idx == _selectedTab) {
        return;
      }
      setState(() => _selectedTab = idx);
    });
    _tabViews = _buildTabViews();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _goRelativeTab(int delta) {
    final target = (_selectedTab + delta).clamp(0, _tabCount - 1);
    if (target == _selectedTab) {
      return;
    }
    _tabController.animateTo(target);
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) {
      return;
    }
    final dx = event.scrollDelta.dx;
    final dy = event.scrollDelta.dy;
    if (dx.abs() <= 12 || dx.abs() <= dy.abs()) {
      return;
    }
    if (dx > 0) {
      _goRelativeTab(1);
    } else {
      _goRelativeTab(-1);
    }
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _maybeScheduleStartupChecks(FinanceProvider finance) {
    if (_startupChecksScheduled || !finance.initialized) {
      return;
    }
    _startupChecksScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkPeriodCloseAlert(finance);
      await _checkForUpdates(finance, manual: false);
      await _checkTrialReminder(finance);
    });
  }

  void _startGuidedTour({bool markAsSeenOnFinish = false}) {
    if (_guideRunning || _guideSteps.isEmpty) {
      return;
    }
    _guideRunning = true;
    _guideStepIndex = 0;
    _guideStepRetries = 0;
    _markGuideSeenOnFinish = markAsSeenOnFinish;
    _runGuideStep();
  }

  Future<void> _switchGuideTab(int targetIndex) async {
    if (_selectedTab == targetIndex) {
      return;
    }
    _tabController.index = targetIndex;
    if (mounted) {
      setState(() => _selectedTab = targetIndex);
    }
    await Future.delayed(const Duration(milliseconds: 80));
  }

  Future<bool> _waitForGuideTarget(
    GlobalKey key, {
    Duration timeout = const Duration(milliseconds: 1500),
  }) async {
    final watch = Stopwatch()..start();
    while (watch.elapsed < timeout) {
      if (!mounted || !_guideRunning) {
        return false;
      }
      final ctx = key.currentContext;
      final ro = ctx?.findRenderObject();
      if (ctx != null &&
          ro is RenderBox &&
          ro.attached &&
          ro.hasSize &&
          ro.size.width > 0 &&
          ro.size.height > 0) {
        return true;
      }
      await WidgetsBinding.instance.endOfFrame;
      await Future.delayed(const Duration(milliseconds: 20));
    }
    return false;
  }

  Future<void> _runGuideStep() async {
    if (!_guideRunning || !mounted) {
      return;
    }
    if (_guideStepIndex >= _guideSteps.length) {
      await _finishGuidedTour();
      return;
    }

    final step = _guideSteps[_guideStepIndex];
    if (step.tabIndex != null && _selectedTab != step.tabIndex) {
      await _switchGuideTab(step.tabIndex!);
    }
    await WidgetsBinding.instance.endOfFrame;
    await Future.delayed(const Duration(milliseconds: 40));
    if (!mounted) {
      return;
    }
    final showcaseContext = _showcaseContext;
    if (showcaseContext == null) {
      await Future.delayed(const Duration(milliseconds: 120));
      if (mounted && _guideRunning) {
        _runGuideStep();
      }
      return;
    }
    final targetReady = await _waitForGuideTarget(step.key);
    if (!targetReady) {
      if (_guideStepRetries < 10) {
        _guideStepRetries += 1;
        await Future.delayed(const Duration(milliseconds: 90));
        if (mounted && _guideRunning) {
          _runGuideStep();
        }
        return;
      }
      _guideStepRetries = 0;
      _guideStepIndex += 1;
      _runGuideStep();
      return;
    }
    _guideStepRetries = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_guideRunning) {
        return;
      }
      ShowCaseWidget.of(showcaseContext).startShowCase([step.key]);
    });
  }

  void _advanceGuidedTour() {
    if (!_guideRunning) {
      return;
    }
    final currentIndex = _guideStepIndex;
    final nextIndex = currentIndex + 1;
    final currentTab = (currentIndex >= 0 && currentIndex < _guideSteps.length)
        ? _guideSteps[currentIndex].tabIndex
        : null;
    final nextTab = (nextIndex >= 0 && nextIndex < _guideSteps.length)
        ? _guideSteps[nextIndex].tabIndex
        : null;
    final showcaseContext = _showcaseContext;
    if (showcaseContext != null && currentTab != nextTab) {
      ShowCaseWidget.of(showcaseContext).dismiss();
    }
    _guideStepRetries = 0;
    _guideStepIndex = nextIndex;
    if (currentTab == nextTab) {
      Future.delayed(const Duration(milliseconds: 12), _runGuideStep);
    } else {
      Future.delayed(const Duration(milliseconds: 35), _runGuideStep);
    }
  }

  void _retreatGuidedTour() {
    if (!_guideRunning) {
      return;
    }
    final currentIndex = _guideStepIndex;
    final prevIndex = (currentIndex - 1).clamp(0, _guideSteps.length - 1);
    final currentTab = (currentIndex >= 0 && currentIndex < _guideSteps.length)
        ? _guideSteps[currentIndex].tabIndex
        : null;
    final prevTab = (prevIndex >= 0 && prevIndex < _guideSteps.length)
        ? _guideSteps[prevIndex].tabIndex
        : null;
    final showcaseContext = _showcaseContext;
    if (showcaseContext != null && currentTab != prevTab) {
      ShowCaseWidget.of(showcaseContext).dismiss();
    }
    _guideStepRetries = 0;
    _guideStepIndex = prevIndex;
    if (currentTab == prevTab) {
      Future.delayed(const Duration(milliseconds: 12), _runGuideStep);
    } else {
      Future.delayed(const Duration(milliseconds: 35), _runGuideStep);
    }
  }

  Future<void> _finishGuidedTour() async {
    if (!_guideRunning) {
      return;
    }
    _guideRunning = false;
    if (!_markGuideSeenOnFinish || !mounted) {
      _markGuideSeenOnFinish = false;
      return;
    }
    _markGuideSeenOnFinish = false;
    final finance = context.read<FinanceProvider>();
    await finance.setSetting('onboarding_v200_seen', 'true');
  }

  Future<void> _checkTrialReminder(FinanceProvider finance) async {
    if (!finance.isTrialMode) {
      return;
    }
    final current = int.tryParse(
          await finance.getSetting('trial_launch_count', defaultValue: '0'),
        ) ??
        0;
    final next = current + 1;
    await finance.setSetting('trial_launch_count', '$next');
    if (next % AppLicense.trialReminderInterval != 0) {
      return;
    }
    if (!mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Modo de prueba'),
          content: const Text(
            'Activa tu licencia para desbloquear exportes PDF/CSV y quitar el limite de gastos por periodo.',
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onOpenActivation();
              },
              icon: const Icon(Icons.vpn_key),
              label: const Text('Activar ahora'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _checkPeriodCloseAlert(FinanceProvider finance) async {
    final today = DateTime.now();
    final starts = await finance.getPeriodStartDays(today.year, today.month);
    if (!starts.contains(today.day)) {
      return;
    }

    late int prevYear;
    late int prevMonth;
    late int prevCycle;
    late String exportKey;

    if (finance.periodMode == 'mensual') {
      final prev = dh.previousMonth(today.year, today.month);
      prevYear = prev.$1;
      prevMonth = prev.$2;
      prevCycle = 1;
      exportKey = 'M:$prevYear-${prevMonth.toString().padLeft(2, '0')}';
    } else {
      final currentCycle = await finance.getCycleForDate(today);
      final prev = dh.previousQuincena(today.year, today.month, currentCycle);
      prevYear = prev.year;
      prevMonth = prev.month;
      prevCycle = prev.cycle;
      exportKey =
          'Q:$prevYear-${prevMonth.toString().padLeft(2, '0')}-$prevCycle';
    }

    final autoExport = (await finance.getSetting('auto_export_close_period',
                defaultValue: 'false'))
            .toLowerCase() ==
        'true';
    final lastKey =
        await finance.getSetting('last_auto_export_key', defaultValue: '');
    final lastPromptKey =
        await finance.getSetting('last_period_close_prompt_key',
            defaultValue: '');

    // Ya fue atendido este cierre de periodo en esta version del app.
    if (lastPromptKey == exportKey) {
      return;
    }

    final periodRange =
        await finance.getPeriodRangeFor(prevYear, prevMonth, prevCycle);
    final periodLabel = dh.formatPeriodLabel(
      year: prevYear,
      month: prevMonth,
      cycle: prevCycle,
      periodMode: finance.periodMode,
      startDate: periodRange.$1,
      endDate: periodRange.$2,
    );

    if (autoExport && lastKey == exportKey) {
      await finance.setSetting('last_period_close_prompt_key', exportKey);
      return;
    }

    if (autoExport && lastKey != exportKey) {
      try {
        final pdfPath =
            await finance.exportPdfForPeriod(prevYear, prevMonth, prevCycle);
        final csvPath =
            await finance.exportCsvForPeriod(prevYear, prevMonth, prevCycle);
        await finance.setSetting('last_auto_export_key', exportKey);
        await finance.setSetting('last_period_close_prompt_key', exportKey);
        _showSnack(
            'Exportacion automatica completada: ${p.basename(pdfPath)} y ${p.basename(csvPath)}');
      } catch (e) {
        _showSnack('Fallo la exportacion automatica del periodo cerrado: $e');
      }
      return;
    }

    if (!mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cierre de periodo'),
          content: Text(
              'Periodo anterior ($periodLabel) termino.\nDeseas generar el reporte PDF?'),
          actions: [
            TextButton(
              onPressed: () async {
                await finance.setSetting('last_period_close_prompt_key', exportKey);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('No'),
            ),
            FilledButton.icon(
              onPressed: () async {
                try {
                  final path = await finance.exportPdfForPeriod(
                      prevYear, prevMonth, prevCycle);
                  await finance.setSetting('last_period_close_prompt_key', exportKey);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                  _showSnack('PDF generado: ${p.basename(path)}');
                } catch (e) {
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                  _showSnack('Error generando PDF: $e');
                }
              },
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Generar PDF'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _checkForUpdates(
    FinanceProvider finance, {
    required bool manual,
    bool? includeBeta,
  }) async {
    try {
      final beta = includeBeta ??
          (await finance.getSetting('include_beta_updates',
                      defaultValue: 'false'))
                  .toLowerCase() ==
              'true';
      final today = DateTime.now().toIso8601String().split('T').first;
      final checkKey = beta
          ? 'update_last_check_date_beta'
          : 'update_last_check_date_stable';

      if (!manual) {
        final lastCheck = await finance.getSetting(checkKey, defaultValue: '');
        if (lastCheck == today) {
          return;
        }
      }

      final latest = await _updateService.fetchLatest(includeBeta: beta);
      await finance.setSetting(checkKey, today);

      if (latest == null) {
        if (manual) {
          _showSnack('No se pudo verificar actualizaciones ahora mismo.');
        }
        return;
      }

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final isNewer = UpdateService.isNewerVersion(currentVersion, latest.tag);
      if (!isNewer) {
        if (manual) {
          if (beta) {
            _showSnack('Ya tienes la version mas reciente (incluyendo beta).');
          } else {
            _showSnack('Ya tienes la version mas reciente.');
          }
        }
        return;
      }

      if (!manual) {
        final snoozed = await finance.getSetting('update_snoozed_version',
            defaultValue: '');
        if (snoozed == latest.tag) {
          return;
        }
      }

      if (!mounted) {
        return;
      }
      await showUpdateAvailableDialog(
        context,
        latest: latest,
        currentVersion: currentVersion,
        manual: manual,
        onSnooze: manual
            ? null
            : () => finance.setSetting('update_snoozed_version', latest.tag),
      );
    } catch (e) {
      if (manual) {
        _showSnack('No se pudo verificar actualizaciones: $e');
      }
    }
  }

  List<Widget> _buildTabViews() {
    return [
      DashboardTab(
        guideKey: _dashboardGuideKey,
        amountsGuideKey: _dashboardAmountsGuideKey,
        onGuideNext: _advanceGuidedTour,
        onGuidePrevious: _retreatGuidedTour,
      ),
      IncomeTab(
        guideKey: _incomeGuideKey,
        onGuideNext: _advanceGuidedTour,
        onGuidePrevious: _retreatGuidedTour,
      ),
      ExpenseTab(
        guideKey: _expenseGuideKey,
        onGuideNext: _advanceGuidedTour,
        onGuidePrevious: _retreatGuidedTour,
      ),
      FixedPaymentsTab(
        guideKey: _fixedGuideKey,
        onGuideNext: _advanceGuidedTour,
        onGuidePrevious: _retreatGuidedTour,
      ),
      LoansTab(
        guideKey: _loanGuideKey,
        onGuideNext: _advanceGuidedTour,
        onGuidePrevious: _retreatGuidedTour,
      ),
      SavingsTab(
        guideKey: _savingsGuideKey,
        onGuideNext: _advanceGuidedTour,
        onGuidePrevious: _retreatGuidedTour,
      ),
      SettingsTab(
        guideKey: _settingsGuideKey,
        onGuideNext: _advanceGuidedTour,
        onGuidePrevious: _retreatGuidedTour,
        onStartGuidedTour: () => _startGuidedTour(markAsSeenOnFinish: false),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final finance = context.read<FinanceProvider>();
    final initialized =
        context.select<FinanceProvider, bool>((f) => f.initialized);
    final isTrialMode =
        context.select<FinanceProvider, bool>((f) => f.isTrialMode);
    final startupError = context.select<FinanceProvider, String?>(
      (f) => f.initialized ? null : f.error,
    );

    if (startupError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.appSubtitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Error inicializando app:\n$startupError',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (!initialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    _maybeScheduleStartupChecks(finance);
    final tabsWidth =
        (MediaQuery.of(context).size.width - 48).clamp(0.0, 900.0).toDouble();
    return ShowCaseWidget(
      blurValue: 1,
      builder: (showcaseContext) {
        _showcaseContext = showcaseContext;
        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Image(
                        image: AssetImage('assets/Untitled.png'),
                        width: 34,
                        height: 34,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        AppStrings.appSubtitle,
                        style:
                            TextStyle(fontSize: 14, color: AppColors.subtitle),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  GuidedShowcase(
                    showcaseKey: _tabsGuideKey,
                    title: 'Pestanas principales',
                    description: '- Aqui navegas por toda la app.\n'
                        '- Usa Siguiente para avanzar.\n'
                        '- Usa Anterior para volver.\n'
                        '- Puedes cerrar la guia cuando quieras desde Configuracion.',
                    onNext: _advanceGuidedTour,
                    showPrevious: false,
                    child: SizedBox(
                      width: double.infinity,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: tabsWidth,
                          child: TabBar(
                            controller: _tabController,
                            isScrollable: true,
                            tabAlignment: TabAlignment.start,
                            padding: EdgeInsets.zero,
                            labelPadding:
                                const EdgeInsets.symmetric(horizontal: 14),
                            tabs: const [
                              Tab(
                                  text: 'Resumen',
                                  icon: Icon(Icons.dashboard_outlined)),
                              Tab(
                                  text: 'Ingresos',
                                  icon: Icon(Icons.attach_money)),
                              Tab(
                                  text: 'Nuevo gasto',
                                  icon: Icon(Icons.add_circle_outline)),
                              Tab(
                                  text: 'Pagos fijos',
                                  icon: Icon(Icons.repeat)),
                              Tab(
                                  text: 'Prestamos',
                                  icon: Icon(Icons.money_off)),
                              Tab(text: 'Ahorro', icon: Icon(Icons.savings)),
                              Tab(
                                  text: 'Configuracion',
                                  icon: Icon(Icons.settings)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  if (isTrialMode)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 8),
                      color: AppColors.trialBannerBg,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Version de prueba: activa tu licencia para acceso completo.',
                              style: TextStyle(
                                color: AppColors.trialBannerText,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          TextButton.icon(
                            onPressed: widget.onOpenActivation,
                            icon: const Icon(Icons.vpn_key, size: 16),
                            label: const Text('Activar'),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Listener(
                      onPointerSignal: _onPointerSignal,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onHorizontalDragEnd: (details) {
                          final v = details.primaryVelocity ?? 0;
                          if (v.abs() < 220) {
                            return;
                          }
                          if (v < 0) {
                            _goRelativeTab(1);
                          } else {
                            _goRelativeTab(-1);
                          }
                        },
                        child: RepaintBoundary(
                          child: IndexedStack(
                            index: _selectedTab,
                            children: _tabViews,
                          ),
                        ),
                      ),
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
