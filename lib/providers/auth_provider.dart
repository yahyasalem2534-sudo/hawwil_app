import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firebase_service.dart';

final firebaseServiceProvider = Provider<FirebaseService>(
  (ref) => FirebaseService(),
);

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseServiceProvider).authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(firebaseServiceProvider));
});

class AuthRepository {
  final FirebaseService _svc;
  AuthRepository(this._svc);
   Future<void> signInWithGoogle() async {
    throw UnimplementedError('Google Sign-In سيُفعَّل قريباً');
  }

  Future<void> signInWithEmail(String email, String password) =>
      _svc.signInWithEmail(email, password);

  Future<void> registerWithEmail(String email, String password) =>
      _svc.registerWithEmail(email, password);

  Future<void> signInWithApple() async {
    throw UnimplementedError('Apple Sign-In غير مفعّل بعد');
  }

  Future<void> signOut() => _svc.signOut();
}
