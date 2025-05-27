import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class StatsCardsWidget extends StatelessWidget {
  final int totalProducts;
  final int outOfStock;
  final double stockValue;
  final int productsSold;
  final double screenWidth;

  const StatsCardsWidget({
    Key? key,
    required this.totalProducts,
    required this.outOfStock,
    required this.stockValue,
    required this.productsSold,
    required this.screenWidth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isVerySmallScreen = screenWidth < 600;
    final isSmallScreen = screenWidth >= 600 && screenWidth < 900;
    final isMediumScreen = screenWidth >= 900 && screenWidth < 1200;

    double cardWidth;
    if (isVerySmallScreen) {
      cardWidth = screenWidth - 16; // Pleine largeur moins padding
    } else if (isSmallScreen) {
      cardWidth = (screenWidth - 32) / 2; // 2 cartes par ligne
    } else if (isMediumScreen) {
      cardWidth = (screenWidth - 48) / 3; // 3 cartes par ligne
    } else {
      cardWidth = (screenWidth - 64) / 4; // 4 cartes par ligne
    }

    return Scrollbar(
      thumbVisibility: true,
      trackVisibility: true,
      notificationPredicate: (notif) => notif.metrics.axis == Axis.horizontal,
      controller: ScrollController(),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildStatCard(
              icon: Icons.inventory_2,
              iconColor: Colors.blue,
              title: '# de produits',
              value: totalProducts.toString(),
              width: cardWidth,
            ),
            const SizedBox(width: 16.0),
            _buildStatCard(
              icon: Icons.warning,
              iconColor: Colors.red,
              title: 'Produits en rupture',
              value: outOfStock.toString(),
              width: cardWidth,
            ),
            const SizedBox(width: 16.0),
            _buildStatCard(
              icon: CupertinoIcons.money_dollar,
              iconColor: Colors.green,
              title: 'Valeur du stock',
              value: 'FCFA ${stockValue.toStringAsFixed(0)}',
              width: cardWidth,
            ),
            const SizedBox(width: 16.0),
            _buildStatCard(
              icon: Icons.trending_up,
              iconColor: Colors.purple,
              title: 'Produits vendus',
              value: productsSold.toString(),
              width: cardWidth,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14.0,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4.0),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}