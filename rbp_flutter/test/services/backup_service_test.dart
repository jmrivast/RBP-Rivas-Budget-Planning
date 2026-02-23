import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:rbp_flutter/data/database/database_helper.dart';
import 'package:rbp_flutter/data/repositories/user_repository.dart';
import 'package:rbp_flutter/services/backup_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('create backup and restore returns database to previous state',
      () async {
    final sandbox = await Directory.systemTemp.createTemp('rbp_backup_test_');
    final docsDir = Directory(p.join(sandbox.path, 'docs'));
    await docsDir.create(recursive: true);

    final dbPath = p.join(docsDir.path, 'finanzas.db');
    final dbHelper = DatabaseHelper(
      databaseName: dbPath,
      useDocumentsDirectory: false,
    );
    final users = UserRepository(dbHelper: dbHelper);
    final backup = BackupService(
      dbHelper: dbHelper,
      documentsDirectoryProvider: () async => docsDir,
    );

    try {
      await users.create('Jose', email: 'jose@rbp.dev');
      final backupPath = await backup.createBackup(fileName: 'snapshot.db');
      expect(File(backupPath).existsSync(), isTrue);

      await users.create('Ana', email: 'ana@rbp.dev');
      final countBeforeRestore = (await users.getAllActive()).length;
      expect(countBeforeRestore, 2);

      await backup.restoreBackup(backupPath);
      final countAfterRestore = (await users.getAllActive()).length;
      expect(countAfterRestore, 1);
      expect((await users.getAllActive()).first.username, 'Jose');
    } finally {
      await dbHelper.close();
      if (await sandbox.exists()) {
        await sandbox.delete(recursive: true);
      }
    }
  });
}
