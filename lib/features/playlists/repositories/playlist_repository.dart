import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/models/app_user.dart';
import '../models/playlist_model.dart';

class PlaylistRepository {
  final FirebaseFirestore _firestore;

  PlaylistRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<Playlist>> watchUserPlaylists(String uid) {
    return _firestore
        .collection('playlists')
        .where('memberUids', arrayContains: uid)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => Playlist.fromFirestore(doc)).toList();
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return list;
    });
  }

  Stream<Playlist?> watchPlaylist(String playlistId) {
    return _firestore
        .collection('playlists')
        .doc(playlistId)
        .snapshots()
        .map((doc) => doc.exists ? Playlist.fromFirestore(doc) : null);
  }

  Future<String> createPlaylist({
    required String title,
    required AppUser user,
  }) async {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) throw Exception('Il titolo della playlist non può essere vuoto.');

    final memberInfo = MemberInfo(
      uid: user.uid,
      displayName: user.displayName,
      username: user.username,
      avatarSeed: user.avatarSeed,
      avatarColor: user.avatarColor,
      joinedAt: DateTime.now(),
    );

    final docRef = _firestore.collection('playlists').doc();
    final now = DateTime.now();

    final playlist = Playlist(
      id: docRef.id,
      title: cleanTitle,
      createdBy: user.uid,
      creatorName: user.displayName,
      memberUids: [user.uid],
      membersData: {user.uid: memberInfo},
      videoCount: 0,
      createdAt: now,
      updatedAt: now,
    );

    await docRef.set(playlist.toMap());
    return docRef.id;
  }

  Future<void> renamePlaylist({
    required String playlistId,
    required String newTitle,
  }) async {
    final cleanTitle = newTitle.trim();
    if (cleanTitle.isEmpty) throw Exception('Il titolo non può essere vuoto.');

    await _firestore.collection('playlists').doc(playlistId).update({
      'title': cleanTitle,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> leavePlaylist({
    required String playlistId,
    required String uid,
  }) async {
    await _firestore.collection('playlists').doc(playlistId).update({
      'memberUids': FieldValue.arrayRemove([uid]),
      'membersData.$uid': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deletePlaylistCascade(String playlistId) async {
    // 1. Elimina i video e le rispettive visualizzazioni
    final videosSnapshot = await _firestore
        .collection('playlists')
        .doc(playlistId)
        .collection('videos')
        .get();

    for (final videoDoc in videosSnapshot.docs) {
      final viewsSnapshot = await videoDoc.reference.collection('views').get();
      final batchViews = _firestore.batch();
      for (final viewDoc in viewsSnapshot.docs) {
        batchViews.delete(viewDoc.reference);
      }
      await batchViews.commit();
      await videoDoc.reference.delete();
    }

    // 2. Elimina gli inviti
    final invitesSnapshot = await _firestore
        .collection('playlists')
        .doc(playlistId)
        .collection('invites')
        .get();

    final batchInvites = _firestore.batch();
    for (final inviteDoc in invitesSnapshot.docs) {
      batchInvites.delete(inviteDoc.reference);
    }
    await batchInvites.commit();

    // 3. Elimina il documento della playlist
    await _firestore.collection('playlists').doc(playlistId).delete();
  }
}
