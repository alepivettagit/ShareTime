import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../avatar/avatar_widget.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;
  Map<String, dynamic>? _foundUser;
  String? _searchError;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUser() async {
    final username = _searchController.text.trim().toLowerCase().replaceAll('@', '');
    if (username.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchError = null;
      _foundUser = null;
    });

    try {
      final doc = await FirebaseFirestore.instance.collection('usernames').doc(username).get();
      if (!doc.exists) {
        setState(() {
          _searchError = 'Nessun amico trovato con @$username';
          _isSearching = false;
        });
        return;
      }

      final targetUid = doc.data()!['uid'] as String;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(targetUid).get();
      if (userDoc.exists && mounted) {
        setState(() {
          _foundUser = {'uid': targetUid, ...userDoc.data()!};
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchError = 'Errore nella ricerca: $e';
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _addFriend(String targetUid) async {
    final me = ref.read(currentUserDataProvider).value;
    if (me == null) return;

    await FirebaseFirestore.instance.collection('users').doc(me.uid).update({
      'friends': FieldValue.arrayUnion([targetUid]),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amico aggiunto alla tua rubrica!')),
      );
      setState(() {
        _foundUser = null;
        _searchController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserDataProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('I tuoi Amici'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Scheda Tuo Username & Condivisione
            if (currentUser != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primaryCyan.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    AvatarWidget(
                      seed: currentUser.avatarSeed,
                      colorHex: currentUser.avatarColor,
                      size: 46,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentUser.displayName,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary),
                          ),
                          Text(
                            '@${currentUser.username}',
                            style: const TextStyle(color: AppColors.primaryCyan, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, color: AppColors.textMuted, size: 20),
                      tooltip: 'Copia username',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: '@${currentUser.username}'));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Username copiato!')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Barra di Ricerca Amici
            const Text(
              'Aggiungi un amico tramite @username',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'es. marco_99',
                      prefixIcon: Icon(Icons.alternate_email, color: AppColors.textMuted, size: 18),
                    ),
                    onSubmitted: (_) => _searchUser(),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _isSearching ? null : _searchUser,
                  child: _isSearching
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.bgDark))
                      : const Icon(Icons.search),
                ),
              ],
            ),
            if (_searchError != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(_searchError!, style: const TextStyle(color: AppColors.accentCoral, fontSize: 13)),
              ),

            // Risultato ricerca
            if (_foundUser != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    AvatarWidget(
                      seed: _foundUser!['avatarSeed'] ?? 'seed',
                      colorHex: _foundUser!['avatarColor'] ?? '#00E5FF',
                      size: 40,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _foundUser!['displayName'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                          Text(
                            '@${_foundUser!['username']}',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _addFriend(_foundUser!['uid']),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      child: const Text('Aggiungi'),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),

            // Lista amici salvati
            const Text(
              'I tuoi Amici Collegati',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            if (currentUser == null || currentUser.friends.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: const Center(
                  child: Text(
                    'Non hai ancora aggiunto amici alla tua cerchia.\nCerca il loro username qui sopra!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.4),
                  ),
                ),
              )
            else
              ...currentUser.friends.map((friendUid) {
                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(friendUid).get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return const SizedBox.shrink();
                    }
                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Row(
                        children: [
                          AvatarWidget(
                            seed: data['avatarSeed'] ?? 'seed',
                            colorHex: data['avatarColor'] ?? '#00E5FF',
                            size: 36,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['displayName'] ?? 'Amico',
                                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                ),
                                Text(
                                  '@${data['username']}',
                                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }),
          ],
        ),
      ),
    );
  }
}
