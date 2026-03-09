import 'package:path/path.dart' as p;

import 'backup_service.dart';

class BackupActionResult {
  const BackupActionResult({
    required this.message,
    this.requiresRefresh = false,
  });

  final String message;
  final bool requiresRefresh;
}

class SettingsActionsService {
  SettingsActionsService({
    BackupService? backupService,
  }) : _backupService = backupService ?? BackupService();

  final BackupService _backupService;

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
}
