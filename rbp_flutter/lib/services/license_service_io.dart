import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../config/platform_config.dart';
import '../data/models/license_info.dart';
import 'license_crypto.dart';
import 'license_key_codec.dart';

class LicenseService {
  LicenseService({
    Future<Directory> Function()? documentsDirectoryProvider,
  }) : _documentsDirectoryProvider =
            documentsDirectoryProvider ?? getApplicationDocumentsDirectory;

  static const _licenseFileName = 'license_info.json';
  final Future<Directory> Function() _documentsDirectoryProvider;

  Future<bool> requiresActivation() async => PlatformConfig.supportsLicense;

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

  static Future<String> generateLicenseKey(String machineId) {
    return LicenseKeyCodec.generateLicenseKey(machineId);
  }

  Future<bool> validateKey(String licenseKey) async {
    final normalized = LicenseKeyCodec.normalizeKey(licenseKey);
    if (!LicenseKeyCodec.looksLikeKey(normalized)) {
      return false;
    }
    final machineId = await getMachineId();
    final aesPayload = await LicenseCrypto.decryptLicenseToken(machineId, normalized);
    if (aesPayload != null) {
      return true;
    }
    final legacy = LicenseKeyCodec.generateLegacyLicenseKey(machineId);
    return normalized == legacy;
  }

  Future<void> storeKey(String licenseKey) async {
    final normalized = LicenseKeyCodec.normalizeKey(licenseKey);
    final machineId = await getMachineId();
    final valid = await validateKey(normalized);
    if (!valid) {
      throw Exception('Clave invalida. Verifica e intenta de nuevo.');
    }

    final tokenPayload = await LicenseCrypto.decryptLicenseToken(machineId, normalized);
    final scheme = switch (tokenPayload?.version) {
      3 => 'aes-v3',
      2 => 'aes-v2',
      _ => 'legacy-v1',
    };
    final info = LicenseInfo(
      key: normalized,
      keyPreview: _keyPreview(normalized),
      machineId: machineId,
      machineFingerprint: LicenseCrypto.machineFingerprint(machineId),
      activatedAt: DateTime.now().toIso8601String(),
      scheme: scheme,
      isActivated: true,
    );
    await _writeEncryptedRecord(info);
  }

  Future<bool> isActivated() async {
    if (!await requiresActivation()) {
      return true;
    }
    final info = await _readLicenseInfo();
    if (info == null || !info.isActivated || info.key == null || info.key!.isEmpty) {
      return false;
    }
    return validateKey(info.key!);
  }

  Future<Map<String, String?>> getLicenseInfo() async {
    final info = await _readLicenseInfo();
    final machineId = await getMachineId();
    return {
      'key': info?.key,
      'activationDate': info?.activatedAt,
      'machineId': machineId,
      'scheme': info?.scheme,
      'keyPreview': info?.keyPreview,
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

  Future<LicenseInfo?> _readLicenseInfo() async {
    try {
      final file = await _licenseFile();
      if (!await file.exists()) {
        return null;
      }
      final raw = (await file.readAsString()).trim();
      if (raw.isEmpty) {
        return null;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final machineId = await getMachineId();
      final encryptedRecord = decoded['record']?.toString();
      if (encryptedRecord != null && encryptedRecord.isNotEmpty) {
        final decrypted = await LicenseCrypto.decryptLocalRecord(
          machineId: machineId,
          token: encryptedRecord,
        );
        if (decrypted == null) {
          return null;
        }
        return LicenseInfo.fromMap(decrypted);
      }

      return _tryMigrateLegacyFile(machineId, decoded);
    } catch (_) {
      return null;
    }
  }

  Future<LicenseInfo?> _tryMigrateLegacyFile(
    String machineId,
    Map<String, dynamic> decoded,
  ) async {
    final legacyKey = decoded['license_key']?.toString() ?? decoded['key']?.toString();
    if (legacyKey == null || legacyKey.isEmpty) {
      return null;
    }

    final normalized = LicenseKeyCodec.normalizeKey(legacyKey);
    final tokenPayload = await LicenseCrypto.decryptLicenseToken(machineId, normalized);
    final legacyInfo = LicenseInfo(
      key: normalized,
      keyPreview: _keyPreview(normalized),
      machineId: machineId,
      machineFingerprint: LicenseCrypto.machineFingerprint(machineId),
      activatedAt: decoded['activation_date']?.toString() ??
          decoded['activated_at']?.toString() ??
          DateTime.now().toIso8601String(),
      scheme: switch (tokenPayload?.version) {
        3 => 'aes-v3',
        2 => 'aes-v2',
        _ => 'legacy-v1',
      },
      isActivated: true,
    );

    if (!await validateKey(normalized)) {
      return null;
    }

    await _writeEncryptedRecord(legacyInfo);
    return legacyInfo;
  }

  Future<void> _writeEncryptedRecord(LicenseInfo info) async {
    final machineId = await getMachineId();
    final encryptedRecord = await LicenseCrypto.encryptLocalRecord(
      machineId: machineId,
      payload: info.toMap(),
    );
    final wrapper = <String, Object?>{
      'scheme': info.scheme,
      'version': LicenseCrypto.currentVersion,
      'record': encryptedRecord,
      'updated_at': DateTime.now().toIso8601String(),
    };
    final file = await _licenseFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(wrapper), flush: true);
  }

  static String _keyPreview(String key) {
    if (key.length <= 14) {
      return key;
    }
    return '${key.substring(0, 9)}...${key.substring(key.length - 4)}';
  }
}
