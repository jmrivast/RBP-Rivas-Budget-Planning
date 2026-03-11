import '../config/constants.dart';
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
    required this.canExport,
    this.maxExpensesPerPeriod,
  });

  final AppAccessMode mode;
  final bool needsActivation;
  final bool canExport;
  final int? maxExpensesPerPeriod;

  bool get activated => mode != AppAccessMode.trial;
  bool get trialMode => mode == AppAccessMode.trial;

  factory AppAccessState.unrestricted() {
    return const AppAccessState(
      mode: AppAccessMode.unrestricted,
      needsActivation: false,
      canExport: true,
    );
  }

  factory AppAccessState.licensed() {
    return const AppAccessState(
      mode: AppAccessMode.licensed,
      needsActivation: false,
      canExport: true,
    );
  }

  factory AppAccessState.trial() {
    return const AppAccessState(
      mode: AppAccessMode.trial,
      needsActivation: true,
      canExport: false,
      maxExpensesPerPeriod: AppLicense.trialExpenseLimit,
    );
  }
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
      return AppAccessState.unrestricted();
    }

    final activated = await _licenseService.isActivated();
    if (!activated) {
      return AppAccessState.trial();
    }

    return AppAccessState.licensed();
  }

  Future<String> getMachineId() => _licenseService.getMachineId();

  Future<bool> validateLicenseKey(String key) => _licenseService.validateKey(key);

  Future<void> storeLicenseKey(String key) => _licenseService.storeKey(key);
}
