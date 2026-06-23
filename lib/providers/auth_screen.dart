import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  bool _loadingGoogle = false;
  bool _loadingEmail  = false;
  bool _isLogin       = true; // toggle login / register
  bool _obscure       = true;

  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          // ── خلفية متوهجة ──────────────────────────────────────────────
          Positioned(
            top: -100,
            left: -80,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── المحتوى ────────────────────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 40, 28, 32),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // الشعار
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withOpacity(0.4),
                                    blurRadius: 30,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(22),
                                child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
                              ),
                            ),
                            const SizedBox(height: 16),
                            RichText(
                              text: const TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'حو',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'ل',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.primaryColor,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // عنوان النموذج
                      Text(
                        _isLogin ? 'مرحباً بعودتك 👋' : 'إنشاء حساب جديد',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _isLogin
                            ? 'سجّل دخولك للمتابعة'
                            : 'انضم إلى منصة حوّل اليوم',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontFamily: 'Cairo',
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ── زر Google ─────────────────────────────────────
                      _GoogleButton(
                        loading: _loadingGoogle,
                        onTap: _signInWithGoogle,
                      ),

                      const SizedBox(height: 20),

                      // فاصل
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              'أو عبر البريد الإلكتروني',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontFamily: 'Cairo',
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ── حقل البريد ───────────────────────────────────
                      _AuthField(
                        controller: _emailCtrl,
                        label: 'البريد الإلكتروني',
                        icon: Icons.email_outlined,
                        type: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),

                      // ── حقل كلمة المرور ──────────────────────────────
                      _AuthField(
                        controller: _passCtrl,
                        label: 'كلمة المرور',
                        icon: Icons.lock_outline_rounded,
                        obscure: _obscure,
                        suffix: IconButton(
                          icon: Icon(
                            _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppTheme.textSecondary,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),

                      // نسيت كلمة المرور
                      if (_isLogin)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: _forgotPassword,
                            child: Text(
                              'نسيت كلمة المرور؟',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontFamily: 'Cairo',
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 24),

                      // ── زر الإرسال ────────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _loadingEmail ? null : _submitEmail,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 8,
                            shadowColor: AppTheme.primaryColor.withOpacity(0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _loadingEmail
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _isLogin ? 'تسجيل الدخول' : 'إنشاء الحساب',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── تبديل تسجيل / إنشاء ──────────────────────────
                      Center(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _isLogin = !_isLogin;
                            _controller.reset();
                            _controller.forward();
                          }),
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
                              children: [
                                TextSpan(
                                  text: _isLogin
                                      ? 'ليس لديك حساب؟  '
                                      : 'لديك حساب بالفعل؟  ',
                                  style: TextStyle(color: AppTheme.textSecondary),
                                ),
                                TextSpan(
                                  text: _isLogin ? 'إنشاء حساب' : 'تسجيل الدخول',
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── المنطق ──────────────────────────────────────────────────────────────

  Future<void> _signInWithGoogle() async {
    setState(() => _loadingGoogle = true);
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
    } catch (e) {
      _snack('فشل تسجيل الدخول بـ Google', Icons.error_outline_rounded);
    }
    if (mounted) setState(() => _loadingGoogle = false);
  }

  Future<void> _submitEmail() async {
    final email = _emailCtrl.text.trim();
    final pass  = _passCtrl.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      _snack('يرجى ملء جميع الحقول', Icons.warning_amber_rounded);
      return;
    }
    if (pass.length < 6) {
      _snack('كلمة المرور يجب أن تكون 6 أحرف على الأقل', Icons.lock_outline_rounded);
      return;
    }

    setState(() => _loadingEmail = true);
    try {
      if (_isLogin) {
        await ref.read(authServiceProvider).signInWithEmail(email, pass);
      } else {
        await ref.read(authServiceProvider).registerWithEmail(email, pass);
      }
    } on AuthException catch (e) {
      _snack(e.message, Icons.error_outline_rounded);
    } catch (_) {
      _snack('حدث خطأ، حاول مجدداً', Icons.error_outline_rounded);
    }
    if (mounted) setState(() => _loadingEmail = false);
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _snack('أدخل بريدك الإلكتروني أولاً', Icons.email_outlined);
      return;
    }
    try {
      await ref.read(authServiceProvider).sendPasswordReset(email);
      _snack('تم إرسال رابط الاستعادة إلى بريدك', Icons.check_circle_outline_rounded, success: true);
    } catch (_) {
      _snack('تعذّر إرسال الرابط، تحقق من البريد', Icons.error_outline_rounded);
    }
  }

  void _snack(String msg, IconData icon, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: success ? AppTheme.primaryColor : const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// ============================================================================
// زر Google
// ============================================================================
class _GoogleButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;
  const _GoogleButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: loading ? AppTheme.surfaceColor.withOpacity(0.6) : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: loading
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppTheme.primaryColor,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // شعار Google بالألوان الحقيقية
                  _GoogleLogo(),
                  const SizedBox(width: 12),
                  const Text(
                    'المتابعة بحساب Google',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // رسم الدائرة الخلفية
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, radius, bgPaint);

    // قطاعات Google
    final segments = [
      (Colors.red[600]!,    -0.26,  0.5),
      (Colors.yellow[700]!, 0.24,   0.5),
      (Colors.green[600]!,  0.74,   0.5),
      (Colors.blue[600]!,   1.24,   0.74),
    ];

    for (final seg in segments) {
      final paint = Paint()..color = seg.$1;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 1),
        seg.$2 * 3.14159,
        seg.$3 * 3.14159,
        true,
        paint,
      );
    }

    // ثقب المنتصف
    canvas.drawCircle(center, radius * 0.45, Paint()..color = AppTheme.surfaceColor);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ============================================================================
// حقل الإدخال
// ============================================================================
class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? type;
  final bool obscure;
  final Widget? suffix;

  const _AuthField({
    required this.controller,
    required this.label,
    required this.icon,
    this.type,
    this.obscure = false,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: type,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white, fontFamily: 'Cairo'),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: AppTheme.textSecondary,
          fontFamily: 'Cairo',
          fontSize: 13,
        ),
        prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppTheme.surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
      ),
    );
  }
}
