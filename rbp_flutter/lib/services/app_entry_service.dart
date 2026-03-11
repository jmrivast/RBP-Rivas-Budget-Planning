import '../config/constants.dart';
import '../presentation/providers/finance_provider.dart';
import '../presentation/providers/settings_provider.dart';
import 'app_access_service.dart';

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
    AppAccessService? accessService,
  }) : _accessService = accessService ?? AppAccessService();

  final AppAccessService _accessService;

  AppAccessService get accessService => _accessService;

  Future<AppEntryResolution> resolveInitialEntry({
    required FinanceProvider finance,
    required SettingsProvider settings,
  }) async {
    await finance.init();
    await settings.loadThemePreset();

    final accessState = await _accessService.resolveAccessState();
    if (accessState.needsActivation) {
      return AppEntryResolution(
        needsActivation: true,
        needsProfileAccess: false,
        activated: accessState.activated,
        trialMode: accessState.trialMode,
      );
    }

    final needsProfile = await _resolveProfileGate(finance);
    return AppEntryResolution(
      needsActivation: false,
      needsProfileAccess: needsProfile,
      activated: accessState.activated,
      trialMode: accessState.trialMode,
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
