import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../services/auth_service.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  bool _loadingGoogle = false;
  bool _loadingEmail  = false;
  bool _isLogin       = true;
  bool _obscure       = true;

  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..forward();
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _ctrl.dispose();
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
          // خلفية متوهجة
          Positioned(
            top: -80,
            left: -60,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppTheme.primaryColor.withOpacity(0.16),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppTheme.primaryColor.withOpacity(0.09),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(26, 36, 26, 30),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 78,
                              height: 78,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                      color: AppTheme.primaryColor
                                          .withOpacity(0.4),
                                      blurRadius: 28,
                                      spreadRadius: 2),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(22),
                                child: Image.asset('assets/images/logo.png',
                                    fit: BoxFit.cover),
                              ),
                            ),
                            const SizedBox(height: 14),
                            RichText(
                              text: const TextSpan(children: [
                                TextSpan(
                                  text: 'حوّ',
                                  style: TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      fontFamily: 'Cairo'),
                                ),
                                TextSpan(
                                  text: 'ل',
                                  style: TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.primaryColor,
                                      fontFamily: 'Cairo'),
                                ),
                              ]),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 36),

                      Text(
                        _isLogin ? 'مرحباً بعودتك 👋' : 'إنشاء حساب جديد',
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            fontFamily: 'Cairo'),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isLogin
                            ? 'سجّل دخولك للمتابعة'
                            : 'انضم إلى حوّل اليوم',
                        style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontFamily: 'Cairo',
                            fontSize: 13),
                      ),

                      const SizedBox(height: 28),

                      // Google
                      _GoogleBtn(
                          loading: _loadingGoogle, onTap: _signInGoogle),

                      const SizedBox(height: 18),

                      Row(children: [
                        Expanded(
                            child: Divider(
                                color: Colors.white.withOpacity(0.1))),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('أو بالبريد',
                              style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                  fontFamily: 'Cairo')),
                        ),
                        Expanded(
                            child: Divider(
                                color: Colors.white.withOpacity(0.1))),
                      ]),

                      const SizedBox(height: 18),

                      _Field(
                          controller: _emailCtrl,
                          label: 'البريد الإلكتروني',
                          icon: Icons.email_outlined,
                          type: TextInputType.emailAddress),
                      const SizedBox(height: 12),
                      _Field(
                        controller: _passCtrl,
                        label: 'كلمة المرور',
                        icon: Icons.lock_outline_rounded,
                        obscure: _obscure,
                        suffix: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppTheme.textSecondary,
                            size: 20,
                          ),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),

                      if (_isLogin)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: _forgotPassword,
                            child: const Text('نسيت كلمة المرور؟',
                                style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontFamily: 'Cairo',
                                    fontSize: 12)),
                          ),
                        ),

                      const SizedBox(height: 22),

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _loadingEmail ? null : _submitEmail,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 8,
                            shadowColor:
                                AppTheme.primaryColor.withOpacity(0.4),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                          ),
                          child: _loadingEmail
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white))
                              : Text(
                                  _isLogin
                                      ? 'تسجيل الدخول'
                                      : 'إنشاء الحساب',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      fontFamily: 'Cairo'),
                                ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      Center(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _isLogin = !_isLogin;
                            _ctrl.reset();
                            _ctrl.forward();
                          }),
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                  fontFamily: 'Cairo', fontSize: 13),
                              children: [
                                TextSpan(
                                  text: _isLogin
                                      ? 'ليس لديك حساب؟  '
                                      : 'لديك حساب؟  ',
                                  style: const TextStyle(
                                      color: AppTheme.textSecondary),
                                ),
                                TextSpan(
                                  text: _isLogin
                                      ? 'إنشاء حساب'
                                      : 'تسجيل الدخول',
                                  style: const TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.w900),
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

  Future<void> _signInGoogle() async {
    setState(() => _loadingGoogle = true);
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
      if (mounted) Navigator.pop(context);
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
      _snack('كلمة المرور يجب أن تكون 6 أحرف على الأقل',
          Icons.lock_outline_rounded);
      return;
    }
    setState(() => _loadingEmail = true);
    try {
      if (_isLogin) {
        await ref.read(authServiceProvider).signInWithEmail(email, pass);
      } else {
        await ref.read(authServiceProvider).registerWithEmail(email, pass);
      }
      if (mounted) Navigator.pop(context);
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
      _snack('تم إرسال رابط الاستعادة', Icons.check_circle_outline_rounded,
          success: true);
    } catch (_) {
      _snack('تعذّر إرسال الرابط', Icons.error_outline_rounded);
    }
  }

  void _snack(String msg, IconData icon, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(
            child: Text(msg,
                style: const TextStyle(
                    fontFamily: 'Cairo', fontWeight: FontWeight.bold))),
      ]),
      backgroundColor:
          success ? AppTheme.primaryColor : const Color(0xFF1E293B),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ));
  }
}

// ── Google Button ─────────────────────────────────────────────────────────
class _GoogleBtn extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;
  const _GoogleBtn({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 54,
        decoration: BoxDecoration(
          color: loading
              ? AppTheme.surfaceColor.withOpacity(0.6)
              : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: loading
            ? const Center(
                child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: AppTheme.primaryColor)))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                      width: 22,
                      height: 22,
                      child: CustomPaint(painter: _GooglePainter())),
                  const SizedBox(width: 12),
                  const Text(
                    'المتابعة بحساب Google',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                        fontSize: 14),
                  ),
                ],
              ),
      ),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    canvas.drawCircle(c, r, Paint()..color = Colors.white);
    final segs = [
      (Colors.red[600]!, -0.26, 0.5),
      (Colors.yellow[700]!, 0.24, 0.5),
      (Colors.green[600]!, 0.74, 0.5),
      (Colors.blue[600]!, 1.24, 0.74),
    ];
    for (final s in segs) {
      canvas.drawArc(
          Rect.fromCircle(center: c, radius: r - 1),
          s.$2 * 3.14159,
          s.$3 * 3.14159,
          true,
          Paint()..color = s.$1);
    }
    canvas.drawCircle(c, r * 0.45, Paint()..color = AppTheme.surfaceColor);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Field ─────────────────────────────────────────────────────────────────
class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? type;
  final bool obscure;
  final Widget? suffix;

  const _Field({
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
        labelStyle: const TextStyle(
            color: AppTheme.textSecondary, fontFamily: 'Cairo', fontSize: 13),
        prefixIcon:
            Icon(icon, color: AppTheme.textSecondary, size: 20),
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
          borderSide:
              const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
      ),
    );
  }
}