import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stock_management/screens/login_screen.dart';
import 'package:stock_management/helpers/database_helper.dart';
import 'package:stock_management/widgets/products_table_widget.dart';
import 'package:stock_management/widgets/stats_cards_widget.dart';
import 'package:stock_management/screens/sales_screen.dart';
import 'package:stock_management/screens/alerts_screen.dart';
import 'package:stock_management/screens/damaged_history_screen.dart';
import 'package:stock_management/screens/products_screen.dart';
import 'package:stock_management/screens/entries_screen.dart';
import 'package:stock_management/screens/exits_screen.dart';
import 'package:stock_management/screens/inventory_screen.dart';
import 'package:stock_management/screens/suppliers_screen.dart';
import 'package:stock_management/screens/users_screen.dart';
import 'package:stock_management/screens/settings_screen.dart';
import 'package:stock_management/screens/no_access_screen.dart';
import 'package:stock_management/models/models.dart';
import 'package:stock_management/widgets/appbar_widget.dart';
import 'package:stock_management/widgets/sidebar_widget.dart';
import 'package:stock_management/constants/screen_permissions.dart';
import 'package:stock_management/providers/auth_provider.dart';
import 'package:stock_management/constants/screen_permissions.dart';

class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({Key? key}) : super(key: key);

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen> {
  late Future<List<Produit>> _produitsFuture;
  late Future<int> _productsSoldFuture;
  int _selectedIndex = appScreenPermissions.indexWhere((entry) => entry.key == 'dashboard');
  static const Set<String> _vendorDefaultKeys = {'dashboard', 'sales', 'alerts', 'damaged_history'};
  Set<String> _allowedKeys = {..._vendorDefaultKeys};
  bool _checkedInitialAccess = false;
  bool _showingNoAccess = false;

  _VendorDashboardScreenState() {
    if (_selectedIndex == -1) {
      _selectedIndex = 0;
    }
  }

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final newAllowed = (user?.permissions == null || user!.permissions!.isEmpty)
        ? _vendorDefaultKeys
        : user.permissions!.toSet();
    if (!setEquals(_allowedKeys, newAllowed)) {
      _allowedKeys = {...newAllowed};
      _checkedInitialAccess = false;
    }
    if (!_checkedInitialAccess) {
      _checkedInitialAccess = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _enforceAccess();
      });
    } else {
      if (!_isScreenAllowed(_selectedIndex)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _enforceAccess();
        });
      }
    }
  }

  void _refreshData() {
    setState(() {
      _produitsFuture = DatabaseHelper.getProduits();
      _productsSoldFuture = DatabaseHelper.getTotalProductsSold();
    });
  }

  void _onItemTapped(int index) {
    final key = index >= 0 && index < appScreenPermissions.length
        ? appScreenPermissions[index].key
        : null;
    if (key == null || !_allowedKeys.contains(key)) {
      _redirectToNoAccess();
      return;
    }
    setState(() {
      _selectedIndex = index;
      if (key == 'dashboard') {
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
    final visibleEntries = appScreenPermissions.where((entry) => _allowedKeys.contains(entry.key)).toList();
    if (visibleEntries.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _redirectToNoAccess();
      });
    }
    final selectedKey = appScreenPermissions[_selectedIndex].key;
    int selectedStackIndex = visibleEntries.indexWhere((entry) => entry.key == selectedKey);
    if (selectedStackIndex == -1 && visibleEntries.isNotEmpty) {
      final firstAllowedIndex = appScreenPermissions.indexWhere((entry) => entry.key == visibleEntries.first.key);
      if (firstAllowedIndex != -1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _selectedIndex = firstAllowedIndex;
            if (visibleEntries.first.key == 'dashboard') {
              _refreshData();
            }
          });
        });
      }
      selectedStackIndex = 0;
    }

    return Scaffold(
      body: Row(
        children: [
          if (!isVerySmallScreen)
            SidebarWidget(
              onItemTapped: _onItemTapped,
              selectedIndex: _selectedIndex,
              allowedKeys: _allowedKeys,
            ),
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
                    child: visibleEntries.isEmpty
                        ? const NoAccessScreen()
                        : IndexedStack(
                            index: selectedStackIndex.clamp(0, visibleEntries.length - 1),
                            children: visibleEntries
                                .map((entry) => _buildScreenForKey(entry.key))
                                .toList(),
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
                allowedKeys: _allowedKeys,
              ),
            )
          : null,
    );
  }

  bool _isScreenAllowed(int index) {
    if (index < 0 || index >= appScreenPermissions.length) {
      return false;
    }
    final key = appScreenPermissions[index].key;
    return _allowedKeys.contains(key);
  }

  int? _firstAllowedIndex() {
    for (var i = 0; i < appScreenPermissions.length; i++) {
      if (_allowedKeys.contains(appScreenPermissions[i].key)) {
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
      if (appScreenPermissions[firstAllowed].key == 'dashboard') {
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

  Widget _buildScreenForKey(String key) {
    switch (key) {
      case 'dashboard':
        return FutureBuilder<List<Produit>>(
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
        );
      case 'products':
        return const ProductsScreen();
      case 'entries':
        return const EntriesScreen();
      case 'exits':
        return const ExitsScreen();
      case 'inventory':
        return InventoryScreen();
      case 'suppliers':
        return SuppliersScreen();
      case 'users':
        return const UsersScreen();
      case 'sales':
        return const SalesScreen();
      case 'alerts':
        return const AlertsScreen();
      case 'settings':
        return const SettingsScreen();
      case 'damaged_history':
        return const DamagedHistoryScreen();
      default:
        return const NoAccessScreen();
    }
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
                // screenWidth: screenWidth,
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
