import 'dart:convert';

import 'package:http/http.dart' as http;

class TeraBoxResolvedVideo {
  const TeraBoxResolvedVideo({
    required this.fileName,
    required this.playableUrl,
    this.size,
  });

  final String fileName;
  final String playableUrl;
  final String? size;
}

class TeraBoxResolver {
  const TeraBoxResolver();

  static const String _resolverBaseUrl =
      'https://tbx-proxy.shakir-ansarii075.workers.dev/';

  bool isTeraBoxUrl(String url) {
    final uri = Uri.tryParse(url.trim());

    if (uri == null || uri.host.isEmpty) {
      return false;
    }

    final host = uri.host.toLowerCase();

    return host.contains('terabox') ||
        host.contains('terasharelink') ||
        host.contains('teraboxshare');
  }

  Future<TeraBoxResolvedVideo> resolve(String shareUrl) async {
    final trimmedUrl = shareUrl.trim();

    if (!isTeraBoxUrl(trimmedUrl)) {
      throw Exception('This is not a valid TeraBox share link.');
    }

    final uri = Uri.parse(_resolverBaseUrl).replace(
      queryParameters: {
        'mode': 'resolve',
        'surl': trimmedUrl,
      },
    );

    final response = await http
        .get(
          uri,
          headers: const {
            'Accept': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'TeraBox resolver returned HTTP ${response.statusCode}.',
      );
    }

    final dynamic decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid TeraBox resolver response.');
    }

    final data = decoded['data'];

    if (data is! Map) {
      throw Exception(
        'The resolver did not return video information.',
      );
    }

    final fileName = data['name']?.toString() ?? 'TeraBox Video';

    final playableUrl = data['dlink']?.toString() ?? '';

    final sizeValue = data['size'];

    final size = sizeValue?.toString();

    if (playableUrl.isEmpty) {
      throw Exception(
        'No playable video URL was returned.',
      );
    }

    return TeraBoxResolvedVideo(
      fileName: fileName,
      playableUrl: playableUrl,
      size: size,
    );
  }
}