import 'dart:convert';

import 'package:http/http.dart' as http;

class ReleaseInfo {
  const ReleaseInfo({
    required this.tag,
    required this.url,
    required this.notes,
    required this.isPrerelease,
  });

  final String tag;
  final String url;
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
    if (current.preRelease == latest.preRelease) {
      return false;
    }
    return latest.preRelease.compareTo(current.preRelease) > 0;
  }

  ReleaseInfo? _toReleaseInfo(Map<String, dynamic> map) {
    final tag = (map['tag_name'] ?? '').toString().trim();
    if (tag.isEmpty) {
      return null;
    }
    final notes = (map['body'] ?? '').toString().trim();
    final assets = map['assets'];
    String url = (map['html_url'] ?? '').toString();
    if (assets is List) {
      for (final item in assets) {
        if (item is! Map<String, dynamic>) {
          continue;
        }
        final name = (item['name'] ?? '').toString().toLowerCase();
        if (!name.endsWith('.zip') &&
            !name.endsWith('.msix') &&
            !name.endsWith('.exe')) {
          continue;
        }
        final candidate = (item['browser_download_url'] ?? '').toString();
        if (candidate.isNotEmpty) {
          url = candidate;
          break;
        }
      }
    }
    if (url.isEmpty) {
      return null;
    }
    return ReleaseInfo(
      tag: tag,
      url: url,
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
