import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/controllers/auth_controller.dart';
import '../services/invite_service.dart';

class InviteScreen extends ConsumerStatefulWidget {
  final String token;

  const InviteScreen({super.key, required this.token});

  @override
  ConsumerState<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends ConsumerState<InviteScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleJoin() async {
    final currentUser = ref.read(currentUserDataProvider).value;
    if (currentUser == null) {
      // Reindirizza a login salvando l'intenzione
      context.go('/auth/login');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final inviteService = InviteService();
      final playlistId = await inviteService.joinPlaylist(
        token: widget.token,
        user: currentUser,
      );

      if (mounted) {
        context.go('/playlist/$playlistId');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invito ShareTime'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primaryCyan, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryCyan.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.mark_email_unread_rounded,
                    size: 44,
                    color: AppColors.primaryCyan,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Sei stato invitato!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Unisciti a questa playlist YouTube condivisa per guardare e consigliare video insieme ai tuoi amici.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppColors.textMuted, height: 1.4),
                ),
                const SizedBox(height: 32),
                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accentCoral.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.accentCoral),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppColors.accentCoral, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                userAsync.when(
                  data: (user) {
                    if (user == null) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Effettua l\'accesso o registrati per accettare l\'invito.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => context.go('/auth/login'),
                            child: const Text('Accedi ed Entra'),
                          ),
                        ],
                      );
                    }

                    return ElevatedButton(
                      onPressed: _isLoading ? null : _handleJoin,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.bgDark),
                            )
                          : const Text('Unisciti alla Playlist'),
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primaryCyan),
                  ),
                  error: (_, __) => ElevatedButton(
                    onPressed: () => context.go('/auth/login'),
                    child: const Text('Accedi'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
