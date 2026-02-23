import 'package:flutter/foundation.dart';
import 'package:universal_platform/universal_platform.dart';

class PlatformConfig {
  static bool get isWeb => kIsWeb;
  static bool get isWindows => !kIsWeb && UniversalPlatform.isWindows;
  static bool get isAndroid => !kIsWeb && UniversalPlatform.isAndroid;
  static bool get isDesktop => isWindows;
  static bool get supportsLicense => isWindows;
}
