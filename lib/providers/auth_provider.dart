import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firebase_service.dart';

final firebaseServiceProvider = Provider<FirebaseService>((ref) => FirebaseService());
final authStateProvider = StreamProvider<User?>((ref) => ref.watch(firebaseServiceProvider).authStateChanges);
final currentUserProvider = Provider<User?>((ref) => ref.watch(authStateProvider).valueOrNull);
final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository(ref.watch(firebaseServiceProvider)));

class AuthRepository {
  final FirebaseService _svc;
  AuthRepository(this._svc);

  // الحل الأضمن والأحدث الذي يعمل على الويب والموبايل معاً
  Future<void> signInWithGoogle() async {
    try {
      final googleProvider = GoogleAuthProvider();
      
      // على الويب، هذه الدالة تفتح نافذة منبثقة، وعلى الموبايل قد تطلب إعدادات إضافية
      // لكنها الطريقة المعيارية الجديدة من Firebase
      await FirebaseAuth.instance.signInWithPopup(googleProvider);
      
    } catch (e) {
      print('خطأ أثناء تسجيل الدخول بواسطة Google: $e');
      // إذا فشل الـ Popup، يمكن تجربة الـ Redirect كبديل
      rethrow;
    }
  }

  Future<void> signInWithEmail(String email, String password) => _svc.signInWithEmail(email, password);
  Future<void> registerWithEmail(String email, String password) => _svc.registerWithEmail(email, password);
  Future<void> signOut() => _svc.signOut();
}
