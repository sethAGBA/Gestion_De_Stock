import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dashboard_provider.dart';
import '../helpers/database_helper.dart';

class AppBarWidget extends StatefulWidget {
  final bool isSmallScreen;
  final VoidCallback? onMenuPressed;
  final VoidCallback? onLogout;

  const AppBarWidget({
    Key? key,
    required this.isSmallScreen,
    this.onMenuPressed,
    this.onLogout,
  }) : super(key: key);

  @override
  State<AppBarWidget> createState() => AppBarWidgetState();
}

class AppBarWidgetState extends State<AppBarWidget> {
  int _alertCount = 0;
  bool _alertsRead = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    fetchAlerts();
  }

  Future<void> fetchAlerts() async {
    setState(() {
      _loading = true;
    });
    final produits = await DatabaseHelper.getLowStockProducts();
    setState(() {
      _alertCount = produits.length;
      if (_alertCount > 0) _alertsRead = false;
      _loading = false;
    });
  }

  void _markAlertsRead() {
    setState(() {
      _alertsRead = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isSmallScreen ? 16.0 : 24.0,
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
          if (widget.onMenuPressed != null)
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: widget.onMenuPressed,
            ),
          if (widget.isSmallScreen) const SizedBox(width: 8.0),
          if (!_loading && _alertCount > 0 && !_alertsRead)
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
                        'Alerte: ${_alertCount} produit${_alertCount > 1 ? 's' : ''} en rupture',
                        style: const TextStyle(
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
          if (_loading || _alertCount == 0 || _alertsRead)
            const Expanded(child: SizedBox()),
          const SizedBox(width: 16.0),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
            onPressed: () async {
              Provider.of<DashboardProvider>(context, listen: false).fetchDashboardData();
              await fetchAlerts();
            },
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  _markAlertsRead();
                },
              ),
              if (!_alertsRead && _alertCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4.0),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$_alertCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16.0),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: widget.onLogout,
          ),
        ],
      ),
    );
  }
}