import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/controllers/auth_controller.dart';
import '../models/video_model.dart';
import '../repositories/video_repository.dart';

final videoRepositoryProvider = Provider<VideoRepository>((ref) {
  return VideoRepository();
});

final playlistVideosProvider = StreamProvider.family<List<VideoItem>, String>((ref, playlistId) {
  final user = ref.watch(currentUserDataProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(videoRepositoryProvider).watchPlaylistVideos(playlistId, user.uid);
});

class VideoController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  VideoRepository get _repository => ref.read(videoRepositoryProvider);

  Future<void> addVideo({
    required String playlistId,
    required String urlOrId,
  }) async {
    final user = ref.read(currentUserDataProvider).value;
    if (user == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.addVideo(
          playlistId: playlistId,
          youtubeUrlOrId: urlOrId,
          user: user,
        ));
  }

  Future<void> toggleWatched({
    required String playlistId,
    required String videoId,
    required bool currentlyWatched,
  }) async {
    final user = ref.read(currentUserDataProvider).value;
    if (user == null) return;

    await _repository.toggleWatched(
      playlistId: playlistId,
      videoId: videoId,
      currentUid: user.uid,
      currentlyWatched: currentlyWatched,
    );
    // Ri-sincronizza lo stream dei video perché la scrittura su views/{uid} non notifica il padre videos
    ref.invalidate(playlistVideosProvider(playlistId));
  }

  Future<void> hideVideo({
    required String playlistId,
    required String videoId,
  }) async {
    final user = ref.read(currentUserDataProvider).value;
    if (user == null) return;

    await _repository.hideVideoForUser(
      playlistId: playlistId,
      videoId: videoId,
      currentUid: user.uid,
    );
  }

  Future<void> deleteVideo({
    required String playlistId,
    required String videoId,
  }) async {
    await _repository.deleteVideo(
      playlistId: playlistId,
      videoId: videoId,
    );
  }
}

final videoControllerProvider = NotifierProvider<VideoController, AsyncValue<void>>(VideoController.new);
