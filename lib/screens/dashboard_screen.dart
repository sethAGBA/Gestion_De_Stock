import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stock_management/providers/auth_provider.dart';
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
import '../models/models.dart';
import '../widgets/stock_movements_chart_widget.dart';
import '../widgets/suppliers_table_widget.dart';
import '../widgets/users_table_widget.dart';
import 'login_screen.dart';
import '../constants/app_constants.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<List<Produit>> _produitsFuture;
  late Future<List<Supplier>> _suppliersFuture;
  late Future<List<User>> _usersFuture;
  late Future<int> _productsSoldFuture;
  final List<String> months = ['Mai', 'Juin', 'Juillet', 'Août', 'Octobre'];
  int _selectedIndex = 0;
  bool _hasCheckedAuth = false;

  @override
  void initState() {
    super.initState();
    print('DashboardScreen initState');
    _produitsFuture = Future.value([]);
    _suppliersFuture = Future.value([]);
    _usersFuture = Future.value([]);
    _productsSoldFuture = Future.value(0);
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    try {
      print('Initialisation de la base de données...');
      await DatabaseHelper.database;
      print('Database initialized successfully');
      _refreshData();
    } catch (e) {
      print('Erreur dans _initDatabase : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de base de données : $e')),
      );
    }
  }

  void _refreshData({bool forceRefresh = false}) {
    setState(() {
      print('Refreshing dashboard data...');
      // Toujours recharger les produits pour refléter les mises à jour de quantiteStock (ex: retours clients)
      _produitsFuture = DatabaseHelper.getProduits();
      _suppliersFuture = DatabaseHelper.getSuppliers();
      _usersFuture = DatabaseHelper.getUsers();
      _productsSoldFuture = DatabaseHelper.getTotalProductsSold();
    });
  }

  List<Widget> get _screens {
    return [
      FutureBuilder<List<Produit>>(
        future: _produitsFuture,
        builder: (context, produitSnapshot) {
          if (produitSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (produitSnapshot.hasError) {
            return Center(child: Text('Erreur : ${produitSnapshot.error}'));
          }
          return FutureBuilder<List<Supplier>>(
            future: _suppliersFuture,
            builder: (context, supplierSnapshot) {
              if (supplierSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (supplierSnapshot.hasError) {
                return Center(child: Text('Erreur : ${supplierSnapshot.error}'));
              }
              return FutureBuilder<List<User>>(
                future: _usersFuture,
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (userSnapshot.hasError) {
                    return Center(child: Text('Erreur : ${userSnapshot.error}'));
                  }
                  return FutureBuilder<int>(
                    future: _productsSoldFuture,
                    builder: (context, productsSoldSnapshot) {
                      if (productsSoldSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (productsSoldSnapshot.hasError) {
                        return Center(child: Text('Erreur : ${productsSoldSnapshot.error}'));
                      }
                      if (!produitSnapshot.hasData ||
                          !supplierSnapshot.hasData ||
                          !userSnapshot.hasData ||
                          !productsSoldSnapshot.hasData) {
                        return const Center(child: Text('Aucune donnée disponible'));
                      }
                      return DashboardContent(
                        produits: produitSnapshot.data!,
                        suppliers: supplierSnapshot.data!,
                        months: months,
                        users: userSnapshot.data!,
                        productsSold: productsSoldSnapshot.data!,
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
      const ProductsScreen(),
      const EntriesScreen(),
      const ExitsScreen(),
      const InventoryScreen(),
       SuppliersScreen(),
      const UsersScreen(),
      const SalesScreen(),
      const AlertsScreen(),
       SettingsScreen(),
      const DamagedHistoryScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      print('Navigating to screen index: $index');
      _selectedIndex = index;
      if (_selectedIndex == 0) {
        _refreshData();
      }
    });
  }

  void _navigateToSalesScreen() async {
    print('Navigating to SalesScreen');
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SalesScreen()),
    );
    if (result == 'refresh') {
      _refreshData(forceRefresh: true); // Forcer le rafraîchissement après SalesScreen
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 1200;
    final isVerySmallScreen = screenWidth < 800;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        print('AuthProvider state: isAuthenticated=${authProvider.isAuthenticated}, currentUser=${authProvider.currentUser?.name}');
        if (!_hasCheckedAuth && !authProvider.isAuthenticated) {
          _hasCheckedAuth = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            print('Redirecting to /login due to unauthenticated state');
            Navigator.pushReplacementNamed(context, '/login');
          });
          return const Center(child: CircularProgressIndicator());
        }

        return ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 800),
          child: Scaffold(
            body: Row(
              children: [
                if (!isVerySmallScreen)
                  SidebarWidget(onItemTapped: _onItemTapped),
                Expanded(
                  child: Container(
                    color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppBarWidget(
                          isSmallScreen: isVerySmallScreen,
                          onMenuPressed: isVerySmallScreen
                              ? () => Scaffold.of(context).openDrawer()
                              : null,
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
                ? Drawer(child: SidebarWidget(onItemTapped: _onItemTapped))
                : null,
          ),
        );
      },
    );
  }
}

class DashboardContent extends StatelessWidget {
  final List<Produit> produits;
  final List<Supplier> suppliers;
  final List<String> months;
  final List<User> users;
  final int productsSold;

  const DashboardContent({
    Key? key,
    required this.produits,
    required this.suppliers,
    required this.months,
    required this.users,
    required this.productsSold,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 1200;
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.isAdmin;

    return SingleChildScrollView(
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
          const SizedBox(height: 24.0),
          // Shared: Stats Cards (Visible to both Admin and Employé)
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade800 : Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                if (!isDarkMode)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10.0,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: StatsCardsWidget(
                totalProducts: produits.length,
                outOfStock: produits.where((p) => p.quantiteStock <= p.stockMin).length,
                stockValue: produits.isNotEmpty
                    ? produits
                        .map((p) => (p.prixVente) * p.quantiteStock)
                        .reduce((a, b) => a + b)
                    : 0.0,
                productsSold: productsSold,
                screenWidth: screenWidth,
              ),
            ),
          ),
          const SizedBox(height: 24.0),
          // Shared: Products Table (Visible to both Admin and Employé)
          Container(
            width: screenWidth * 0.9,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade800 : Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                if (!isDarkMode)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10.0,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: produits.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 48,
                          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun produit disponible',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    child: ProductsTableWidget(produits: produits),
                  ),
          ),
          const SizedBox(height: 24.0),
          // Shared: Stock Movements Chart (Visible to both Admin and Employé)
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade800 : Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                if (!isDarkMode)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10.0,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: SingleChildScrollView(
              child: StockMovementsChartWidget(months: months),
            ),
          ),
          const SizedBox(height: 24.0),
          // Admin-Only and Shared Sections
          isSmallScreen
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Admin-Only: Suppliers Table
                    if (isAdmin)
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey.shade800 : Colors.white,
                          borderRadius: BorderRadius.circular(12.0),
                          boxShadow: [
                            if (!isDarkMode)
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10.0,
                                offset: const Offset(0, 4),
                              ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          child: SuppliersTableWidget(suppliers: suppliers),
                        ),
                      ),
                    if (isAdmin) const SizedBox(height: 24.0),
                    // Admin-Only: Users Table
                    if (isAdmin)
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey.shade800 : Colors.white,
                          borderRadius: BorderRadius.circular(12.0),
                          boxShadow: [
                            if (!isDarkMode)
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10.0,
                                offset: const Offset(0, 4),
                              ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          child: UsersTableWidget(users: users),
                        ),
                      ),
                    // Message for Employé
                    if (!isAdmin)
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey.shade800 : Colors.white,
                          borderRadius: BorderRadius.circular(12.0),
                          boxShadow: [
                            if (!isDarkMode)
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10.0,
                                offset: const Offset(0, 4),
                              ),
                          ],
                        ),
                        child: Text(
                          'Certaines fonctionnalités, comme la gestion des fournisseurs et des utilisateurs, sont réservées aux administrateurs.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Admin-Only: Suppliers Table
                    Expanded(
                      child: isAdmin
                          ? Container(
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: isDarkMode ? Colors.grey.shade800 : Colors.white,
                                borderRadius: BorderRadius.circular(12.0),
                                boxShadow: [
                                  if (!isDarkMode)
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10.0,
                                      offset: const Offset(0, 4),
                                    ),
                                ],
                              ),
                              child: SingleChildScrollView(
                                child: SuppliersTableWidget(suppliers: suppliers),
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: isDarkMode ? Colors.grey.shade800 : Colors.white,
                                borderRadius: BorderRadius.circular(12.0),
                                boxShadow: [
                                  if (!isDarkMode)
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10.0,
                                      offset: const Offset(0, 4),
                                    ),
                                ],
                              ),
                              child: Text(
                                'Gestion des fournisseurs réservée aux administrateurs.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                    ),
                    const SizedBox(width: 24.0),
                    // Admin-Only: Users Table
                    Expanded(
                      child: isAdmin
                          ? Container(
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: isDarkMode ? Colors.grey.shade800 : Colors.white,
                                borderRadius: BorderRadius.circular(12.0),
                                boxShadow: [
                                  if (!isDarkMode)
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10.0,
                                      offset: const Offset(0, 4),
                                    ),
                                ],
                              ),
                              child: SingleChildScrollView(
                                child: UsersTableWidget(users: users),
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: isDarkMode ? Colors.grey.shade800 : Colors.white,
                                borderRadius: BorderRadius.circular(12.0),
                                boxShadow: [
                                  if (!isDarkMode)
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10.0,
                                      offset: const Offset(0, 4),
                                    ),
                                ],
                              ),
                              child: Text(
                                'Gestion des utilisateurs réservée aux administrateurs.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}