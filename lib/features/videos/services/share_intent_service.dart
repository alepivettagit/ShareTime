import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import '../../../core/theme/app_theme.dart';
import '../../playlists/controllers/playlist_controller.dart';
import '../controllers/video_controller.dart';
import 'youtube_service.dart';

class ShareIntentService {
  static StreamSubscription? _intentSub;

  /// Inizializza l'ascoltatore di condivisioni esterne (es. da YouTube app)
  static void init(BuildContext context, WidgetRef ref) {
    if (kIsWeb) return; // Su Web l'intent è gestito via query parameters / manifest PWA

    // Quando l'app è già aperta in memoria
    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        _handleSharedFiles(context, ref, value);
      }
    }, onError: (err) {
      debugPrint('Errore receive_sharing_intent stream: $err');
    });

    // Quando l'app viene avviata da zero tramite menu condividi
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        _handleSharedFiles(context, ref, value);
        ReceiveSharingIntent.instance.reset();
      }
    });
  }

  static void dispose() {
    _intentSub?.cancel();
  }

  static void _handleSharedFiles(
    BuildContext context,
    WidgetRef ref,
    List<SharedMediaFile> files,
  ) {
    final textOrUrl = files.first.path;
    final videoId = YouTubeService.extractVideoId(textOrUrl);
    if (videoId == null) return;

    _showTargetPlaylistSheet(context, ref, textOrUrl);
  }

  static void _showTargetPlaylistSheet(
    BuildContext context,
    WidgetRef ref,
    String videoUrl,
  ) {
    final playlists = ref.read(userPlaylistsProvider).value ?? [];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: AppColors.borderSubtle, width: 1.2),
      ),
      builder: (bottomSheetCtx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  Icon(Icons.share_rounded, color: AppColors.primaryCyan),
                  SizedBox(width: 10),
                  Text(
                    'Aggiungi a una Playlist',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (playlists.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Non hai ancora nessuna playlist.\nCreane una prima di condividere video.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: playlists.length,
                    itemBuilder: (ctx, i) {
                      final p = playlists[i];
                      return ListTile(
                        leading: const Icon(Icons.playlist_play_rounded, color: AppColors.primaryCyan),
                        title: Text(p.title, style: const TextStyle(color: AppColors.textPrimary)),
                        subtitle: Text('${p.videoCount} video', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        onTap: () async {
                          Navigator.of(bottomSheetCtx).pop();
                          try {
                            await ref.read(videoControllerProvider.notifier).addVideo(
                                  playlistId: p.id,
                                  urlOrId: videoUrl,
                                );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Video aggiunto a "${p.title}"!')),
                              );
                              context.push('/playlist/${p.id}');
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Errore: $e'), backgroundColor: AppColors.accentCoral),
                              );
                            }
                          }
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
