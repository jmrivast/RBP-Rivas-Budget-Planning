import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/database/database_helper.dart';

class BackupService {
  BackupService({
    DatabaseHelper? dbHelper,
    Future<Directory> Function()? documentsDirectoryProvider,
  })  : _dbHelper = dbHelper ?? DatabaseHelper.instance,
        _documentsDirectoryProvider =
            documentsDirectoryProvider ?? getApplicationDocumentsDirectory;

  final DatabaseHelper _dbHelper;
  final Future<Directory> Function() _documentsDirectoryProvider;

  Future<String> createBackup({String? fileName}) async {
    final dbPath = await _resolveDbPath();
    final dbFile = File(dbPath);
    if (!await dbFile.exists()) {
      throw Exception('No se encontro base de datos para respaldar.');
    }

    final documentsDir = await _documentsDirectoryProvider();
    final backupsDir = Directory(p.join(documentsDir.path, 'backups'));
    if (!await backupsDir.exists()) {
      await backupsDir.create(recursive: true);
    }

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final targetName = fileName ?? 'finanzas_backup_$timestamp.db';
    final targetPath = p.join(backupsDir.path, targetName);

    await dbFile.copy(targetPath);
    return targetPath;
  }

  Future<void> restoreBackup(String sourcePath) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw Exception('Archivo de respaldo no encontrado.');
    }

    await _dbHelper.close();
    final dbPath = await _resolveDbPath();
    await sourceFile.copy(dbPath);
    await _dbHelper.database;
  }

  Future<String?> pickAndRestoreBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['db', 'sqlite', 'sqlite3'],
    );
    if (result == null ||
        result.files.isEmpty ||
        result.files.first.path == null) {
      return null;
    }
    final sourcePath = result.files.first.path!;
    await restoreBackup(sourcePath);
    return sourcePath;
  }

  Future<void> importDatabase(String sourcePath) async {
    await restoreBackup(sourcePath);
  }

  Future<String> _resolveDbPath() async {
    final documents = await _documentsDirectoryProvider();
    return p.join(documents.path, 'finanzas.db');
  }
}
