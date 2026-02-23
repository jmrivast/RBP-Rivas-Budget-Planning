import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../config/platform_config.dart';
import 'license_key_codec.dart';

class LicenseService {
  LicenseService({
    Future<Directory> Function()? documentsDirectoryProvider,
  }) : _documentsDirectoryProvider =
            documentsDirectoryProvider ?? getApplicationDocumentsDirectory;

  static const _licenseKeyField = 'license_key';
  static const _activationDateField = 'activation_date';
  static const _machineIdField = 'machine_id';
  static const _licenseFileName = 'license_info.json';
  final Future<Directory> Function() _documentsDirectoryProvider;

  Future<String> getMachineId() async {
    String rawId = '';
    try {
      if (PlatformConfig.isWindows) {
        final info = await DeviceInfoPlugin().windowsInfo;
        rawId =
            '${info.computerName}|${info.numberOfCores}|${info.systemMemoryInMegabytes}|${info.deviceId}';
      }
    } catch (_) {
      rawId = '';
    }

    if (rawId.trim().isEmpty) {
      final host = Platform.localHostname;
      final user = Platform.environment['USERNAME'] ?? '';
      rawId = '$host|$user|rbp';
    }

    final digest = sha256.convert(utf8.encode(rawId));
    return digest.toString().substring(0, 16).toUpperCase();
  }

  static String generateLicenseKey(String machineId) {
    return LicenseKeyCodec.generateLicenseKey(machineId);
  }

  Future<bool> validateKey(String licenseKey) async {
    final normalized = LicenseKeyCodec.normalizeKey(licenseKey);
    if (!LicenseKeyCodec.looksLikeKey(normalized)) {
      return false;
    }
    final machineId = await getMachineId();
    return normalized == generateLicenseKey(machineId);
  }

  Future<void> storeKey(String licenseKey) async {
    final normalized = _normalizeKey(licenseKey);
    final valid = await validateKey(normalized);
    if (!valid) {
      throw Exception('Clave invalida. Verifica e intenta de nuevo.');
    }
    final machineId = await getMachineId();
    final payload = <String, String>{
      _licenseKeyField: normalized,
      _activationDateField: DateTime.now().toIso8601String(),
      _machineIdField: machineId,
    };
    final file = await _licenseFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(payload), flush: true);
  }

  Future<bool> isActivated() async {
    if (!PlatformConfig.supportsLicense) {
      return true;
    }
    final data = await _readStoredData();
    final key = data[_licenseKeyField];
    if (key == null || key.isEmpty) {
      return false;
    }
    return validateKey(key);
  }

  Future<Map<String, String?>> getLicenseInfo() async {
    final data = await _readStoredData();
    return {
      'key': data[_licenseKeyField],
      'activationDate': data[_activationDateField],
      'machineId': await getMachineId(),
    };
  }

  Future<void> deactivate() async {
    final file = await _licenseFile();
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<File> _licenseFile() async {
    final docs = await _documentsDirectoryProvider();
    return File(p.join(docs.path, 'rbp', _licenseFileName));
  }

  Future<Map<String, String>> _readStoredData() async {
    try {
      final file = await _licenseFile();
      if (!await file.exists()) {
        return const {};
      }
      final raw = (await file.readAsString()).trim();
      if (raw.isEmpty) {
        return const {};
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return const {};
      }
      return decoded.map(
          (key, value) => MapEntry(key.toString(), value?.toString() ?? ''));
    } catch (_) {
      return const {};
    }
  }

  static String _normalizeKey(String key) {
    return LicenseKeyCodec.normalizeKey(key);
  }
}
