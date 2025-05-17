import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:stock_management/providers/auth_provider.dart';
import '../helpers/database_helper.dart';
import '../models/models.dart';

class ExitsScreen extends StatefulWidget {
  const ExitsScreen({Key? key}) : super(key: key);

  @override
  _ExitsScreenState createState() => _ExitsScreenState();
}

class _ExitsScreenState extends State<ExitsScreen> {
  String _selectedFilter = 'all'; // 'all', 'sale', 'internal', 'return', 'other'
  final _searchController = TextEditingController();
  final _numberFormat = NumberFormat("#,##0", "fr_FR");

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Produit>> _getProduits() async {
    return await DatabaseHelper.getProduits();
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
            child: _buildExitsList(isDarkMode),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddExitDialog(context),
        child: const Icon(Icons.add),
        tooltip: 'Ajouter une sortie',
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
                Icons.arrow_downward,
                color: Theme.of(context).primaryColor,
                size: 32,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sorties de stock',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gestion des sorties (ventes, retours, usage interne)',
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
              hintText: 'Rechercher dans les sorties...',
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterChip('Tout', 'all'),
            const SizedBox(width: 8),
            _filterChip('Ventes', 'sale'),
            const SizedBox(width: 8),
            _filterChip('Retours', 'return'),
            const SizedBox(width: 8),
            _filterChip('Usage interne', 'internal'),
            const SizedBox(width: 8),
            _filterChip('Autres', 'other'),
          ],
        ),
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

  Widget _buildExitsList(bool isDarkMode) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper.getAllExits(typeFilter: _selectedFilter == 'all' ? null : _selectedFilter),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erreur : ${snapshot.error}'));
        }
        final exits = snapshot.data ?? [];
        if (exits.isEmpty) {
          return _buildEmptyState();
        }

        final filteredExits = exits.where((exit) {
          final searchTerm = _searchController.text.toLowerCase();
          return (exit['produitNom'] as String).toLowerCase().contains(searchTerm) ||
              (exit['raison'] as String?)?.toLowerCase().contains(searchTerm) == true;
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Historique des sorties (${filteredExits.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredExits.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final exit = filteredExits[index];
                  return _buildExitCard(exit, isDarkMode);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExitCard(Map<String, dynamic> exit, bool isDarkMode) {
    final type = exit['type'] as String;
    final color = type == 'sale'
        ? Colors.green
        : type == 'return'
            ? Colors.red
            : type == 'internal'
                ? Colors.blue
                : Colors.grey;
    final date = DateTime.fromMillisecondsSinceEpoch(exit['date'] as int);
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(date);

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
              child: Icon(
                type == 'sale'
                    ? Icons.shopping_cart
                    : type == 'return'
                        ? Icons.undo
                        : Icons.arrow_downward,
                color: color,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exit['produitNom'] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Type: ${_getTypeLabel(type)}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Quantité: ${_numberFormat.format(exit['quantite'])}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Date: $formattedDate',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  if (exit['raison'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Raison: ${exit['raison']}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    'Par: ${exit['utilisateur']}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'sale':
        return 'Vente';
      case 'return':
        return 'Retour client';
      case 'internal':
        return 'Usage interne';
      case 'other':
        return 'Autre';
      default:
        return type;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.arrow_downward,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucune sortie enregistrée',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez une sortie avec le bouton +',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddExitDialog(BuildContext context) async {
    final produits = await _getProduits();
    if (produits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun produit disponible')),
      );
      return;
    }

    Produit? selectedProduit;
    String? selectedType;
    int quantite = 1;
    String raison = '';
    final types = ['internal', 'return', 'other'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nouvelle sortie de stock'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<Produit>(
                  decoration: const InputDecoration(labelText: 'Produit'),
                  items: produits.map((produit) {
                    return DropdownMenuItem(
                      value: produit,
                      child: Text('${produit.nom} (Stock: ${produit.quantiteStock})'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedProduit = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Type de sortie'),
                  items: types.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(_getTypeLabel(type)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedType = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Quantité'),
                  keyboardType: TextInputType.number,
                  initialValue: '1',
                  onChanged: (value) {
                    setDialogState(() {
                      quantite = int.tryParse(value) ?? 1;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Raison (optionnel)'),
                  onChanged: (value) {
                    setDialogState(() {
                      raison = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: selectedProduit == null || selectedType == null || quantite <= 0
                  ? null
                  : () async {
                      try {
                        final exit = StockExit(
                          produitId: selectedProduit!.id!,
                          produitNom: selectedProduit!.nom,
                          quantite: quantite,
                          type: selectedType!,
                          raison: raison.isEmpty ? null : raison,
                          date: DateTime.now(),
                          utilisateur: Provider.of<AuthProvider>(context, listen: false).currentUser?.name ?? 'Inconnu', // Replace with actual user
                        );
                        await DatabaseHelper.addStockExit(exit);
                        Navigator.pop(context);
                        setState(() {}); // Refresh list
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Sortie ajoutée avec succès')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erreur : $e')),
                        );
                      }
                    },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }
}