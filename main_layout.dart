import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'main.dart';
import 'views/home/home_screen.dart';
import 'views/transfer/transfer_screen.dart';
import 'views/cards/cards_screen.dart';
import 'views/profile/profile_screen.dart';
import 'providers/auth_provider.dart';

final currentTabProvider = StateProvider<int>((ref) => 0);

class MainLayout extends ConsumerWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(currentTabProvider);
    final user = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    final tabs = [
      const HomeScreen(),
      const TransferScreen(),
      const CardsScreen(),
      if (user != null) const ProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset('assets/images/logo.png',
                  width: 32, height: 32, fit: BoxFit.cover),
            ),
            const SizedBox(width: 8),
            const Text('حوّل',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded),
            onPressed: () {
              ref.read(themeModeProvider.notifier).state =
                  isDark ? ThemeMode.light : ThemeMode.dark;
            },
          ),
          if (user == null)
            TextButton(
              onPressed: () => _showAuthModal(context, ref),
              child: const Text('دخول', style: TextStyle(fontWeight: FontWeight.w800)),
            )
          else
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.greenLight,
                child: Text(
                  (user.email ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(
                      color: AppTheme.green, fontWeight: FontWeight.w900),
                ),
              ),
            ),
        ],
      ),
      body: IndexedStack(
        index: currentTab.clamp(0, tabs.length - 1),
        children: tabs,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentTab.clamp(0, user != null ? 3 : 2),
        onDestinationSelected: (i) {
          if (i == 3 && user == null) {
            _showAuthModal(context, ref);
            return;
          }
          ref.read(currentTabProvider.notifier).state = i;
        },
        backgroundColor: Theme.of(context).cardColor,
        indicatorColor: AppTheme.greenLight,
        destinations: [
          const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: AppTheme.green),
              label: 'الرئيسية'),
          const NavigationDestination(
              icon: Icon(Icons.swap_horiz_outlined),
              selectedIcon: Icon(Icons.swap_horiz_rounded, color: AppTheme.green),
              label: 'التحويل'),
          const NavigationDestination(
              icon: Icon(Icons.gamepad_outlined),
              selectedIcon: Icon(Icons.gamepad_rounded, color: AppTheme.green),
              label: 'البطاقات'),
          NavigationDestination(
              icon: Icon(user != null ? Icons.person_outline : Icons.login_outlined),
              selectedIcon: Icon(
                  user != null ? Icons.person_rounded : Icons.login_rounded,
                  color: AppTheme.green),
              label: user != null ? 'حسابي' : 'دخول'),
        ],
      ),
    );
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

// ── Auth Modal ──
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
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 20),
            
            // --- تبويبات البريد الإلكتروني ---
            Row(
              children: [
                Expanded(
                  child: _AuthTab(
                    label: 'تسجيل الدخول',
                    isActive: _isLogin,
                    onTap: () => setState(() => _isLogin = true),
                  ),
                ),
                Expanded(
                  child: _AuthTab(
                    label: 'حساب جديد',
                    isActive: !_isLogin,
                    onTap: () => setState(() => _isLogin = false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'كلمة المرور',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppTheme.red, fontSize: 13)),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _submitEmail,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(_isLogin ? 'تسجيل الدخول' : 'إنشاء حساب'),
            ),
            
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('أو', style: TextStyle(color: Colors.grey)),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
            ),

            // --- زر Apple Sign In ---
            OutlinedButton.icon(
              onPressed: _loading ? null : _submitApple,
              icon: const Icon(Icons.apple, color: Colors.black, size: 24),
              label: const Text('المتابعة باستخدام Apple', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800)),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: Colors.black, width: 1.5),
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 12),
          ],
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
      setState(() => _error = 'تأكد من صحة البيانات (كلمة المرور 6 أحرف على الأقل)');
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _submitApple() async {
    setState(() { _loading = true; _error = null; });
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.signInWithApple();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = 'لم يتم تفعيل Apple Sign-In بعد، أو حدث خطأ.');
    }
    
    if (mounted) {
      setState(() => _loading = false);
    }
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
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? AppTheme.green : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: isActive ? AppTheme.green : Colors.grey,
          ),
        ),
      ),
    );
  }
}
