class ExportDeliveryService {
  Future<String?> saveAsDialog(
    String sourcePath, {
    required String dialogTitle,
    String? suggestedFileName,
  }) async {
    return sourcePath;
  }

  Future<bool> openFile(String filePath) async {
    return true;
  }

  Future<String> deliverExportedFile(
    String filePath, {
    required String label,
  }) async {
    return '$label descargado: $filePath';
  }
}
