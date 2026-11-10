import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/friends/screens/friends_screen.dart';
import '../../features/invite/screens/invite_screen.dart';
import '../../features/playlists/screens/playlist_detail_screen.dart';
import '../../features/playlists/screens/playlist_list_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../theme/app_theme.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);

  return GoRouter(
    initialLocation: '/playlists',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');
      final isInviteRoute = state.matchedLocation.startsWith('/invite');

      // Se non loggato e tenta di accedere a schermate protette (tranne inviti)
      if (!isLoggedIn && !isAuthRoute && !isInviteRoute) {
        return '/auth/login';
      }

      // Se già loggato e va sulle pagine di auth, manda alla home
      if (isLoggedIn && isAuthRoute) {
        return '/playlists';
      }

      return null;
    },
    routes: [
      // Auth Routes
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Invito Deep Link
      GoRoute(
        path: '/invite/:token',
        builder: (context, state) {
          final token = state.pathParameters['token'] ?? '';
          return InviteScreen(token: token);
        },
      ),

      // Shell Principale con Bottom Navigation Bar
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return Scaffold(
            body: navigationShell,
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: navigationShell.currentIndex,
              onTap: (index) => navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              ),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.playlist_play_rounded),
                  activeIcon: Icon(Icons.playlist_play_rounded, color: AppColors.primaryCyan),
                  label: 'Playlist',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.people_outline_rounded),
                  activeIcon: Icon(Icons.people_rounded, color: AppColors.primaryCyan),
                  label: 'Amici',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline_rounded),
                  activeIcon: Icon(Icons.person_rounded, color: AppColors.primaryCyan),
                  label: 'Profilo',
                ),
              ],
            ),
          );
        },
        branches: [
          // Ramo 0: Playlist
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/playlists',
                builder: (context, state) => const PlaylistListScreen(),
              ),
            ],
          ),
          // Ramo 1: Amici
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/friends',
                builder: (context, state) => const FriendsScreen(),
              ),
            ],
          ),
          // Ramo 2: Profilo
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Dettaglio Playlist
      GoRoute(
        path: '/playlist/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return PlaylistDetailScreen(playlistId: id);
        },
      ),
    ],
  );
});
