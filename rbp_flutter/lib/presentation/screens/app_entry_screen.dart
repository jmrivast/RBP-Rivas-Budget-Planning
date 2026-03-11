import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../providers/finance_provider.dart';
import '../providers/settings_provider.dart';
import '../../services/app_access_service.dart';
import '../../services/app_entry_service.dart';
import 'activation_screen.dart';
import 'home_screen.dart';
import 'profile_access_screen.dart';

class AppEntryScreen extends StatefulWidget {
  const AppEntryScreen({super.key});

  @override
  State<AppEntryScreen> createState() => _AppEntryScreenState();
}

class _AppEntryScreenState extends State<AppEntryScreen> {
  final _appEntryService = AppEntryService();
  bool _loading = true;
  bool _needsActivation = false;
  bool _needsProfileAccess = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resolveEntry();
    });
  }

  Future<void> _resolveEntry() async {
    final finance = context.read<FinanceProvider>();
    final settings = context.read<SettingsProvider>();
    try {
      final resolution = await _appEntryService.resolveInitialEntry(
        finance: finance,
        settings: settings,
      );
      finance.setAccessState(resolution.accessState);
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _needsActivation = resolution.needsActivation;
        _needsProfileAccess = resolution.needsProfileAccess;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _onActivated() {
    final finance = context.read<FinanceProvider>();
    finance.setAccessState(AppAccessState.licensed());
    _resolveProfileGateAfterActivation(accessState: AppAccessState.licensed());
  }

  void _onContinueTrial() {
    final finance = context.read<FinanceProvider>();
    finance.setAccessState(AppAccessState.trial());
    _resolveProfileGateAfterActivation(accessState: AppAccessState.trial());
  }

  Future<void> _resolveProfileGateAfterActivation({
    required AppAccessState accessState,
  }) async {
    if (!mounted) {
      return;
    }
    setState(() {
      _loading = true;
      _needsActivation = false;
      _needsProfileAccess = false;
      _error = null;
    });
    try {
      final finance = context.read<FinanceProvider>();
      final resolution = await _appEntryService.resolveAfterAccessGranted(
        finance: finance,
        accessState: accessState,
      );
      finance.setAccessState(resolution.accessState);
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _needsProfileAccess = resolution.needsProfileAccess;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('RBP - Error')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'No se pudo iniciar la aplicacion.\n$_error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (_needsActivation) {
      return ActivationScreen(
        licenseService: _appEntryService.accessService.licenseService,
        onActivated: _onActivated,
        onContinueTrial: _onContinueTrial,
      );
    }

    if (_needsProfileAccess) {
      return ProfileAccessScreen(
        sessionHours: AppProfiles.sessionHours,
        onAuthenticated: () {
          if (!mounted) {
            return;
          }
          setState(() {
            _needsProfileAccess = false;
          });
        },
      );
    }

    if (finance.error != null && !finance.initialized) {
      return Scaffold(
        appBar: AppBar(title: const Text('RBP - Error')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Error inicializando app:\n${finance.error}',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (!finance.initialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return HomeScreen(
      onOpenActivation: () {
        setState(() {
          _needsActivation = true;
        });
      },
    );
  }
}

