import '../config/platform_config.dart';

String getPlatformName() {
  if (PlatformConfig.isWeb) {
    return 'web';
  }
  if (PlatformConfig.isAndroid) {
    return 'android';
  }
  if (PlatformConfig.isWindows) {
    return 'windows';
  }
  return 'unknown';
}

bool isDesktopLike() => PlatformConfig.isDesktop;
