import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'license_crypto.dart';

class LicenseKeyCodec {
  static const secretSalt = String.fromEnvironment(
    'RBP_LICENSE_SALT',
    defaultValue: 'RBP_SECRET_SALT_CHANGE_ME',
  );

  static Future<String> generateLicenseKey(String machineId) {
    return LicenseCrypto.generateLicenseToken(machineId);
  }

  static String generateLegacyLicenseKey(String machineId) {
    final normalizedMachine = normalizeMachineId(machineId);
    final input = '$normalizedMachine:$secretSalt';
    final hash = sha256.convert(utf8.encode(input)).toString().toUpperCase();
    final raw = hash.substring(0, 16);
    return '${raw.substring(0, 4)}-${raw.substring(4, 8)}-${raw.substring(8, 12)}-${raw.substring(12, 16)}';
  }

  static bool looksLikeKey(String key) {
    final normalized = normalizeKey(key);
    final legacy = RegExp(r'^[A-Z0-9]{4}(?:-[A-Z0-9]{4}){3}$');
    return legacy.hasMatch(normalized) || LicenseCrypto.looksLikeV2Token(normalized);
  }

  static String normalizeMachineId(String machineId) {
    return machineId.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  static String normalizeKey(String key) {
    final trimmed = key.trim().toUpperCase();
    final legacyRaw = trimmed.replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (legacyRaw.length == 16) {
      return '${legacyRaw.substring(0, 4)}-${legacyRaw.substring(4, 8)}-${legacyRaw.substring(8, 12)}-${legacyRaw.substring(12, 16)}';
    }
    return LicenseCrypto.normalizeToken(trimmed);
  }
}
