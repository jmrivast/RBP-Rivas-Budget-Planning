import '../../config/platform_config.dart';

class AppCapabilities {
  const AppCapabilities({
    required this.requiresLicenseActivation,
    required this.supportsWindowManager,
    required this.supportsUpdateChecks,
    required this.supportsLocalBackup,
    required this.supportsAutoPeriodExport,
    required this.supportsExportOpen,
    required this.supportsNativeShare,
    required this.supportsPdfCsvExport,
    required this.isDesktop,
    required this.isMobile,
    required this.isWeb,
  });

  final bool requiresLicenseActivation;
  final bool supportsWindowManager;
  final bool supportsUpdateChecks;
  final bool supportsLocalBackup;
  final bool supportsAutoPeriodExport;
  final bool supportsExportOpen;
  final bool supportsNativeShare;
  final bool supportsPdfCsvExport;
  final bool isDesktop;
  final bool isMobile;
  final bool isWeb;

  static AppCapabilities get current => AppCapabilities(
        requiresLicenseActivation: PlatformConfig.supportsLicense,
        supportsWindowManager: PlatformConfig.supportsWindowManager,
        supportsUpdateChecks: PlatformConfig.supportsUpdateChecks,
        supportsLocalBackup: PlatformConfig.supportsLocalBackup,
        supportsAutoPeriodExport: PlatformConfig.supportsAutoPeriodExport,
        supportsExportOpen: PlatformConfig.supportsExportOpen,
        supportsNativeShare: PlatformConfig.supportsNativeShare,
        supportsPdfCsvExport: PlatformConfig.supportsPdfCsvExport,
        isDesktop: PlatformConfig.isDesktop,
        isMobile: PlatformConfig.isMobile,
        isWeb: PlatformConfig.isWeb,
      );
}
