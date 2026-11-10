import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../../auth/models/app_user.dart';
import '../../playlists/models/playlist_model.dart';

class InviteService {
  final FirebaseFirestore _firestore;

  InviteService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static String generateRandomToken([int length = 20]) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random.secure();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  /// Crea un link d'invito sicuro valido per 7 giorni
  Future<String> createInvite({
    required String playlistId,
    required String creatorUid,
  }) async {
    final token = generateRandomToken(20);
    final expiresAt = DateTime.now().add(const Duration(days: 7));

    await _firestore
        .collection('playlists')
        .doc(playlistId)
        .collection('invites')
        .doc(token)
        .set({
      'token': token,
      'playlistId': playlistId,
      'createdBy': creatorUid,
      'expiresAt': Timestamp.fromDate(expiresAt),
      'revoked': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final projectId = Firebase.app().options.projectId;
    final isHostedWeb = kIsWeb &&
        Uri.base.host.isNotEmpty &&
        Uri.base.host != 'localhost' &&
        Uri.base.host != '127.0.0.1';
    final baseUrl = isHostedWeb ? Uri.base.origin : 'https://$projectId.web.app';
    return '$baseUrl/invite/$token';
  }

  /// Risolve il token d'invito e inserisce in modo sicuro il membro nella playlist
  Future<String> joinPlaylist({
    required String token,
    required AppUser user,
  }) async {
    // Cerchiamo l'invito tramite collectionGroup 'invites'
    final query = await _firestore
        .collectionGroup('invites')
        .where('token', isEqualTo: token.trim())
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw Exception('Link di invito non valido o inesistente.');
    }

    final inviteDoc = query.docs.first;
    final data = inviteDoc.data();
    final revoked = data['revoked'] as bool? ?? false;
    final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final playlistId = data['playlistId'] as String;

    if (revoked) {
      throw Exception('Questo link di invito è stato revocato dal creatore.');
    }

    if (DateTime.now().isAfter(expiresAt)) {
      throw Exception('Questo link di invito è scaduto.');
    }

    // Aggiunta atomica del membro alla playlist
    final memberInfo = MemberInfo(
      uid: user.uid,
      displayName: user.displayName,
      username: user.username,
      avatarSeed: user.avatarSeed,
      avatarColor: user.avatarColor,
      joinedAt: DateTime.now(),
    );

    await _firestore.collection('playlists').doc(playlistId).update({
      'memberUids': FieldValue.arrayUnion([user.uid]),
      'membersData.${user.uid}': memberInfo.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return playlistId;
  }
}
