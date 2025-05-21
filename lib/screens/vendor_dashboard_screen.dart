import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stock_management/screens/login_screen.dart';
import 'package:stock_management/helpers/database_helper.dart';
import 'package:stock_management/widgets/products_table_widget.dart';
import 'package:stock_management/widgets/stats_cards_widget.dart';
import 'package:stock_management/screens/sales_screen.dart';
import 'package:stock_management/screens/alerts_screen.dart';
import 'package:stock_management/screens/damaged_history_screen.dart';
import 'package:stock_management/models/models.dart';
import 'package:stock_management/widgets/appbar_widget.dart';

class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({Key? key}) : super(key: key);

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen> {
  late Future<List<Produit>> _produitsFuture;
  late Future<int> _productsSoldFuture;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _produitsFuture = Future.value([]);
    _productsSoldFuture = Future.value(0);
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    try {
      print('Initialisation de la base de données pour VendorDashboard...');
      await DatabaseHelper.database;
      _refreshData();
    } catch (e) {
      print('Erreur dans _initDatabase : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de base de données : $e')),
      );
    }
  }

  void _refreshData() {
    setState(() {
      _produitsFuture = DatabaseHelper.getProduits();
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
          return FutureBuilder<int>(
            future: _productsSoldFuture,
            builder: (context, productsSoldSnapshot) {
              if (productsSoldSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (productsSoldSnapshot.hasError) {
                return Center(child: Text('Erreur : ${productsSoldSnapshot.error}'));
              }
              if (!produitSnapshot.hasData || !productsSoldSnapshot.hasData) {
                return const Center(child: Text('Aucune donnée disponible'));
              }
              return VendorDashboardContent(
                produits: produitSnapshot.data!,
                productsSold: productsSoldSnapshot.data!,
              );
            },
          );
        },
      ),
      const SalesScreen(),
      const AlertsScreen(),
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

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (Route<dynamic> route) => false,
              );
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 1200;
    final isVerySmallScreen = screenWidth < 800;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Row(
        children: [
          if (!isVerySmallScreen)
            VendorSidebarWidget(onItemTapped: _onItemTapped),
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
                    onLogout: _logout,
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
          ? Drawer(child: VendorSidebarWidget(onItemTapped: _onItemTapped))
          : null,
    );
  }
}

class VendorDashboardContent extends StatelessWidget {
  final List<Produit> produits;
  final int productsSold;

  const VendorDashboardContent({
    Key? key,
    required this.produits,
    required this.productsSold,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
        ],
      ),
    );
  }
}

class VendorSidebarWidget extends StatefulWidget {
  final Function(int)? onItemTapped;

  const VendorSidebarWidget({Key? key, this.onItemTapped}) : super(key: key);

  @override
  _VendorSidebarWidgetState createState() => _VendorSidebarWidgetState();
}

class _VendorSidebarWidgetState extends State<VendorSidebarWidget> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isVerySmallScreen = screenWidth < 800;

    double sidebarWidth = isVerySmallScreen ? 60.0 : 260.0;
    if (!_isExpanded && !isVerySmallScreen) {
      sidebarWidth = 60.0;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: sidebarWidth,
      color: const Color(0xFF1C3144),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              isVerySmallScreen || !_isExpanded ? 8.0 : 16.0,
              24.0,
              isVerySmallScreen || !_isExpanded ? 8.0 : 16.0,
              32.0,
            ),
            child: Row(
              mainAxisAlignment: isVerySmallScreen || !_isExpanded ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                const Icon(
                  CupertinoIcons.cube,
                  color: Colors.white,
                  size: 28.0,
                ),
                if (!isVerySmallScreen && _isExpanded) ...[
                  const SizedBox(width: 12.0),
                  const Text(
                    'GESTION DE STOCK',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!isVerySmallScreen)
            IconButton(
              icon: Icon(
                _isExpanded ? Icons.arrow_back_ios : Icons.arrow_forward_ios,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
            ),
          Expanded(
            child: ListView(
              children: [
                _buildMenuItem(
                  icon: Icons.dashboard,
                  title: 'Tableau de bord',
                  index: 0,
                  isSelected: true,
                  isExpanded: !isVerySmallScreen && _isExpanded,
                ),
                _buildMenuItem(
                  icon: Icons.account_balance_outlined,
                  title: 'Ventes',
                  index: 1,
                  isExpanded: !isVerySmallScreen && _isExpanded,
                ),
                _buildMenuItem(
                  icon: Icons.notifications,
                  title: 'Alertes',
                  index: 2,
                  isExpanded: !isVerySmallScreen && _isExpanded,
                ),
                _buildMenuItem(
                  icon: Icons.history,
                  title: 'Historiques',
                  index: 3,
                  isExpanded: !isVerySmallScreen && _isExpanded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required int index,
    bool isSelected = false,
    required bool isExpanded,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isExpanded ? 16.0 : 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: isExpanded
            ? Text(
                title,
                style: const TextStyle(color: Colors.white),
              )
            : null,
        selected: isSelected,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        onTap: () {
          if (widget.onItemTapped != null) {
            widget.onItemTapped!(index);
          }
        },
      ),
    );
  }
}