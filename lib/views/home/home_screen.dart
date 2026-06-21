import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme/app_theme.dart';
import '../../models/game_model.dart';
import '../../providers/data_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // جلب البيانات باستخدام المزودات المنفصلة التي قمت ببرمجتها
    final slidersAsync = ref.watch(slidersProvider);
    final gamesAsync = ref.watch(gameGamesProvider);
    final servicesAsync = ref.watch(serviceGamesProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              _buildSearchBar(context),
              const SizedBox(height: 20),
              
              // قسم السلايدر مربوط بـ Firebase
              _buildHeroSlider(context, slidersAsync),
              
              const SizedBox(height: 24),
              _buildSectionTitle('الألعاب الأكثر طلباً', () {}),
              // قسم الألعاب
              _buildProductsSection(gamesAsync),
              
              const SizedBox(height: 24),
              _buildSectionTitle('البطاقات الرقمية', () {}),
              // قسم الخدمات/البطاقات
              _buildProductsSection(servicesAsync),
              
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // --- شريط البحث ---
  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'ابحث عن لعبة أو بطاقة...',
            hintStyle: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w600),
            prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.green, size: 28),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            fillColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }

  // --- السلايدر المربوط بـ Firebase ---
  Widget _buildHeroSlider(BuildContext context, AsyncValue<List<String>> slidersAsync) {
    return slidersAsync.when(
      data: (urls) {
        if (urls.isEmpty) {
          // سلايدر افتراضي في حال لم تكن هناك صور في قاعدة البيانات
          return _buildDefaultSliderItem(context, 'https://images.unsplash.com/photo-1605901309584-818e25960b8f?q=80&w=1000');
        }
        return CarouselSlider(
          options: CarouselOptions(
            height: 180.0,
            enlargeCenterPage: true,
            autoPlay: true,
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            viewportFraction: 0.9,
          ),
          items: urls.map((imageUrl) => _buildDefaultSliderItem(context, imageUrl)).toList(),
        );
      },
      loading: () => _buildSliderShimmer(context),
      error: (error, stack) => _buildDefaultSliderItem(context, 'https://images.unsplash.com/photo-1542751371-adc38448a05e?q=80&w=1000'),
    );
  }

  // تصميم عنصر السلايدر
  Widget _buildDefaultSliderItem(BuildContext context, String imageUrl) {
    return Container(
      width: MediaQuery.of(context).size.width,
      margin: const EdgeInsets.symmetric(horizontal: 5.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))
        ],
        image: DecorationImage(
          image: CachedNetworkImageProvider(imageUrl),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: 20, right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('عروض Hawwil', style: TextStyle(color: AppTheme.gold, fontSize: 16, fontWeight: FontWeight.bold)),
                Text('تسوق الآن', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // تأثير التحميل للسلايدر
  Widget _buildSliderShimmer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Container(
        height: 180.0,
        margin: const EdgeInsets.symmetric(horizontal: 20.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  // --- عنوان القسم ---
  Widget _buildSectionTitle(String title, VoidCallback onSeeAll) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          TextButton(
            onPressed: onSeeAll,
            child: const Text('عرض الكل', style: TextStyle(color: AppTheme.green, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  // --- قسم المنتجات (ألعاب أو بطاقات) ---
  Widget _buildProductsSection(AsyncValue<List<GameModel>> asyncGames) {
    return asyncGames.when(
      data: (items) {
        if (items.isEmpty) {
          return const SizedBox(
            height: 150,
            child: Center(child: Text('لا توجد منتجات حالياً', style: TextStyle(color: Colors.grey))),
          );
        }

        return SizedBox(
          height: 220,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              
              // حساب أقل سعر
              double startingPrice = 0;
              if (item.pkgs.isNotEmpty) {
                startingPrice = item.pkgs.map((p) => p.price).reduce((a, b) => a < b ? a : b);
              }

              final imageUrl = item.logo ?? item.icon ?? '';

              return ProductCard(
                game: item, // نمرر الكائن كاملاً لنستخدمه عند الضغط
                startingPrice: startingPrice.toStringAsFixed(0),
                imageUrl: imageUrl,
              );
            },
          ),
        );
      },
      loading: () => _buildProductsShimmer(context),
      error: (error, stack) => const SizedBox(
        height: 150, 
        child: Center(child: Text('حدث خطأ في جلب البيانات', style: TextStyle(color: AppTheme.red)))
      ),
    );
  }

  // تأثير التحميل للمنتجات
  Widget _buildProductsShimmer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 220,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
            highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
            child: Container(
              width: 150,
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            ),
          );
        },
      ),
    );
  }
}

// --- بطاقة المنتج ---
class ProductCard extends StatelessWidget {
  final GameModel game;
  final String startingPrice;
  final String imageUrl;

  const ProductCard({
    super.key,
    required this.game,
    required this.startingPrice,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // TODO: فتح ProductModal وتمرير الكائن game
            // showModalBottomSheet(context: context, builder: (_) => ProductModal(game: game));
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: imageUrl.isEmpty
                      ? const Icon(Icons.videogame_asset, size: 50, color: Colors.grey)
                      : CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.contain, // لحل مشكلة قص الصور
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: AppTheme.greenLight)),
                          errorWidget: (context, url, error) => const Icon(Icons.image_not_supported, color: Colors.grey),
                        ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        game.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Row(
                        children: [
                          const Text('يبدأ من: ', style: TextStyle(color: Colors.grey, fontSize: 10)),
                          Text(
                            '$startingPrice أوقية',
                            style: const TextStyle(color: AppTheme.green, fontWeight: FontWeight.w900, fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
