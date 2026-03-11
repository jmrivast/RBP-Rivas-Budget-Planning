import 'license_service.dart';

enum AppAccessMode {
  unrestricted,
  licensed,
  trial,
}

class AppAccessState {
  const AppAccessState({
    required this.mode,
    required this.needsActivation,
  });

  final AppAccessMode mode;
  final bool needsActivation;

  bool get activated => mode != AppAccessMode.trial;
  bool get trialMode => mode == AppAccessMode.trial;
}

class AppAccessService {
  AppAccessService({
    LicenseService? licenseService,
  }) : _licenseService = licenseService ?? LicenseService();

  final LicenseService _licenseService;

  LicenseService get licenseService => _licenseService;

  Future<AppAccessState> resolveAccessState() async {
    final requiresActivation = await _licenseService.requiresActivation();
    if (!requiresActivation) {
      return const AppAccessState(
        mode: AppAccessMode.unrestricted,
        needsActivation: false,
      );
    }

    final activated = await _licenseService.isActivated();
    if (!activated) {
      return const AppAccessState(
        mode: AppAccessMode.trial,
        needsActivation: true,
      );
    }

    return const AppAccessState(
      mode: AppAccessMode.licensed,
      needsActivation: false,
    );
  }

  Future<String> getMachineId() => _licenseService.getMachineId();

  Future<bool> validateLicenseKey(String key) => _licenseService.validateKey(key);

  Future<void> storeLicenseKey(String key) => _licenseService.storeKey(key);
}
