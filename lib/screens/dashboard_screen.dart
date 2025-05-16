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

  @override
  void initState() {
    super.initState();
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
      _refreshData();
    } catch (e) {
      print('Erreur dans _initDatabase : $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de base de données : $e')),
        );
      }
    }
  }

  void _refreshData() {
    setState(() {
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
       InventoryScreen(),
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
      _selectedIndex = index;
      if (_selectedIndex == 0) {
        _refreshData();
      }
    });
  }

  void _navigateToSalesScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SalesScreen()),
    );
    if (result == 'refresh') {
      _refreshData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (!authProvider.isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/login');
          });
          return const SizedBox.shrink();
        }

        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 1200;
        final isVerySmallScreen = screenWidth < 800;
        final theme = Theme.of(context);
        final isDarkMode = theme.brightness == Brightness.dark;

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
                          onLogout: () {
                            authProvider.logout();
                            Navigator.pushReplacementNamed(context, '/login');
                          },
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
          isSmallScreen
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    const SizedBox(height: 24.0),
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
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
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
                    ),
                    const SizedBox(width: 24.0),
                    Expanded(
                      child: Container(
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
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}