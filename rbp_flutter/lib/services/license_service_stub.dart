class LicenseService {
  LicenseService({Future<dynamic> Function()? documentsDirectoryProvider});

  Future<String> getMachineId() async => 'WEB-NO-LICENSE';

  static String generateLicenseKey(String machineId) => 'N/A';

  Future<bool> validateKey(String licenseKey) async => true;

  Future<void> storeKey(String licenseKey) async {}

  Future<bool> isActivated() async => true;

  Future<Map<String, String?>> getLicenseInfo() async {
    return const {
      'key': null,
      'activationDate': null,
      'machineId': 'WEB-NO-LICENSE',
    };
  }

  Future<void> deactivate() async {}
}
