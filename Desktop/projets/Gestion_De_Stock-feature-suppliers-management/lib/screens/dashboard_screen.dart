import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
    // Sync latest permissions from DB so changes take effect without logout
    _syncPermissionsFromDatabase();
    if (!_checkedInitialAccess) {
      _checkedInitialAccess = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _enforceAccess());
    }
  }

  Future<void> _syncPermissionsFromDatabase() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final current = auth.currentUser;
      if (current == null) return;
      final users = await DatabaseHelper.getUsers();
      final fresh = users.firstWhere((u) => u.id == current.id, orElse: () => current);
      final allowed = fresh.permissions == null || fresh.permissions!.isEmpty
          ? appScreenPermissions.map((e) => e.key).toSet()
          : fresh.permissions!.toSet();
      if (!setEquals(_allowedScreenKeys, allowed)) {
        if (!mounted) return;
        setState(() {
          _allowedScreenKeys = allowed;
        });
        _enforceAccess();
      }
    } catch (_) {
      // Ignore sync errors
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
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = auth.currentUser;
    final isVendor = currentUser?.role == 'Vendeur';
    final vendorName = currentUser?.name;

    final produitsFuture = DatabaseHelper.getProduits();
    final suppliersFuture = DatabaseHelper.getSuppliers();
    final usersFuture = DatabaseHelper.getUsers();
    final productsSoldFuture = DatabaseHelper.getTotalProductsSold();
    final salesTodayFuture = DatabaseHelper.getTotalSalesToday();
    final paidInvoicesFuture = DatabaseHelper.getPaidInvoicesCount();
    final pendingInvoicesFuture = DatabaseHelper.getPendingInvoicesCount();
    final cancelledInvoicesFuture = DatabaseHelper.getCancelledInvoicesCount();
    final topSellingProductsFuture = DatabaseHelper.getTopSellingProducts();
    final leastSellingProductsFuture = DatabaseHelper.getLeastSellingProducts();
    final topClientsFuture = DatabaseHelper.getTopClients();

    // Données spécifiques au vendeur si applicable
    Future<double> vendorSalesTodayFuture = Future.value(0.0);
    Future<double> vendorTotalSalesFuture = Future.value(0.0);
    Future<int> vendorInvoicesCountFuture = Future.value(0);
    Future<int> vendorPaidInvoicesFuture = Future.value(0);
    Future<List<Map<String, dynamic>>> vendorTopProductsFuture = Future.value([]);
    Future<List<Map<String, dynamic>>> vendorTopClientsFuture = Future.value([]);

    if (isVendor && vendorName != null) {
      vendorSalesTodayFuture = DatabaseHelper.getVendorSalesToday(vendorName);
      vendorTotalSalesFuture = DatabaseHelper.getVendorTotalSales(vendorName);
      vendorInvoicesCountFuture = DatabaseHelper.getVendorInvoicesCount(vendorName);
      vendorPaidInvoicesFuture = DatabaseHelper.getVendorPaidInvoicesCount(vendorName);
      vendorTopProductsFuture = DatabaseHelper.getVendorTopProducts(vendorName);
      vendorTopClientsFuture = DatabaseHelper.getVendorTopClients(vendorName);
    }

    final produits = await produitsFuture;
    final suppliers = await suppliersFuture;
    final users = await usersFuture;
    final productsSold = await productsSoldFuture;
    final salesToday = await salesTodayFuture;
    final paidInvoices = await paidInvoicesFuture;
    final pendingInvoices = await pendingInvoicesFuture;
    final cancelledInvoices = await cancelledInvoicesFuture;
    final topSellingProducts = await topSellingProductsFuture;
    final leastSellingProducts = await leastSellingProductsFuture;
    final topClients = await topClientsFuture;

    // Données spécifiques au vendeur
    final vendorSalesToday = await vendorSalesTodayFuture;
    final vendorTotalSales = await vendorTotalSalesFuture;
    final vendorInvoicesCount = await vendorInvoicesCountFuture;
    final vendorPaidInvoices = await vendorPaidInvoicesFuture;
    final vendorTopProducts = await vendorTopProductsFuture;
    final vendorTopClients = await vendorTopClientsFuture;

    // Vérification des données pour éviter les erreurs de type
    print('Données récupérées:');
    print('- Utilisateur: ${currentUser?.name} (${currentUser?.role})');
    print('- Produits: ${produits.length}');
    print('- Ventes aujourd\'hui: $salesToday');
    print('- Factures payées: $paidInvoices');
    print('- Factures en attente: $pendingInvoices');
    print('- Factures annulées: $cancelledInvoices');
    print('- Top produits: ${topSellingProducts.length}');
    print('- Moins vendus: ${leastSellingProducts.length}');
    print('- Top clients: ${topClients.length}');
    if (isVendor) {
      print('- Ventes vendeur aujourd\'hui: $vendorSalesToday');
      print('- Total ventes vendeur: $vendorTotalSales');
      print('- Factures vendeur: $vendorInvoicesCount');
      print('- Factures payées vendeur: $vendorPaidInvoices');
    }

    return DashboardData(
      produits: produits,
      suppliers: suppliers,
      users: users,
      productsSold: productsSold,
      salesToday: salesToday,
      paidInvoices: paidInvoices,
      pendingInvoices: pendingInvoices,
      cancelledInvoices: cancelledInvoices,
      topSellingProducts: topSellingProducts,
      leastSellingProducts: leastSellingProducts,
      topClients: topClients,
      isVendor: isVendor,
      vendorName: vendorName,
      vendorSalesToday: vendorSalesToday,
      vendorTotalSales: vendorTotalSales,
      vendorInvoicesCount: vendorInvoicesCount,
      vendorPaidInvoices: vendorPaidInvoices,
      vendorTopProducts: vendorTopProducts,
      vendorTopClients: vendorTopClients,
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
            print('Erreur FutureBuilder: ${snapshot.error}');
            print('Stack trace: ${snapshot.stackTrace}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur de chargement',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _dashboardFuture = _initializeDashboard();
                      });
                    },
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
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
            salesToday: data.salesToday,
            paidInvoices: data.paidInvoices,
            pendingInvoices: data.pendingInvoices,
            cancelledInvoices: data.cancelledInvoices,
            topSellingProducts: data.topSellingProducts,
            leastSellingProducts: data.leastSellingProducts,
            topClients: data.topClients,
            isVendor: data.isVendor,
            vendorName: data.vendorName,
            vendorSalesToday: data.vendorSalesToday,
            vendorTotalSales: data.vendorTotalSales,
            vendorInvoicesCount: data.vendorInvoicesCount,
            vendorPaidInvoices: data.vendorPaidInvoices,
            vendorTopProducts: data.vendorTopProducts,
            vendorTopClients: data.vendorTopClients,
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
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout, color: Colors.redAccent),
              ),
              const SizedBox(width: 12),
              const Text(
                'Déconnexion',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            'Voulez-vous vraiment vous déconnecter ? Vous serez redirigé vers l\'écran de connexion.',
          ),
          actionsAlignment: MainAxisAlignment.end,
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (Route<dynamic> route) => false,
                );
              },
              icon: const Icon(Icons.logout),
              label: const Text('Se déconnecter'),
            ),
          ],
        );
      },
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
  final double salesToday;
  final int paidInvoices;
  final int pendingInvoices;
  final int cancelledInvoices;
  final List<Map<String, dynamic>> topSellingProducts;
  final List<Map<String, dynamic>> leastSellingProducts;
  final List<Map<String, dynamic>> topClients;
  final bool isVendor;
  final String? vendorName;
  final double vendorSalesToday;
  final double vendorTotalSales;
  final int vendorInvoicesCount;
  final int vendorPaidInvoices;
  final List<Map<String, dynamic>> vendorTopProducts;
  final List<Map<String, dynamic>> vendorTopClients;
  final Future<void> Function() onRefresh;
  final ScrollController modalScrollController;

  const DashboardContent({
    Key? key,
    required this.produits,
    required this.suppliers,
    required this.months,
    required this.users,
    required this.productsSold,
    required this.salesToday,
    required this.paidInvoices,
    required this.pendingInvoices,
    required this.cancelledInvoices,
    required this.topSellingProducts,
    required this.leastSellingProducts,
    required this.topClients,
    required this.isVendor,
    required this.vendorName,
    required this.vendorSalesToday,
    required this.vendorTotalSales,
    required this.vendorInvoicesCount,
    required this.vendorPaidInvoices,
    required this.vendorTopProducts,
    required this.vendorTopClients,
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
              isVendor ? 'Mon tableau de bord' : 'Tableau de bord',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.grey.shade900,
              ),
            ),
            const SizedBox(height: 16.0),
            buildHeroCard(),
            const SizedBox(height: 24.0),
            // Cartes de ventes - différentes selon le rôle
            if (isVendor) ...[
              // Cartes spécifiques au vendeur
              Row(
                children: [
                  Expanded(
                    child: _buildSalesCard(
                      'Mes ventes aujourd\'hui',
                      '${NumberFormat('#,##0.00', 'fr_FR').format(vendorSalesToday)} FCFA',
                      Icons.today_rounded,
                      Colors.green,
                      isDarkMode,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSalesCard(
                      'Total mes ventes',
                      '${NumberFormat('#,##0.00', 'fr_FR').format(vendorTotalSales)} FCFA',
                      Icons.trending_up_rounded,
                      Colors.blue,
                      isDarkMode,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSalesCard(
                      'Mes factures',
                      vendorInvoicesCount.toString(),
                      Icons.receipt_long_rounded,
                      Colors.orange,
                      isDarkMode,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSalesCard(
                      'Mes factures payées',
                      vendorPaidInvoices.toString(),
                      Icons.check_circle_rounded,
                      Colors.teal,
                      isDarkMode,
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Cartes générales pour les autres rôles
              Row(
                children: [
                  Expanded(
                    child: _buildSalesCard(
                      'Ventes aujourd\'hui',
                      '${NumberFormat('#,##0.00', 'fr_FR').format(salesToday)} FCFA',
                      Icons.today_rounded,
                      Colors.green,
                      isDarkMode,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSalesCard(
                      'Factures payées',
                      paidInvoices.toString(),
                      Icons.check_circle_rounded,
                      Colors.blue,
                      isDarkMode,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSalesCard(
                      'Factures en attente',
                      pendingInvoices.toString(),
                      Icons.pending_rounded,
                      Colors.orange,
                      isDarkMode,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSalesCard(
                      'Factures annulées',
                      cancelledInvoices.toString(),
                      Icons.cancel_rounded,
                      Colors.red,
                      isDarkMode,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24.0),
            // Statistiques générales - seulement pour les non-vendeurs
            if (!isVendor) ...[
              buildSurface(
                child: StatsCardsWidget(
                  totalProducts: produits.length,
                  outOfStock: outOfStockCount,
                  stockValue: totalStockValue,
                  productsSold: productsSold,
                ),
              ),
            ],
            const SizedBox(height: 24.0),
            // Inventaire - seulement pour les non-vendeurs
            if (!isVendor) ...[
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
            ],
            // Mouvements de stock - seulement pour les non-vendeurs
            if (!isVendor) ...[
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
            ],
            const SizedBox(height: 24.0),
            // Section des analyses de ventes - différentes selon le rôle
            if (isVendor) ...[
              // Analyses spécifiques au vendeur
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: buildSection(
                      title: 'Mes produits les plus vendus',
                      subtitle: 'Top 5 de mes produits par quantité',
                      child: _buildProductRanking(context, vendorTopProducts, true),
                    ),
                  ),
                  const SizedBox(width: 24.0),
                  Expanded(
                    child: buildSection(
                      title: 'Mes meilleurs clients',
                      subtitle: 'Top 5 de mes clients par chiffre d\'affaires',
                      child: _buildClientRanking(vendorTopClients),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Analyses générales pour les autres rôles
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: buildSection(
                      title: 'Produits les plus vendus',
                      subtitle: 'Top 5 des produits par quantité',
                      child: _buildProductRanking(context, topSellingProducts, true),
                    ),
                  ),
                  const SizedBox(width: 24.0),
                  Expanded(
                    child: buildSection(
                      title: 'Produits les moins vendus',
                      subtitle: 'Produits nécessitant plus d\'attention',
                      child: _buildProductRanking(context, leastSellingProducts, false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24.0),
              buildSection(
                title: 'Meilleurs clients',
                subtitle: 'Top 5 des clients par chiffre d\'affaires',
                child: _buildClientRanking(topClients),
              ),
            ],
            const SizedBox(height: 24.0),
            // Fournisseurs et utilisateurs - seulement pour les non-vendeurs
            if (!isVendor) ...[
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
          ],
        ),
      ),
    );
  }

  Widget _buildSalesCard(String title, String value, IconData icon, Color color, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          if (!isDarkMode)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductRanking(BuildContext ctx, List<Map<String, dynamic>> products, bool isTopSelling) {
    Widget _detailRow(String label, String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(value, textAlign: TextAlign.right, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      );
    }
    Produit? _findProduitFromTop(Map<String, dynamic> row) {
      final int? id = (row['id'] as num?)?.toInt();
      if (id != null) {
        try {
          return produits.firstWhere((p) => p.id == id);
        } catch (_) {}
      }
      final String? name = row['nom'] as String?;
      if (name != null) {
        try {
          return produits.firstWhere((p) => p.nom == name);
        } catch (_) {}
      }
      return null;
    }

    void _showEnlargedImage(BuildContext context, String? imageUrl) {
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            padding: const EdgeInsets.all(16),
            constraints: const BoxConstraints(maxWidth: 320, maxHeight: 380),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: (imageUrl != null && File(imageUrl).existsSync())
                      ? Image.file(
                          File(imageUrl),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stack) => const Icon(Icons.image_not_supported, size: 100, color: Colors.grey),
                        )
                      : const Icon(Icons.image_not_supported, size: 100, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Fermer',
                    style: TextStyle(color: isDarkMode ? Colors.blue.shade200 : Colors.blue.shade700, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    void _showProductDetails(BuildContext ctx, Produit produit) {
      final theme = Theme.of(ctx);
      final isDarkMode = theme.brightness == Brightness.dark;
      final currency = NumberFormat('#,##0.00', 'fr_FR');
      showDialog(
        context: ctx,
        barrierDismissible: true,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          title: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.blue.shade50),
                clipBehavior: Clip.antiAlias,
                child: (produit.imageUrl != null && produit.imageUrl!.isNotEmpty && File(produit.imageUrl!).existsSync())
                    ? Image.file(File(produit.imageUrl!), fit: BoxFit.cover)
                    : Icon(Icons.inventory_2_outlined, color: Colors.blue.shade600),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(produit.nom, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _detailRow('Catégorie', produit.categorie),
              if (produit.marque != null && produit.marque!.isNotEmpty) _detailRow('Marque', produit.marque!),
              if (produit.sku != null && produit.sku!.isNotEmpty) _detailRow('SKU', produit.sku!),
              if (produit.codeBarres != null && produit.codeBarres!.isNotEmpty) _detailRow('Code-barres', produit.codeBarres!),
              _detailRow('Unité', produit.unite),
              _detailRow('Stock', '${produit.quantiteStock}'),
              _detailRow('Prix vente', '${currency.format(produit.prixVente)} FCFA'),
              if (produit.prixVenteGros > 0) _detailRow('Prix gros', '${currency.format(produit.prixVenteGros)} FCFA'),
              if (produit.description != null && produit.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Description', style: theme.textTheme.labelLarge),
                const SizedBox(height: 4),
                Text(produit.description!),
              ],
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => _showEnlargedImage(ctx, produit.imageUrl),
                  icon: const Icon(Icons.zoom_in),
                  label: Text('Voir l\'image', style: TextStyle(color: isDarkMode ? Colors.blue.shade200 : Colors.blue.shade700)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer')),
          ],
        ),
      );
    }

    void _showProductDetailsFromTop(BuildContext ctx, Map<String, dynamic> row) {
      final produit = _findProduitFromTop(row);
      if (produit != null) {
        _showProductDetails(ctx, produit);
        return;
      }
      final currency = NumberFormat('#,##0.00', 'fr_FR');
      final name = row['nom']?.toString() ?? 'Produit';
      final qty = (row['totalQuantite'] as num?)?.toInt() ?? 0;
      final ca = (row['totalCA'] as num?)?.toDouble() ?? 0.0;
      showDialog(
        context: ctx,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Quantité vendue', '$qty'),
              _detailRow('Chiffre d\'affaires', '${currency.format(ca)} FCFA'),
            ],
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer'))],
        ),
      );
    }

    
    if (products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Aucune donnée disponible',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }

    return Column(
      children: products.asMap().entries.map((entry) {
        final index = entry.key;
        final product = entry.value;
        final rank = index + 1;
        final name = product['nom'] as String? ?? 'N/A';
        final quantity = (product['totalQuantite'] as num?)?.toInt() ?? 0;
        final ca = (product['totalCA'] as num?)?.toDouble() ?? 0.0;

        final imageUrl = product['imageUrl'] as String?;
        return InkWell(
          onTap: () => _showProductDetailsFromTop(ctx, product),
          borderRadius: BorderRadius.circular(8),
          child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isTopSelling ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    rank.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.grey.shade200),
                clipBehavior: Clip.antiAlias,
                child: (imageUrl != null && imageUrl.isNotEmpty && File(imageUrl).existsSync())
                    ? Image.file(File(imageUrl), fit: BoxFit.cover)
                    : Icon(Icons.image_not_supported, color: Colors.grey.shade500, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$quantity unités • ${NumberFormat('#,##0.00', 'fr_FR').format(ca)} FCFA',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
      }).toList(),
    );
  }

  Widget _buildClientRanking(List<Map<String, dynamic>> clients) {
    if (clients.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Aucune donnée disponible',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }

    return Column(
      children: clients.asMap().entries.map((entry) {
        final index = entry.key;
        final client = entry.value;
        final rank = index + 1;
        final name = client['clientNom'] as String? ?? 'Client anonyme';
        final invoiceCount = (client['factureCount'] as num?)?.toInt() ?? 0;
        final ca = (client['totalCA'] as num?)?.toDouble() ?? 0.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    rank.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$invoiceCount facture(s) • ${NumberFormat('#,##0.00', 'fr_FR').format(ca)} FCFA',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class DashboardData {
  final List<Produit> produits;
  final List<Supplier> suppliers;
  final List<User> users;
  final int productsSold;
  final double salesToday;
  final int paidInvoices;
  final int pendingInvoices;
  final int cancelledInvoices;
  final List<Map<String, dynamic>> topSellingProducts;
  final List<Map<String, dynamic>> leastSellingProducts;
  final List<Map<String, dynamic>> topClients;
  final bool isVendor;
  final String? vendorName;
  final double vendorSalesToday;
  final double vendorTotalSales;
  final int vendorInvoicesCount;
  final int vendorPaidInvoices;
  final List<Map<String, dynamic>> vendorTopProducts;
  final List<Map<String, dynamic>> vendorTopClients;

  const DashboardData({
    required this.produits,
    required this.suppliers,
    required this.users,
    required this.productsSold,
    required this.salesToday,
    required this.paidInvoices,
    required this.pendingInvoices,
    required this.cancelledInvoices,
    required this.topSellingProducts,
    required this.leastSellingProducts,
    required this.topClients,
    required this.isVendor,
    required this.vendorName,
    required this.vendorSalesToday,
    required this.vendorTotalSales,
    required this.vendorInvoicesCount,
    required this.vendorPaidInvoices,
    required this.vendorTopProducts,
    required this.vendorTopClients,
  });
}
