import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;

import '../config/platform_config.dart';
import 'backup_service.dart';
import 'update_service.dart';

enum UpdateCheckStatus {
  unsupported,
  unavailable,
  upToDate,
  updateAvailable,
}

class BackupActionResult {
  const BackupActionResult({
    required this.message,
    this.requiresRefresh = false,
  });

  final String message;
  final bool requiresRefresh;
}

class UpdateCheckResult {
  const UpdateCheckResult({
    required this.status,
    required this.message,
    this.release,
    this.currentVersion,
    this.checkKey,
    this.checkedOn,
  });

  final UpdateCheckStatus status;
  final String message;
  final ReleaseInfo? release;
  final String? currentVersion;
  final String? checkKey;
  final String? checkedOn;
}

class SettingsActionsService {
  SettingsActionsService({
    BackupService? backupService,
    UpdateService? updateService,
    Future<PackageInfo> Function()? packageInfoLoader,
  })  : _backupService = backupService ?? BackupService(),
        _updateService = updateService ?? UpdateService(),
        _packageInfoLoader = packageInfoLoader ?? PackageInfo.fromPlatform;

  final BackupService _backupService;
  final UpdateService _updateService;
  final Future<PackageInfo> Function() _packageInfoLoader;

  Future<BackupActionResult> createBackup() async {
    final path = await _backupService.createBackup();
    return BackupActionResult(
      message: 'Respaldo creado: ${p.basename(path)}',
    );
  }

  Future<BackupActionResult?> restoreBackup() async {
    final source = await _backupService.pickAndRestoreBackup();
    if (source == null) {
      return null;
    }
    return BackupActionResult(
      message: 'Respaldo restaurado: ${p.basename(source)}',
      requiresRefresh: true,
    );
  }

  Future<UpdateCheckResult> checkForUpdates({
    required bool includeBeta,
  }) async {
    if (!PlatformConfig.supportsUpdateChecks) {
      return const UpdateCheckResult(
        status: UpdateCheckStatus.unsupported,
        message:
            'Las actualizaciones automaticas solo estan disponibles en escritorio.',
      );
    }

    final checkKey = includeBeta
        ? 'update_last_check_date_beta'
        : 'update_last_check_date_stable';
    final checkedOn = DateTime.now().toIso8601String().split('T').first;

    final release = await _updateService.fetchLatest(includeBeta: includeBeta);
    if (release == null) {
      return UpdateCheckResult(
        status: UpdateCheckStatus.unavailable,
        message: 'No se pudo verificar actualizaciones ahora mismo.',
        checkKey: checkKey,
        checkedOn: checkedOn,
      );
    }

    final info = await _packageInfoLoader();
    final currentVersion = info.version;
    final hasNew = UpdateService.isNewerVersion(currentVersion, release.tag);
    if (!hasNew) {
      return UpdateCheckResult(
        status: UpdateCheckStatus.upToDate,
        message: includeBeta
            ? 'Ya tienes la version mas reciente (incluyendo beta).'
            : 'Ya tienes la version mas reciente.',
        currentVersion: currentVersion,
        checkKey: checkKey,
        checkedOn: checkedOn,
      );
    }

    return UpdateCheckResult(
      status: UpdateCheckStatus.updateAvailable,
      message: '',
      release: release,
      currentVersion: currentVersion,
      checkKey: checkKey,
      checkedOn: checkedOn,
    );
  }
}
