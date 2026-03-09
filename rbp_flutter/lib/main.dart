import 'package:flutter/widgets.dart';

import 'app.dart';
import 'core/platform/app_platform_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializePlatformServices();
  runApp(const RbpApp());
}
