import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/models.dart';

class ProductsTableWidget extends StatefulWidget {
  final List<Produit> produits;

  const ProductsTableWidget({Key? key, required this.produits}) : super(key: key);

  @override
  _ProductsTableWidgetState createState() => _ProductsTableWidgetState();
}

class _ProductsTableWidgetState extends State<ProductsTableWidget> {
  String _searchQuery = '';
  List<Produit> _filteredProduits = [];

  @override
  void initState() {
    super.initState();
    _filteredProduits = widget.produits;
  }

  void _filterProduits(String query) {
    setState(() {
      _searchQuery = query.trim();
      if (_searchQuery.isEmpty) {
        _filteredProduits = widget.produits;
      } else {
        _filteredProduits = widget.produits.where((produit) {
          final lowerQuery = _searchQuery.toLowerCase();
          return (produit.nom?.toLowerCase()?.contains(lowerQuery) ?? false) ||
              (produit.categorie?.toLowerCase()?.contains(lowerQuery) ?? false) ||
              (produit.fournisseurPrincipal?.toLowerCase()?.contains(lowerQuery) ?? false) ||
              (produit.statut?.toLowerCase()?.contains(lowerQuery) ?? false) ||
              (lowerQuery.contains('avarié') && produit.quantiteAvariee > 0);
        }).toList();
      }
    });
  }

  Color _getStockColor(Produit produit) {
    if (produit.quantiteAvariee > 0) {
      return Colors.red.withOpacity(0.1); // Mise en évidence des produits avariés
    } else if (produit.quantiteStock <= produit.stockMin) {
      return Colors.red.withOpacity(0.05);
    } else if (produit.quantiteStock <= produit.seuilAlerte) {
      return Colors.orange.withOpacity(0.05);
    }
    return Colors.transparent;
  }

  String _getDisplayStatus(Produit produit) {
    if (produit.quantiteAvariee > 0) {
      return 'Contient avariés';
    } else if (produit.quantiteStock <= produit.seuilAlerte) {
      return 'Bientôt en rupture';
    }
    return produit.statut ?? 'N/A';
  }

  Widget _highlightText(String text, String query, TextStyle? baseStyle, bool isDarkMode) {
    if (query.isEmpty || text.isEmpty) {
      return Text(text, style: baseStyle);
    }
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final matches = lowerText.indexOf(lowerQuery);
    if (matches == -1) {
      return Text(text, style: baseStyle);
    }

    final beforeMatch = text.substring(0, matches);
    final matchText = text.substring(matches, matches + query.length);
    final afterMatch = text.substring(matches + query.length);

    return RichText(
      text: TextSpan(
        style: baseStyle,
        children: [
          if (beforeMatch.isNotEmpty) TextSpan(text: beforeMatch),
          TextSpan(
            text: matchText,
            style: TextStyle(
              color: isDarkMode ? Colors.blue.shade200 : Colors.blue.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (afterMatch.isNotEmpty) TextSpan(text: afterMatch),
        ],
      ),
    );
  }

  void _showEnlargedImage(BuildContext context, String? imageUrl) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(16),
          constraints: const BoxConstraints(maxWidth: 300, maxHeight: 350),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: imageUrl != null && File(imageUrl).existsSync()
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Produits',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.grey.shade900,
                ),
              ),
              SizedBox(
                width: 300,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Rechercher un produit (inclut "avarié")',
                    prefixIcon: Icon(Icons.search, color: isDarkMode ? Colors.white : Colors.grey.shade600),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade100,
                  ),
                  onChanged: _filterProduits,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          widget.produits.isEmpty
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
              : _filteredProduits.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun produit trouvé pour cette recherche',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: DataTable(
                          columnSpacing: 48.0,
                          horizontalMargin: 32.0,
                          dividerThickness: 0.5,
                          headingRowHeight: 48,
                          dataRowHeight: 48,
                          headingTextStyle: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                          ),
                          dataTextStyle: theme.textTheme.bodyMedium,
                          headingRowColor: MaterialStateProperty.resolveWith<Color>(
                            (states) => isDarkMode ? Colors.grey.shade700 : Colors.grey.shade100,
                          ),
                          columns: const [
                            DataColumn(label: Text('ID')),
                            DataColumn(label: Text('Image')),
                            DataColumn(label: Text('Nom')),
                            DataColumn(label: Text('Catégorie')),
                            DataColumn(label: Text('Stock')),
                            DataColumn(label: Text('Avarié')),
                            DataColumn(label: Text('Prix Vente')),
                            DataColumn(label: Text('Fournisseur')),
                            DataColumn(label: Text('Statut')),
                          ],
                          rows: _filteredProduits
                              .asMap()
                              .entries
                              .map(
                                (entry) {
                                  final int index = entry.key;
                                  final Produit produit = entry.value;
                                  final String displayStatus = _getDisplayStatus(produit);
                                  return DataRow(
                                    color: MaterialStateProperty.resolveWith<Color>(
                                      (states) => _getStockColor(produit),
                                    ),
                                    cells: [
                                      DataCell(
                                        Text(
                                          (index + 1).toString(),
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                      ),
                                      DataCell(
                                        GestureDetector(
                                          onTap: () => _showEnlargedImage(context, produit.imageUrl),
                                          child: produit.imageUrl != null && File(produit.imageUrl!).existsSync()
                                              ? Image.file(
                                                  File(produit.imageUrl!),
                                                  width: 40,
                                                  height: 40,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) => const Icon(
                                                    Icons.image_not_supported,
                                                    size: 40,
                                                    color: Colors.grey,
                                                  ),
                                                )
                                              : const Icon(
                                                  Icons.image_not_supported,
                                                  size: 40,
                                                  color: Colors.grey,
                                                ),
                                        ),
                                      ),
                                      DataCell(
                                        _highlightText(
                                          produit.nom ?? 'N/A',
                                          _searchQuery,
                                          theme.textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                          isDarkMode,
                                        ),
                                      ),
                                      DataCell(
                                        _highlightText(
                                          produit.categorie ?? 'N/A',
                                          _searchQuery,
                                          theme.textTheme.bodyMedium?.copyWith(
                                            color: isDarkMode ? Colors.blue.shade200 : Colors.blue.shade700,
                                          ),
                                          isDarkMode,
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          '${produit.quantiteStock}${produit.unite == 'kg' ? ' kg' : ''}',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: produit.quantiteStock <= produit.stockMin
                                                ? Colors.red.shade500
                                                : produit.quantiteStock <= produit.seuilAlerte
                                                    ? Colors.orange.shade500
                                                    : null,
                                            fontWeight: produit.quantiteStock <= produit.seuilAlerte
                                                ? FontWeight.w600
                                                : null,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          '${produit.quantiteAvariee}${produit.unite == 'kg' ? ' kg' : ''}',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: produit.quantiteAvariee > 0 ? Colors.red.shade500 : null,
                                            fontWeight: produit.quantiteAvariee > 0 ? FontWeight.w600 : null,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          produit.prixVente.toStringAsFixed(2),
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: isDarkMode ? Colors.green.shade300 : Colors.green.shade700,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        _highlightText(
                                          produit.fournisseurPrincipal ?? 'N/A',
                                          _searchQuery,
                                          theme.textTheme.bodyMedium,
                                          isDarkMode,
                                        ),
                                      ),
                                      DataCell(
                                        Chip(
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          visualDensity: VisualDensity.compact,
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                          label: _highlightText(
                                            displayStatus,
                                            _searchQuery,
                                            theme.textTheme.labelSmall?.copyWith(
                                              color: displayStatus == 'disponible'
                                                  ? isDarkMode
                                                      ? Colors.green.shade200
                                                      : Colors.green.shade800
                                                  : displayStatus == 'Bientôt en rupture'
                                                      ? isDarkMode
                                                          ? Colors.orange.shade200
                                                          : Colors.orange.shade800
                                                      : displayStatus == 'Contient avariés'
                                                          ? isDarkMode
                                                              ? Colors.red.shade200
                                                              : Colors.red.shade800
                                                          : isDarkMode
                                                              ? Colors.red.shade200
                                                              : Colors.red.shade800,
                                            ),
                                            isDarkMode,
                                          ),
                                          backgroundColor: displayStatus == 'disponible'
                                              ? isDarkMode
                                                  ? Colors.green.shade900.withOpacity(0.3)
                                                  : Colors.green.shade100
                                              : displayStatus == 'Bientôt en rupture'
                                                  ? isDarkMode
                                                      ? Colors.orange.shade900.withOpacity(0.3)
                                                      : Colors.orange.shade100
                                                  : isDarkMode
                                                      ? Colors.red.shade900.withOpacity(0.3)
                                                      : Colors.red.shade100,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              )
                              .toList(),
                        ),
                      ),
                    ),
        ],
      ),
    );
  }
}