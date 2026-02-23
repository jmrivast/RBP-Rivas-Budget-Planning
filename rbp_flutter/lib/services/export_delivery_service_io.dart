import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

class ExportDeliveryService {
  Future<String?> saveAsDialog(
    String sourcePath, {
    required String dialogTitle,
    String? suggestedFileName,
  }) async {
    final fileName = suggestedFileName ?? p.basename(sourcePath);
    final targetPath = await FilePicker.platform.saveFile(
      dialogTitle: dialogTitle,
      fileName: fileName,
      lockParentWindow: true,
    );
    if (targetPath == null || targetPath.trim().isEmpty) {
      return null;
    }
    final source = File(sourcePath);
    await source.copy(targetPath);
    return targetPath;
  }

  Future<bool> openFile(String filePath) async {
    final path = p.normalize(filePath);
    if (!File(path).existsSync()) {
      return false;
    }
    try {
      if (Platform.isWindows) {
        await Process.start('explorer.exe', [path], runInShell: true);
        return true;
      }
      if (Platform.isMacOS) {
        await Process.start('open', [path], runInShell: true);
        return true;
      }
      if (Platform.isLinux) {
        await Process.start('xdg-open', [path], runInShell: true);
        return true;
      }
    } catch (_) {
      return false;
    }
    return false;
  }
}
