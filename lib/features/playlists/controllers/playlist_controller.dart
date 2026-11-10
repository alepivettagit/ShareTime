import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/controllers/auth_controller.dart';
import '../models/playlist_model.dart';
import '../repositories/playlist_repository.dart';

final playlistRepositoryProvider = Provider<PlaylistRepository>((ref) {
  return PlaylistRepository();
});

final userPlaylistsProvider = StreamProvider<List<Playlist>>((ref) {
  final authUser = ref.watch(currentUserDataProvider).value;
  if (authUser == null) return Stream.value([]);
  return ref.watch(playlistRepositoryProvider).watchUserPlaylists(authUser.uid);
});

final playlistDetailProvider = StreamProvider.family<Playlist?, String>((ref, playlistId) {
  return ref.watch(playlistRepositoryProvider).watchPlaylist(playlistId);
});

class PlaylistController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  PlaylistRepository get _repository => ref.read(playlistRepositoryProvider);

  Future<String?> createPlaylist(String title) async {
    final user = ref.read(currentUserDataProvider).value;
    if (user == null) return null;

    state = const AsyncValue.loading();
    String? createdId;
    state = await AsyncValue.guard(() async {
      createdId = await _repository.createPlaylist(title: title, user: user);
    });
    return createdId;
  }

  Future<void> renamePlaylist(String playlistId, String newTitle) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.renamePlaylist(
          playlistId: playlistId,
          newTitle: newTitle,
        ));
  }

  Future<void> leavePlaylist(String playlistId) async {
    final user = ref.read(currentUserDataProvider).value;
    if (user == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.leavePlaylist(
          playlistId: playlistId,
          uid: user.uid,
        ));
  }

  Future<void> deletePlaylist(String playlistId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.deletePlaylistCascade(playlistId));
  }
}

final playlistControllerProvider = NotifierProvider<PlaylistController, AsyncValue<void>>(PlaylistController.new);
