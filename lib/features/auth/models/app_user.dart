import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String username;
  final String displayName;
  final String avatarSeed;
  final String avatarColor;
  final List<String> friends;
  final DateTime createdAt;

  const AppUser({
    required this.uid,
    required this.email,
    required this.username,
    required this.displayName,
    required this.avatarSeed,
    required this.avatarColor,
    this.friends = const [],
    required this.createdAt,
  });

  factory AppUser.fromMap(Map<String, dynamic> data, String uid) {
    return AppUser(
      uid: uid,
      email: data['email'] as String? ?? '',
      username: data['username'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      avatarSeed: data['avatarSeed'] as String? ?? uid,
      avatarColor: data['avatarColor'] as String? ?? '#00E5FF',
      friends: (data['friends'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'username': username,
      'displayName': displayName,
      'avatarSeed': avatarSeed,
      'avatarColor': avatarColor,
      'friends': friends,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  AppUser copyWith({
    String? displayName,
    String? avatarSeed,
    String? avatarColor,
    List<String>? friends,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      username: username,
      displayName: displayName ?? this.displayName,
      avatarSeed: avatarSeed ?? this.avatarSeed,
      avatarColor: avatarColor ?? this.avatarColor,
      friends: friends ?? this.friends,
      createdAt: createdAt,
    );
  }
}
