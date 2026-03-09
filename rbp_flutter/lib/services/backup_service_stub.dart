import '../data/database/database_helper.dart';

class BackupService {
  BackupService({
    DatabaseHelper? dbHelper,
    Future<dynamic> Function()? documentsDirectoryProvider,
  });

  Future<String> createBackup({String? fileName}) async {
    throw UnsupportedError(
      'El respaldo local aun no esta disponible en esta plataforma.',
    );
  }

  Future<void> restoreBackup(String sourcePath) async {
    throw UnsupportedError(
      'La restauracion local aun no esta disponible en esta plataforma.',
    );
  }

  Future<String?> pickAndRestoreBackup() async {
    throw UnsupportedError(
      'La restauracion local aun no esta disponible en esta plataforma.',
    );
  }

  Future<void> importDatabase(String sourcePath) async {
    throw UnsupportedError(
      'La importacion de base de datos aun no esta disponible en esta plataforma.',
    );
  }
}
