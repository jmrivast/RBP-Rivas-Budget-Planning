class LicenseService {
  LicenseService({Future<dynamic> Function()? documentsDirectoryProvider});

  Future<bool> requiresActivation() async => false;

  Future<String> getMachineId() async => 'WEB-NO-LICENSE';

  static Future<String> generateLicenseKey(String machineId) async => 'N/A';

  Future<bool> validateKey(String licenseKey) async => true;

  Future<void> storeKey(String licenseKey) async {}

  Future<bool> isActivated() async => true;

  Future<Map<String, String?>> getLicenseInfo() async {
    return const {
      'key': null,
      'activationDate': null,
      'machineId': 'WEB-NO-LICENSE',
      'scheme': 'stub',
      'keyPreview': null,
    };
  }

  Future<void> deactivate() async {}
}
