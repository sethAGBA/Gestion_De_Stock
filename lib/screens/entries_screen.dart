import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:stock_management/providers/auth_provider.dart';
import '../helpers/database_helper.dart';
import '../models/models.dart';

class EntriesScreen extends StatefulWidget {
  const EntriesScreen({super.key});

  @override
  State<EntriesScreen> createState() => _EntriesScreenState();
}

class _EntriesScreenState extends State<EntriesScreen> {
  String _selectedFilter = 'all'; // 'all', 'manual', 'delivery', 'order'
  final _searchController = TextEditingController();
  final _numberFormat = NumberFormat("#,##0", "fr_FR");
  String? _searchQuery;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _searchQuery = _searchController.text;
          });
        }
      });
    });
    debugPrint('EntriesScreen initialized');
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrées de stock'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Ajouter une entrée',
            onPressed: () => _showAddEntryDialog(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          children: [
            _buildHeader(theme, isDarkMode),
            _buildFilters(theme),
            Expanded(child: _buildEntriesList(isDarkMode)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          debugPrint('FAB pressed');
          _showAddEntryDialog(context);
        },
        backgroundColor: theme.primaryColor,
        elevation: 6,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Ajouter une entrée',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
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
                Icons.arrow_upward,
                color: theme.primaryColor,
                size: 32,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Entrées de stock',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gestion des entrées (manuelles, livraisons, commandes)',
                    style: TextStyle(color: theme.textTheme.bodySmall?.color?.withOpacity(0.6), fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher par produit ou source...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(theme, 'Tout', 'all'),
            const SizedBox(width: 8),
            _buildFilterChip(theme, 'Manuelles', 'manual'),
            const SizedBox(width: 8),
            _buildFilterChip(theme, 'Livraisons', 'delivery'),
            const SizedBox(width: 8),
            _buildFilterChip(theme, 'Commandes', 'order'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(ThemeData theme, String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = selected ? value : 'all';
        });
      },
      backgroundColor: isSelected ? theme.primaryColor.withOpacity(0.1) : null,
      selectedColor: theme.primaryColor.withOpacity(0.2),
      checkmarkColor: theme.primaryColor,
    );
  }

  Widget _buildEntriesList(bool isDarkMode) {
    return FutureBuilder<List<StockEntry>>(
      future: DatabaseHelper.getStockEntries(typeFilter: _selectedFilter == 'all' ? null : _selectedFilter),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          debugPrint('Entries list error: ${snapshot.error}');
          return Center(child: Text('Erreur : ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        }
        final entries = snapshot.data ?? [];
        if (entries.isEmpty) {
          return _buildEmptyState();
        }

        final filteredEntries = entries.where((entry) {
          final searchTerm = (_searchQuery ?? '').toLowerCase();
          return entry.produitNom.toLowerCase().contains(searchTerm) ||
              (entry.source?.toLowerCase().contains(searchTerm) ?? false);
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Historique des entrées (${filteredEntries.length})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredEntries.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  return _buildEntryCard(filteredEntries[index], isDarkMode);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEntryCard(StockEntry entry, bool isDarkMode) {
    final typeColors = {
      'manual': Colors.blue,
      'delivery': Colors.green,
      'order': Colors.orange,
    };
    final typeIcons = {
      'manual': Icons.edit,
      'delivery': Icons.local_shipping,
      'order': Icons.receipt,
    };
    final color = typeColors[entry.type] ?? Colors.grey;
    final icon = typeIcons[entry.type] ?? Icons.help;
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(entry.dateTime);

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
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.produitNom,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Type: ${_getTypeLabel(entry.type)}',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Quantité: ${_numberFormat.format(entry.quantite)}',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Date: $formattedDate',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  if (entry.source != null && entry.source!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Source: ${entry.source}',
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    'Par: ${entry.utilisateur}',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
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
    return switch (type) {
      'manual' => 'Manuelle',
      'delivery' => 'Livraison',
      'order' => 'Commande',
      _ => type,
    };
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.arrow_upward, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'Aucune entrée enregistrée',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez une entrée avec le bouton +',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddEntryDialog(BuildContext context) async {
    debugPrint('Opening add entry dialog');
    final produits = await DatabaseHelper.getProduits();
    if (produits.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucun produit disponible')),
        );
      }
      return;
    }

    Produit? selectedProduit;
    String? selectedType;
    int? quantite;
    String source = '';
    bool isValid = false;
    final types = ['manual', 'delivery', 'order'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nouvelle entrée de stock'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<Produit>(
                  decoration: const InputDecoration(
                    labelText: 'Produit',
                    border: OutlineInputBorder(),
                  ),
                  items: produits.map((produit) {
                    return DropdownMenuItem(
                      value: produit,
                      child: Text('${produit.nom} (Stock: ${produit.quantiteStock})'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedProduit = value;
                      isValid = _validateForm(selectedProduit, selectedType, quantite);
                    });
                  },
                  validator: (value) => value == null ? 'Sélectionnez un produit' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Type d\'entrée',
                    border: OutlineInputBorder(),
                  ),
                  items: types.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(_getTypeLabel(type)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedType = value;
                      isValid = _validateForm(selectedProduit, selectedType, quantite);
                    });
                  },
                  validator: (value) => value == null ? 'Sélectionnez un type' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Quantité',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  initialValue: '1',
                  onChanged: (value) {
                    setDialogState(() {
                      quantite = int.tryParse(value);
                      isValid = _validateForm(selectedProduit, selectedType, quantite);
                    });
                  },
                  validator: (value) {
                    final num = int.tryParse(value ?? '');
                    if (num == null || num <= 0) {
                      return 'Entrez une quantité positive';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Source (optionnel)',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setDialogState(() {
                      source = value.trim();
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
              onPressed: isValid
                  ? () async {
                      try {
                        final entry = StockEntry(
  produitId: selectedProduit!.id!,
  produitNom: selectedProduit!.nom,
  quantite: quantite!,
  type: selectedType!,
  source: source.isEmpty ? null : source,
  date: DateTime.now().microsecondsSinceEpoch,  // Utilise un objet DateTime
  utilisateur: Provider.of<AuthProvider>(context, listen: false).currentUser?.name ?? 'Inconnu',
);
                        await DatabaseHelper.addStockEntry(entry);
                        if (context.mounted) {
                          Navigator.pop(context);
                          setState(() {}); // Refresh list
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Entrée ajoutée avec succès')),
                          );
                        }
                      } catch (e) {
                        debugPrint('Error adding entry: $e');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erreur : $e')),
                          );
                        }
                      }
                    }
                  : null,
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  bool _validateForm(Produit? produit, String? type, int? quantite) {
    return produit != null && type != null && quantite != null && quantite > 0;
  }
}