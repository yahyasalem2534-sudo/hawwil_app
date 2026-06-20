import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/data_providers.dart';
import '../../main_layout.dart';
import '../../widgets/game_card_widget.dart';
import '../cards/product_modal.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: RefreshIndicator(
        color: AppTheme.green,
        onRefresh: () async {},
        child: CustomScrollView(
          slivers: [
            // Hero Section
            SliverToBoxAdapter(child: _buildHero(context, ref)),

            // Order Tracker
            SliverToBoxAdapter(child: _buildOrderTracker(context, ref)),

            // Stats
            SliverToBoxAdapter(child: _buildStats()),

            // How it works
            SliverToBoxAdapter(child: _buildHowItWorks()),

            // Games Preview
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'البطاقات والألعاب',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    TextButton(
                      onPressed: () => ref
                          .read(currentTabProvider.notifier)
                          .state = 2,
                      child: const Text('عرض الكل',
                          style: TextStyle(color: AppTheme.green)),
                    ),
                  ],
                ),
              ),
            ),
            _buildGamesPreview(ref),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.greenDark, AppTheme.green],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(99),
            ),
            child: const Text(
              '🇲🇷 خدمات مالية موريتانية موثوقة',
              style: TextStyle(
                  color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'حوّل أموالك بين\nالبنوك الموريتانية\nبكل سهولة',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'منصة آمنة وسريعة لتحويل الأموال وشراء البطاقات الرقمية.',
            style: TextStyle(
                color: Colors.white70, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () =>
                      ref.read(currentTabProvider.notifier).state = 1,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.green,
                    minimumSize: const Size(0, 46),
                  ),
                  child: const Text('🏦 ابدأ التحويل'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      ref.read(currentTabProvider.notifier).state = 2,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white60),
                    minimumSize: const Size(0, 46),
                  ),
                  child: const Text('🎮 البطاقات'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTracker(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🔍 تتبع حالة طلبك اللحظية',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: 'HW-12345 أو CRD-12345',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (controller.text.isNotEmpty) {
                        _showOrderStatus(context, ref, controller.text.trim());
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(70, 48),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text('بحث'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOrderStatus(BuildContext context, WidgetRef ref, String refNum) {
    showDialog(
      context: context,
      builder: (_) => _OrderStatusDialog(orderRef: refNum, ref: ref),
    );
  }

  Widget _buildStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: AppTheme.greenLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: const [
          _StatItem(value: '+10,000', label: 'عملية ناجحة'),
          _StatItem(value: '5%', label: 'عمولة شفافة'),
          _StatItem(value: '24س', label: 'دعم متواصل'),
          _StatItem(value: '100%', label: 'أمان مضمون'),
        ],
      ),
    );
  }

  Widget _buildHowItWorks() {
    const steps = [
      ('١', 'أرسل المبلغ', 'أرسل لرقم حسابنا في أي بنك'),
      ('٢', 'أرسل الطلب', 'أرفق معلومات التحويل والوصل'),
      ('٣', 'نُراجع الطلب', 'نتحقق من الإيداع ونحسب العمولة'),
      ('٤', 'تستلم المبلغ', 'نحوّل فوراً مع إشعار تأكيد'),
    ];

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              'كيف يعمل التحويل؟',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: steps.length,
            itemBuilder: (_, i) {
              final s = steps[i];
              return Container(
                width: 160,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE8F5EE)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.$1,
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.green)),
                    const SizedBox(height: 6),
                    Text(s.$2,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(s.$3,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGamesPreview(WidgetRef ref) {
    final gamesAsync = ref.watch(gamesProvider);

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: gamesAsync.when(
        loading: () => SliverGrid(
          delegate: SliverChildBuilderDelegate(
            (_, __) => Shimmer.fromColors(
              baseColor: Colors.grey[200]!,
              highlightColor: Colors.grey[100]!,
              child: Card(child: Container()),
            ),
            childCount: 4,
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
        ),
        error: (e, _) =>
            const SliverToBoxAdapter(child: Text('حدث خطأ في التحميل')),
        data: (games) => SliverGrid(
          delegate: SliverChildBuilderDelegate(
            (ctx, i) => GameCardWidget(
              game: games[i],
              onTap: () => showProductModal(ctx, games[i]),
            ),
            childCount: games.take(6).length,
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.green)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(fontSize: 10.5, color: Colors.grey),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _OrderStatusDialog extends ConsumerWidget {
  final String orderRef;
  final WidgetRef ref;

  const _OrderStatusDialog({required this.orderRef, required this.ref});

  @override
  Widget build(BuildContext ctx, WidgetRef r) {
    final svc = r.read(firebaseServiceProvider);

    return AlertDialog(
      title: Text('تتبع الطلب: $orderRef'),
      content: StreamBuilder<Map<String, dynamic>?>(
        stream: svc.trackOrder(orderRef),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const SizedBox(
                height: 60,
                child: Center(child: CircularProgressIndicator()));
          }
          if (!snap.hasData || snap.data == null) {
            return const Text('❌ لم يتم العثور على الطلب',
                style: TextStyle(color: AppTheme.red));
          }
          final data = snap.data!;
          final status = data['status'];
          if (status == 'done') {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('✅ تم اكتمال طلبك!',
                    style: TextStyle(
                        color: AppTheme.green, fontWeight: FontWeight.w800)),
                if (data['deliveredCode'] != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.greenLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppTheme.green, style: BorderStyle.solid),
                    ),
                    child: SelectableText(
                      data['deliveredCode'],
                      style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 18,
                          fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ],
            );
          } else if (status == 'rejected') {
            return const Text('❌ تم رفض الطلب. يرجى التواصل مع الدعم.',
                style: TextStyle(color: AppTheme.red));
          }
          return const Text('⏳ طلبك قيد المراجعة...',
              style: TextStyle(
                  color: Colors.orange, fontWeight: FontWeight.w800));
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('إغلاق'),
        ),
      ],
    );
  }
}
