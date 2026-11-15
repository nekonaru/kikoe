/// Update checker: compares the installed version against the latest GitHub
/// release tag. Used by the About screen ("tap version to check for updates").
library;

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class UpdateCheckResult {
  const UpdateCheckResult._(this.status, {this.latestVersion, this.releaseUrl});

  final UpdateStatus status;
  final String? latestVersion;
  final String? releaseUrl;

  factory UpdateCheckResult.upToDate() =>
      const UpdateCheckResult._(UpdateStatus.upToDate);
  factory UpdateCheckResult.updateAvailable(String version, String url) =>
      UpdateCheckResult._(UpdateStatus.updateAvailable,
          latestVersion: version, releaseUrl: url);
  factory UpdateCheckResult.failed() =>
      const UpdateCheckResult._(UpdateStatus.failed);
}

enum UpdateStatus { upToDate, updateAvailable, failed }

class UpdateChecker {
  UpdateChecker._();

  static final instance = UpdateChecker._();

  static const _apiUrl = 'https://api.github.com/repos/nekonaru/kikoe/releases/latest';
  static const releasesUrl = 'https://github.com/nekonaru/kikoe/releases/latest';

  Future<bool> isNewer(String remoteTag, String current) async {
    List<int> parts(String v) => v
        .replaceAll(RegExp(r'^[vV]'), '')
        .split('.')
        .map((p) => int.tryParse(p.replaceAll(RegExp(r'[^0-9].*$'), '')) ?? 0)
        .toList();
    final r = parts(remoteTag);
    final c = parts(current);
    for (var i = 0; i < 3; i++) {
      final rv = i < r.length ? r[i] : 0;
      final cv = i < c.length ? c[i] : 0;
      if (rv > cv) return true;
      if (rv < cv) return false;
    }
    return false;
  }

  Future<UpdateCheckResult> check(String currentVersion) async {
    try {
      final response = await http
          .get(Uri.parse(_apiUrl), headers: {
            'User-Agent': 'kikoe-app',
            'Accept': 'application/vnd.github+json',
          })
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return UpdateCheckResult.failed();
      final map = jsonDecode(response.body) as Map<String, dynamic>;
      final tag = map['tag_name'] as String?;
      final url = (map['html_url'] as String?) ?? releasesUrl;
      if (tag == null) return UpdateCheckResult.failed();
      if (await isNewer(tag, currentVersion)) {
        return UpdateCheckResult.updateAvailable(tag.replaceAll(RegExp(r'^[vV]'), ''), url);
      }
      return UpdateCheckResult.upToDate();
    } on TimeoutException {
      return UpdateCheckResult.failed();
    } catch (_) {
      return UpdateCheckResult.failed();
    }
  }
}
