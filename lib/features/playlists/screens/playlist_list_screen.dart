import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../avatar/avatar_widget.dart';
import '../controllers/playlist_controller.dart';
import 'create_playlist_dialog.dart';

class PlaylistListScreen extends ConsumerWidget {
  const PlaylistListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(userPlaylistsProvider);
    final currentUser = ref.watch(currentUserDataProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primaryCyan.withOpacity(0.5)),
              ),
              child: const Icon(Icons.radar_rounded, color: AppColors.primaryCyan, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('ShareTime'),
          ],
        ),
        actions: [
          if (currentUser != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: AvatarWidget(
                seed: currentUser.avatarSeed,
                colorHex: currentUser.avatarColor,
                size: 34,
                onTap: () => context.go('/profile'),
              ),
            ),
        ],
      ),
      body: playlistsAsync.when(
        data: (playlists) {
          if (playlists.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.borderSubtle, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.sensors_off_rounded,
                        size: 56,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Nessuna Playlist Trovata',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Crea la tua prima playlist condivisa con gli amici oppure fatti inviare un link d\'invito.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: AppColors.textMuted, height: 1.4),
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final id = await CreatePlaylistDialog.show(context);
                        if (id != null && context.mounted) {
                          context.push('/playlist/$id');
                        }
                      },
                      icon: const Icon(Icons.add, size: 20),
                      label: const Text('Crea Nuova Playlist'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              final playlist = playlists[index];
              final isCreator = currentUser != null && playlist.createdBy == currentUser.uid;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle, width: 1),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => context.push('/playlist/${playlist.id}'),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                playlist.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.primaryCyan.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.video_library_outlined, size: 14, color: AppColors.primaryCyan),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${playlist.videoCount}',
                                    style: const TextStyle(
                                      color: AppColors.primaryCyan,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            // Avatars dei membri
                            SizedBox(
                              height: 30,
                              child: ListView(
                                shrinkWrap: true,
                                scrollDirection: Axis.horizontal,
                                children: playlist.membersData.values.take(5).map((m) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: AvatarWidget(
                                      seed: m.avatarSeed,
                                      colorHex: m.avatarColor,
                                      size: 28,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              isCreator ? 'Creata da te' : 'Creata da ${playlist.creatorName}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryCyan),
        ),
        error: (err, stack) => Center(
          child: Text('Errore nel caricamento: $err', style: const TextStyle(color: AppColors.accentCoral)),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final id = await CreatePlaylistDialog.show(context);
          if (id != null && context.mounted) {
            context.push('/playlist/$id');
          }
        },
        backgroundColor: AppColors.primaryCyan,
        foregroundColor: AppColors.bgDark,
        elevation: 4,
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }
}
