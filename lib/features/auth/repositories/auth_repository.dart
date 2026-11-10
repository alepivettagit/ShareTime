import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<AppUser?> getCurrentUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists || doc.data() == null) return null;

    return AppUser.fromMap(doc.data()!, user.uid);
  }

  Stream<AppUser?> watchCurrentUserData() {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) {
        return Stream.value(null);
      }
      return _firestore
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .map((doc) => doc.exists && doc.data() != null
              ? AppUser.fromMap(doc.data()!, user.uid)
              : null);
    });
  }

  Future<bool> isUsernameAvailable(String username) async {
    final cleanUsername = username.trim().toLowerCase();
    final doc = await _firestore.collection('usernames').doc(cleanUsername).get();
    return !doc.exists;
  }

  Future<AppUser> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
    required String displayName,
    required String avatarSeed,
    required String avatarColor,
  }) async {
    final cleanUsername = username.trim().toLowerCase();
    if (!RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(cleanUsername)) {
      throw Exception('Lo username deve contenere tra 3 e 20 caratteri alfanumerici.');
    }

    // 1. Verifica preventiva disponibilità username
    final usernameDoc = await _firestore.collection('usernames').doc(cleanUsername).get();
    if (usernameDoc.exists) {
      throw Exception('Lo username "$cleanUsername" è già in uso. Scegline un altro.');
    }

    // 2. Creazione Auth
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = credential.user!.uid;

    final appUser = AppUser(
      uid: uid,
      email: email.trim(),
      username: cleanUsername,
      displayName: displayName.trim().isEmpty ? cleanUsername : displayName.trim(),
      avatarSeed: avatarSeed.isEmpty ? uid : avatarSeed,
      avatarColor: avatarColor,
      createdAt: DateTime.now(),
    );

    // 3. Batch atomico: users/{uid} + usernames/{username}
    final batch = _firestore.batch();
    batch.set(_firestore.collection('users').doc(uid), appUser.toMap());
    batch.set(_firestore.collection('usernames').doc(cleanUsername), {
      'uid': uid,
      'claimedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    return appUser;
  }

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> updateProfile({
    String? displayName,
    String? avatarSeed,
    String? avatarColor,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final updates = <String, dynamic>{};
    if (displayName != null) updates['displayName'] = displayName.trim();
    if (avatarSeed != null) updates['avatarSeed'] = avatarSeed;
    if (avatarColor != null) updates['avatarColor'] = avatarColor;

    if (updates.isNotEmpty) {
      await _firestore.collection('users').doc(user.uid).update(updates);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
