import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/data_providers.dart';
import '../../models/game_model.dart';
import 'product_modal.dart';

class CardsScreen extends ConsumerStatefulWidget {
  const CardsScreen({super.key});

  @override
  ConsumerState<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends ConsumerState<CardsScreen> {
  // 0 يعني تبويب الألعاب، 1 يعني تبويب البطاقات
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // جلب البيانات بناءً على التبويب المحدد
    final asyncData = _selectedIndex == 0 
        ? ref.watch(gameGamesProvider) 
        : ref.watch(serviceGamesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الكتالوج'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // --- أزرار التبديل العلوية (Segmented Control) ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Container(
              height: 50,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTabButton(
                      title: '🎮 الألعاب',
                      isSelected: _selectedIndex == 0,
                      onTap: () => setState(() => _selectedIndex = 0),
                    ),
                  ),
                  Expanded(
                    child: _buildTabButton(
                      title: '💳 البطاقات الرقمية',
                      isSelected: _selectedIndex == 1,
                      onTap: () => setState(() => _selectedIndex = 1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 10),

          // --- شبكة المنتجات (Grid) ---
          Expanded(
            child: asyncData.when(
              data: (items) {
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _selectedIndex == 0 ? 'لا توجد ألعاب حالياً' : 'لا توجد بطاقات حالياً',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72, // نسبة الطول إلى العرض للبطاقة
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return GridProductCard(
                      game: item,
                      onTap: () => showProductModal(context, item),
                    );
                  },
                );
              },
              loading: () => _buildShimmerGrid(context),
              error: (error, stack) => Center(
                child: Text('حدث خطأ في تحميل البيانات', style: TextStyle(color: AppTheme.red, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // تصميم زر التبويب
  Widget _buildTabButton({required String title, required bool isSelected, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.green : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected 
              ? [BoxShadow(color: AppTheme.green.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))] 
              : [],
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[600]),
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // تأثير التحميل (Skeleton) للشبكة
  Widget _buildShimmerGrid(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
        highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
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

// --- تصميم البطاقة المخصصة لصفحة الكتالوج ---
class GridProductCard extends StatelessWidget {
  final GameModel game;
  final VoidCallback onTap;

  const GridProductCard({
    super.key,
    required this.game,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // حساب أقل سعر
    double startingPrice = 0;
    if (game.pkgs.isNotEmpty) {
      startingPrice = game.pkgs.map((p) => p.price).reduce((a, b) => a < b ? a : b);
    }
    
    final imageUrl = game.logo ?? game.icon ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // منطقة الصورة
              Expanded(
                flex: 5,
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
                          fit: BoxFit.contain, // السر في عدم قص أي شعار مهما كان حجمه
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: AppTheme.greenLight)),
                          errorWidget: (context, url, error) => const Icon(Icons.image_not_supported, color: Colors.grey),
                        ),
                ),
              ),
              // منطقة النصوص
              Expanded(
                flex: 4,
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
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, height: 1.2),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.greenLight.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'من ${startingPrice.toStringAsFixed(0)} أوقية',
                          style: const TextStyle(color: AppTheme.green, fontWeight: FontWeight.w900, fontSize: 11),
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
