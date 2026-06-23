import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme/app_theme.dart';
import '../../models/game_model.dart';
import '../../providers/providers.dart';
import 'product_modal.dart';

class CardsScreen extends ConsumerStatefulWidget {
  const CardsScreen({super.key});

  @override
  ConsumerState<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends ConsumerState<CardsScreen> {
  int _tab = 0; // 0=ألعاب  1=بطاقات

  @override
  Widget build(BuildContext context) {
    final data = _tab == 0
        ? ref.watch(gameGamesProvider)
        : ref.watch(serviceGamesProvider);

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
                    'الكتالوج',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 48,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    _tab_(0, '🎮  الألعاب'),
                    _tab_(1, '💳  البطاقات'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Grid
            Expanded(
              child: data.when(
                loading: () => _shimmerGrid(),
                error: (_, __) => const Center(
                  child: Text('حدث خطأ',
                      style: TextStyle(color: Colors.redAccent)),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined,
                              size: 56, color: Colors.grey[700]),
                          const SizedBox(height: 14),
                          Text(
                            'لا يوجد شيء هنا حالياً',
                            style: TextStyle(
                                color: Colors.grey[600],
                                fontFamily: 'Cairo',
                                fontSize: 15),
                          ),
                        ],
                      ),
                    );
                  }
                  return GridView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(16, 10, 16, 20),
                    physics: const BouncingScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                    ),
                    itemCount: items.length,
                    itemBuilder: (ctx, i) {
                      final item = items[i];
                      return _GridCard(
                        game: item,
                        onTap: () => showProductModal(ctx, item),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tab_(int index, String label) {
    final sel = _tab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: sel ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: sel
                ? [
                    BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ]
                : [],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: sel ? Colors.white : AppTheme.textSecondary,
              fontWeight: sel ? FontWeight.w900 : FontWeight.w600,
              fontSize: 13,
              fontFamily: 'Cairo',
            ),
          ),
        ),
      ),
    );
  }

  Widget _shimmerGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: AppTheme.surfaceColor,
        highlightColor: AppTheme.surface2Color,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _GridCard extends StatelessWidget {
  final GameModel game;
  final VoidCallback onTap;

  const _GridCard({required this.game, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final imageUrl = game.logo ?? game.icon ?? '';
    final minPrice = game.pkgs.isEmpty
        ? 0.0
        : game.pkgs.map((p) => p.price).reduce((a, b) => a < b ? a : b);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(18)),
                  ),
                  child: imageUrl.isEmpty
                      ? const Icon(Icons.videogame_asset,
                          size: 46, color: Colors.grey)
                      : CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.contain,
                          placeholder: (_, __) => const Center(
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.primaryColor),
                          ),
                          errorWidget: (_, __, ___) => const Icon(
                              Icons.image_not_supported,
                              color: Colors.grey),
                        ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(11),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        game.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            fontFamily: 'Cairo',
                            color: Colors.white),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.greenLight.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'من ${minPrice.toStringAsFixed(0)} أوقية',
                          style: const TextStyle(
                              color: AppTheme.green,
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                              fontFamily: 'Cairo'),
                        ),
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