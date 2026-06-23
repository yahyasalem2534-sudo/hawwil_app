import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../auth/auth_screen.dart';
import '../cards/cards_screen.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final _screens = const [
    HomeScreen(),
    CardsScreen(),
    ProfileScreen(),
  ];

  final _navItems = const [
    _NavItem(icon: Icons.home_rounded,      outlined: Icons.home_outlined,          label: 'الرئيسية'),
    _NavItem(icon: Icons.grid_view_rounded, outlined: Icons.grid_view_outlined,     label: 'الكتالوج'),
    _NavItem(icon: Icons.person_rounded,    outlined: Icons.person_outline_rounded, label: 'حسابي'),
  ];

  void _onTap(int i) {
    // حسابي يحتاج تسجيل دخول
    if (i == 2 && ref.read(currentUserProvider) == null) {
      _openAuth();
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _index = i);
  }

  void _openAuth() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const AuthScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 380),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // بعد تسجيل الدخول، اذهب لحسابي تلقائياً
    ref.listen(authStateProvider, (_, next) {
      if (next.value != null && _index == 0) {
        // لا نفعل شيئاً، فقط تحديث الحالة
      }
    });

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.backgroundColor,
      // Drawer من اليمين
      endDrawer: _buildDrawer(),
      body: Stack(
        children: [
          IndexedStack(index: _index, children: _screens),
          // زر فتح الـ Drawer في أعلى اليمين يُضاف من الـ HomeScreen
          // نستخدم SafeArea + Positioned
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 10, 16, 0),
                child: GestureDetector(
                  onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(13),
                      border:
                          Border.all(color: Colors.white.withOpacity(0.07)),
                    ),
                    child: const Icon(Icons.menu_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── Bottom Nav ─────────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.07), width: 1),
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 24,
              offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 62,
          child: Row(
            children: List.generate(
                _navItems.length, (i) => _navItem(i)),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int i) {
    final item = _navItems[i];
    final sel  = _index == i;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTap(i),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 230),
              curve: Curves.easeOutCubic,
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              decoration: BoxDecoration(
                color: sel
                    ? AppTheme.primaryColor.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                sel ? item.icon : item.outlined,
                color: sel ? AppTheme.primaryColor : Colors.grey[600],
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 230),
              style: TextStyle(
                fontSize: 10,
                fontFamily: 'Cairo',
                fontWeight: sel ? FontWeight.w900 : FontWeight.w500,
                color: sel ? AppTheme.primaryColor : Colors.grey[600]!,
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }

  // ── Drawer ─────────────────────────────────────────────────────────────
  Widget _buildDrawer() {
    final user = ref.watch(currentUserProvider);

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.78,
      backgroundColor: AppTheme.surfaceColor,
      child: SafeArea(
        child: Column(
          children: [
            // Header الـ Drawer
            Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.9),
                    AppTheme.primaryColor.withOpacity(0.5),
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.white.withOpacity(0.15),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.asset('assets/images/logo.png',
                          fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'حوّل',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      Text(
                        user?.email ?? 'متجرك للبطاقات الرقمية',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 11,
                          fontFamily: 'Cairo',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // قائمة الروابط
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _drawerItem(
                    icon: Icons.receipt_long_rounded,
                    label: 'سجل الطلبات',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _index = 2);
                      if (user == null) _openAuth();
                    },
                  ),
                  _divider(),
                  _drawerItem(
                    icon: Icons.info_outline_rounded,
                    label: 'من نحن',
                    onTap: () {
                      Navigator.pop(context);
                      _showInfoSheet('من نحن',
                          'حوّل هي منصة موريتانية متخصصة في بيع البطاقات الرقمية وشحن الألعاب. نسعى لتقديم أفضل الخدمات بأسرع وقت ممكن.');
                    },
                  ),
                  _drawerItem(
                    icon: Icons.headset_mic_rounded,
                    label: 'تواصل معنا',
                    onTap: () {
                      Navigator.pop(context);
                      _showInfoSheet('تواصل معنا',
                          'للتواصل مع فريق الدعم:\n📞 ${AppTheme.green}\nيمكنك التواصل معنا عبر الواتساب أو الاتصال المباشر على الرقم المعتمد.');
                    },
                  ),
                  _drawerItem(
                    icon: Icons.privacy_tip_outlined,
                    label: 'سياسة الخصوصية',
                    onTap: () {
                      Navigator.pop(context);
                      _showInfoSheet('سياسة الخصوصية',
                          'نحن نحترم خصوصيتك تماماً. البيانات التي تقدمها تُستخدم فقط لمعالجة طلباتك ولا تُشارك مع أي طرف ثالث.');
                    },
                  ),
                  _drawerItem(
                    icon: Icons.help_outline_rounded,
                    label: 'مركز المساعدة',
                    onTap: () {
                      Navigator.pop(context);
                      _showInfoSheet('مركز المساعدة',
                          'أكثر الأسئلة شيوعاً:\n\n• كم يستغرق تنفيذ الطلب؟\nعادةً من 5 إلى 30 دقيقة.\n\n• ما طرق الدفع المتاحة؟\nجميع البنوك الموريتانية المدعومة.\n\n• هل يمكن استرداد المبلغ؟\nفي حالة عدم التنفيذ يُعاد المبلغ كاملاً.');
                    },
                  ),
                  if (user != null) ...[
                    _divider(),
                    _drawerItem(
                      icon: Icons.delete_outline_rounded,
                      label: 'حذف الحساب',
                      color: Colors.redAccent,
                      onTap: () {
                        Navigator.pop(context);
                        _confirmDeleteAccount();
                      },
                    ),
                  ],
                ],
              ),
            ),

            // تذييل
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'حوّل © 2025 — الإصدار 1.0',
                style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontFamily: 'Cairo'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final c = color ?? Colors.white;
    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: (color ?? AppTheme.primaryColor).withOpacity(0.12),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, color: color ?? AppTheme.primaryColor, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: c,
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _divider() => Divider(
      color: Colors.white.withOpacity(0.07),
      height: 1,
      indent: 16,
      endIndent: 16);

  void _showInfoSheet(String title, String content) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Cairo')),
            const SizedBox(height: 14),
            Text(content,
                style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                    fontFamily: 'Cairo',
                    height: 1.8)),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('حذف الحساب',
            style: TextStyle(
                color: Colors.white,
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w900)),
        content: const Text(
          'هل أنت متأكد من حذف حسابك نهائياً؟ لا يمكن التراجع عن هذا الإجراء.',
          style: TextStyle(
              color: AppTheme.textSecondary, fontFamily: 'Cairo', height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء',
                style: TextStyle(
                    color: AppTheme.textSecondary, fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(firebaseServiceProvider).deleteAccount();
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('أعد تسجيل الدخول أولاً ثم حاول مجدداً',
                          style: TextStyle(fontFamily: 'Cairo')),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('حذف',
                style: TextStyle(
                    fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData outlined;
  final String label;
  const _NavItem(
      {required this.icon, required this.outlined, required this.label});
}