class ExportDeliveryService {
  Future<String?> saveAsDialog(
    String sourcePath, {
    required String dialogTitle,
    String? suggestedFileName,
  }) async {
    return null;
  }

  Future<bool> openFile(String filePath) async {
    return false;
  }

  Future<String> deliverExportedFile(
    String filePath, {
    required String label,
  }) async {
    return '$label no esta disponible en esta plataforma.';
  }
}
