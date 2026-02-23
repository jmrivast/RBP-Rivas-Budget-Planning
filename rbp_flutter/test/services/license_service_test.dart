import 'package:flutter_test/flutter_test.dart';
import 'package:rbp_flutter/services/license_service.dart';

class _FakeLicenseService extends LicenseService {
  _FakeLicenseService(this._machineId);

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
        RegExp(r'^[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$').hasMatch(key),
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
  });
}
