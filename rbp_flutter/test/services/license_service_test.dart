import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:rbp_flutter/services/license_key_codec.dart';
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
    test('generateLicenseKey returns grouped token and looksLikeKey accepts it', () async {
      const machineId = 'ABCDEF1234567890';
      final key = await LicenseService.generateLicenseKey(machineId);

      expect(key.contains('-'), isTrue);
      expect(LicenseKeyCodec.looksLikeKey(key), isTrue);
    });

    test('validateKey accepts matching AES token and rejects invalid key', () async {
      const machineId = 'ABCDEF1234567890';
      final service = _FakeLicenseService(machineId);
      final valid = await LicenseService.generateLicenseKey(machineId);
      final bad = await LicenseService.generateLicenseKey('ZZZZZZZZZZZZZZZZ');

      expect(await service.validateKey(valid), isTrue);
      expect(await service.validateKey(bad), isFalse);
    });

    test('validateKey still accepts legacy v1 hash licenses', () async {
      const machineId = 'ABCDEF1234567890';
      final service = _FakeLicenseService(machineId);
      final legacy = LicenseKeyCodec.generateLegacyLicenseKey(machineId);

      expect(await service.validateKey(legacy), isTrue);
    });

    test('storeKey persists encrypted local record instead of plain key data', () async {
      const machineId = 'ABCDEF1234567890';
      final sandbox =
          await Directory.systemTemp.createTemp('rbp_license_test_');
      final docs = Directory(p.join(sandbox.path, 'docs'));
      await docs.create(recursive: true);

      final service = _FakeLicenseService(
        machineId,
        documentsDirectoryProvider: () async => docs,
      );
      final key = await LicenseService.generateLicenseKey(machineId);
      final licenseFile = File(p.join(docs.path, 'rbp', 'license_info.json'));

      try {
        await service.storeKey(key);
        expect(await service.isActivated(), isTrue);

        final info = await service.getLicenseInfo();
        expect(info['machineId'], machineId);
        expect(info['activationDate'], isNotNull);
        expect(info['scheme'], 'aes-v3');
        expect(info['keyPreview'], isNotNull);

        final raw = await licenseFile.readAsString();
        expect(raw.contains(key), isFalse);
        expect(raw.contains(machineId), isFalse);
        expect(raw.contains('license_key'), isFalse);
        expect(raw.contains('machine_id'), isFalse);

        await service.deactivate();
        expect(await service.isActivated(), isFalse);
      } finally {
        if (await sandbox.exists()) {
          await sandbox.delete(recursive: true);
        }
      }
    });

    test('legacy plain storage is migrated to encrypted record on read', () async {
      const machineId = 'ABCDEF1234567890';
      final sandbox =
          await Directory.systemTemp.createTemp('rbp_license_legacy_test_');
      final docs = Directory(p.join(sandbox.path, 'docs'));
      await docs.create(recursive: true);
      final licenseFile = File(p.join(docs.path, 'rbp', 'license_info.json'));
      await licenseFile.parent.create(recursive: true);

      final legacyKey = LicenseKeyCodec.generateLegacyLicenseKey(machineId);
      await licenseFile.writeAsString(
        jsonEncode({
          'license_key': legacyKey,
          'activation_date': '2026-03-09T12:00:00.000Z',
          'machine_id': machineId,
        }),
      );

      final service = _FakeLicenseService(
        machineId,
        documentsDirectoryProvider: () async => docs,
      );

      try {
        expect(await service.isActivated(), isTrue);
        final migrated = await licenseFile.readAsString();
        expect(migrated.contains('license_key'), isFalse);
        expect(migrated.contains(machineId), isFalse);

        final info = await service.getLicenseInfo();
        expect(info['scheme'], 'legacy-v1');
      } finally {
        if (await sandbox.exists()) {
          await sandbox.delete(recursive: true);
        }
      }
    });
  });
}
