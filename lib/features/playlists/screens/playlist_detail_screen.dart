import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../avatar/avatar_widget.dart';
import '../../invite/services/invite_service.dart';
import '../../videos/controllers/video_controller.dart';
import '../../videos/models/video_model.dart';
import '../../videos/services/youtube_service.dart';
import '../../videos/widgets/video_card.dart';
import '../controllers/playlist_controller.dart';
import '../models/playlist_model.dart';

class PlaylistDetailScreen extends ConsumerStatefulWidget {
  final String playlistId;

  const PlaylistDetailScreen({super.key, required this.playlistId});

  @override
  ConsumerState<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends ConsumerState<PlaylistDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedMemberUid; // null = "Tutti"

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showInviteDialog(Playlist playlist) async {
    final inviteService = InviteService();
    try {
      final inviteUrl = await inviteService.createInvite(
        playlistId: playlist.id,
        creatorUid: playlist.createdBy,
      );

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.borderSubtle, width: 1.2),
          ),
          title: const Row(
            children: [
              Icon(Icons.person_add_alt_1_rounded, color: AppColors.primaryCyan),
              SizedBox(width: 10),
              Text('Invita Amici', style: TextStyle(color: AppColors.textPrimary)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Condividi questo link con i tuoi amici. Aprendolo, potranno entrare direttamente nella playlist!',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: SelectableText(
                  inviteUrl,
                  style: const TextStyle(
                    color: AppColors.primaryCyan,
                    fontSize: 13,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Chiudi', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: inviteUrl));
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link di invito copiato negli appunti!')),
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text('Copia Link'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore invito: $e'), backgroundColor: AppColors.accentCoral),
        );
      }
    }
  }

  Future<void> _showAddVideoDialog() async {
    final urlController = TextEditingController();
    YouTubeMetadata? previewMeta;
    bool isSearching = false;
    String? searchError;

    await showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surfaceDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.borderSubtle, width: 1.2),
              ),
              title: const Row(
                children: [
                  Icon(Icons.video_call_rounded, color: AppColors.primaryCyan),
                  SizedBox(width: 10),
                  Text('Aggiungi Video YouTube', style: TextStyle(color: AppColors.textPrimary, fontSize: 18)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: urlController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Incolla link o ID YouTube',
                        hintText: 'es. https://youtu.be/...',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search, color: AppColors.primaryCyan),
                          onPressed: () async {
                            final input = urlController.text.trim();
                            final videoId = YouTubeService.extractVideoId(input);
                            if (videoId == null) {
                              setDialogState(() {
                                searchError = 'Link YouTube non valido.';
                                previewMeta = null;
                              });
                              return;
                            }
                            setDialogState(() {
                              isSearching = true;
                              searchError = null;
                            });
                            try {
                              final meta = await YouTubeService.fetchMetadata(videoId);
                              setDialogState(() {
                                previewMeta = meta;
                                isSearching = false;
                              });
                            } catch (err) {
                              setDialogState(() {
                                searchError = err.toString();
                                isSearching = false;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    if (isSearching)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator(color: AppColors.primaryCyan)),
                      ),
                    if (searchError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(searchError!, style: const TextStyle(color: AppColors.accentCoral, fontSize: 13)),
                      ),
                    if (previewMeta != null) ...[
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.network(previewMeta!.thumbnailUrl, fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        previewMeta!.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Annulla', style: TextStyle(color: AppColors.textMuted)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final input = urlController.text.trim();
                    if (input.isEmpty) return;

                    Navigator.of(dialogCtx).pop();
                    try {
                      await ref.read(videoControllerProvider.notifier).addVideo(
                            playlistId: widget.playlistId,
                            urlOrId: input,
                          );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Video aggiunto alla playlist!')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Errore: $e'), backgroundColor: AppColors.accentCoral),
                        );
                      }
                    }
                  },
                  child: const Text('Aggiungi'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final playlistAsync = ref.watch(playlistDetailProvider(widget.playlistId));
    final videosAsync = ref.watch(playlistVideosProvider(widget.playlistId));
    final currentUser = ref.watch(currentUserDataProvider).value;

    return playlistAsync.when(
      data: (playlist) {
        if (playlist == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Playlist non trovata o rimossa.')),
          );
        }

        final isCreator = currentUser != null && playlist.createdBy == currentUser.uid;
        final currentVideos = videosAsync.value ?? const <VideoItem>[];
        final unwatchedCount = currentVideos.where((v) {
          final matchesMember = _selectedMemberUid == null || v.sharedByUid == _selectedMemberUid;
          return matchesMember && !v.isWatched;
        }).length;

        return Scaffold(
          appBar: AppBar(
            title: Text(playlist.title),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_add_alt_1_outlined, color: AppColors.primaryCyan),
                tooltip: 'Invita amici',
                onPressed: () => _showInviteDialog(playlist),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
                color: AppColors.surfaceElevated,
                onSelected: (val) async {
                  if (val == 'leave') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppColors.surfaceDark,
                        title: const Text('Esci dalla playlist'),
                        content: const Text('Vuoi davvero lasciare questa playlist condivisa?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annulla')),
                          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Esci')),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await ref.read(playlistControllerProvider.notifier).leavePlaylist(playlist.id);
                      if (context.mounted) context.pop();
                    }
                  } else if (val == 'delete') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppColors.surfaceDark,
                        title: const Text('Elimina playlist'),
                        content: const Text('Sei sicuro? La playlist e tutti i video saranno cancellati per tutti.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annulla')),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentCoral),
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Elimina'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await ref.read(playlistControllerProvider.notifier).deletePlaylist(playlist.id);
                      if (context.mounted) context.pop();
                    }
                  }
                },
                itemBuilder: (ctx) => [
                  if (!isCreator)
                    const PopupMenuItem(value: 'leave', child: Text('Esci dalla playlist')),
                  if (isCreator)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Elimina playlist', style: TextStyle(color: AppColors.accentCoral)),
                    ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              // 1. Chip Membri Orizzontali
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(vertical: 8),
                color: AppColors.bgDark,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Chip "Tutti"
                    ChoiceChip(
                      selected: _selectedMemberUid == null,
                      onSelected: (selected) {
                        setState(() => _selectedMemberUid = null);
                      },
                      avatar: const Icon(Icons.group_outlined, size: 18, color: AppColors.primaryCyan),
                      label: const Text('Tutti'),
                      selectedColor: AppColors.primaryCyan.withOpacity(0.2),
                      backgroundColor: AppColors.surfaceDark,
                      labelStyle: TextStyle(
                        color: _selectedMemberUid == null ? AppColors.primaryCyan : AppColors.textMuted,
                        fontWeight: _selectedMemberUid == null ? FontWeight.w700 : FontWeight.w500,
                      ),
                      side: BorderSide(
                        color: _selectedMemberUid == null ? AppColors.primaryCyan : AppColors.borderSubtle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Chip per ogni membro
                    ...playlist.membersData.values.map((member) {
                      final isSelected = _selectedMemberUid == member.uid;
                      final isMe = currentUser != null && member.uid == currentUser.uid;
                      final label = isMe ? 'Tu' : member.displayName;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedMemberUid = selected ? member.uid : null;
                            });
                          },
                          avatar: AvatarWidget(
                            seed: member.avatarSeed,
                            colorHex: member.avatarColor,
                            size: 22,
                          ),
                          label: Text(label),
                          selectedColor: AppColors.parseHex(member.avatarColor).withOpacity(0.2),
                          backgroundColor: AppColors.surfaceDark,
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.textPrimary : AppColors.textMuted,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.parseHex(member.avatarColor)
                                : AppColors.borderSubtle,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              // 2. Sezioni Tab: [Da vedere] | [Già visti] | [Condivisi da ...]
              Container(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.borderSubtle, width: 1)),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.primaryCyan,
                  indicatorWeight: 2.5,
                  labelColor: AppColors.primaryCyan,
                  unselectedLabelColor: AppColors.textMuted,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  tabs: [
                    Tab(text: unwatchedCount > 0 ? 'Da vedere ($unwatchedCount)' : 'Da vedere'),
                    const Tab(text: 'Già visti'),
                    Tab(
                      text: _selectedMemberUid == null
                          ? 'Tutti i video'
                          : (_selectedMemberUid == currentUser?.uid
                              ? 'I miei video'
                              : 'Condivisi'),
                    ),
                  ],
                ),
              ),

              // 3. Feed Video
              Expanded(
                child: videosAsync.when(
                  data: (videos) {
                    return TabBarView(
                      controller: _tabController,
                      children: [
                        // Tab 1: Da vedere
                        _buildVideoList(
                          videos.where((v) {
                            final matchesMember = _selectedMemberUid == null || v.sharedByUid == _selectedMemberUid;
                            return matchesMember && !v.isWatched;
                          }).toList(),
                          playlist,
                          currentUser?.uid ?? '',
                          emptyMsg: 'Ottimo lavoro! Nessun video da vedere in questa cerchia.',
                        ),
                        // Tab 2: Già visti
                        _buildVideoList(
                          videos.where((v) {
                            final matchesMember = _selectedMemberUid == null || v.sharedByUid == _selectedMemberUid;
                            return matchesMember && v.isWatched;
                          }).toList(),
                          playlist,
                          currentUser?.uid ?? '',
                          emptyMsg: 'Non hai ancora segnato nessun video come già visto.',
                        ),
                        // Tab 3: Condivisi
                        _buildVideoList(
                          videos.where((v) {
                            if (_selectedMemberUid == null) return true;
                            return v.sharedByUid == _selectedMemberUid;
                          }).toList(),
                          playlist,
                          currentUser?.uid ?? '',
                          emptyMsg: 'Nessun video condiviso da questo membro.',
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primaryCyan),
                  ),
                  error: (err, _) => Center(
                    child: Text('Errore caricamento video: $err', style: const TextStyle(color: AppColors.accentCoral)),
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _showAddVideoDialog,
            backgroundColor: AppColors.primaryCyan,
            foregroundColor: AppColors.bgDark,
            elevation: 4,
            child: const Icon(Icons.add_rounded, size: 28),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryCyan)),
      ),
      error: (err, _) => Scaffold(
        body: Center(child: Text('Errore: $err')),
      ),
    );
  }

  Widget _buildVideoList(
    List<VideoItem> videos,
    Playlist playlist,
    String currentUid, {
    required String emptyMsg,
  }) {
    if (videos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.playlist_play_rounded, size: 48, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text(
                emptyMsg,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    final isCreator = playlist.createdBy == currentUid;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];
        return VideoCard(
          video: video,
          currentUid: currentUid,
          isCreator: isCreator,
          onToggleWatched: () {
            ref.read(videoControllerProvider.notifier).toggleWatched(
                  playlistId: playlist.id,
                  videoId: video.id,
                  currentlyWatched: video.isWatched,
                );
          },
          onHide: () {
            ref.read(videoControllerProvider.notifier).hideVideo(
                  playlistId: playlist.id,
                  videoId: video.id,
                );
          },
          onDelete: () {
            ref.read(videoControllerProvider.notifier).deleteVideo(
                  playlistId: playlist.id,
                  videoId: video.id,
                );
          },
        );
      },
    );
  }
}
