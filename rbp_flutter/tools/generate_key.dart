import 'dart:io';

import 'package:rbp_flutter/services/license_key_codec.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stdout.writeln('Usage: dart run tools/generate_key.dart <MACHINE_ID>');
    return;
  }
  final machineId = args.first.toUpperCase();
  final key = await LicenseKeyCodec.generateLicenseKey(machineId);
  stdout.writeln('Machine ID: $machineId');
  stdout.writeln('License Key: $key');
}
