import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../main.dart';
import '../views/home/home_screen.dart';
import '../providers/auth_provider.dart';

class MainLayout extends ConsumerWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      // AppBar احترافي ونظيف
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset('assets/images/logo.png', width: 32, height: 32, fit: BoxFit.cover),
            ),
            const SizedBox(width: 10),
            const Text('HAWWIL', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: 1.5)),
          ],
        ),
        actions: [
          // زر تبديل الوضع (Dark/Light)
          IconButton(
            icon: Icon(isDark ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded),
            onPressed: () {
              ref.read(themeModeProvider.notifier).state = isDark ? ThemeMode.light : ThemeMode.dark;
            },
          ),
          
          // قائمة الثلاث نقاط الاحترافية (⋮)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, size: 28),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            position: PopupMenuPosition.under,
            elevation: 8,
            onSelected: (value) {
              _handleMenuSelection(value, context, ref);
            },
            itemBuilder: (BuildContext context) => [
              if (user == null)
                const PopupMenuItem(
                  value: 'login',
                  child: Row(
                    children: [
                      Icon(Icons.login_rounded, size: 20),
                      SizedBox(width: 12),
                      Text('تسجيل الدخول', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              if (user != null)
                PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: AppTheme.primaryColor,
                        backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                        child: user.photoURL == null ? const Icon(Icons.person, size: 16, color: Colors.white) : null,
                      ),
                      const SizedBox(width: 12),
                      Text(user.displayName ?? 'حسابي', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'about', child: Text('من نحن')),
              const PopupMenuItem(value: 'privacy', child: Text('سياسة الخصوصية')),
              const PopupMenuItem(value: 'terms', child: Text('الشروط والأحكام')),
              const PopupMenuItem(value: 'contact', child: Text('تواصل معنا')),
              if (user != null) const PopupMenuDivider(),
              if (user != null)
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                      SizedBox(width: 12),
                      Text('تسجيل الخروج', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      
      // الصفحة الرئيسية الوحيدة
      body: const HomeScreen(),
    );
  }

  void _handleMenuSelection(String value, BuildContext context, WidgetRef ref) {
    switch (value) {
      case 'login':
        _showAuthModal(context, ref);
        break;
      case 'logout':
        ref.read(authRepositoryProvider).signOut();
        break;
      // يمكنك لاحقاً إضافة Navigation لباقي الصفحات (من نحن، الشروط، إلخ) هنا
      case 'about':
      case 'privacy':
      case 'terms':
      case 'contact':
        // TODO: Navigate to respective screens
        break;
    }
  }

  void _showAuthModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AuthModal(),
    );
  }
}

// ============================================================================
// AuthModal - تم الاحتفاظ بالمنطق البرمجي مع تحسين المظهر ليكون Premium
// ============================================================================
class AuthModal extends ConsumerStatefulWidget {
  const AuthModal({super.key});
  @override
  ConsumerState<AuthModal> createState() => _AuthModalState();
}

class _AuthModalState extends ConsumerState<AuthModal> {
  bool _isLogin = true;
  bool _loading = false;
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String? _error;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, spreadRadius: 5)
        ]
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 30),
              
              // زر Google الفخم
              OutlinedButton.icon(
                onPressed: _loading ? null : _submitGoogle,
                icon: Image.network(
                  'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                  width: 24,
                  height: 24,
                ),
                label: const Text('المتابعة باستخدام Google', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                style: OutlinedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  foregroundColor: isDark ? Colors.white : Colors.black87,
                  side: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[300]!, width: 1.5),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Row(
                  children: [
                    Expanded(child: Divider(thickness: 0.5)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('أو باستخدام البريد', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ),
                    Expanded(child: Divider(thickness: 0.5)),
                  ],
                ),
              ),

              Row(
                children: [
                  Expanded(child: _AuthTab(label: 'دخول', isActive: _isLogin, onTap: () => setState(() => _isLogin = true))),
                  Expanded(child: _AuthTab(label: 'حساب جديد', isActive: !_isLogin, onTap: () => setState(() => _isLogin = false))),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'البريد الإلكتروني', 
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'كلمة المرور', 
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.w600)),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _submitEmail,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                    : Text(_isLogin ? 'تسجيل الدخول' : 'إنشاء حساب جديد', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitEmail() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      setState(() => _error = 'يرجى إدخال البريد وكلمة المرور');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final repo = ref.read(authRepositoryProvider);
      if (_isLogin) {
        await repo.signInWithEmail(_emailCtrl.text.trim(), _passCtrl.text.trim());
      } else {
        await repo.registerWithEmail(_emailCtrl.text.trim(), _passCtrl.text.trim());
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = 'تأكد من صحة البيانات أو كلمة المرور');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _submitGoogle() async {
    setState(() { _loading = true; _error = null; });
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.signInWithGoogle();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = 'حدث خطأ أثناء الدخول بحساب Google');
    }
    if (mounted) setState(() => _loading = false);
  }
}

class _AuthTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _AuthTab({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? AppTheme.primaryColor : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isActive ? AppTheme.primaryColor : Colors.grey[500],
          ),
        ),
      ),
    );
  }
}
