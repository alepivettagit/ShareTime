import 'package:cloud_firestore/cloud_firestore.dart';

class VideoItem {
  final String id;
  final String youtubeId;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String sharedByUid;
  final String sharedByName;
  final String sharedByAvatarSeed;
  final String sharedByAvatarColor;
  final int durationSec;
  final List<String> hiddenForUsers;
  final DateTime sharedAt;
  final bool isWatched;

  const VideoItem({
    required this.id,
    required this.youtubeId,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.sharedByUid,
    required this.sharedByName,
    required this.sharedByAvatarSeed,
    required this.sharedByAvatarColor,
    this.durationSec = 0,
    this.hiddenForUsers = const [],
    required this.sharedAt,
    this.isWatched = false,
  });

  factory VideoItem.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    bool isWatched = false,
  }) {
    final data = doc.data() ?? {};
    return VideoItem(
      id: doc.id,
      youtubeId: data['youtubeId'] as String? ?? '',
      title: data['title'] as String? ?? 'Senza Titolo',
      description: data['description'] as String? ?? '',
      thumbnailUrl: data['thumbnailUrl'] as String? ?? '',
      sharedByUid: data['sharedByUid'] as String? ?? '',
      sharedByName: data['sharedByName'] as String? ?? 'Membro',
      sharedByAvatarSeed: data['sharedByAvatarSeed'] as String? ?? 'seed',
      sharedByAvatarColor: data['sharedByAvatarColor'] as String? ?? '#00E5FF',
      durationSec: (data['durationSec'] as num?)?.toInt() ?? 0,
      hiddenForUsers: (data['hiddenForUsers'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      sharedAt: (data['sharedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isWatched: isWatched,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'youtubeId': youtubeId,
      'title': title,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'sharedByUid': sharedByUid,
      'sharedByName': sharedByName,
      'sharedByAvatarSeed': sharedByAvatarSeed,
      'sharedByAvatarColor': sharedByAvatarColor,
      'durationSec': durationSec,
      'hiddenForUsers': hiddenForUsers,
      'sharedAt': Timestamp.fromDate(sharedAt),
    };
  }

  VideoItem copyWith({
    bool? isWatched,
    List<String>? hiddenForUsers,
  }) {
    return VideoItem(
      id: id,
      youtubeId: youtubeId,
      title: title,
      description: description,
      thumbnailUrl: thumbnailUrl,
      sharedByUid: sharedByUid,
      sharedByName: sharedByName,
      sharedByAvatarSeed: sharedByAvatarSeed,
      sharedByAvatarColor: sharedByAvatarColor,
      durationSec: durationSec,
      hiddenForUsers: hiddenForUsers ?? this.hiddenForUsers,
      sharedAt: sharedAt,
      isWatched: isWatched ?? this.isWatched,
    );
  }

  String get formattedDuration {
    if (durationSec <= 0) return '';
    final minutes = durationSec ~/ 60;
    final seconds = durationSec % 60;
    final secondsStr = seconds < 10 ? '0$seconds' : '$seconds';
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final remMinutes = minutes % 60;
      final minStr = remMinutes < 10 ? '0$remMinutes' : '$remMinutes';
      return '$hours:$minStr:$secondsStr';
    }
    return '$minutes:$secondsStr';
  }
}
