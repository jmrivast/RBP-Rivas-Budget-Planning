import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/update_service.dart';

Future<void> showUpdateAvailableDialog(
  BuildContext context, {
  required ReleaseInfo latest,
  required String currentVersion,
  required bool manual,
  Future<void> Function()? onSnooze,
}) async {
  final notes = latest.notes.trim();
  final preview = notes.length > 320 ? '${notes.substring(0, 320)}...' : notes;

  await showDialog<void>(
    context: context,
    builder: (context) {
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
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          if (!manual)
            OutlinedButton(
              onPressed: () async {
                if (onSnooze != null) {
                  await onSnooze();
                }
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Recordarmelo luego'),
            ),
          FilledButton.icon(
            onPressed: () async {
              final uri = Uri.parse(latest.url);
              await launchUrl(uri, mode: LaunchMode.externalApplication);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            icon: const Icon(Icons.download),
            label: const Text('Abrir descarga'),
          ),
        ],
      );
    },
  );
}
