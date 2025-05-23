import 'package:flutter/material.dart';

class AppBarWidget extends StatelessWidget {
  final bool isSmallScreen;
  final VoidCallback? onMenuPressed;

  const AppBarWidget({
    Key? key,
    required this.isSmallScreen,
    this.onMenuPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16.0 : 24.0,
        vertical: 16.0,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
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
          if (onMenuPressed != null)
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: onMenuPressed,
            ),
          if (isSmallScreen) const SizedBox(width: 8.0),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning, color: Colors.red, size: 18.0),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      'Alerte: Produits en rupture de stock',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16.0),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          ),
          if (!isSmallScreen) const SizedBox(width: 16.0),
          if (!isSmallScreen)
            IconButton(
              icon: const Icon(Icons.account_circle),
              onPressed: () {},
            ),
        ],
      ),
    );
  }
}