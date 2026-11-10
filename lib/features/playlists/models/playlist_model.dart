import 'package:cloud_firestore/cloud_firestore.dart';

class MemberInfo {
  final String uid;
  final String displayName;
  final String username;
  final String avatarSeed;
  final String avatarColor;
  final DateTime joinedAt;

  const MemberInfo({
    required this.uid,
    required this.displayName,
    required this.username,
    required this.avatarSeed,
    required this.avatarColor,
    required this.joinedAt,
  });

  factory MemberInfo.fromMap(Map<String, dynamic> data, String uid) {
    return MemberInfo(
      uid: uid,
      displayName: data['displayName'] as String? ?? 'Amico',
      username: data['username'] as String? ?? '',
      avatarSeed: data['avatarSeed'] as String? ?? uid,
      avatarColor: data['avatarColor'] as String? ?? '#00E5FF',
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'username': username,
      'avatarSeed': avatarSeed,
      'avatarColor': avatarColor,
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }
}

class Playlist {
  final String id;
  final String title;
  final String createdBy;
  final String creatorName;
  final List<String> memberUids;
  final Map<String, MemberInfo> membersData;
  final int videoCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Playlist({
    required this.id,
    required this.title,
    required this.createdBy,
    required this.creatorName,
    required this.memberUids,
    required this.membersData,
    this.videoCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Playlist.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final rawMembers = data['membersData'] as Map<String, dynamic>? ?? {};
    final membersMap = <String, MemberInfo>{};

    rawMembers.forEach((uid, val) {
      if (val is Map<String, dynamic>) {
        membersMap[uid] = MemberInfo.fromMap(val, uid);
      }
    });

    return Playlist(
      id: doc.id,
      title: data['title'] as String? ?? 'Senza Titolo',
      createdBy: data['createdBy'] as String? ?? '',
      creatorName: data['creatorName'] as String? ?? '',
      memberUids: (data['memberUids'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      membersData: membersMap,
      videoCount: (data['videoCount'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'createdBy': createdBy,
      'creatorName': creatorName,
      'memberUids': memberUids,
      'membersData': membersData.map((k, v) => MapEntry(k, v.toMap())),
      'videoCount': videoCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
