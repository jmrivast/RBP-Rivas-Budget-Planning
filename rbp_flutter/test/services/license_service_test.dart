import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:rbp_flutter/services/license_service.dart';

class _FakeLicenseService extends LicenseService {
  _FakeLicenseService(
    this._machineId, {
    super.documentsDirectoryProvider,
  });

  final String _machineId;

  @override
  Future<String> getMachineId() async => _machineId;
}

void main() {
  group('LicenseService', () {
    test('generateLicenseKey returns grouped uppercase key', () {
      const machineId = 'ABCDEF1234567890';
      final key = LicenseService.generateLicenseKey(machineId);
      expect(
        RegExp(r'^[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$')
            .hasMatch(key),
        isTrue,
      );
    });

    test('validateKey accepts matching key and rejects invalid key', () async {
      const machineId = 'ABCDEF1234567890';
      final service = _FakeLicenseService(machineId);
      final valid = LicenseService.generateLicenseKey(machineId);
      final bad = LicenseService.generateLicenseKey('ZZZZZZZZZZZZZZZZ');

      expect(await service.validateKey(valid), isTrue);
      expect(await service.validateKey(bad), isFalse);
    });

    test('storeKey activates license and deactivate removes activation',
        () async {
      const machineId = 'ABCDEF1234567890';
      final sandbox =
          await Directory.systemTemp.createTemp('rbp_license_test_');
      final docs = Directory(p.join(sandbox.path, 'docs'));
      await docs.create(recursive: true);

      final service = _FakeLicenseService(
        machineId,
        documentsDirectoryProvider: () async => docs,
      );
      final key = LicenseService.generateLicenseKey(machineId);

      try {
        await service.storeKey(key);
        expect(await service.isActivated(), isTrue);

        final info = await service.getLicenseInfo();
        expect(info['key'], key);
        expect(info['machineId'], machineId);
        expect(info['activationDate'], isNotNull);

        await service.deactivate();
        expect(await service.isActivated(), isFalse);
      } finally {
        if (await sandbox.exists()) {
          await sandbox.delete(recursive: true);
        }
      }
    });
  });
}
