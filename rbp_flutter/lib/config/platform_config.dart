import 'package:flutter/foundation.dart';
import 'package:universal_platform/universal_platform.dart';

class PlatformConfig {
  static bool get isWeb => kIsWeb;
  static bool get isWindows => !kIsWeb && UniversalPlatform.isWindows;
  static bool get isMacOS => !kIsWeb && UniversalPlatform.isMacOS;
  static bool get isLinux => !kIsWeb && UniversalPlatform.isLinux;
  static bool get isAndroid => !kIsWeb && UniversalPlatform.isAndroid;
  static bool get isIOS => !kIsWeb && UniversalPlatform.isIOS;
  static bool get isDesktop => isWindows || isMacOS || isLinux;
  static bool get isMobile => isAndroid || isIOS;

  static bool get supportsLicense => isWindows;
  static bool get supportsWindowManager => isWindows;
  static bool get supportsUpdateChecks => isWindows;
  static bool get supportsLocalBackup => isWindows;
  static bool get supportsAutoPeriodExport => isWindows;
  static bool get supportsExportOpen => isDesktop;
  static bool get supportsNativeShare => isMobile;
  static bool get supportsPdfCsvExport => isDesktop || isMobile || isWeb;
}


