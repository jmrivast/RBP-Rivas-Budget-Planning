import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import 'update_service.dart';

class AutoUpdateResult {
  const AutoUpdateResult({
    required this.started,
    required this.message,
  });

  final bool started;
  final String message;
}

class WindowsAutoUpdateService {
  Future<AutoUpdateResult> installRelease(ReleaseInfo release) async {
    if (!Platform.isWindows) {
      return const AutoUpdateResult(
        started: false,
        message: 'Auto-actualizacion solo disponible en Windows.',
      );
    }

    final uri = Uri.tryParse(release.downloadUrl);
    if (uri == null) {
      return const AutoUpdateResult(
        started: false,
        message: 'URL de actualizacion invalida.',
      );
    }

    final fileName = _extractFileName(uri, release.tag);
    if (!fileName.toLowerCase().endsWith('.exe')) {
      return const AutoUpdateResult(
        started: false,
        message:
            'No se encontro instalador .exe en este release. Usa "Abrir release".',
      );
    }

    final updateDir =
        await Directory(p.join(Directory.systemTemp.path, 'rbp_update'))
            .create(recursive: true);
    final installerPath = p.join(updateDir.path, fileName);
    final installerFile = File(installerPath);

    late http.Response response;
    try {
      response = await http
          .get(uri, headers: const {'User-Agent': 'RBP-Flutter/1.0'})
          .timeout(const Duration(minutes: 3));
    } catch (e) {
      return AutoUpdateResult(
        started: false,
        message: 'No se pudo descargar la actualizacion: $e',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return AutoUpdateResult(
        started: false,
        message: 'Descarga fallida (HTTP ${response.statusCode}).',
      );
    }

    try {
      await installerFile.writeAsBytes(response.bodyBytes, flush: true);
    } catch (e) {
      return AutoUpdateResult(
        started: false,
        message: 'No se pudo guardar el instalador: $e',
      );
    }

    final currentExe = Platform.resolvedExecutable;
    final scriptPath = p.join(updateDir.path, 'run_update.cmd');
    final script = StringBuffer()
      ..writeln('@echo off')
      ..writeln('setlocal')
      ..writeln('timeout /t 1 /nobreak >nul')
      ..writeln('start "" /wait "${_escapeForCmd(installerPath)}" /S')
      ..writeln('timeout /t 1 /nobreak >nul')
      ..writeln('if exist "${_escapeForCmd(currentExe)}" start "" "${_escapeForCmd(currentExe)}"')
      ..writeln('endlocal');

    try {
      await File(scriptPath).writeAsString(script.toString(), flush: true);
      await Process.start(
        'cmd',
        ['/c', scriptPath],
        mode: ProcessStartMode.detached,
        runInShell: false,
      );
    } catch (e) {
      return AutoUpdateResult(
        started: false,
        message: 'No se pudo iniciar instalador silencioso: $e',
      );
    }

    return const AutoUpdateResult(
      started: true,
      message: 'Actualizacion iniciada. La app se cerrara para instalar.',
    );
  }

  String _extractFileName(Uri uri, String tag) {
    final fallback = 'RBP_Setup_${tag.replaceAll('v', '')}.exe';
    if (uri.pathSegments.isEmpty) {
      return fallback;
    }
    final raw = uri.pathSegments.last.trim();
    if (raw.isEmpty) {
      return fallback;
    }
    return raw;
  }

  String _escapeForCmd(String value) {
    return value.replaceAll('"', '""');
  }
}

