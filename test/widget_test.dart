import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharetime/core/theme/app_theme.dart';
import 'package:sharetime/features/avatar/avatar_widget.dart';
import 'package:sharetime/features/videos/models/video_model.dart';
import 'package:sharetime/features/videos/widgets/video_card.dart';

void main() {
  testWidgets('AvatarWidget renders correctly with seed and color', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: Center(
            child: AvatarWidget(
              seed: 'user_node_42',
              colorHex: '#00E5FF',
              size: 60,
              showGlow: true,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(AvatarWidget), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('VideoCard shows "Condiviso da te" and "Visto" for own watched video', (WidgetTester tester) async {
    final video = VideoItem(
      id: 'v1',
      youtubeId: 'dQw4w9WgXcQ',
      title: 'Test Video Proprio',
      description: '',
      thumbnailUrl: '',
      sharedByUid: 'my_uid',
      sharedByName: 'Alessandro',
      sharedByAvatarSeed: 'ale',
      sharedByAvatarColor: '#00E5FF',
      sharedAt: DateTime.now(),
      isWatched: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: VideoCard(
              video: video,
              currentUid: 'my_uid',
              isCreator: true,
              onToggleWatched: () {},
              onHide: () {},
              onDelete: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('Condiviso da te'), findsOneWidget);
    expect(find.text('Visto'), findsOneWidget);
  });

  testWidgets('VideoCard shows friend name and "Segna visto" for unwatched friend video', (WidgetTester tester) async {
    final video = VideoItem(
      id: 'v2',
      youtubeId: 'dQw4w9WgXcQ',
      title: 'Test Video Amico',
      description: '',
      thumbnailUrl: '',
      sharedByUid: 'friend_uid',
      sharedByName: 'Marco',
      sharedByAvatarSeed: 'marco',
      sharedByAvatarColor: '#FF6B4A',
      sharedAt: DateTime.now(),
      isWatched: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: VideoCard(
              video: video,
              currentUid: 'my_uid',
              isCreator: false,
              onToggleWatched: () {},
              onHide: () {},
              onDelete: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('Condiviso da Marco'), findsOneWidget);
    expect(find.text('Segna visto'), findsOneWidget);
  });
}
