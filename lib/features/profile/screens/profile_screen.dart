import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../avatar/avatar_picker_dialog.dart';
import '../../avatar/avatar_widget.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  bool _isEditingName = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _changeAvatar(String currentSeed, String currentColor) async {
    final choice = await AvatarPickerDialog.show(
      context,
      currentSeed: currentSeed,
      currentColorHex: currentColor,
    );

    if (choice != null) {
      await ref.read(authControllerProvider.notifier).updateProfile(
            avatarSeed: choice.seed,
            avatarColor: choice.colorHex,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar aggiornato con successo!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Il tuo Profilo'),
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Nessun utente autenticato.'));
          }

          if (!_isEditingName) {
            _nameController.text = user.displayName;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Avatar con Pulsante Modifica
                    Center(
                      child: Column(
                        children: [
                          AvatarWidget(
                            seed: user.avatarSeed,
                            colorHex: user.avatarColor,
                            size: 96,
                            showGlow: true,
                            onTap: () => _changeAvatar(user.avatarSeed, user.avatarColor),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () => _changeAvatar(user.avatarSeed, user.avatarColor),
                            icon: const Icon(Icons.palette_outlined, size: 16),
                            label: const Text('Cambia Avatar Identicon'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.surfaceElevated,
                              foregroundColor: AppColors.primaryCyan,
                              elevation: 0,
                              side: const BorderSide(color: AppColors.borderSubtle),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Display Name
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nome Visualizzato',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: _isEditingName
                                    ? TextField(
                                        controller: _nameController,
                                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                                        autofocus: true,
                                      )
                                    : Text(
                                        user.displayName,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                              IconButton(
                                icon: Icon(_isEditingName ? Icons.check : Icons.edit_outlined,
                                    color: AppColors.primaryCyan, size: 20),
                                onPressed: () async {
                                  if (_isEditingName) {
                                    await ref.read(authControllerProvider.notifier).updateProfile(
                                          displayName: _nameController.text,
                                        );
                                    setState(() => _isEditingName = false);
                                  } else {
                                    setState(() => _isEditingName = true);
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Username
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Username Univoco (@)',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '@${user.username}',
                            style: const TextStyle(
                              color: AppColors.primaryCyan,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Email
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Email di Accesso',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            user.email,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Logout Button
                    OutlinedButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: AppColors.surfaceDark,
                            title: const Text('Disconnetti'),
                            content: const Text('Vuoi uscire da ShareTime su questo dispositivo?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annulla')),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentCoral),
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text('Esci'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await ref.read(authControllerProvider.notifier).signOut();
                          if (context.mounted) context.go('/auth/login');
                        }
                      },
                      icon: const Icon(Icons.logout_rounded, color: AppColors.accentCoral, size: 18),
                      label: const Text('Disconnetti Account', style: TextStyle(color: AppColors.accentCoral)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.accentCoral),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryCyan)),
        error: (err, _) => Center(child: Text('Errore: $err')),
      ),
    );
  }
}
