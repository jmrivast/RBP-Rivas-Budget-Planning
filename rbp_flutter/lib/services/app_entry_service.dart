import '../config/constants.dart';
import '../presentation/providers/finance_provider.dart';
import '../presentation/providers/settings_provider.dart';
import 'license_service.dart';

class AppEntryResolution {
  const AppEntryResolution({
    required this.needsActivation,
    required this.needsProfileAccess,
    required this.activated,
    required this.trialMode,
  });

  final bool needsActivation;
  final bool needsProfileAccess;
  final bool activated;
  final bool trialMode;
}

class AppEntryService {
  AppEntryService({
    LicenseService? licenseService,
  }) : _licenseService = licenseService ?? LicenseService();

  final LicenseService _licenseService;

  LicenseService get licenseService => _licenseService;

  Future<AppEntryResolution> resolveInitialEntry({
    required FinanceProvider finance,
    required SettingsProvider settings,
  }) async {
    await finance.init();
    await settings.loadThemePreset();

    final requiresActivation = await _licenseService.requiresActivation();
    if (!requiresActivation) {
      final needsProfile = await _resolveProfileGate(finance);
      return AppEntryResolution(
        needsActivation: false,
        needsProfileAccess: needsProfile,
        activated: true,
        trialMode: false,
      );
    }

    final activated = await _licenseService.isActivated();
    if (!activated) {
      return const AppEntryResolution(
        needsActivation: true,
        needsProfileAccess: false,
        activated: false,
        trialMode: true,
      );
    }

    final needsProfile = await _resolveProfileGate(finance);
    return AppEntryResolution(
      needsActivation: false,
      needsProfileAccess: needsProfile,
      activated: true,
      trialMode: false,
    );
  }

  Future<AppEntryResolution> resolveAfterAccessGranted({
    required FinanceProvider finance,
    required bool activated,
  }) async {
    final needsProfile = await _resolveProfileGate(finance);
    return AppEntryResolution(
      needsActivation: false,
      needsProfileAccess: needsProfile,
      activated: activated,
      trialMode: !activated,
    );
  }

  Future<bool> _resolveProfileGate(FinanceProvider finance) async {
    final needsProfile = await finance.shouldPromptProfileAccess(
      sessionHours: AppProfiles.sessionHours,
    );
    if (!needsProfile) {
      await finance.markProfileSession(
        sessionHours: AppProfiles.sessionHours,
      );
    }
    return needsProfile;
  }
}
