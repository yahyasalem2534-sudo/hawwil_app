import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme/app_theme.dart';
import '../../models/order_model.dart';
import '../../providers/providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  List<CardOrder> _orders = [];
  bool _loading = true;
  final _fmt = NumberFormat('#,###', 'ar');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final user = ref.read(currentUserProvider);
    if (user == null) {
      setState(() => _loading = false);
      return;
    }
    final orders =
        await ref.read(firebaseServiceProvider).getUserCards(user.uid);
    if (mounted) setState(() { _orders = orders; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  const Text(
                    'حسابي',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const Spacer(),
                  if (user != null)
                    GestureDetector(
                      onTap: () async =>
                          ref.read(firebaseServiceProvider).signOut(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(
                              color: Colors.redAccent.withOpacity(0.25)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.logout_rounded,
                                color: Colors.redAccent, size: 15),
                            SizedBox(width: 5),
                            Text('خروج',
                                style: TextStyle(
                                    color: Colors.redAccent,
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // بطاقة المستخدم
            if (user != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor.withOpacity(0.8),
                        AppTheme.primaryColor.withOpacity(0.4),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 8)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle),
                        child: Center(
                          child: Text(
                            (user.email ?? 'U')[0].toUpperCase(),
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.primaryColor,
                                fontFamily: 'Cairo'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('مرحباً بك،',
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontFamily: 'Cairo')),
                            const SizedBox(height: 3),
                            Text(
                              user.email ?? 'مستخدم',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Cairo'),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${_orders.length}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Cairo'),
                          ),
                          const Text('طلب',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontFamily: 'Cairo')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // عنوان القائمة
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text(
                    'طلباتي',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        fontFamily: 'Cairo'),
                  ),
                  const Spacer(),
                  if (!_loading)
                    GestureDetector(
                      onTap: _load,
                      child: const Icon(Icons.refresh_rounded,
                          color: AppTheme.textSecondary, size: 20),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // القائمة
            Expanded(
              child: user == null
                  ? _buildNotLoggedIn()
                  : _loading
                      ? _shimmer()
                      : _orders.isEmpty
                          ? _empty()
                          : RefreshIndicator(
                              onRefresh: _load,
                              color: AppTheme.primaryColor,
                              backgroundColor: AppTheme.surfaceColor,
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20),
                                physics: const BouncingScrollPhysics(
                                    parent:
                                        AlwaysScrollableScrollPhysics()),
                                itemCount: _orders.length,
                                itemBuilder: (_, i) =>
                                    _OrderTile(order: _orders[i], fmt: _fmt),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotLoggedIn() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_outline_rounded,
              size: 60, color: AppTheme.textSecondary),
          const SizedBox(height: 14),
          const Text('سجّل دخولك لعرض طلباتك',
              style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontFamily: 'Cairo',
                  fontSize: 14)),
        ],
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long_outlined,
                size: 50, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 14),
          const Text('لا توجد طلبات حتى الآن',
              style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _shimmer() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 3,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Shimmer.fromColors(
          baseColor: AppTheme.surfaceColor,
          highlightColor: AppTheme.surface2Color,
          child: Container(
            height: 100,
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18)),
          ),
        ),
      ),
    );
  }
}

// ── بطاقة الطلب ───────────────────────────────────────────────────────────
class _OrderTile extends StatelessWidget {
  final CardOrder order;
  final NumberFormat fmt;
  const _OrderTile({required this.order, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.receipt_long_rounded,
                        size: 13, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(order.ref,
                        style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
                _StatusBadge(status: order.status),
              ],
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child:
                  Divider(color: Colors.white.withOpacity(0.06), height: 1),
            ),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(Icons.gamepad_rounded,
                      color: AppTheme.primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.game,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'Cairo')),
                      const SizedBox(height: 2),
                      Text(order.package,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              fontFamily: 'Cairo')),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('السعر',
                        style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.textSecondary,
                            fontFamily: 'Cairo')),
                    Text(
                      '${fmt.format(order.price)} أوقية',
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primaryColor,
                          fontFamily: 'Cairo',
                          fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),

            // كود الشحن
            if (order.status == 'done' &&
                order.deliveredCode != null &&
                order.deliveredCode!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.vpn_key_rounded,
                            size: 13, color: AppTheme.primaryColor),
                        const SizedBox(width: 5),
                        const Text('كود الشحن',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                                fontFamily: 'Cairo')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            order.deliveredCode!,
                            style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1.5),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: order.deliveredCode!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('تم نسخ الكود!',
                                    style: TextStyle(fontFamily: 'Cairo')),
                                backgroundColor: AppTheme.primaryColor,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                margin: const EdgeInsets.all(16),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy_rounded, size: 14),
                          label: const Text('نسخ',
                              style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(68, 32),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9)),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    late Color bg, fg;
    late String label;
    late IconData icon;
    switch (status.toLowerCase()) {
      case 'done':
        bg = AppTheme.primaryColor.withOpacity(0.15);
        fg = AppTheme.primaryColor;
        label = 'مكتمل';
        icon = Icons.check_circle_rounded;
        break;
      case 'rejected':
        bg = Colors.redAccent.withOpacity(0.15);
        fg = Colors.redAccent;
        label = 'مرفوض';
        icon = Icons.cancel_rounded;
        break;
      default:
        bg = Colors.amber.withOpacity(0.15);
        fg = Colors.amber;
        label = 'قيد المراجعة';
        icon = Icons.hourglass_top_rounded;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: fg,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Cairo')),
        ],
      ),
    );
  }
}