import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme/app_theme.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<TransferOrder> _transfers = [];
  List<CardOrder> _cards = [];
  bool _loading = true;
  final _fmt = NumberFormat('#,###', 'ar');

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _loading = true);
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final svc = ref.read(firebaseServiceProvider);
    final transfers = await svc.getUserTransfers(user.uid);
    final cards = await svc.getUserCards(user.uid);

    if (mounted) {
      setState(() {
        _transfers = transfers;
        _cards = cards;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('حسابي'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: () async {
              await ref.read(firebaseServiceProvider).signOut();
            },
            icon: const Icon(Icons.logout_rounded, color: AppTheme.red),
            tooltip: 'تسجيل الخروج',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // --- بطاقة معلومات المستخدم (Profile Header) ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.green, AppTheme.greenDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: AppTheme.green.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))
                      ],
                    ),
                    child: Center(
                      child: Text(
                        (user?.email ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.green),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'مرحباً بك،',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        Text(
                          user?.email ?? 'مستخدم غير معروف',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // --- التبويبات (TabBar) ---
          TabBar(
            controller: _tabCtrl,
            labelColor: AppTheme.green,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.green,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            tabs: const [
              Tab(icon: Icon(Icons.gamepad_rounded), text: 'طلبات البطاقات'),
              Tab(icon: Icon(Icons.swap_horiz_rounded), text: 'التحويلات المالية'),
            ],
          ),

          // --- محتوى الطلبات (TabBarView) ---
          Expanded(
            child: _loading
                ? _buildShimmerLoading()
                : TabBarView(
                    controller: _tabCtrl,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildCardsList(isDark),
                      _buildTransfersList(isDark),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // --- تأثير التحميل ---
  Widget _buildShimmerLoading() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 4,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Shimmer.fromColors(
          baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
          child: Container(
            height: 120,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
    );
  }

  // --- قائمة البطاقات ---
  Widget _buildCardsList(bool isDark) {
    if (_cards.isEmpty) {
      return _buildEmptyState('لا توجد طلبات بطاقات أو ألعاب حتى الآن.', Icons.sports_esports_rounded);
    }
    return RefreshIndicator(
      onRefresh: _loadOrders,
      color: AppTheme.green,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        itemCount: _cards.length,
        itemBuilder: (_, i) => _CardOrderWidget(order: _cards[i], fmt: _fmt, isDark: isDark),
      ),
    );
  }

  // --- قائمة التحويلات ---
  Widget _buildTransfersList(bool isDark) {
    if (_transfers.isEmpty) {
      return _buildEmptyState('لا توجد عمليات تحويل مالي حتى الآن.', Icons.account_balance_wallet_rounded);
    }
    return RefreshIndicator(
      onRefresh: _loadOrders,
      color: AppTheme.green,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        itemCount: _transfers.length,
        itemBuilder: (_, i) => _TransferCardWidget(order: _transfers[i], fmt: _fmt, isDark: isDark),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppTheme.greenLight.withOpacity(0.5), shape: BoxShape.circle),
            child: Icon(icon, size: 64, color: AppTheme.green),
          ),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ==========================================
// تصميم بطاقة طلب (الألعاب/البطاقات)
// ==========================================
class _CardOrderWidget extends StatelessWidget {
  final CardOrder order;
  final NumberFormat fmt;
  final bool isDark;

  const _CardOrderWidget({required this.order, required this.fmt, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // الهيدر (رقم الطلب والحالة)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_long_rounded, size: 18, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      order.ref,
                      style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w900, color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                _StatusBadge(status: order.status),
              ],
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
            
            // تفاصيل المنتج
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: isDark ? Colors.grey[800] : Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.gamepad_rounded, color: AppTheme.green),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.game, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(order.package, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('السعر', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    Text('${fmt.format(order.price)} أوقية', style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.green)),
                  ],
                ),
              ],
            ),

            // كود الشحن (يظهر فقط إذا كان الطلب مكتمل ويوجد كود)
            if (order.status == 'done' && order.deliveredCode != null && order.deliveredCode!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.greenLight.withOpacity(isDark ? 0.1 : 0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.green.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.vpn_key_rounded, size: 16, color: AppTheme.green),
                        SizedBox(width: 6),
                        Text('كود الشحن الخاص بك:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.greenDark)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: SelectableText(
                            order.deliveredCode!,
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: order.deliveredCode!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('📋 تم نسخ الكود بنجاح!'), backgroundColor: AppTheme.green, behavior: SnackBarBehavior.floating),
                            );
                          },
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          label: const Text('نسخ', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(80, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

// ==========================================
// تصميم بطاقة التحويل المالي
// ==========================================
class _TransferCardWidget extends StatelessWidget {
  final TransferOrder order;
  final NumberFormat fmt;
  final bool isDark;

  const _TransferCardWidget({required this.order, required this.fmt, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
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
                    const Icon(Icons.receipt_long_rounded, size: 18, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      order.ref,
                      style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w900, color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                _StatusBadge(status: order.status),
              ],
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
            
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: isDark ? Colors.grey[800] : Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.account_balance_rounded, color: AppTheme.gold),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('مسار التحويل', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text('${order.fromBank} ➔ ${order.toBank}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('المبلغ المرسل', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      Text('${fmt.format(order.amount)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('المبلغ المستلم', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      Text('${fmt.format(order.receive)} أوقية', style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.green, fontSize: 15)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// تصميم شارة الحالة (Status Badge)
// ==========================================
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'done':
        bg = AppTheme.greenLight;
        fg = AppTheme.green;
        label = 'مكتمل';
        icon = Icons.check_circle_rounded;
        break;
      case 'rejected':
        bg = AppTheme.redLight;
        fg = AppTheme.red;
        label = 'مرفوض';
        icon = Icons.cancel_rounded;
        break;
      default:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
        label = 'قيد المراجعة';
        icon = Icons.hourglass_top_rounded;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) bg = bg.withOpacity(0.2);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
