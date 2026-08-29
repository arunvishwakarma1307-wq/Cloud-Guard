import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.version,
    required this.downloadUrl,
    required this.releaseNotes,
  });

  final String version;
  final String downloadUrl;
  final String releaseNotes;
}

class AppUpdateChecker {
  AppUpdateChecker({http.Client? client}) : _client = client ?? http.Client();

  static final Uri manifestUri = Uri.parse(
    'https://raw.githubusercontent.com/arunvishwakarma1307-wq/Cloud-Guard/main/update_manifest.json',
  );

  static const String trustedGitHubHost = 'github.com';
  static const String trustedRepositoryPath =
      '/arunvishwakarma1307-wq/Cloud-Guard/';

  final http.Client _client;

  Future<AppUpdateInfo?> checkForAndroidUpdate() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final response = await _client
          .get(manifestUri)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;

      final latestVersion = decoded['version'];
      final downloadUrl = decoded['downloadUrl'];
      final releaseNotes = decoded['releaseNotes'];

      if (latestVersion is! String ||
          downloadUrl is! String ||
          !isTrustedDownloadUrl(downloadUrl)) {
        return null;
      }

      if (compareVersions(
            latestVersion,
            packageInfo.version,
            packageInfo.buildNumber,
          ) <=
          0) {
        return null;
      }

      return AppUpdateInfo(
        version: latestVersion,
        downloadUrl: downloadUrl,
        releaseNotes: releaseNotes is String
            ? releaseNotes
            : 'Bug fixes and improvements.',
      );
    } catch (_) {
      // Update checks must never block or break the existing app.
      return null;
    }
  }

  Future<bool> openDownloadUrl(String downloadUrl) async {
    if (!isTrustedDownloadUrl(downloadUrl)) return false;
    return launchUrl(
      Uri.parse(downloadUrl),
      mode: LaunchMode.externalApplication,
    );
  }

  static bool isTrustedDownloadUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme != 'https') return false;
    if (uri.host != trustedGitHubHost) return false;
    return uri.path.startsWith(trustedRepositoryPath) &&
        uri.path.contains('/releases/');
  }

  static int compareVersions(
    String latest,
    String currentVersion,
    String currentBuildNumber,
  ) {
    final latestParts = parseVersion(latest);
    final currentParts = parseVersion('$currentVersion+$currentBuildNumber');

    for (var index = 0; index < 4; index++) {
      final latestValue = latestParts[index];
      final currentValue = currentParts[index];
      if (latestValue != currentValue) {
        return latestValue.compareTo(currentValue);
      }
    }

    return 0;
  }

  static List<int> parseVersion(String value) {
    final normalized = value.trim().replaceFirst(RegExp(r'^v'), '');
    final pieces = normalized.split('+');
    final semanticParts = pieces.first.split('.');
    final buildPart = pieces.length > 1 ? pieces[1] : '0';

    return <int>[
      _parseNumber(semanticParts, 0),
      _parseNumber(semanticParts, 1),
      _parseNumber(semanticParts, 2),
      int.tryParse(buildPart) ?? 0,
    ];
  }

  static int _parseNumber(List<String> values, int index) {
    if (index >= values.length) return 0;
    return int.tryParse(values[index]) ?? 0;
  }

  void dispose() {
    _client.close();
  }
}
