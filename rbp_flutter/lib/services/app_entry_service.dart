import '../config/constants.dart';
import '../presentation/providers/finance_provider.dart';
import '../presentation/providers/settings_provider.dart';
import 'app_access_service.dart';

class AppEntryResolution {
  const AppEntryResolution({
    required this.accessState,
    required this.needsActivation,
    required this.needsProfileAccess,
  });

  final AppAccessState accessState;
  final bool needsActivation;
  final bool needsProfileAccess;
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
        accessState: accessState,
        needsActivation: true,
        needsProfileAccess: false,
      );
    }

    final needsProfile = await _resolveProfileGate(finance);
    return AppEntryResolution(
      accessState: accessState,
      needsActivation: false,
      needsProfileAccess: needsProfile,
    );
  }

  Future<AppEntryResolution> resolveAfterAccessGranted({
    required FinanceProvider finance,
    required AppAccessState accessState,
  }) async {
    final needsProfile = await _resolveProfileGate(finance);
    return AppEntryResolution(
      accessState: accessState,
      needsActivation: false,
      needsProfileAccess: needsProfile,
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
