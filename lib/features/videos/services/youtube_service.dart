import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_keys.dart';

class YouTubeMetadata {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final int durationSec;

  const YouTubeMetadata({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    this.durationSec = 0,
  });
}

class YouTubeService {
  static final RegExp _idRegex = RegExp(
    r'(?:https?:\/\/)?(?:www\.|m\.)?(?:youtube\.com\/(?:watch\?v=|embed\/|v\/|shorts\/)|youtu\.be\/)([a-zA-Z0-9_-]{11})',
  );

  /// Estrae l'ID univoco di 11 caratteri da qualsiasi link YouTube o testo grezzo
  static String? extractVideoId(String input) {
    final trimmed = input.trim();
    if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(trimmed)) {
      return trimmed;
    }
    final match = _idRegex.firstMatch(trimmed);
    return match?.group(1);
  }

  /// Recupera i metadati chiamando direttamente YouTube Data API v3 con fallback resiliente
  static Future<YouTubeMetadata> fetchMetadata(String videoId) async {
    final cleanId = extractVideoId(videoId) ?? videoId;
    if (cleanId.length != 11) {
      throw Exception('ID video YouTube non valido.');
    }

    final apiKey = kIsWeb ? ApiKeys.youtubeWebKey : ApiKeys.youtubeAndroidKey;

    // Se l'utente ha configurato la chiave Google Cloud, proviamo l'endpoint ufficiale v3
    if (apiKey.isNotEmpty && !apiKey.startsWith('INSERISCI_')) {
      try {
        final url = Uri.parse(
          'https://www.googleapis.com/youtube/v3/videos?part=snippet,contentDetails&id=$cleanId&key=$apiKey',
        );
        final res = await http.get(url).timeout(const Duration(seconds: 8));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          final items = data['items'] as List<dynamic>? ?? [];
          if (items.isNotEmpty) {
            final item = items.first as Map<String, dynamic>;
            final snippet = item['snippet'] as Map<String, dynamic>? ?? {};
            final contentDetails = item['contentDetails'] as Map<String, dynamic>? ?? {};

            final title = snippet['title'] as String? ?? 'Video YouTube';
            final desc = snippet['description'] as String? ?? '';
            final thumbs = snippet['thumbnails'] as Map<String, dynamic>? ?? {};
            final bestThumb = (thumbs['maxres']?['url'] ??
                thumbs['high']?['url'] ??
                thumbs['medium']?['url'] ??
                thumbs['default']?['url'] ??
                'https://img.youtube.com/vi/$cleanId/hqdefault.jpg') as String;

            final durationIso = contentDetails['duration'] as String? ?? '';
            final durationSec = _parseIsoDuration(durationIso);

            return YouTubeMetadata(
              id: cleanId,
              title: title,
              description: desc.length > 300 ? '${desc.substring(0, 300)}...' : desc,
              thumbnailUrl: bestThumb,
              durationSec: durationSec,
            );
          }
        }
      } catch (e) {
        debugPrint('YouTube Data API v3 fallback: $e');
      }
    }

    // Fallback automatico via noembed.com (non richiede chiavi, quote illimitate, zero CORS)
    try {
      final noembedUrl = Uri.parse('https://noembed.com/embed?url=https://www.youtube.com/watch?v=$cleanId');
      final fallbackRes = await http.get(noembedUrl).timeout(const Duration(seconds: 8));
      if (fallbackRes.statusCode == 200) {
        final fallbackData = jsonDecode(fallbackRes.body) as Map<String, dynamic>;
        final title = fallbackData['title'] as String? ?? 'Video YouTube';
        return YouTubeMetadata(
          id: cleanId,
          title: title,
          description: 'Condiviso tramite ShareTime',
          thumbnailUrl: 'https://img.youtube.com/vi/$cleanId/hqdefault.jpg',
          durationSec: 0,
        );
      }
    } catch (_) {}

    // Fallback estremo di emergenza
    return YouTubeMetadata(
      id: cleanId,
      title: 'Video YouTube ($cleanId)',
      description: 'Link condiviso',
      thumbnailUrl: 'https://img.youtube.com/vi/$cleanId/hqdefault.jpg',
      durationSec: 0,
    );
  }

  /// Converte stringhe ISO 8601 (es. PT14M28S, PT1H2M10S) in secondi
  static int _parseIsoDuration(String iso) {
    if (iso.isEmpty) return 0;
    try {
      final match = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?').firstMatch(iso);
      if (match == null) return 0;
      final hours = int.tryParse(match.group(1) ?? '0') ?? 0;
      final minutes = int.tryParse(match.group(2) ?? '0') ?? 0;
      final seconds = int.tryParse(match.group(3) ?? '0') ?? 0;
      return (hours * 3600) + (minutes * 60) + seconds;
    } catch (_) {
      return 0;
    }
  }
}
