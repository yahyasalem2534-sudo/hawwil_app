import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

  // ---------- تسجيل الدخول بواسطة Google ----------
  Future<void> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // طريقة الويب
        final googleProvider = GoogleAuthProvider();
        await FirebaseAuth.instance.signInWithPopup(googleProvider);
      } else {
        // طريقة الموبايل
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) return;

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        await FirebaseAuth.instance.signInWithCredential(credential);
      }
    } catch (e) {
      print('خطأ أثناء تسجيل الدخول بواسطة Google: $e');
      rethrow;
    }
  }

  // ---------- تسجيل الدخول بالبريد وكلمة المرور ----------
  Future<void> signInWithEmail(String email, String password) =>
      _svc.signInWithEmail(email, password);

  // ---------- إنشاء حساب جديد بالبريد وكلمة المرور ----------
  Future<void> registerWithEmail(String email, String password) =>
      _svc.registerWithEmail(email, password);

  // ---------- تسجيل الخروج ----------
  Future<void> signOut() => _svc.signOut();
}
