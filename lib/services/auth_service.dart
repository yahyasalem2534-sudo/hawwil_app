import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
}

class AuthService {
  final FirebaseAuth  _auth        = FirebaseAuth.instance;
  final GoogleSignIn  _googleSignIn = GoogleSignIn();

  Future<void> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw AuthException('تم إلغاء تسجيل الدخول');
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken:     googleAuth.idToken,
      );
      await _auth.signInWithCredential(credential);
    } on AuthException {
      rethrow;
    } catch (_) {
      throw AuthException('فشل تسجيل الدخول بـ Google');
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapError(e.code));
    }
  }

  Future<void> registerWithEmail(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapError(e.code));
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapError(e.code));
    }
  }

  String _mapError(String code) {
    switch (code) {
      case 'user-not-found':       return 'البريد الإلكتروني غير مسجل';
      case 'wrong-password':       return 'كلمة المرور غير صحيحة';
      case 'email-already-in-use': return 'البريد الإلكتروني مستخدم بالفعل';
      case 'weak-password':        return 'كلمة المرور ضعيفة جداً';
      case 'invalid-email':        return 'صيغة البريد الإلكتروني غير صحيحة';
      case 'too-many-requests':    return 'محاولات كثيرة، حاول لاحقاً';
      default:                     return 'حدث خطأ، حاول مجدداً';
    }
  }
}