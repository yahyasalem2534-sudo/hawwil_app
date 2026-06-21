import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme/app_theme.dart';
import '../main.dart';
import '../views/home/home_screen.dart';
import '../views/cards/cards_screen.dart';
import '../views/profile/profile_screen.dart';
import '../providers/auth_provider.dart';

final currentTabProvider = StateProvider<int>((ref) => 0);

class MainLayout extends ConsumerWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(currentTabProvider);
    final user = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    // تم إضافة 3 شاشات لتتناسب مع الـ Bottom Navigation
    final tabs = [
      const HomeScreen(),
      const CardsScreen(),
      if (user != null) const ProfileScreen() else const SizedBox.shrink(),
    ];

    return Scaffold(
      // --- القائمة الجانبية الاحترافية (Drawer) ---
      drawer: _buildDrawer(context, ref, user),
      
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, size: 28),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset('assets/images/logo.png', width: 32, height: 32, fit: BoxFit.cover),
            ),
            const SizedBox(width: 10),
            const Text('حوّل', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded),
            onPressed: () {
              ref.read(themeModeProvider.notifier).state = isDark ? ThemeMode.light : ThemeMode.dark;
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      
      body: IndexedStack(
        index: currentTab.clamp(0, tabs.length - 1),
        children: tabs,
      ),

      // --- شريط التنقل السفلي الحديث (GNav) ---
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            )
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 12),
            child: GNav(
              rippleColor: AppTheme.greenLight,
              hoverColor: AppTheme.greenLight.withOpacity(0.5),
              gap: 8,
              activeColor: AppTheme.green,
              iconSize: 26,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor: isDark ? AppTheme.greenDark.withOpacity(0.2) : AppTheme.greenLight,
              color: isDark ? Colors.grey[400]! : Colors.grey[600]!,
              tabs: [
                const GButton(
                  icon: Icons.home_rounded,
                  text: 'الرئيسية',
                ),
                const GButton(
                  icon: Icons.gamepad_rounded,
                  text: 'البطاقات',
                ),
                GButton(
                  icon: user != null ? Icons.person_rounded : Icons.login_rounded,
                  text: user != null ? 'حسابي' : 'دخول',
                ),
              ],
              selectedIndex: currentTab.clamp(0, 2),
              onTabChange: (index) {
                if (index == 2 && user == null) {
                  _showAuthModal(context, ref);
                  return;
                }
                ref.read(currentTabProvider.notifier).state = index;
              },
            ),
          ),
        ),
      ),
    );
  }

  // تصميم القائمة الجانبية (Drawer)
  Widget _buildDrawer(BuildContext context, WidgetRef ref, dynamic user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: isDark ? AppTheme.backgroundDark : Colors.white),
            margin: EdgeInsets.zero,
            accountName: Text(
              user != null ? (user.displayName ?? 'مستخدم حوّل') : 'مرحباً بك في حوّل',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            accountEmail: Text(
              user?.email ?? 'سجل دخولك للاستمتاع بخدماتنا',
              style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: AppTheme.greenLight,
              backgroundImage: user?.photoURL != null ? NetworkImage(user.photoURL!) : null,
              child: user?.photoURL == null
                  ? const Icon(Icons.person, size: 40, color: AppTheme.green)
                  : null,
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 8),
              children: [
                if (user != null) ...[
                  _buildDrawerItem(icon: Icons.person_outline, title: 'حسابي', onTap: () {
                    Navigator.pop(context);
                    ref.read(currentTabProvider.notifier).state = 2;
                  }),
                  _buildDrawerItem(icon: Icons.shopping_bag_outlined, title: 'طلباتي', onTap: () {}),
                  const Divider(indent: 20, endIndent: 20),
                ],
                _buildDrawerItem(icon: Icons.help_outline, title: 'مركز المساعدة', onTap: () {}),
                _buildDrawerItem(icon: Icons.privacy_tip_outlined, title: 'سياسة الخصوصية', onTap: () {}),
                _buildDrawerItem(icon: Icons.description_outlined, title: 'الشروط والأحكام', onTap: () {}),
                _buildDrawerItem(icon: Icons.info_outline, title: 'حول تطبيق حوّل', onTap: () {}),
                const Divider(indent: 20, endIndent: 20),
                _buildDrawerItem(icon: Icons.support_agent_rounded, title: 'تواصل معنا', onTap: () {}),
              ],
            ),
          ),
          if (user != null) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: AppTheme.redLight,
                leading: const Icon(Icons.delete_forever_rounded, color: AppTheme.red),
                title: const Text('حذف الحساب', style: TextStyle(color: AppTheme.red, fontWeight: FontWeight.bold)),
                onTap: () {
                  // TODO: إضافة منطق حذف الحساب
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0, right: 16, left: 16),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                  foregroundColor: isDark ? Colors.white : Colors.black87,
                ),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('تسجيل الخروج'),
                onPressed: () {
                  ref.read(authRepositoryProvider).signOut();
                  Navigator.pop(context);
                },
              ),
            )
          ] else ...[
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showAuthModal(context, ref);
                },
                child: const Text('تسجيل الدخول'),
              ),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildDrawerItem({required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, size: 26),
      title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      onTap: onTap,
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
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, spreadRadius: 5)
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
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 30),
              
              // زر Google Barz ومميز
              OutlinedButton.icon(
                onPressed: _loading ? null : _submitGoogle,
                icon: Image.network(
                  'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                  width: 26,
                  height: 26,
                ),
                label: const Text('المتابعة باستخدام Google', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                style: OutlinedButton.styleFrom(
                  backgroundColor: isDark ? Colors.grey[800] : Colors.white,
                  foregroundColor: isDark ? Colors.white : Colors.black87,
                  side: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!, width: 1.5),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
              
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('أو باستخدام البريد', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                    ),
                    Expanded(child: Divider()),
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
                decoration: const InputDecoration(labelText: 'البريد الإلكتروني', prefixIcon: Icon(Icons.email_outlined)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'كلمة المرور', prefixIcon: Icon(Icons.lock_outline)),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: AppTheme.red, fontSize: 14, fontWeight: FontWeight.w600)),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _submitEmail,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _loading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                    : Text(_isLogin ? 'تسجيل الدخول' : 'إنشاء حساب جديد', style: const TextStyle(fontSize: 18)),
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
              color: isActive ? AppTheme.green : Colors.transparent,
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
            color: isActive ? AppTheme.green : Colors.grey[500],
          ),
        ),
      ),
    );
  }
}
