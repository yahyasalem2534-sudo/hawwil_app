import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme/app_theme.dart';
import '../../models/game_model.dart';
import '../../providers/providers.dart';
import '../cards/product_modal.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentSlider = 0;
  // نخزن آخر لعبة ظهرت في السلايدر لفتح modal عند الضغط
  GameModel? _featuredGame;

  @override
  Widget build(BuildContext context) {
    final slidersAsync = ref.watch(slidersProvider);
    final gamesAsync   = ref.watch(gameGamesProvider);
    final servicesAsync = ref.watch(serviceGamesProvider);
    final allGames     = ref.watch(gamesProvider).value ?? [];

    // أول لعبة كـ featured افتراضي
    if (_featuredGame == null && allGames.isNotEmpty) {
      _featuredGame = allGames.first;
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ─── Header ────────────────────────────────────────────────────
          SliverToBoxAdapter(child: _buildHeader()),

          // ─── Hero Slider (بدون هوامش جانبية) ──────────────────────────
          SliverToBoxAdapter(
            child: _buildHeroSlider(slidersAsync, allGames),
          ),

          // ─── قسم الألعاب ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 32),
              child: _buildSectionHeader('🎮  الألعاب', Icons.sports_esports_rounded),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildHorizontalList(gamesAsync),
          ),

          // ─── قسم البطاقات الرقمية ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 28),
              child: _buildSectionHeader('💳  البطاقات الرقمية', Icons.card_giftcard_rounded),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildHorizontalList(servicesAsync),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 110)),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Row(
          children: [
            // Logo + Name
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.4),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 10),
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'حوّ',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      TextSpan(
                        text: 'ل',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primaryColor,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            // زر الإشعارات
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Hero Slider ─────────────────────────────────────────────────────────
  Widget _buildHeroSlider(
    AsyncValue<List<String>> slidersAsync,
    List<GameModel> allGames,
  ) {
    return slidersAsync.when(
      loading: () => _sliderShimmer(),
      error: (_, __) => _sliderFallback(allGames),
      data: (urls) {
        final list = urls.isEmpty
            ? ['https://images.unsplash.com/photo-1511512578047-dfb367046420?q=80&w=1200']
            : urls;
        return _buildSlider(list, allGames);
      },
    );
  }

  Widget _buildSlider(List<String> urls, List<GameModel> allGames) {
    final height = MediaQuery.of(context).size.width * 0.58;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Stack(
        children: [
          CarouselSlider(
            options: CarouselOptions(
              height: height,
              viewportFraction: 1.0,
              enlargeCenterPage: false,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 4),
              autoPlayAnimationDuration: const Duration(milliseconds: 800),
              autoPlayCurve: Curves.fastOutSlowIn,
              enableInfiniteScroll: true,
              onPageChanged: (index, reason) {
                setState(() {
                  _currentSlider = index;
                  if (allGames.isNotEmpty) {
                    _featuredGame = allGames[index % allGames.length];
                  }
                });
              },
            ),
            items: urls.map((url) => _sliderItem(url)).toList(),
          ),

          // ── زر "تسوق الآن" المتوهج في المنتصف ──────────────────────
          Positioned(
            bottom: 28,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  if (_featuredGame != null) {
                    showProductModal(context, _featuredGame!);
                  }
                },
                child: _GlowShopButton(),
              ),
            ),
          ),

          // ── مؤشرات السلايدر ───────────────────────────────────────────
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                urls.length > 6 ? 6 : urls.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentSlider == i ? 18 : 6,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _currentSlider == i
                        ? AppTheme.primaryColor
                        : Colors.white.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sliderItem(String imageUrl) {
    return Stack(
      children: [
        // الصورة
        CachedNetworkImage(
          imageUrl: imageUrl,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(color: AppTheme.surfaceColor),
          errorWidget: (_, __, ___) => Container(color: AppTheme.surfaceColor),
        ),
        // تدرج تحتي لإظهار الزر
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.15),
                  Colors.black.withOpacity(0.65),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sliderShimmer() {
    final height = MediaQuery.of(context).size.width * 0.58;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Shimmer.fromColors(
        baseColor: AppTheme.surfaceColor,
        highlightColor: AppTheme.surface2Color,
        child: Container(
          width: double.infinity,
          height: height,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _sliderFallback(List<GameModel> allGames) {
    return _buildSlider(
      ['https://images.unsplash.com/photo-1542751371-adc38448a05e?q=80&w=1200'],
      allGames,
    );
  }

  // ── Section Header ───────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w900,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  // ── Horizontal List ──────────────────────────────────────────────────────
  Widget _buildHorizontalList(AsyncValue<List<GameModel>> asyncGames) {
    return asyncGames.when(
      loading: () => _listShimmer(),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text(
                'لا توجد منتجات حالياً',
                style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo'),
              ),
            ),
          );
        }
        return SizedBox(
          height: 210,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (ctx, i) {
              final item = items[i];
              final minPrice = item.pkgs.isEmpty
                  ? 0.0
                  : item.pkgs.map((p) => p.price).reduce((a, b) => a < b ? a : b);
              return _ProductCard(
                game: item,
                startingPrice: minPrice.toStringAsFixed(0),
                onTap: () => showProductModal(ctx, item),
              );
            },
          ),
        );
      },
    );
  }

  Widget _listShimmer() {
    return SizedBox(
      height: 210,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        itemBuilder: (_, __) => Shimmer.fromColors(
          baseColor: AppTheme.surfaceColor,
          highlightColor: AppTheme.surface2Color,
          child: Container(
            width: 150,
            margin: const EdgeInsets.symmetric(horizontal: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// زر "تسوق الآن" المتوهج
// ============================================================================
class _GlowShopButton extends StatefulWidget {
  @override
  State<_GlowShopButton> createState() => _GlowShopButtonState();
}

class _GlowShopButtonState extends State<_GlowShopButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>    _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _glow = Tween<double>(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glow,
      builder: (_, child) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.55 * _glow.value),
              blurRadius: 22 * _glow.value,
              spreadRadius: 2 * _glow.value,
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.08 * _glow.value),
              blurRadius: 10,
            ),
          ],
        ),
        child: child,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 13),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: Colors.white.withOpacity(0.45),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.shopping_bag_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Text(
                  'تسوق الآن',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Cairo',
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// بطاقة المنتج
// ============================================================================
class _ProductCard extends StatelessWidget {
  final GameModel game;
  final String startingPrice;
  final VoidCallback onTap;

  const _ProductCard({
    required this.game,
    required this.startingPrice,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = game.logo ?? game.icon ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        margin: const EdgeInsets.symmetric(horizontal: 7),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // صورة
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                padding: const EdgeInsets.all(12),
                child: imageUrl.isEmpty
                    ? const Icon(Icons.videogame_asset, size: 44, color: Colors.grey)
                    : CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.contain,
                        placeholder: (_, __) => const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        errorWidget: (_, __, ___) =>
                            const Icon(Icons.image_not_supported, color: Colors.grey),
                      ),
              ),
            ),
            // نص
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(11, 9, 11, 9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      game.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        fontFamily: 'Cairo',
                        height: 1.3,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'من $startingPrice أوقية',
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}