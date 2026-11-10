import 'package:flutter_test/flutter_test.dart';
import 'package:sharetime/features/videos/services/youtube_service.dart';

void main() {
  group('YouTube URL Parser', () {
    test('estrae ID da formato standard watch?v=', () {
      final id = YouTubeService.extractVideoId('https://www.youtube.com/watch?v=dQw4w9WgXcQ');
      expect(id, equals('dQw4w9WgXcQ'));
    });

    test('estrae ID da formato short youtu.be/', () {
      final id = YouTubeService.extractVideoId('https://youtu.be/dQw4w9WgXcQ?si=abcdef');
      expect(id, equals('dQw4w9WgXcQ'));
    });

    test('estrae ID da formato YouTube Shorts', () {
      final id = YouTubeService.extractVideoId('https://www.youtube.com/shorts/dQw4w9WgXcQ');
      expect(id, equals('dQw4w9WgXcQ'));
    });

    test('accetta ID puro di 11 caratteri', () {
      final id = YouTubeService.extractVideoId('dQw4w9WgXcQ');
      expect(id, equals('dQw4w9WgXcQ'));
    });

    test('rifiuta stringhe non conformi', () {
      final id = YouTubeService.extractVideoId('https://google.com/test');
      expect(id, isNull);
    });
  });
}
