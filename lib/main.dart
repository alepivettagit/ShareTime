import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/videos/services/share_intent_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const ProviderScope(
      child: ShareTimeApp(),
    ),
  );
}

class ShareTimeApp extends ConsumerStatefulWidget {
  const ShareTimeApp({super.key});

  @override
  ConsumerState<ShareTimeApp> createState() => _ShareTimeAppState();
}

class _ShareTimeAppState extends ConsumerState<ShareTimeApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ShareIntentService.init(context, ref);
      _checkWebShareTarget();
    });
  }

  void _checkWebShareTarget() {
    if (!kIsWeb) return;
    try {
      final uri = Uri.base;
      final sharedText = uri.queryParameters['text'] ?? uri.queryParameters['url'];
      if (sharedText != null && sharedText.isNotEmpty) {
        // Ricevuto parametro da Web Share Target
        debugPrint('Web Share Target rilevato: $sharedText');
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    ShareIntentService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'ShareTime',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('it', 'IT'),
        Locale('en', 'US'),
      ],
      locale: const Locale('it', 'IT'),
    );
  }
}
