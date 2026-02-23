import 'dart:convert';

import 'package:crypto/crypto.dart';

class LicenseKeyCodec {
  static const secretSalt = String.fromEnvironment(
    'RBP_LICENSE_SALT',
    defaultValue: 'RBP_SECRET_SALT_CHANGE_ME',
  );

  static String generateLicenseKey(String machineId) {
    final normalizedMachine = normalizeMachineId(machineId);
    final input = '$normalizedMachine:$secretSalt';
    final hash = sha256.convert(utf8.encode(input)).toString().toUpperCase();
    final raw = hash.substring(0, 16);
    return '${raw.substring(0, 4)}-${raw.substring(4, 8)}-${raw.substring(8, 12)}-${raw.substring(12, 16)}';
  }

  static bool looksLikeKey(String key) {
    final normalized = normalizeKey(key);
    final re = RegExp(r'^[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$');
    return re.hasMatch(normalized);
  }

  static String normalizeMachineId(String machineId) {
    return machineId.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  static String normalizeKey(String key) {
    return key.trim().toUpperCase();
  }
}
