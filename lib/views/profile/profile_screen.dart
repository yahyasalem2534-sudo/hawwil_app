import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
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

    setState(() {
      _transfers = transfers;
      _cards = cards;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('حسابي وطلباتي'),
        actions: [
          IconButton(
            onPressed: () async {
              await ref.read(firebaseServiceProvider).signOut();
            },
            icon: const Icon(Icons.logout_rounded, color: AppTheme.red),
            tooltip: 'تسجيل الخروج',
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppTheme.green,
          indicatorColor: AppTheme.green,
          tabs: const [
            Tab(text: '🏦 تحويلاتي'),
            Tab(text: '🎮 بطاقاتي'),
          ],
        ),
      ),
      body: Column(
        children: [
          // User Email Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppTheme.greenLight,
            child: Text(
              user?.email ?? '',
              style: const TextStyle(
                  fontWeight: FontWeight.w800, color: AppTheme.green),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _buildTransfersList(),
                      _buildCardsList(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransfersList() {
    if (_transfers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.swap_horiz_rounded, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('لا توجد تحويلات سابقة.',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _transfers.length,
        itemBuilder: (_, i) => _TransferCard(
            order: _transfers[i], fmt: _fmt),
      ),
    );
  }

  Widget _buildCardsList() {
    if (_cards.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.gamepad_rounded, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('لا توجد طلبات بطاقات سابقة.',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _cards.length,
        itemBuilder: (_, i) => _CardOrderCard(
            order: _cards[i], fmt: _fmt),
      ),
    );
  }
}

class _TransferCard extends StatelessWidget {
  final TransferOrder order;
  final NumberFormat fmt;

  const _TransferCard({required this.order, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(order.ref,
                    style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w900,
                        color: AppTheme.green)),
                _StatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 10),
            Text('المبلغ: ${fmt.format(order.amount)} أوقية',
                style: const TextStyle(fontSize: 13)),
            Text('${order.fromBank} ➡️ ${order.toBank}',
                style: const TextStyle(fontSize: 13)),
            Text('يستلم: ${fmt.format(order.receive)} أوقية',
                style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.green,
                    fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _CardOrderCard extends StatelessWidget {
  final CardOrder order;
  final NumberFormat fmt;

  const _CardOrderCard({required this.order, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(order.ref,
                    style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w900,
                        color: AppTheme.green)),
                _StatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 10),
            Text('${order.game} (${order.package})',
                style: const TextStyle(fontSize: 13)),
            Text('السعر: ${fmt.format(order.price)} أوقية',
                style: const TextStyle(fontSize: 13)),
            if (order.status == 'done' && order.deliveredCode != null)
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.greenLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.green),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('كود الشحن:',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 4),
                    SelectableText(
                      order.deliveredCode!,
                      style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 18,
                          fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 32,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: order.deliveredCode!));
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('📋 تم نسخ الكود!')));
                        },
                        icon: const Icon(Icons.copy, size: 14),
                        label: const Text('نسخ الكود',
                            style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12)),
                      ),
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

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'done':
        bg = AppTheme.greenLight;
        fg = AppTheme.green;
        label = '✅ مكتمل';
        break;
      case 'rejected':
        bg = AppTheme.redLight;
        fg = AppTheme.red;
        label = '❌ مرفوض';
        break;
      default:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
        label = '⏳ قيد المراجعة';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(99)),
      child: Text(label,
          style: TextStyle(
              color: fg, fontSize: 11, fontWeight: FontWeight.w800)),
    );
  }
}
