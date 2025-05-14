import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import '../models/models.dart';
import 'package:intl/intl.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({Key? key}) : super(key: key);

  @override
  _AlertsScreenState createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  late Database _database;
  String _selectedFilter = 'all'; // 'all', 'damaged', 'low_stock'
  final _searchController = TextEditingController();
  final _numberFormat = NumberFormat("#,##0", "fr_FR");

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _database.close();
    super.dispose();
  }

  Future<void> _initDatabase() async {
    _database = await openDatabase(
      path.join(await getDatabasesPath(), 'dashboard.db'),
    );
  }

  Future<List<Produit>> _getDamagedProducts() async {
    try {
      final maps = await _database.query(
        'produits',
        where: 'quantiteAvariee > ?',
        whereArgs: [0],
      );
      return List.generate(maps.length, (i) => Produit.fromMap(maps[i]));
    } catch (e) {
      print('Erreur lors de la récupération des produits avariés : $e');
      return [];
    }
  }

  Future<List<Produit>> _getLowStockProducts() async {
    try {
      final maps = await _database.query(
        'produits',
        where: 'quantiteStock <= seuilAlerte AND statut != ?',
        whereArgs: ['arrêté'],
      );
      return List.generate(maps.length, (i) => Produit.fromMap(maps[i]));
    } catch (e) {
      print('Erreur lors de la récupération des produits à faible stock : $e');
      return [];
    }
  }

  Future<Map<String, List<Produit>>> _getAlerts() async {
    try {
      final damagedProducts = await _getDamagedProducts();
      final lowStockProducts = await _getLowStockProducts();
      return {
        'damaged': damagedProducts,
        'lowStock': lowStockProducts,
      };
    } catch (e) {
      debugPrint('Erreur lors de la récupération des alertes : $e');
      return {'damaged': [], 'lowStock': []};
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(isDarkMode),
          _buildFilters(theme),
          Expanded(
            child: _buildAlertsList(isDarkMode),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Theme.of(context).primaryColor,
                size: 32,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Centre d\'alertes',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gestion des produits à risque',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher dans les alertes...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
            ),
            onChanged: (value) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
      child: Row(
        children: [
          _filterChip('Tout', 'all'),
          const SizedBox(width: 8),
          _filterChip('Produits avariés', 'damaged'),
          const SizedBox(width: 8),
          _filterChip('Stock faible', 'low_stock'),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          _selectedFilter = selected ? value : 'all';
        });
      },
      backgroundColor: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
    );
  }

  Widget _buildAlertsList(bool isDarkMode) {
    return FutureBuilder<Map<String, List<Produit>>>(
      future: _getAlerts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        final alerts = snapshot.data!;
        final damagedProducts = alerts['damaged'] ?? [];
        final lowStockProducts = alerts['lowStock'] ?? [];

        if (damagedProducts.isEmpty && lowStockProducts.isEmpty) {
          return _buildEmptyState();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              if (_selectedFilter != 'low_stock')
                _buildAlertSection(
                  'Produits avariés',
                  damagedProducts,
                  Colors.red,
                  isDarkMode,
                ),
              if (_selectedFilter != 'damaged')
                _buildAlertSection(
                  'Stock faible',
                  lowStockProducts,
                  Colors.orange,
                  isDarkMode,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAlertSection(
    String title,
    List<Produit> products,
    Color color,
    bool isDarkMode,
  ) {
    final filteredProducts = products.where((p) {
      final searchTerm = _searchController.text.toLowerCase();
      return p.nom.toLowerCase().contains(searchTerm) ||
          p.categorie.toLowerCase().contains(searchTerm);
    }).toList();

    if (filteredProducts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: color),
            const SizedBox(width: 8),
            Text(
              '$title (${filteredProducts.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredProducts.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final produit = filteredProducts[index];
            return _buildAlertCard(produit, color, isDarkMode);
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildAlertCard(Produit produit, Color color, bool isDarkMode) {
    return Card(
      elevation: 0,
      color: isDarkMode ? Colors.grey.shade800 : color.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.inventory_2, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    produit.nom,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Catégorie: ${produit.categorie}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildAlertInfo(produit, color),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertInfo(Produit produit, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        produit.quantiteAvariee > 0
            ? '${_numberFormat.format(produit.quantiteAvariee)} unités avariées'
            : 'Stock: ${_numberFormat.format(produit.quantiteStock)} / ${_numberFormat.format(produit.seuilAlerte)}',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: Colors.green.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucune alerte à signaler',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tout va bien pour le moment',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'Une erreur est survenue',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}