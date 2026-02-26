import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/platform_config.dart';
import '../../providers/finance_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/license_service.dart';
import 'activation_screen.dart';
import 'home_screen.dart';

class AppEntryScreen extends StatefulWidget {
  const AppEntryScreen({super.key});

  @override
  State<AppEntryScreen> createState() => _AppEntryScreenState();
}

class _AppEntryScreenState extends State<AppEntryScreen> {
  final _licenseService = LicenseService();
  bool _loading = true;
  bool _needsActivation = false;
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
      await finance.init();
      await settings.loadThemePreset();
      if (!PlatformConfig.supportsLicense) {
        finance.setLicenseState(activated: true, trialMode: false);
        if (!mounted) {
          return;
        }
        setState(() {
          _loading = false;
          _needsActivation = false;
        });
        return;
      }

      final activated = await _licenseService.isActivated();
      finance.setLicenseState(activated: activated, trialMode: !activated);
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _needsActivation = !activated;
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
    finance.setLicenseState(activated: true, trialMode: false);
    setState(() {
      _needsActivation = false;
    });
  }

  void _onContinueTrial() {
    final finance = context.read<FinanceProvider>();
    finance.setLicenseState(activated: false, trialMode: true);
    setState(() {
      _needsActivation = false;
    });
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
        licenseService: _licenseService,
        onActivated: _onActivated,
        onContinueTrial: _onContinueTrial,
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
