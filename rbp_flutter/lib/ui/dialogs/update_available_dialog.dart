import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/update_service.dart';
import '../../services/windows_auto_update_service.dart';

Future<void> showUpdateAvailableDialog(
  BuildContext context, {
  required ReleaseInfo latest,
  required String currentVersion,
  required bool manual,
  Future<void> Function()? onSnooze,
}) async {
  final notes = latest.notes.trim();
  final preview = notes.length > 320 ? '${notes.substring(0, 320)}...' : notes;
  final autoUpdater = WindowsAutoUpdateService();
  var isUpdating = false;

  await showDialog<void>(
    context: context,
    builder: (context) {
      return StatefulBuilder(builder: (context, setState) {
        Future<void> startAutoUpdate() async {
          if (isUpdating) {
            return;
          }
          setState(() => isUpdating = true);
          final result = await autoUpdater.installRelease(latest);
          if (!context.mounted) {
            return;
          }
          if (!result.started) {
            setState(() => isUpdating = false);
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(result.message)));
            return;
          }
          Navigator.of(context).pop();
          // Cerramos para permitir sobreescritura de binarios durante instalacion.
          exit(0);
        }

        final canAutoUpdate = !kIsWeb && Platform.isWindows;
        return AlertDialog(
          title: const Text('Actualizacion disponible'),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Version actual: v$currentVersion'),
                Text('Nueva version: ${latest.tag}',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                const Text('Novedades:'),
                const SizedBox(height: 4),
                Text(preview.isEmpty ? 'Sin notas de version.' : preview),
                const SizedBox(height: 10),
                Text(
                  canAutoUpdate
                      ? 'Actualizar ahora: descarga, instala en silencio y reabre la app.'
                      : 'Actualizacion automatica solo disponible en Windows.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isUpdating ? null : () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
            if (!manual)
              OutlinedButton(
                onPressed: isUpdating
                    ? null
                    : () async {
                        if (onSnooze != null) {
                          await onSnooze();
                        }
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                child: const Text('Recordarmelo luego'),
              ),
            OutlinedButton.icon(
              onPressed: isUpdating
                  ? null
                  : () async {
                      final uri = Uri.parse(latest.releasePageUrl);
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
              icon: const Icon(Icons.open_in_new),
              label: const Text('Ver release'),
            ),
            FilledButton.icon(
              onPressed: (isUpdating || !canAutoUpdate) ? null : startAutoUpdate,
              icon: isUpdating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.system_update_alt),
              label: Text(isUpdating ? 'Actualizando...' : 'Actualizar ahora'),
            ),
          ],
        );
      });
    },
  );
}
