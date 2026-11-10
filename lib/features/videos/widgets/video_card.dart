import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../avatar/avatar_widget.dart';
import '../models/video_model.dart';

class VideoCard extends StatelessWidget {
  final VideoItem video;
  final String currentUid;
  final bool isCreator;
  final VoidCallback onToggleWatched;
  final VoidCallback onHide;
  final VoidCallback onDelete;

  const VideoCard({
    super.key,
    required this.video,
    required this.currentUid,
    required this.isCreator,
    required this.onToggleWatched,
    required this.onHide,
    required this.onDelete,
  });

  Future<void> _openYouTube() async {
    final uri = Uri.parse('https://www.youtube.com/watch?v=${video.youtubeId}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}g fa';
    if (diff.inHours > 0) return '${diff.inHours}h fa';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m fa';
    return 'adesso';
  }

  @override
  Widget build(BuildContext context) {
    final isMyVideo = video.sharedByUid == currentUid;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: video.isWatched
              ? AppColors.borderSubtle.withOpacity(0.5)
              : AppColors.borderSubtle,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Thumbnail 16:9 con badge durata
          GestureDetector(
            onTap: _openYouTube,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      video.thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppColors.surfaceElevated,
                        child: const Icon(Icons.movie_creation_outlined, color: AppColors.textMuted, size: 48),
                      ),
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: AppColors.surfaceElevated,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryCyan),
                          ),
                        );
                      },
                    ),
                    // Sfumatura gradiente scuro sul fondo dell'immagine
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 48,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppColors.bgDark.withOpacity(0.85),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Badge Durata (se presente)
                    if (video.formattedDuration.isNotEmpty)
                      Positioned(
                        right: 12,
                        bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white.withOpacity(0.15)),
                          ),
                          child: Text(
                            video.formattedDuration,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    // Pulsante Play centrale
                    Center(
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primaryCyan.withOpacity(0.8), width: 1.5),
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: AppColors.primaryCyan,
                          size: 32,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Info Video & Metadati
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        video.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          height: 1.25,
                        ),
                      ),
                    ),
                    // Menu Opzioni
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: AppColors.textMuted, size: 20),
                      color: AppColors.surfaceElevated,
                      onSelected: (val) {
                        if (val == 'hide') onHide();
                        if (val == 'delete') onDelete();
                      },
                      itemBuilder: (context) => [
                        if (!isMyVideo)
                          const PopupMenuItem(
                            value: 'hide',
                            child: Row(
                              children: [
                                Icon(Icons.visibility_off_outlined, size: 18, color: AppColors.textMuted),
                                SizedBox(width: 8),
                                Text('Nascondi per me'),
                              ],
                            ),
                          ),
                        if (isMyVideo || isCreator)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, size: 18, color: AppColors.accentCoral),
                                SizedBox(width: 8),
                                Text('Elimina video', style: TextStyle(color: AppColors.accentCoral)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Membro che ha condiviso + Data
                Row(
                  children: [
                    AvatarWidget(
                      seed: video.sharedByAvatarSeed,
                      colorHex: video.sharedByAvatarColor,
                      size: 26,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Condiviso da ${isMyVideo ? 'te' : video.sharedByName} • ${_formatTimeAgo(video.sharedAt)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Pulsanti di Azione
                Row(
                  children: [
                    // Apri su YouTube
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _openYouTube,
                        icon: const Icon(Icons.play_circle_outline, size: 18),
                        label: const Text('Apri su YouTube'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          backgroundColor: AppColors.primaryCyan,
                          foregroundColor: AppColors.bgDark,
                          elevation: 0,
                          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Toggle "Visto"
                    OutlinedButton.icon(
                      onPressed: onToggleWatched,
                      icon: Icon(
                        video.isWatched ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                        size: 16,
                        color: video.isWatched ? AppColors.accentGreen : AppColors.textMuted,
                      ),
                      label: Text(
                        video.isWatched ? 'Visto' : 'Segna visto',
                        style: TextStyle(
                          color: video.isWatched ? AppColors.accentGreen : AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        side: BorderSide(
                          color: video.isWatched ? AppColors.accentGreen : AppColors.borderSubtle,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
