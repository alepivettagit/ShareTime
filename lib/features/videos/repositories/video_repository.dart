import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/models/app_user.dart';
import '../models/video_model.dart';
import '../services/youtube_service.dart';

class VideoRepository {
  final FirebaseFirestore _firestore;

  VideoRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Determina se il video è già stato visto dall'utente corrente.
  /// I video condivisi dall'utente stesso risultano visti di default (anche per i dati legacy),
  /// a meno che l'utente non li abbia esplicitamente segnati come non visti.
  static bool resolveIsWatched({
    required bool viewDocExists,
    required bool? viewDocWatched,
    required String sharedByUid,
    required String currentUid,
  }) {
    if (viewDocExists) {
      return viewDocWatched == true;
    }
    return sharedByUid.isNotEmpty && sharedByUid == currentUid;
  }

  Stream<List<VideoItem>> watchPlaylistVideos(String playlistId, String currentUid) {
    return _firestore
        .collection('playlists')
        .doc(playlistId)
        .collection('videos')
        .orderBy('sharedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final visibleDocs = snapshot.docs.where((doc) {
        final hiddenForUsers = (doc.data()['hiddenForUsers'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
        // Se l'utente ha nascosto il video per sé, non lo mostriamo nel suo feed
        return !hiddenForUsers.contains(currentUid);
      }).toList();

      return Future.wait(visibleDocs.map((doc) async {
        // Verifica stato visualizzazione personale in parallelo
        final viewDoc = await doc.reference.collection('views').doc(currentUid).get();
        final sharedByUid = doc.data()['sharedByUid'] as String? ?? '';
        final isWatched = resolveIsWatched(
          viewDocExists: viewDoc.exists,
          viewDocWatched: viewDoc.data()?['watched'] as bool?,
          sharedByUid: sharedByUid,
          currentUid: currentUid,
        );
        return VideoItem.fromFirestore(doc, isWatched: isWatched);
      }));
    });
  }

  Future<void> addVideo({
    required String playlistId,
    required String youtubeUrlOrId,
    required AppUser user,
  }) async {
    final videoId = YouTubeService.extractVideoId(youtubeUrlOrId);
    if (videoId == null) {
      throw Exception('Link YouTube non valido.');
    }

    // 1. Controllo duplicati nella playlist
    final existingQuery = await _firestore
        .collection('playlists')
        .doc(playlistId)
        .collection('videos')
        .where('youtubeId', isEqualTo: videoId)
        .limit(1)
        .get();

    if (existingQuery.docs.isNotEmpty) {
      throw Exception('Questo video è già presente nella playlist!');
    }

    // 2. Recupero metadati client-side (Zero Server/Functions)
    final meta = await YouTubeService.fetchMetadata(videoId);

    // 3. Batch write: crea video + incrementa contatore playlist
    final videoDocRef = _firestore
        .collection('playlists')
        .doc(playlistId)
        .collection('videos')
        .doc();

    final videoItem = VideoItem(
      id: videoDocRef.id,
      youtubeId: meta.id,
      title: meta.title,
      description: meta.description,
      thumbnailUrl: meta.thumbnailUrl,
      sharedByUid: user.uid,
      sharedByName: user.displayName,
      sharedByAvatarSeed: user.avatarSeed,
      sharedByAvatarColor: user.avatarColor,
      durationSec: meta.durationSec,
      sharedAt: DateTime.now(),
    );

    final batch = _firestore.batch();
    batch.set(videoDocRef, videoItem.toMap());
    // Segna automaticamente il video come già visto per l'autore che lo condivide
    batch.set(videoDocRef.collection('views').doc(user.uid), {
      'watched': true,
      'watchedAt': FieldValue.serverTimestamp(),
    });
    batch.update(_firestore.collection('playlists').doc(playlistId), {
      'videoCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<void> toggleWatched({
    required String playlistId,
    required String videoId,
    required String currentUid,
    required bool currentlyWatched,
  }) async {
    final viewRef = _firestore
        .collection('playlists')
        .doc(playlistId)
        .collection('videos')
        .doc(videoId)
        .collection('views')
        .doc(currentUid);

    // Scrive esplicitamente watched: true/false per distinguere un override manuale dai video legacy
    await viewRef.set({
      'watched': !currentlyWatched,
      'watchedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> hideVideoForUser({
    required String playlistId,
    required String videoId,
    required String currentUid,
  }) async {
    await _firestore
        .collection('playlists')
        .doc(playlistId)
        .collection('videos')
        .doc(videoId)
        .update({
      'hiddenForUsers': FieldValue.arrayUnion([currentUid]),
    });
  }

  Future<void> deleteVideo({
    required String playlistId,
    required String videoId,
  }) async {
    final videoRef = _firestore
        .collection('playlists')
        .doc(playlistId)
        .collection('videos')
        .doc(videoId);

    // Elimina sub-collezione views
    final views = await videoRef.collection('views').get();
    final batch = _firestore.batch();
    for (final v in views.docs) {
      batch.delete(v.reference);
    }
    batch.delete(videoRef);
    batch.update(_firestore.collection('playlists').doc(playlistId), {
      'videoCount': FieldValue.increment(-1),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }
}
