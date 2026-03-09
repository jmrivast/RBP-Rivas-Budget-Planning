import 'package:flutter/services.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';

import '../../config/platform_config.dart';

Future<void> initializePlatformServices() async {
  if (PlatformConfig.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  if (!PlatformConfig.supportsWindowManager) {
    return;
  }

  try {
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(
      title: 'RBP - Finanzas Personales',
      minimumSize: Size(900, 600),
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  } on MissingPluginException {
    // Allows app startup when the plugin registrant is not available yet.
  }
}
