import 'package:flutter_test/flutter_test.dart';
import 'package:rbp_flutter/services/update_service.dart';

void main() {
  group('UpdateService.isNewerVersion', () {
    test('detects newer stable versions', () {
      expect(UpdateService.isNewerVersion('2.0.0', 'v2.0.1'), isTrue);
      expect(UpdateService.isNewerVersion('2.0.0', '2.1.0'), isTrue);
      expect(UpdateService.isNewerVersion('2.0.0', '2.0.0'), isFalse);
      expect(UpdateService.isNewerVersion('2.0.1', '2.0.0'), isFalse);
    });

    test('stable beats prerelease on same core version', () {
      expect(UpdateService.isNewerVersion('2.0.0', '2.0.0-beta.1'), isFalse);
      expect(UpdateService.isNewerVersion('2.0.0-beta.1', '2.0.0'), isTrue);
    });

    test('compares prerelease identifiers correctly', () {
      expect(UpdateService.isNewerVersion('2.0.0-beta.1', '2.0.0-beta.2'),
          isTrue);
      expect(UpdateService.isNewerVersion('2.0.0-beta.2', '2.0.0-beta.10'),
          isTrue);
      expect(UpdateService.isNewerVersion('2.0.0-beta.10', '2.0.0-beta.2'),
          isFalse);
      expect(UpdateService.isNewerVersion('2.0.0-alpha.1', '2.0.0-beta.1'),
          isTrue);
      expect(UpdateService.isNewerVersion('2.0.0-rc.1', '2.0.0-beta.9'),
          isFalse);
    });

    test('handles build metadata and loose tags', () {
      expect(UpdateService.isNewerVersion('2.0.0+5', 'v2.0.1+1'), isTrue);
      expect(UpdateService.isNewerVersion('2.0', 'v2.0.0'), isFalse);
      expect(UpdateService.isNewerVersion('2', 'v2.0.1'), isTrue);
    });
  });
}
