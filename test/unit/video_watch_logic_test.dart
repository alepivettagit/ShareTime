import 'package:flutter_test/flutter_test.dart';
import 'package:sharetime/features/videos/repositories/video_repository.dart';

void main() {
  group('VideoRepository.resolveIsWatched', () {
    test('marks video shared by friend without viewDoc as unwatched (da vedere)', () {
      final result = VideoRepository.resolveIsWatched(
        viewDocExists: false,
        viewDocWatched: null,
        sharedByUid: 'friend_uid',
        currentUid: 'my_uid',
      );
      expect(result, isFalse);
    });

    test('marks video shared by current user without viewDoc (new or legacy) as watched', () {
      final result = VideoRepository.resolveIsWatched(
        viewDocExists: false,
        viewDocWatched: null,
        sharedByUid: 'my_uid',
        currentUid: 'my_uid',
      );
      expect(result, isTrue);
    });

    test('returns true when viewDoc exists with watched=true', () {
      final result = VideoRepository.resolveIsWatched(
        viewDocExists: true,
        viewDocWatched: true,
        sharedByUid: 'friend_uid',
        currentUid: 'my_uid',
      );
      expect(result, isTrue);
    });

    test('respects explicit override when sharer manually sets watched=false', () {
      final result = VideoRepository.resolveIsWatched(
        viewDocExists: true,
        viewDocWatched: false,
        sharedByUid: 'my_uid',
        currentUid: 'my_uid',
      );
      expect(result, isFalse);
    });

    test('returns false when sharedByUid and currentUid are both empty and no viewDoc', () {
      final result = VideoRepository.resolveIsWatched(
        viewDocExists: false,
        viewDocWatched: null,
        sharedByUid: '',
        currentUid: '',
      );
      expect(result, isFalse);
    });
  });
}
