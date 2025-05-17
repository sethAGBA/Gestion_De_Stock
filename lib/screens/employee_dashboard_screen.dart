import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stock_management/providers/auth_provider.dart';
import 'package:stock_management/providers/dashboard_provider.dart';
import 'package:stock_management/screens/damaged_history_screen.dart';
import '../helpers/database_helper.dart';
import '../widgets/products_table_widget.dart';
import '../widgets/sidebar_widget.dart';
import '../widgets/appbar_widget.dart';
import '../widgets/stats_cards_widget.dart';
import '../screens/sales_screen.dart';
import '../screens/alerts_screen.dart';
import '../screens/settings_screen.dart';
import '../models/models.dart';
import 'login_screen.dart';

class EmployeeDashboardScreen extends StatefulWidget {
  const EmployeeDashboardScreen({Key? key}) : super(key: key);

  @override
  State<EmployeeDashboardScreen> createState() => _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> {
  int _selectedIndex = 0;
  bool _hasCheckedAuth = false;

  @override
  void initState() {
    super.initState();
    print('EmployeeDashboardScreen initState');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initData();
    });
  }

  Future<void> _initData() async {
    try {
      print('Initialisation des données...');
      await DatabaseHelper.database;
      print('Database initialized successfully');
      _refreshData();
    } catch (e) {
      print('Erreur dans _initData : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de base de données : $e')),
      );
    }
  }

  void _refreshData({bool forceRefresh = false}) {
    print('Refreshing dashboard data...');
    Provider.of<DashboardProvider>(context, listen: false).fetchDashboardData();
  }

  List<Widget> get _screens {
    return [
      Consumer<DashboardProvider>(
        builder: (context, dashboardProvider, child) {
          if (dashboardProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (dashboardProvider.errorMessage != null) {
            return Center(child: Text('Erreur : ${dashboardProvider.errorMessage}'));
          }
          return DashboardContent(
            produits: dashboardProvider.produits,
            productsSold: dashboardProvider.productsSold,
          );
        },
      ),
      const SalesScreen(),
      const DamagedHistoryScreen(),
      const AlertsScreen(),
       SettingsScreen(),
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
  final int productsSold;

  const DashboardContent({
    Key? key,
    required this.produits,
    required this.productsSold,
  }) : super(key: key);

  @override
  Widget build( context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth < 800 ? 8.0 : 16.0,
        vertical: 16.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bienvenue,',
            style: theme.textTheme.titleMedium?.copyWith(
              color: const Color(0xFF1C3144),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${Provider.of<AuthProvider>(context).currentUser?.name ?? "Employé"}',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 24.0),
          // Stats Cards
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
          // Products Table
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
        ],
      ),
    );
  }
}