import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stock_management/screens/login_screen.dart';
import '../helpers/database_helper.dart';
import '../widgets/products_table_widget.dart';
import '../widgets/sidebar_widget.dart';
import '../widgets/appbar_widget.dart';
import '../widgets/stats_cards_widget.dart';
import '../screens/products_screen.dart';
import '../screens/entries_screen.dart';
import '../screens/exits_screen.dart';
import '../screens/inventory_screen.dart';
import '../screens/suppliers_screen.dart';
import '../screens/users_screen.dart';
import '../screens/sales_screen.dart';
import '../screens/alerts_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/damaged_history_screen.dart';
import '../screens/no_access_screen.dart';
import '../models/models.dart';
import '../widgets/stock_movements_chart_widget.dart';
import '../widgets/suppliers_table_widget.dart';
import '../widgets/users_table_widget.dart' show UsersTableWidget;
import '../providers/auth_provider.dart';
import '../constants/screen_permissions.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<DashboardData> _dashboardFuture;
  static const List<String> months = [
    'Janvier',
    'Février',
    'Mars',
    'Avril',
    'Mai',
    'Juin',
    'Juillet',
    'Août',
    'Septembre',
    'Octobre',
    'Novembre',
    'Décembre',
  ];
  int _selectedIndex = 0;
  final GlobalKey<AppBarWidgetState> appBarKey = GlobalKey<AppBarWidgetState>();
  final ScrollController _modalVerticalController = ScrollController();
  Set<String> _allowedScreenKeys = appScreenPermissions.map((e) => e.key).toSet();
  bool _checkedInitialAccess = false;
  bool _showingNoAccess = false;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _initializeDashboard();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final allowed = user == null || user.permissions == null
        ? appScreenPermissions.map((e) => e.key).toSet()
        : user.permissions!.toSet();
    if (!setEquals(_allowedScreenKeys, allowed)) {
      _allowedScreenKeys = allowed;
    }
    if (!_checkedInitialAccess) {
      _checkedInitialAccess = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _enforceAccess());
    }
  }

  Future<DashboardData> _initializeDashboard() async {
    try {
      debugPrint('Initialisation de la base de données...');
      await DatabaseHelper.database;
      final data = await _fetchDashboardData();
      _scheduleAlertsRefresh();
      return data;
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation du tableau de bord : $e');
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur de base de données : $e')),
          );
        });
      }
      rethrow;
    }
  }

  Future<DashboardData> _fetchDashboardData() async {
    final produitsFuture = DatabaseHelper.getProduits();
    final suppliersFuture = DatabaseHelper.getSuppliers();
    final usersFuture = DatabaseHelper.getUsers();
    final productsSoldFuture = DatabaseHelper.getTotalProductsSold();

    final produits = await produitsFuture;
    final suppliers = await suppliersFuture;
    final users = await usersFuture;
    final productsSold = await productsSoldFuture;

    return DashboardData(
      produits: produits,
      suppliers: suppliers,
      users: users,
      productsSold: productsSold,
    );
  }

  Future<void> _refreshData() async {
    final refreshedFuture = _fetchDashboardData();
    if (mounted) {
      setState(() {
        _dashboardFuture = refreshedFuture;
      });
    }
    try {
      await refreshedFuture;
    } finally {
      if (mounted) {
        _scheduleAlertsRefresh();
      }
    }
  }

  @override
  void dispose() {
    _modalVerticalController.dispose();
    super.dispose();
  }

  void _scheduleAlertsRefresh() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      appBarKey.currentState?.fetchAlerts();
    });
  }

  List<Widget> get _screens {
    return [
      FutureBuilder<DashboardData>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }
          final data = snapshot.data;
          if (data == null) {
            return const Center(child: Text('Aucune donnée disponible'));
          }
          return DashboardContent(
            produits: data.produits,
            suppliers: data.suppliers,
            months: months,
            users: data.users,
            productsSold: data.productsSold,
            onRefresh: _refreshData,
            modalScrollController: _modalVerticalController,
          );
        },
      ),
      const ProductsScreen(),
      const EntriesScreen(),
      const ExitsScreen(),
       InventoryScreen(),
      SuppliersScreen(),
      const UsersScreen(),
      const SalesScreen(),
      const AlertsScreen(),
      const SettingsScreen(),
      const DamagedHistoryScreen(),
    ];
  }

  void _onItemTapped(int index) {
    if (!_isScreenAllowed(index)) {
      _redirectToNoAccess();
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
    if (_selectedIndex == 0) {
      _refreshData();
    }
  }

  void _logout() {
    // Ajout d'une boîte de dialogue de confirmation
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Déconnexion'),
            content: const Text('Voulez-vous vraiment vous déconnecter ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Ferme la boîte de dialogue
                  // DatabaseHelper.clearSession(); // Décommentez si implémenté
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (Route<dynamic> route) =>
                        false, // Supprime toutes les routes précédentes
                  );
                },
                child: const Text('Confirmer'),
              ),
            ],
          ),
    );
  }

  bool _isScreenAllowed(int index) {
    if (index < 0 || index >= appScreenPermissions.length) {
      return false;
    }
    final key = appScreenPermissions[index].key;
    return _allowedScreenKeys.contains(key);
  }

  int? _firstAllowedIndex() {
    for (var i = 0; i < appScreenPermissions.length; i++) {
      if (_allowedScreenKeys.contains(appScreenPermissions[i].key)) {
        return i;
      }
    }
    return null;
  }

  void _enforceAccess() {
    final firstAllowed = _firstAllowedIndex();
    if (firstAllowed == null) {
      _redirectToNoAccess();
      return;
    }
    if (!_isScreenAllowed(_selectedIndex)) {
      setState(() {
        _selectedIndex = firstAllowed;
      });
      if (_selectedIndex == 0) {
        _refreshData();
      }
    }
  }

  void _redirectToNoAccess() {
    if (_showingNoAccess) return;
    _showingNoAccess = true;
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const NoAccessScreen()))
        .then((_) {
      if (mounted) {
        setState(() {
          _showingNoAccess = false;
        });
      } else {
        _showingNoAccess = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isVerySmallScreen = screenWidth < 800;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 800),
      child: Scaffold(
        body: Row(
          children: [
            if (!isVerySmallScreen)
              SidebarWidget(
                onItemTapped: _onItemTapped,
                selectedIndex: _selectedIndex,
                allowedKeys: _allowedScreenKeys,
              ),
            Expanded(
              child: Container(
                color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppBarWidget(
                      key: appBarKey,
                      isSmallScreen: isVerySmallScreen,
                      onMenuPressed:
                          isVerySmallScreen
                              ? () => Scaffold.of(context).openDrawer()
                              : null,
                      onLogout: _logout, // Passage du callback de déconnexion
                    ),
                    Expanded(
                      child: IndexedStack(
                        index: _selectedIndex,
                        children: _screens,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        drawer: isVerySmallScreen
            ? Drawer(
                child: SidebarWidget(
                  onItemTapped: (index) {
                    Navigator.of(context).pop();
                    _onItemTapped(index);
                  },
                  selectedIndex: _selectedIndex,
                  allowedKeys: _allowedScreenKeys,
                ),
              )
            : null,
      ),
    );
  }
}

class DashboardContent extends StatelessWidget {
  final List<Produit> produits;
  final List<Supplier> suppliers;
  final List<String> months;
  final List<User> users;
  final int productsSold;
  final Future<void> Function() onRefresh;
  final ScrollController modalScrollController;

  const DashboardContent({
    Key? key,
    required this.produits,
    required this.suppliers,
    required this.months,
    required this.users,
    required this.productsSold,
    required this.onRefresh,
    required this.modalScrollController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 1200;
    final outOfStockCount =
        produits.where((p) => p.quantiteStock <= p.stockMin).length;
    final totalStockValue = produits.fold<double>(
      0.0,
      (sum, product) => sum + (product.prixVente) * product.quantiteStock,
    );

    BoxDecoration _cardDecoration() {
      return BoxDecoration(
        color: isDarkMode ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color:
              isDarkMode
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          if (!isDarkMode)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 28,
              offset: const Offset(0, 18),
            ),
        ],
      );
    }

    Widget buildSurface({
      required Widget child,
      EdgeInsetsGeometry padding = const EdgeInsets.all(24),
    }) {
      return Container(
        width: double.infinity,
        padding: padding,
        decoration: _cardDecoration(),
        child: child,
      );
    }

    Widget buildSection({
      required String title,
      String? subtitle,
      Widget? action,
      required Widget child,
    }) {
      final titleColor = isDarkMode ? Colors.white : Colors.grey.shade900;
      final subtitleColor =
          isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;

      return buildSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: subtitleColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (action != null) action,
              ],
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      );
    }

    Widget buildHeroCard() {
      final gradientColors =
          isDarkMode
              ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
              : [const Color(0xFF3730A3), const Color(0xFF2563EB)];
      final double lowStockRatio =
          produits.isEmpty
              ? 0
              : (outOfStockCount / produits.length).clamp(0.0, 1.0);
      final Color progressColor =
          lowStockRatio > 0.45
              ? Colors.orangeAccent
              : lowStockRatio > 0.2
              ? Colors.amberAccent
              : Colors.lightGreenAccent;

      Widget metric(String label, String value, IconData icon) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.82),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: gradientColors.last.withValues(alpha: 0.35),
              blurRadius: 38,
              offset: const Offset(0, 24),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vue d\'ensemble',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pilotez le stock, les ventes et les fournisseurs depuis un seul endroit.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.18),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                  ),
                  onPressed: () {
                    onRefresh();
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Actualiser'),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                metric(
                  'Produits actifs',
                  produits.length.toString(),
                  Icons.widgets_rounded,
                ),
                metric(
                  'Fournisseurs',
                  suppliers.length.toString(),
                  Icons.handshake_rounded,
                ),
                metric(
                  'Utilisateurs',
                  users.length.toString(),
                  Icons.people_alt_rounded,
                ),
                metric(
                  'Produits vendus',
                  productsSold.toString(),
                  Icons.shopping_cart_checkout_rounded,
                ),
              ],
            ),
            const SizedBox(height: 28),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Produits à surveiller',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: lowStockRatio,
                    backgroundColor: Colors.white.withValues(alpha: 0.18),
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  outOfStockCount == 0
                      ? 'Tout est sous contrôle, aucune rupture détectée.'
                      : '$outOfStockCount référence${outOfStockCount > 1 ? 's' : ''} proche${outOfStockCount > 1 ? 's' : ''} de la rupture.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      displacement: 18,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth < 800 ? 8.0 : 16.0,
          vertical: 16.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tableau de bord',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.grey.shade900,
              ),
            ),
            const SizedBox(height: 16.0),
            buildHeroCard(),
            const SizedBox(height: 24.0),
            buildSurface(
              child: StatsCardsWidget(
                totalProducts: produits.length,
                outOfStock: outOfStockCount,
                stockValue: totalStockValue,
                productsSold: productsSold,
              ),
            ),
            const SizedBox(height: 24.0),
            buildSection(
              title: 'Inventaire',
              subtitle: 'Synthèse des produits et états de stock',
              action: TextButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      final mq = MediaQuery.of(context).size;
                      final modalTableWidth = math.min(mq.width * 0.9, 1400.0);
                      return Dialog(
                        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                        child: SizedBox(
                          width: mq.width * 0.95,
                          height: mq.height * 0.9,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Inventaire produits',
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () => Navigator.of(context).pop(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Expanded(
                                      child: Scrollbar(
                                        thumbVisibility: true,
                                        controller: modalScrollController,
                                        child: SingleChildScrollView(
                                          controller: modalScrollController,
                                          padding: const EdgeInsets.only(bottom: 32),
                                          child: Align(
                                            alignment: Alignment.topCenter,
                                            child: ConstrainedBox(
                                          constraints: BoxConstraints(
                                            maxWidth: modalTableWidth,
                                          ),
                                          child: ProductsTableWidget(
                                            produits: produits,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('Voir tout'),
              ),
              child: ProductsTableWidget(
                produits: produits.length > 10
                    ? produits.take(10).toList()
                    : produits,
                embedInCard: true,
              ),
            ),
            const SizedBox(height: 24.0),
            buildSection(
              title: 'Mouvements de stock',
              subtitle: 'Historique des 12 derniers mois',
              child: SizedBox(
                height: 320.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: StockMovementsChartWidget(months: months),
                ),
              ),
            ),
            const SizedBox(height: 24.0),
            if (isSmallScreen) ...[
              buildSection(
                title: 'Fournisseurs',
                subtitle: 'Partenaires et interlocuteurs clés',
                child: SuppliersTableWidget(
                  suppliers: suppliers,
                  embedInCard: true,
                ),
              ),
              const SizedBox(height: 24.0),
              buildSection(
                title: 'Utilisateurs',
                subtitle: 'Équipe et rôles actifs',
                child: UsersTableWidget(users: users, embedInCard: true),
              ),
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: buildSection(
                      title: 'Fournisseurs',
                      subtitle: 'Partenaires et interlocuteurs clés',
                      child: SuppliersTableWidget(
                        suppliers: suppliers,
                        embedInCard: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24.0),
                  Expanded(
                    child: buildSection(
                      title: 'Utilisateurs',
                      subtitle: 'Équipe et rôles actifs',
                      child: UsersTableWidget(users: users, embedInCard: true),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class DashboardData {
  final List<Produit> produits;
  final List<Supplier> suppliers;
  final List<User> users;
  final int productsSold;

  const DashboardData({
    required this.produits,
    required this.suppliers,
    required this.users,
    required this.productsSold,
  });
}
