import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/data_providers.dart';
import '../../widgets/game_card_widget.dart';
import 'product_modal.dart';

class CardsScreen extends ConsumerWidget {
  const CardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('البطاقات والألعاب')),
      body: ListView(
        children: [
          // Games Section
          _buildSection(context, ref, '🎮 شحن الألعاب', true),
          const SizedBox(height: 8),
          // Services Section
          _buildSection(context, ref, '💳 بطاقات واشتراكات', false),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSection(
      BuildContext context, WidgetRef ref, String title, bool isGames) {
    final gamesAsync = isGames
        ? ref.watch(gameGamesProvider)
        : ref.watch(serviceGamesProvider);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(
            isGames
                ? 'شحن فوري لأشهر الألعاب (ببجي، فري فاير، والمزيد)'
                : 'اشتراكات وبطاقات هدايا (نتفلكس، آبل، بلايستيشن)',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 14),
          gamesAsync.when(
            loading: () => _buildShimmerGrid(),
            error: (_, __) => const Text('خطأ في التحميل'),
            data: (games) => games.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        isGames ? '🎮 لا توجد ألعاب' : '💳 لا توجد بطاقات',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                    ),
                    itemCount: games.length,
                    itemBuilder: (ctx, i) => GameCardWidget(
                      game: games[i],
                      onTap: () => showProductModal(ctx, games[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: 4,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.grey[100]!,
        child: Card(child: Container()),
      ),
    );
  }
}
