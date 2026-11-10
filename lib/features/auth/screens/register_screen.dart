import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../avatar/avatar_picker_dialog.dart';
import '../../avatar/avatar_widget.dart';
import '../controllers/auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();

  late String _avatarSeed;
  late String _avatarColor;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    final randInt = Random().nextInt(0xFFFFFF);
    _avatarSeed = 'agent_${randInt.toRadixString(16)}';
    _avatarColor = AppColors.avatarPalette[Random().nextInt(AppColors.avatarPalette.length)];
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authControllerProvider.notifier).register(
          email: _emailController.text,
          password: _passwordController.text,
          username: _usernameController.text,
          displayName: _displayNameController.text,
          avatarSeed: _avatarSeed,
          avatarColor: _avatarColor,
        );

    final state = ref.read(authControllerProvider);
    if (state.hasError && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore: ${state.error.toString().replaceAll("Exception: ", "")}'),
          backgroundColor: AppColors.accentCoral,
        ),
      );
    }
  }

  Future<void> _openAvatarPicker() async {
    final choice = await AvatarPickerDialog.show(
      context,
      currentSeed: _avatarSeed,
      currentColorHex: _avatarColor,
    );
    if (choice != null && mounted) {
      setState(() {
        _avatarSeed = choice.seed;
        _avatarColor = choice.colorHex;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crea Account'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Avatar Selettore con Preview
                    Center(
                      child: Column(
                        children: [
                          AvatarWidget(
                            seed: _avatarSeed,
                            colorHex: _avatarColor,
                            size: 80,
                            showGlow: true,
                            onTap: _openAvatarPicker,
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _openAvatarPicker,
                            icon: const Icon(Icons.palette_outlined, size: 16, color: AppColors.primaryCyan),
                            label: const Text(
                              'Personalizza Avatar',
                              style: TextStyle(color: AppColors.primaryCyan, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Username Field
                    TextFormField(
                      controller: _usernameController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Username univoco (@)',
                        hintText: 'es. luca_99',
                        prefixIcon: Icon(Icons.alternate_email, color: AppColors.textMuted, size: 20),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Inserisci un username';
                        if (!RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(val.trim())) {
                          return 'Tra 3 e 20 caratteri (lettere, numeri, _)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Display Name Field
                    TextFormField(
                      controller: _displayNameController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Nome visualizzato',
                        hintText: 'es. Luca',
                        prefixIcon: Icon(Icons.badge_outlined, color: AppColors.textMuted, size: 20),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined, color: AppColors.textMuted, size: 20),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Inserisci la tua email';
                        if (!val.contains('@')) return 'Email non valida';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textMuted, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: AppColors.textMuted,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Inserisci una password';
                        if (val.length < 6) return 'Almeno 6 caratteri';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Conferma Password
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Conferma Password',
                        prefixIcon: Icon(Icons.lock_reset, color: AppColors.textMuted, size: 20),
                      ),
                      validator: (val) {
                        if (val != _passwordController.text) return 'Le password non coincidono';
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),

                    // Bottone Registrati
                    ElevatedButton(
                      onPressed: isLoading ? null : _handleRegister,
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.bgDark),
                            )
                          : const Text('Crea Account e Unisciti'),
                    ),
                    const SizedBox(height: 16),

                    // Torna al Login
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Hai già un account? ',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                        ),
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: const Text(
                            'Accedi',
                            style: TextStyle(
                              color: AppColors.primaryCyan,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
