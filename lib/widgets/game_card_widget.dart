import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../models/game_model.dart';

class GameCardWidget extends StatelessWidget {
  final GameModel game;
  final VoidCallback onTap;

  const GameCardWidget({super.key, required this.game, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover
            AspectRatio(
              aspectRatio: 16 / 9,
              child: _buildCover(),
            ),
            // Body
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (game.desc != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      game.desc!,
                      style: TextStyle(
                          fontSize: 11.5, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (game.pkgs.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: game.pkgs.take(3).map((p) => _PkgChip(pkg: p)).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCover() {
    final bgColor = _parseColor(game.bg) ?? const Color(0xFF1A1A2E);

    if (game.logo != null && game.logo!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: game.logo!,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: bgColor),
        errorWidget: (_, __, ___) => _iconFallback(bgColor),
      );
    }
    return _iconFallback(bgColor);
  }

  Widget _iconFallback(Color bg) {
    return Container(
      color: bg,
      alignment: Alignment.center,
      child: Text(game.icon ?? '🎮', style: const TextStyle(fontSize: 42)),
    );
  }

  Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return null;
    }
  }
}

class _PkgChip extends StatelessWidget {
  final PackageModel pkg;
  const _PkgChip({required this.pkg});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###', 'ar');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.greenLight,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${fmt.format(pkg.price)} أوقية',
        style: const TextStyle(
            fontSize: 10.5, color: AppTheme.green, fontWeight: FontWeight.w700),
      ),
    );
  }
}
