import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StatsCardsWidget extends StatelessWidget {
  final int totalProducts;
  final int outOfStock;
  final double stockValue;
  final int productsSold;

  const StatsCardsWidget({
    Key? key,
    required this.totalProducts,
    required this.outOfStock,
    required this.stockValue,
    required this.productsSold,
  }) : super(key: key);

  static const double _spacing = 16.0;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth =
            constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : MediaQuery.of(context).size.width;
        final columns = _resolveColumns(availableWidth);
        final cardWidth =
            columns == 1
                ? availableWidth
                : (availableWidth - _spacing * (columns - 1)) / columns;

        final cards = [
          _StatCardData(
            title: '# de produits',
            subtitle: 'Références actives',
            value: totalProducts.toString(),
            icon: Icons.inventory_2,
            colors: const [Color(0xFF4F46E5), Color(0xFF8B5CF6)],
          ),
          _StatCardData(
            title: 'Produits en rupture',
            subtitle:
                outOfStock == 0
                    ? 'Stock sous contrôle'
                    : 'À surveiller rapidement',
            value: outOfStock.toString(),
            icon: Icons.warning_amber_rounded,
            colors: const [Color(0xFFEF4444), Color(0xFFF97316)],
            emphasizeValue: outOfStock > 0,
          ),
          _StatCardData(
            title: 'Valeur du stock',
            subtitle: 'Estimation globale',
            value: '${NumberFormat('#,##0', 'fr_FR').format(stockValue)}\u00A0FCFA',
            icon: Icons.account_balance_wallet_rounded,
            colors: const [Color(0xFF10B981), Color(0xFF34D399)],
          ),
          _StatCardData(
            title: 'Produits vendus',
            subtitle: 'Sur la période sélectionnée',
            value: productsSold.toString(),
            icon: Icons.trending_up_rounded,
            colors: const [Color(0xFF6366F1), Color(0xFF3B82F6)],
          ),
        ];

        return Wrap(
          spacing: _spacing,
          runSpacing: _spacing,
          children:
              cards
                  .map(
                    (card) => ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: columns == 1 ? availableWidth : cardWidth,
                      ),
                      child: _StatCard(data: card, isDarkMode: isDarkMode),
                    ),
                  )
                  .toList(),
        );
      },
    );
  }

  int _resolveColumns(double width) {
    if (width < 520) {
      return 1;
    }
    if (width < 900) {
      return 2;
    }
    if (width < 1240) {
      return 3;
    }
    return 4;
  }
}

class _StatCardData {
  final String title;
  final String subtitle;
  final String value;
  final IconData icon;
  final List<Color> colors;
  final bool emphasizeValue;

  const _StatCardData({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
    required this.colors,
    this.emphasizeValue = false,
  });
}

class _StatCard extends StatelessWidget {
  final _StatCardData data;
  final bool isDarkMode;

  const _StatCard({Key? key, required this.data, required this.isDarkMode})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gradientColors =
        data.colors
            .map(
              (color) =>
                  isDarkMode
                      ? Color.alphaBlend(
                        Colors.black.withValues(alpha: 0.35),
                        color,
                      )
                      : color,
            )
            .toList();

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _IconBadge(icon: data.icon),
              if (data.emphasizeValue)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Urgent',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24.0),
          Text(
            data.title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              letterSpacing: 0.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8.0),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              data.value,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 12.0),
          Text(
            data.subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;

  const _IconBadge({Key? key, required this.icon}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      width: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }
}
