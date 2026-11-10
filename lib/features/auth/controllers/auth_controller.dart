import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_user.dart';
import '../repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final currentUserDataProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).watchCurrentUserData();
});

class AuthController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.signInWithEmailAndPassword(
          email: email,
          password: password,
        ));
  }

  Future<void> register({
    required String email,
    required String password,
    required String username,
    required String displayName,
    required String avatarSeed,
    required String avatarColor,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.registerWithEmailAndPassword(
          email: email,
          password: password,
          username: username,
          displayName: displayName,
          avatarSeed: avatarSeed,
          avatarColor: avatarColor,
        ));
  }

  Future<void> resetPassword(String email) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.sendPasswordResetEmail(email));
  }

  Future<void> updateProfile({
    String? displayName,
    String? avatarSeed,
    String? avatarColor,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.updateProfile(
          displayName: displayName,
          avatarSeed: avatarSeed,
          avatarColor: avatarColor,
        ));
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.signOut());
  }
}

final authControllerProvider = NotifierProvider<AuthController, AsyncValue<void>>(AuthController.new);
