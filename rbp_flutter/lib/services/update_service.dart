import 'dart:convert';

import 'package:http/http.dart' as http;

class ReleaseInfo {
  const ReleaseInfo({
    required this.tag,
    required this.url,
    required this.releasePageUrl,
    required this.downloadUrl,
    required this.notes,
    required this.isPrerelease,
  });

  final String tag;
  // Backward-compat alias: points to release page URL.
  final String url;
  final String releasePageUrl;
  final String downloadUrl;
  final String notes;
  final bool isPrerelease;
}

class UpdateService {
  static const _latestApi =
      'https://api.github.com/repos/jmrivast/RBP-Rivas-Budget-Planning/releases/latest';
  static const _releasesApi =
      'https://api.github.com/repos/jmrivast/RBP-Rivas-Budget-Planning/releases?per_page=25';
  static const _userAgent = 'RBP-Flutter/1.0';

  Future<ReleaseInfo?> fetchLatest({bool includeBeta = false}) async {
    final uri = Uri.parse(includeBeta ? _releasesApi : _latestApi);
    final response =
        await http.get(uri, headers: {'User-Agent': _userAgent}).timeout(
      const Duration(seconds: 8),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }
    final payload = jsonDecode(response.body);
    if (!includeBeta) {
      if (payload is! Map<String, dynamic>) {
        return null;
      }
      return _toReleaseInfo(payload);
    }
    if (payload is! List) {
      return null;
    }
    for (final item in payload) {
      if (item is! Map<String, dynamic>) {
        continue;
      }
      if (item['draft'] == true) {
        continue;
      }
      return _toReleaseInfo(item);
    }
    return null;
  }

  static bool isNewerVersion(String currentVersion, String releaseTag) {
    final current = _parseVersion(currentVersion);
    final latest = _parseVersion(releaseTag);
    for (var i = 0; i < 3; i++) {
      if (latest.core[i] != current.core[i]) {
        return latest.core[i] > current.core[i];
      }
    }
    if (current.preRelease.isEmpty && latest.preRelease.isNotEmpty) {
      return false;
    }
    if (current.preRelease.isNotEmpty && latest.preRelease.isEmpty) {
      return true;
    }
    return _comparePreRelease(current.preRelease, latest.preRelease) < 0;
  }

  static int _comparePreRelease(String a, String b) {
    if (a == b) {
      return 0;
    }
    if (a.isEmpty && b.isNotEmpty) {
      return 1;
    }
    if (a.isNotEmpty && b.isEmpty) {
      return -1;
    }
    final left = a.split('.');
    final right = b.split('.');
    final maxLen = left.length > right.length ? left.length : right.length;
    for (var i = 0; i < maxLen; i++) {
      final l = i < left.length ? left[i] : null;
      final r = i < right.length ? right[i] : null;
      if (l == null && r == null) {
        return 0;
      }
      if (l == null) {
        return -1;
      }
      if (r == null) {
        return 1;
      }
      final lNum = int.tryParse(l);
      final rNum = int.tryParse(r);
      if (lNum != null && rNum != null) {
        if (lNum != rNum) {
          return lNum.compareTo(rNum);
        }
        continue;
      }
      if (lNum != null && rNum == null) {
        return -1;
      }
      if (lNum == null && rNum != null) {
        return 1;
      }
      final cmp = l.compareTo(r);
      if (cmp != 0) {
        return cmp;
      }
    }
    return 0;
  }

  ReleaseInfo? _toReleaseInfo(Map<String, dynamic> map) {
    final tag = (map['tag_name'] ?? '').toString().trim();
    if (tag.isEmpty) {
      return null;
    }
    final notes = (map['body'] ?? '').toString().trim();
    final releasePageUrl = (map['html_url'] ?? '').toString();
    if (releasePageUrl.isEmpty) {
      return null;
    }

    String downloadUrl = releasePageUrl;
    final assets = map['assets'];
    if (assets is List) {
      String? setupExe;
      String? anyExe;
      String? msix;
      String? zip;
      for (final item in assets) {
        if (item is! Map<String, dynamic>) {
          continue;
        }
        final name = (item['name'] ?? '').toString().toLowerCase();
        final candidate = (item['browser_download_url'] ?? '').toString();
        if (candidate.isEmpty) {
          continue;
        }
        if (name.endsWith('.exe')) {
          anyExe ??= candidate;
          if (name.contains('setup')) {
            setupExe ??= candidate;
          }
          continue;
        }
        if (name.endsWith('.msix')) {
          msix ??= candidate;
          continue;
        }
        if (name.endsWith('.zip')) {
          zip ??= candidate;
        }
      }
      downloadUrl = setupExe ?? anyExe ?? msix ?? zip ?? releasePageUrl;
    }

    return ReleaseInfo(
      tag: tag,
      url: releasePageUrl,
      releasePageUrl: releasePageUrl,
      downloadUrl: downloadUrl,
      notes: notes,
      isPrerelease: map['prerelease'] == true,
    );
  }

  static ({List<int> core, String preRelease}) _parseVersion(String raw) {
    final cleaned =
        raw.trim().toLowerCase().replaceFirst('v', '').split('+').first;
    final parts = cleaned.split('-');
    final coreRaw = parts.first;
    final pre = parts.length > 1 ? parts.sublist(1).join('-') : '';
    final coreSplit = coreRaw.split('.');
    final core = <int>[];
    for (var i = 0; i < 3; i++) {
      if (i >= coreSplit.length) {
        core.add(0);
      } else {
        core.add(int.tryParse(coreSplit[i]) ?? 0);
      }
    }
    return (core: core, preRelease: pre);
  }
}
