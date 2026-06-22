import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:ui'; // لعمل تأثيرات Blur (Glassmorphism)

import '../../core/theme/app_theme.dart';
import '../../models/game_model.dart';
import '../../providers/data_providers.dart';
import '../cards/product_modal.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              const SizedBox(height: 16),
              _buildSearchBar(context),
              const SizedBox(height: 24),
              
              // السلايدر الاحترافي
              _buildHeroSlider(context, slidersAsync),
              
              const SizedBox(height: 32),
              
              // قسم الألعاب
              _buildSectionTitle('الألعاب الأكثر طلباً'),
              _buildProductsSection(context, gamesAsync),
              
              const SizedBox(height: 32),
              
              // قسم البطاقات الرقمية
              _buildSectionTitle('البطاقات الرقمية'),
              _buildProductsSection(context, servicesAsync),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 5)),
          ],
        ),
        child: TextField(
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'ابحث عن لعبة أو بطاقة...',
            hintStyle: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
            prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryColor, size: 28),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            fillColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSlider(BuildContext context, AsyncValue<List<String>> slidersAsync) {
    return slidersAsync.when(
      data: (urls) {
        if (urls.isEmpty) {
          // صورة افتراضية في حال عدم وجود صور
          return _buildDefaultSliderItem(context, 'https://images.unsplash.com/photo-1605901309584-818e25960b8f?q=80&w=1000');
        }
        return CarouselSlider(
          options: CarouselOptions(
            aspectRatio: 16 / 9, // نسبة عرض إلى ارتفاع قياسية واحترافية
            enlargeCenterPage: true,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 4),
            autoPlayAnimationDuration: const Duration(milliseconds: 1000),
            autoPlayCurve: Curves.fastOutSlowIn,
            viewportFraction: 0.92,
          ),
          items: urls.map((imageUrl) => _buildDefaultSliderItem(context, imageUrl)).toList(),
        );
      },
      loading: () => _buildSliderShimmer(context),
      error: (error, stack) => _buildDefaultSliderItem(context, 'https://images.unsplash.com/photo-1542751371-adc38448a05e?q=80&w=1000'),
    );
  }

  Widget _buildDefaultSliderItem(BuildContext context, String imageUrl) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 5.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
        ],
        image: DecorationImage(
          image: CachedNetworkImageProvider(imageUrl),
          fit: BoxFit.cover,
          // طبقة داكنة لضمان وضوح الزر
          colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.darken),
        ),
      ),
      child: Stack(
        alignment: Alignment.bottomCenter, // محاذاة كل شيء في الأسفل والمنتصف
        children: [
          // زر "تسوق الآن" في وسط أسفل السلايدر
          Positioned(
            bottom: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'تسوق الآن',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderShimmer(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF1E293B), // يتناسب مع اللون الداكن
      highlightColor: const Color(0xFF334155),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20.0),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
      child: Text(
        title, 
        style: const TextStyle(
          color: AppTheme.textPrimary, 
          fontSize: 22, 
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildProductsSection(BuildContext context, AsyncValue<List<GameModel>> asyncGames) {
    return asyncGames.when(
      data: (items) {
        if (items.isEmpty) {
          return const SizedBox(
            height: 150,
            child: Center(child: Text('لا توجد منتجات حالياً', style: TextStyle(color: AppTheme.textSecondary))),
          );
        }

        return SizedBox(
          height: 240, // زيادة الارتفاع ليتناسب مع التصميم الجديد للبطاقة
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              
              double startingPrice = 0;
              if (item.pkgs.isNotEmpty) {
                startingPrice = item.pkgs.map((p) => p.price).reduce((a, b) => a < b ? a : b);
              }

              final imageUrl = item.logo ?? item.icon ?? '';

              return ProductCard(
                game: item,
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
        child: Center(child: Text('حدث خطأ في جلب البيانات', style: TextStyle(color: Colors.redAccent)))
      ),
    );
  }

  Widget _buildProductsShimmer(BuildContext context) {
    return SizedBox(
      height: 240,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: const Color(0xFF1E293B),
            highlightColor: const Color(0xFF334155),
            child: Container(
              width: 160,
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================================
// تصميم بطاقة المنتج (Premium Dark Card)
// ============================================================================
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
      width: 160,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          highlightColor: AppTheme.primaryColor.withOpacity(0.1),
          splashColor: AppTheme.primaryColor.withOpacity(0.2),
          onTap: () {
            showModalBottomSheet(
              context: context, 
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => _ProductModalBridge(game: game) 
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // قسم الصورة (يملأ الجزء العلوي)
              Expanded(
                flex: 5,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9), // خلفية بيضاء خفيفة لإبراز لوجو اللعبة
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: imageUrl.isEmpty
                        ? const Icon(Icons.videogame_asset, size: 50, color: Colors.grey)
                        : CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.contain,
                            placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
                            errorWidget: (context, url, error) => const Icon(Icons.image_not_supported, color: Colors.grey),
                          ),
                  ),
                ),
              ),
              // قسم التفاصيل (داكن وأنيق)
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        game.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('تبدأ من', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                          const SizedBox(height: 2),
                          Text(
                            '$startingPrice أوقية',
                            style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w900, fontSize: 15),
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

class _ProductModalBridge extends StatelessWidget {
  final GameModel game;
  const _ProductModalBridge({required this.game});

  @override
  Widget build(BuildContext context) {
    return showProductModalContent(context, game);
  }
}
