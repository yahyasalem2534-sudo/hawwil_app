import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../auth/auth_screen.dart';
import '../home/home_screen.dart';
import '../cards/cards_screen.dart';
import '../transfer/transfer_screen.dart';
import '../profile/profile_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    CardsScreen(),
    TransferScreen(),
    ProfileScreen(),
  ];

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.home_rounded,        outlined: Icons.home_outlined,              label: 'الرئيسية'),
    _NavItem(icon: Icons.grid_view_rounded,   outlined: Icons.grid_view_outlined,         label: 'الكتالوج'),
    _NavItem(icon: Icons.swap_horiz_rounded,  outlined: Icons.swap_horiz_rounded,         label: 'التحويل'),
    _NavItem(icon: Icons.person_rounded,      outlined: Icons.person_outline_rounded,     label: 'حسابي'),
  ];

  void _onTap(int index) {
    // التحويل وحسابي يحتاجان تسجيل دخول
    if ((index == 2 || index == 3) &&
        ref.read(currentUserProvider).value == null) {
      _showAuthSheet();
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
  }

  void _showAuthSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AuthBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // مراقبة حالة المصادقة
    ref.listen(currentUserProvider, (_, next) {
      // بعد تسجيل الدخول، أغلق الـ Sheet تلقائياً
      if (next.value != null) {
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

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
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 62,
          child: Row(
            children: List.generate(
              _navItems.length,
              (i) => _buildNavItem(i),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final item       = _navItems[index];
    final isSelected = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryColor.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isSelected ? item.icon : item.outlined,
                color: isSelected ? AppTheme.primaryColor : Colors.grey[600],
                size: 23,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: TextStyle(
                fontSize: 10,
                fontFamily: 'Cairo',
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                color: isSelected ? AppTheme.primaryColor : Colors.grey[600]!,
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sheet صغير يعرض خيار تسجيل الدخول ─────────────────────────────────────
class _AuthBottomSheet extends StatelessWidget {
  const _AuthBottomSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 40),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // مقبض
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 24),
          const Icon(Icons.lock_outline_rounded, color: AppTheme.primaryColor, size: 40),
          const SizedBox(height: 14),
          const Text(
            'يرجى تسجيل الدخول',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'تحتاج إلى حساب للوصول لهذه الميزة',
            style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo', fontSize: 13),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => const AuthScreen(),
                    transitionsBuilder: (_, anim, __, child) =>
                        FadeTransition(opacity: anim, child: child),
                    transitionDuration: const Duration(milliseconds: 400),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text(
                'تسجيل الدخول / إنشاء حساب',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, fontFamily: 'Cairo'),
              ),
            ),
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
  const _NavItem({required this.icon, required this.outlined, required this.label});
}
