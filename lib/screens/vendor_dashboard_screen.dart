import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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
  late Future<double> _vendorSalesTodayFuture;
  late Future<double> _vendorTotalSalesFuture;
  late Future<int> _vendorInvoicesCountFuture;
  late Future<int> _vendorPaidInvoicesFuture;
  late Future<List<Map<String, dynamic>>> _vendorTopProductsFuture;
  late Future<List<Map<String, dynamic>>> _vendorTopClientsFuture;
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
    _vendorSalesTodayFuture = Future.value(0.0);
    _vendorTotalSalesFuture = Future.value(0.0);
    _vendorInvoicesCountFuture = Future.value(0);
    _vendorPaidInvoicesFuture = Future.value(0);
    _vendorTopProductsFuture = Future.value([]);
    _vendorTopClientsFuture = Future.value([]);
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
    final allKeys = appScreenPermissions.map((e) => e.key).toSet();
    Set<String> newAllowed;
    if (user?.permissions == null) {
      // Null = "tous les écrans" (case Tous sélectionnée dans la modale)
      newAllowed = allKeys;
    } else {
      // Respecter exactement la sélection (liste vide => aucun écran autorisé)
      newAllowed = user!.permissions!.toSet();
    }
    if (!setEquals(_allowedKeys, newAllowed)) {
      _allowedKeys = {...newAllowed};
      _checkedInitialAccess = false;
    }
    // Sync permissions from DB to reflect live updates (e.g., changed by admin)
    _syncPermissionsFromDatabase();
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

  Future<void> _syncPermissionsFromDatabase() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final current = auth.currentUser;
      if (current == null) return;
      final users = await DatabaseHelper.getUsers();
      final fresh = users.firstWhere((u) => u.id == current.id, orElse: () => current);
      final allKeys = appScreenPermissions.map((e) => e.key).toSet();
      Set<String> newAllowed;
      if (fresh.permissions == null) {
        // Tous les écrans
        newAllowed = allKeys;
      } else {
        // Sélection exacte (peut être vide)
        newAllowed = fresh.permissions!.toSet();
      }
      if (!setEquals(_allowedKeys, newAllowed)) {
        if (!mounted) return;
        setState(() {
          _allowedKeys = {...newAllowed};
        });
        _enforceAccess();
      }
    } catch (_) {
      // Ignore sync errors silently
    }
  }

  void _refreshData() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = auth.currentUser;
    final vendorName = currentUser?.name;

    setState(() {
      _produitsFuture = DatabaseHelper.getProduits();
      _productsSoldFuture = DatabaseHelper.getTotalProductsSold();
      
      if (vendorName != null) {
        _vendorSalesTodayFuture = DatabaseHelper.getVendorSalesToday(vendorName);
        _vendorTotalSalesFuture = DatabaseHelper.getVendorTotalSales(vendorName);
        _vendorInvoicesCountFuture = DatabaseHelper.getVendorInvoicesCount(vendorName);
        _vendorPaidInvoicesFuture = DatabaseHelper.getVendorPaidInvoicesCount(vendorName);
        _vendorTopProductsFuture = DatabaseHelper.getVendorTopProducts(vendorName);
        _vendorTopClientsFuture = DatabaseHelper.getVendorTopClients(vendorName);
      }
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
      barrierDismissible: true,
      builder: (context) {
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
                return FutureBuilder<double>(
                  future: _vendorSalesTodayFuture,
                  builder: (context, salesTodaySnapshot) {
                    return FutureBuilder<double>(
                      future: _vendorTotalSalesFuture,
                      builder: (context, totalSalesSnapshot) {
                        return FutureBuilder<int>(
                          future: _vendorInvoicesCountFuture,
                          builder: (context, invoicesCountSnapshot) {
                            return FutureBuilder<int>(
                              future: _vendorPaidInvoicesFuture,
                              builder: (context, paidInvoicesSnapshot) {
                                return FutureBuilder<List<Map<String, dynamic>>>(
                                  future: _vendorTopProductsFuture,
                                  builder: (context, topProductsSnapshot) {
                                    return FutureBuilder<List<Map<String, dynamic>>>(
                                      future: _vendorTopClientsFuture,
                                      builder: (context, topClientsSnapshot) {
                                        if (salesTodaySnapshot.connectionState == ConnectionState.waiting ||
                                            totalSalesSnapshot.connectionState == ConnectionState.waiting ||
                                            invoicesCountSnapshot.connectionState == ConnectionState.waiting ||
                                            paidInvoicesSnapshot.connectionState == ConnectionState.waiting ||
                                            topProductsSnapshot.connectionState == ConnectionState.waiting ||
                                            topClientsSnapshot.connectionState == ConnectionState.waiting) {
                                          return const Center(child: CircularProgressIndicator());
                                        }
                                        
                                        if (!produitSnapshot.hasData || !productsSoldSnapshot.hasData) {
                                          return const Center(child: Text('Aucune donnée disponible'));
                                        }
                                        
                                        return VendorDashboardContent(
                                          produits: produitSnapshot.data!,
                                          productsSold: productsSoldSnapshot.data!,
                                          vendorSalesToday: salesTodaySnapshot.data ?? 0.0,
                                          vendorTotalSales: totalSalesSnapshot.data ?? 0.0,
                                          vendorInvoicesCount: invoicesCountSnapshot.data ?? 0,
                                          vendorPaidInvoices: paidInvoicesSnapshot.data ?? 0,
                                          vendorTopProducts: topProductsSnapshot.data ?? [],
                                          vendorTopClients: topClientsSnapshot.data ?? [],
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
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

class VendorDashboardContent extends StatefulWidget {
  final List<Produit> produits;
  final int productsSold;
  final double vendorSalesToday;
  final double vendorTotalSales;
  final int vendorInvoicesCount;
  final int vendorPaidInvoices;
  final List<Map<String, dynamic>> vendorTopProducts;
  final List<Map<String, dynamic>> vendorTopClients;

  const VendorDashboardContent({
    Key? key,
    required this.produits,
    required this.productsSold,
    required this.vendorSalesToday,
    required this.vendorTotalSales,
    required this.vendorInvoicesCount,
    required this.vendorPaidInvoices,
    required this.vendorTopProducts,
    required this.vendorTopClients,
  }) : super(key: key);

  @override
  State<VendorDashboardContent> createState() => _VendorDashboardContentState();
}

class _VendorDashboardContentState extends State<VendorDashboardContent> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.image_not_supported,
                          size: 100,
                          color: Colors.grey,
                        ),
                      )
                    : const Icon(
                        Icons.image_not_supported,
                        size: 100,
                        color: Colors.grey,
                      ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Fermer',
                  style: TextStyle(
                    color: isDarkMode ? Colors.blue.shade200 : Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Produit? _findProduitFromTop(Map<String, dynamic> topRow) {
    final int? id = (topRow['id'] as num?)?.toInt();
    if (id != null) {
      try {
        return widget.produits.firstWhere((p) => p.id == id);
      } catch (_) {}
    }
    final String? name = topRow['nom'] as String?;
    if (name != null) {
      try {
        return widget.produits.firstWhere((p) => p.nom == name);
      } catch (_) {}
    }
    return null;
  }

  void _showProductDetails(Produit produit) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final currency = NumberFormat('#,##0.00', 'fr_FR');
    showDialog(
      context: context,
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
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.blue.shade50,
              ),
              clipBehavior: Clip.antiAlias,
              child: (produit.imageUrl != null && produit.imageUrl!.isNotEmpty && File(produit.imageUrl!).existsSync())
                  ? Image.file(File(produit.imageUrl!), fit: BoxFit.cover)
                  : Icon(Icons.inventory_2_outlined, color: Colors.blue.shade600),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                produit.nom,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _detailRow('Catégorie', produit.categorie),
            if (produit.marque != null && produit.marque!.isNotEmpty)
              _detailRow('Marque', produit.marque!),
            if (produit.sku != null && produit.sku!.isNotEmpty)
              _detailRow('SKU', produit.sku!),
            if (produit.codeBarres != null && produit.codeBarres!.isNotEmpty)
              _detailRow('Code-barres', produit.codeBarres!),
            _detailRow('Unité', produit.unite),
            _detailRow('Stock', '${produit.quantiteStock}'),
            _detailRow('Prix vente', '${currency.format(produit.prixVente)} FCFA'),
            if (produit.prixVenteGros > 0)
              _detailRow('Prix gros', '${currency.format(produit.prixVenteGros)} FCFA'),
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
                onPressed: () => _showEnlargedImage(context, produit.imageUrl),
                icon: const Icon(Icons.zoom_in),
                label: Text(
                  'Voir l\'image',
                  style: TextStyle(
                    color: isDarkMode ? Colors.blue.shade200 : Colors.blue.shade700,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showProductDetailsFromTop(Map<String, dynamic> row) {
    final produit = _findProduitFromTop(row);
    if (produit != null) {
      _showProductDetails(produit);
      return;
    }
    // Fallback minimal dialog using available data
    final theme = Theme.of(context);
    final currency = NumberFormat('#,##0.00', 'fr_FR');
    final name = row['nom']?.toString() ?? 'Produit';
    final qty = (row['totalQuantite'] as num?)?.toInt() ?? 0;
    final ca = (row['totalCA'] as num?)?.toDouble() ?? 0.0;
    showDialog(
      context: context,
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 1200;

    // Filtrer les produits selon la recherche
    final filteredProducts = _searchQuery.isEmpty
        ? widget.produits
        : widget.produits.where((produit) {
            final searchLower = _searchQuery.toLowerCase();
            return produit.nom.toLowerCase().contains(searchLower) ||
                   (produit.sku?.toLowerCase().contains(searchLower) ?? false) ||
                   (produit.codeBarres?.toLowerCase().contains(searchLower) ?? false) ||
                   produit.categorie.toLowerCase().contains(searchLower);
          }).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth < 800 ? 8.0 : 16.0,
        vertical: 16.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mon tableau de bord',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 16.0),
          _buildHeroCard(isDarkMode),
          const SizedBox(height: 24.0),
          // Cartes de ventes personnelles
          Row(
            children: [
              Expanded(
                child: _buildSalesCard(
                  'Mes ventes aujourd\'hui',
                  '${NumberFormat('#,##0.00', 'fr_FR').format(widget.vendorSalesToday)} FCFA',
                  Icons.today_rounded,
                  Colors.green,
                  isDarkMode,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSalesCard(
                  'Total de mes ventes',
                  '${NumberFormat('#,##0.00', 'fr_FR').format(widget.vendorTotalSales)} FCFA',
                  Icons.trending_up_rounded,
                  Colors.blue,
                  isDarkMode,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSalesCard(
                  'Total des factures',
                  widget.vendorInvoicesCount.toString(),
                  Icons.receipt_long_rounded,
                  Colors.orange,
                  isDarkMode,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Row(
            children: [
              Expanded(
                child: _buildSalesCard(
                  'Factures payées',
                  widget.vendorPaidInvoices.toString(),
                  Icons.check_circle_rounded,
                  Colors.teal,
                  isDarkMode,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSalesCard(
                  'Factures impayées',
                  (widget.vendorInvoicesCount - widget.vendorPaidInvoices).toString(),
                  Icons.pending_rounded,
                  Colors.red,
                  isDarkMode,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(), // Espace vide pour équilibrer
              ),
            ],
          ),
          const SizedBox(height: 24.0),
          // Analyses personnalisées
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildSection(
                  title: 'Mes produits les plus vendus',
                  subtitle: 'Top 5 de mes produits par quantité',
                  child: _buildProductRanking(widget.vendorTopProducts, true),
                  isDarkMode: isDarkMode,
                ),
              ),
              const SizedBox(width: 24.0),
              Expanded(
                child: _buildSection(
                  title: 'Mes meilleurs clients',
                  subtitle: 'Top 5 de mes clients par chiffre d\'affaires',
                  child: _buildClientRanking(widget.vendorTopClients),
                  isDarkMode: isDarkMode,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24.0),
          // Liste des produits avec recherche
          _buildSection(
            title: 'Liste des produits',
            subtitle: 'Tous les produits disponibles',
            child: Column(
              children: [
                _buildSearchBar(isDarkMode),
                const SizedBox(height: 16.0),
                _buildProductsList(filteredProducts),
              ],
            ),
            isDarkMode: isDarkMode,
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.teal.shade600,
            Colors.teal.shade800,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.3),
            blurRadius: 20.0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenue sur votre tableau de bord',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  'Suivez vos performances de vente en temps réel',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.person_rounded,
            size: 64,
            color: Colors.white.withOpacity(0.8),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesCard(String title, String value, IconData icon, Color color, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          if (!isDarkMode)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10.0,
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
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 16.0),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.grey.shade900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required Widget child,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          if (!isDarkMode)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10.0,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16.0),
          child,
        ],
      ),
    );
  }

  Widget _buildProductRanking(List<Map<String, dynamic>> products, bool isTop) {
    if (products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 8),
              Text(
                'Aucun produit vendu',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: products.asMap().entries.map((entry) {
        final index = entry.key;
        final product = entry.value;
        final rank = index + 1;
        final name = product['nom'] ?? 'N/A';
        final quantity = product['totalQuantite'] ?? 0;
        final revenue = product['totalCA'] ?? 0.0;
        final String? imageUrl = product['imageUrl'] as String?;

        return InkWell(
          onTap: () => _showProductDetailsFromTop(product as Map<String, dynamic>),
          borderRadius: BorderRadius.circular(8.0),
          child: Container(
          margin: const EdgeInsets.only(bottom: 8.0),
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isTop ? Colors.amber : Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: () => _showEnlargedImage(context, imageUrl),
                borderRadius: BorderRadius.circular(8.0),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                    color: Colors.grey.shade200,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: (imageUrl != null && imageUrl.isNotEmpty && File(imageUrl).existsSync())
                      ? Image.file(File(imageUrl), fit: BoxFit.cover)
                      : Icon(Icons.image_not_supported, color: Colors.grey.shade500, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '$quantity unités vendues',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${NumberFormat('#,##0', 'fr_FR').format(revenue)} FCFA',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        );
      }).toList(),
    );
  }

  Widget _buildClientRanking(List<Map<String, dynamic>> clients) {
    if (clients.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Icon(
                Icons.people_outline,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 8),
              Text(
                'Aucun client',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: clients.asMap().entries.map((entry) {
        final index = entry.key;
        final client = entry.value;
        final rank = index + 1;
        final name = client['clientNom'] ?? 'Client anonyme';
        final invoiceCount = client['factureCount'] ?? 0;
        final totalCA = client['totalCA'] ?? 0.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 8.0),
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$rank',
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
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '$invoiceCount factures',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${NumberFormat('#,##0', 'fr_FR').format(totalCA)} FCFA',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSearchBar(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Rechercher un produit...',
          hintStyle: TextStyle(
            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
        ),
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.grey.shade900,
        ),
      ),
    );
  }

  Widget _buildProductsList(List<Produit> products) {
    if (products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 8),
              Text(
                'Aucun produit disponible',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      child: SingleChildScrollView(
        child: Column(
          children: products.map((produit) {
            final isLowStock = produit.quantiteStock <= produit.stockMin;
            final stockValue = produit.prixVente * produit.quantiteStock;
            
            return InkWell(
              onTap: () => _showProductDetails(produit),
              borderRadius: BorderRadius.circular(8.0),
              child: Container(
              margin: const EdgeInsets.only(bottom: 8.0),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: isLowStock ? Colors.red.shade200 : Colors.grey.shade200,
                ),
              ),
              child: Row(
                children: [
                  // Image du produit (ou icône fallback)
                  InkWell(
                    onTap: () => _showEnlargedImage(context, produit.imageUrl),
                    borderRadius: BorderRadius.circular(8.0),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                        color: isLowStock ? Colors.red.shade50 : Colors.blue.shade50,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: (produit.imageUrl != null && produit.imageUrl!.isNotEmpty && File(produit.imageUrl!).existsSync())
                          ? Image.file(File(produit.imageUrl!), fit: BoxFit.cover)
                          : Icon(
                              Icons.inventory_2_outlined,
                              color: isLowStock ? Colors.red.shade600 : Colors.blue.shade600,
                              size: 22,
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Informations du produit
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          produit.nom,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'SKU: ${produit.sku ?? 'N/A'}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Stock et prix
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Stock: ',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${produit.quantiteStock}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isLowStock ? Colors.red.shade700 : Colors.green.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${NumberFormat('#,##0', 'fr_FR').format(produit.prixVente)} FCFA',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  // Badge de statut
                  if (isLowStock)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Stock bas',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
