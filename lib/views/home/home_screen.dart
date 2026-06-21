import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/data_providers.dart';
import '../../widgets/game_card_widget.dart';
import '../cards/product_modal.dart';
import '../../services/firebase_service.dart'; // تم إضافة الاستدعاء الصحيح للفايربيس

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // تم تصحيح لون الخلفية هنا
      backgroundColor: isDarkMode ? const Color(0xFF0D0D0D) : Colors.grey[50],
      body: RefreshIndicator(
        color: AppTheme.green,
        onRefresh: () async {
          ref.invalidate(slidersProvider);
          ref.invalidate(gamesProvider);
        },
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // 1. السلايدر الاحترافي (Banner Carousel)
            SliverToBoxAdapter(
              child: _buildBannerCarousel(ref),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // 2. تتبع الطلبات (للبطاقات)
            SliverToBoxAdapter(child: _buildOrderTracker(context, ref)),

            // 3. عنوان قسم الألعاب والبطاقات
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.sports_esports, color: AppTheme.green),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'شحن الألعاب',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      // تم تصحيح زر عرض الكل لتجنب أخطاء التوجيه
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('جميع البطاقات معروضة بالأسفل')),
                        );
                      },
                      child: const Text('عرض الكل', style: TextStyle(color: AppTheme.green, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),

            // 4. شبكة الألعاب المتجاوبة
            _buildGamesGrid(ref),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerCarousel(WidgetRef ref) {
    final slidersAsync = ref.watch(slidersProvider);

    return slidersAsync.when(
      loading: () => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          height: 180,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      error: (e, _) => SizedBox(
        height: 180,
        child: Center(
          child: Text(
            'عذراً، تعذر تحميل العروض',
            style: TextStyle(color: Colors.red[300], fontWeight: FontWeight.bold),
          ),
        ),
      ),
      data: (images) {
        if (images.isEmpty) return const SizedBox();

        return CarouselSlider(
          options: CarouselOptions(
            height: 180.0,
            autoPlay: true,
            enlargeCenterPage: true,
            aspectRatio: 16 / 9,
            autoPlayCurve: Curves.fastOutSlowIn,
            enableInfiniteScroll: true,
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            viewportFraction: 0.92,
          ),
          items: images.map((imageUrl) {
            return Builder(
              builder: (BuildContext context) {
                return Container(
                  width: MediaQuery.of(context).size.width,
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.grey[200]),
                      errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.grey),
                    ),
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildOrderTracker(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: isDarkMode ? 0 : 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                      decoration: InputDecoration(
                        hintText: 'مثال: CRD-12345',
                        isDense: true,
                        filled: true,
                        fillColor: isDarkMode ? Colors.black12 : Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
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
                      minimumSize: const Size(80, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: const Text('بحث', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGamesGrid(WidgetRef ref) {
    final gamesAsync = ref.watch(gamesProvider);

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: gamesAsync.when(
        loading: () => SliverGrid(
          delegate: SliverChildBuilderDelegate(
            (_, __) => Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Container(),
              ),
            ),
            childCount: 4,
          ),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 220,
            mainAxisExtent: 270,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
          ),
        ),
        error: (e, _) => const SliverToBoxAdapter(
          child: Center(child: Text('حدث خطأ في تحميل الألعاب')),
        ),
        data: (games) {
          if (games.isEmpty) {
            return const SliverToBoxAdapter(
              child: Center(child: Text('لا توجد بطاقات حالياً')),
            );
          }

          return SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => GameCardWidget(
                game: games[i],
                onTap: () => showProductModal(ctx, games[i]),
              ),
              childCount: games.length, 
            ),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220, 
              mainAxisExtent: 270, 
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
            ),
          );
        },
      ),
    );
  }

  void _showOrderStatus(BuildContext context, WidgetRef ref, String refNum) {
    showDialog(
      context: context,
      builder: (_) => _OrderStatusDialog(orderRef: refNum, ref: ref),
    );
  }
}

class _OrderStatusDialog extends ConsumerWidget {
  final String orderRef;
  final WidgetRef ref;

  const _OrderStatusDialog({required this.orderRef, required this.ref});

  @override
  Widget build(BuildContext ctx, WidgetRef r) {
    // تم تصحيح استدعاء الفايربيس هنا ليعمل بشكل مباشر ومضمون
    final svc = FirebaseService();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('تتبع الطلب: $orderRef', style: const TextStyle(fontSize: 16)),
      content: StreamBuilder<Map<String, dynamic>?>(
        stream: svc.trackOrder(orderRef),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 60,
              child: Center(child: CircularProgressIndicator(color: AppTheme.green)),
            );
          }
          if (!snap.hasData || snap.data == null) {
            return const Text('❌ لم يتم العثور على الطلب',
                style: TextStyle(color: AppTheme.red, fontWeight: FontWeight.bold));
          }
          final data = snap.data!;
          final status = data['status'];
          if (status == 'done') {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('✅ تم اكتمال طلبك!',
                    style: TextStyle(color: AppTheme.green, fontWeight: FontWeight.w900, fontSize: 18)),
                if (data['deliveredCode'] != null) ...[
                  const SizedBox(height: 16),
                  const Text('كود البطاقة:', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.greenLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.green.withOpacity(0.5)),
                    ),
                    child: SelectableText(
                      data['deliveredCode'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 20,
                          color: AppTheme.greenDark,
                          fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ],
            );
          } else if (status == 'rejected') {
            return const Text('❌ تم رفض الطلب. يرجى التواصل مع الدعم.',
                style: TextStyle(color: AppTheme.red, fontWeight: FontWeight.bold));
          }
          return const Text('⏳ طلبك قيد المراجعة...',
              style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w900, fontSize: 16));
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('إغلاق', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
