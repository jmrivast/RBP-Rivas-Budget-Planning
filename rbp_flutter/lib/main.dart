import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'config/platform_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initPlatformServices();
  runApp(const RbpApp());
}

Future<void> _initPlatformServices() async {
  if (PlatformConfig.isWeb) {
    databaseFactory = databaseFactoryFfiWeb;
    return;
  }

  if (PlatformConfig.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

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
      // Allows app startup when plugin registrant is not available yet.
    }
  }
}
