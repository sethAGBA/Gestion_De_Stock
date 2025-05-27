import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../helpers/database_helper.dart';
import '../models/models.dart';
import 'package:stock_management/services/pdf_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:excel/excel.dart' as excel;
import 'dart:io';

class EntriesScreen extends StatefulWidget {
  const EntriesScreen({super.key});

  @override
  State<EntriesScreen> createState() => _EntriesScreenState();
}

class _EntriesScreenState extends State<EntriesScreen> {
  String _selectedFilter = 'all'; // 'all', 'manual', 'delivery', 'order'
  String _dateFilterMode = 'all'; // 'all', 'single', 'range'
  DateTime? _selectedDate;
  DateTimeRange? _selectedDateRange;
  final _searchController = TextEditingController();
  final _numberFormat = NumberFormat("#,##0", "fr_FR");
  String? _searchQuery;
  int _sortColumnIndex = 1; // Default sort by Product Name
  bool _sortAscending = true; // Default ascending

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

  Widget _highlightText(String text, String? query, TextStyle? baseStyle, bool isDarkMode) {
    if (query == null || query.isEmpty || text.isEmpty) {
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
              color: isDarkMode ? Colors.amber.shade200 : Colors.amber.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (afterMatch.isNotEmpty) TextSpan(text: afterMatch),
        ],
      ),
    );
  }

  void _sortEntries<T>(Comparable<T> Function(Produit) getField, int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  void _showEntriesDialog(BuildContext context, List<StockEntry> entries, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Détails des entrées de stock'),
        content: SizedBox(
          width: double.maxFinite,
          child: entries.isEmpty
              ? const Text('Aucune entrée disponible.')
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: entries.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(entry.date);
                    final entryText = 'Ajout: ${_numberFormat.format(entry.quantite)} le $formattedDate (${_getTypeLabel(entry.type)})';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entryText,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (entry.source != null && entry.source!.isNotEmpty)
                          _highlightText(
                            'Source: ${entry.source}',
                            _searchQuery,
                            Theme.of(context).textTheme.bodySmall,
                            isDarkMode,
                          ),
                        Text(
                          'Par: ${entry.utilisateur}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    );
                  },
                ),
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

  Future<void> _pickSingleDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
        _selectedDateRange = null;
        _dateFilterMode = 'single';
      });
    }
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDateRange = picked;
        _selectedDate = null;
        _dateFilterMode = 'range';
      });
    }
  }

  void _clearDateFilter() {
    setState(() {
      _selectedDate = null;
      _selectedDateRange = null;
      _dateFilterMode = 'all';
    });
  }

  Future<void> _exportToPdf() async {
    try {
      final produits = await DatabaseHelper.getProduits();
      final entries = await DatabaseHelper.getStockEntries(
        typeFilter: _selectedFilter == 'all' ? null : _selectedFilter,
        startDate: _dateFilterMode == 'single'
            ? _selectedDate
            : _dateFilterMode == 'range'
                ? _selectedDateRange?.start
                : null,
        endDate: _dateFilterMode == 'single'
            ? _selectedDate
            : _dateFilterMode == 'range'
                ? _selectedDateRange?.end
                : null,
      );
      if (produits.isEmpty || entries.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aucune donnée à exporter')),
          );
        }
        return;
      }

      // Create product map for quick lookup
      final productMap = {for (var p in produits) p.id: p};

      // Prepare items for PDF, sorted by date
      final numberFormat = NumberFormat('#,##0.00', 'fr_FR');
      final items = entries.map((entry) {
        final produit = productMap[entry.produitId]!;
        final valeurStock = entry.quantite * (produit.prixVente ?? 0.0);
        return {
          'produitId': produit.id,
          'produitNom': entry.produitNom,
          'categorie': produit.categorie ?? 'N/A',
          'unite': produit.unite ?? 'N/A',
          'quantiteInitiale': produit.quantiteInitiale,
          'quantiteStock': produit.quantiteStock,
          'quantite': entry.quantite,
          'prixUnitaire': produit.prixVente ?? 0.0,
          'valeurStock': valeurStock,
          'type': _getTypeLabel(entry.type),
          'source': entry.source ?? '',
          'date': entry.date,
          'utilisateur': entry.utilisateur,
        };
      }).toList()
        ..sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

      final totalValue = items.fold<double>(
          0.0, (sum, item) => sum + (item['valeurStock'] as double));

      // Generate PDF with date filter in title
      final dateFormat = DateFormat('dd_MM_yyyy', 'fr_FR');
      final reportTitle = _dateFilterMode == 'single'
          ? 'RPT_${dateFormat.format(_selectedDate!)}'
          : _dateFilterMode == 'range'
              ? 'RPT_${dateFormat.format(_selectedDateRange!.start)}_to_${dateFormat.format(_selectedDateRange!.end)}'
              : 'RPT${DateTime.now().millisecondsSinceEpoch}';

      final file = await PdfService.saveEntriesReport(
        numero: reportTitle,
        date: DateTime.now(),
        magasinAdresse: '',
        utilisateurNom: '',
        items: items,
        totalValue: totalValue,
      );

      if (mounted) {
        await Share.shareXFiles([XFile(file.path)], text: 'Rapport des entrées');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rapport PDF exporté : ${file.path}')),
        );
      }
    } catch (e) {
      debugPrint('PDF export error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'exportation PDF : $e')),
        );
      }
    }
  }

  Future<void> _exportToExcel() async {
    try {
      final produits = await DatabaseHelper.getProduits();
      final entries = await DatabaseHelper.getStockEntries(
        typeFilter: _selectedFilter == 'all' ? null : _selectedFilter,
        startDate: _dateFilterMode == 'single'
            ? _selectedDate
            : _dateFilterMode == 'range'
                ? _selectedDateRange?.start
                : null,
        endDate: _dateFilterMode == 'single'
            ? _selectedDate
            : _dateFilterMode == 'range'
                ? _selectedDateRange?.end
                : null,
      );
      if (produits.isEmpty || entries.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aucune donnée à exporter')),
          );
        }
        return;
      }

      // Create Excel file
      final excelFile = excel.Excel.createExcel();
      final sheet = excelFile['Entrées'];

      // Add headers
      sheet.appendRow([
        excel.TextCellValue('ID'),
        excel.TextCellValue('Nom du produit'),
        excel.TextCellValue('Catégorie'),
        excel.TextCellValue('Unité'),
        excel.TextCellValue('Stock initial'),
        excel.TextCellValue('Stock actuel'),
        excel.TextCellValue('Quantité entrée'),
        excel.TextCellValue('Prix Unitaire (FCFA)'),
        excel.TextCellValue('Valeur Stock (FCFA)'),
        excel.TextCellValue('Type'),
        excel.TextCellValue('Source'),
        excel.TextCellValue('Date'),
        excel.TextCellValue('Utilisateur'),
      ]);

      // Create product map for quick lookup
      final productMap = {for (var p in produits) p.id: p};

      // Sort entries by date
      final sortedEntries = entries
        ..sort((a, b) => a.date.compareTo(b.date));

      // Add data rows
      final numberFormat = NumberFormat('#,##0.00', 'fr_FR');
      final excelDateFormat = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');
      for (var i = 0; i < sortedEntries.length; i++) {
        final entry = sortedEntries[i];
        final produit = productMap[entry.produitId]!;
        final prixUnitaire = produit.prixVente ?? 0.0;
        final valeurStock = entry.quantite * prixUnitaire;
        sheet.appendRow([
          excel.TextCellValue((i + 1).toString()),
          excel.TextCellValue(produit.nom),
          excel.TextCellValue(produit.categorie ?? 'N/A'),
          excel.TextCellValue(produit.unite ?? 'N/A'),
          excel.TextCellValue(produit.quantiteInitiale.toString()),
          excel.TextCellValue(produit.quantiteStock.toString()),
          excel.TextCellValue(entry.quantite.toString()),
          excel.TextCellValue(numberFormat.format(prixUnitaire)),
          excel.TextCellValue(numberFormat.format(valeurStock)),
          excel.TextCellValue(_getTypeLabel(entry.type)),
          excel.TextCellValue(entry.source ?? ''),
          excel.TextCellValue(excelDateFormat.format(entry.date)),
          excel.TextCellValue(entry.utilisateur),
        ]);
      }

      // Save Excel file with date filter in filename
      final excelFileDateFormat = DateFormat('yyyyMMdd', 'fr_FR');
      final fileName = _dateFilterMode == 'single'
          ? 'entrees_${excelFileDateFormat.format(_selectedDate!)}'
          : _dateFilterMode == 'range'
              ? 'entrees_${excelFileDateFormat.format(_selectedDateRange!.start)}_to_${excelFileDateFormat.format(_selectedDateRange!.end)}'
              : 'entrees_${DateTime.now().millisecondsSinceEpoch}';
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName.xlsx';
      final fileBytes = excelFile.encode();
      final file = File(filePath);
      await file.writeAsBytes(fileBytes!);

      if (mounted) {
        await Share.shareXFiles([XFile(file.path)], text: 'Rapport des entrées Excel');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rapport Excel exporté : $filePath')),
        );
      }
    } catch (e) {
      debugPrint('Excel export error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'exportation Excel : $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrées de stock'),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Exporter en PDF',
            onPressed: _exportToPdf,
          ),
          IconButton(
            icon: const Icon(Icons.table_chart),
            tooltip: 'Exporter en Excel',
            onPressed: _exportToExcel,
          ),
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
            _buildFilters(theme, isDarkMode),
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
            color: Colors.black.withOpacity(0.1),
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
                color: Theme.of(context).primaryColor,
                size: 32,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Entrées de stock',
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gestion des entrées (manuelles, livraisons, commandes)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
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
              hintText: 'Rechercher par produit ou source...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(ThemeData theme, bool isDarkMode) {
    final dateFormat = DateFormat('dd/MM/yyyy', 'fr_FR');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(theme, 'Tout', 'all', isDarkMode),
            const SizedBox(width: 8),
            _buildFilterChip(theme, 'Manuelles', 'manual', isDarkMode),
            const SizedBox(width: 8),
            _buildFilterChip(theme, 'Livraisons', 'delivery', isDarkMode),
            const SizedBox(width: 8),
            _buildFilterChip(theme, 'Commandes', 'order', isDarkMode),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: () => _pickSingleDate(context),
              icon: const Icon(Icons.calendar_today, size: 20),
              label: const Text('Choisir une date'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _pickDateRange(context),
              icon: const Icon(Icons.date_range, size: 20),
              label: const Text('Choisir une période'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(width: 8),
            if (_dateFilterMode != 'all')
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Chip(
                  label: Text(
                    _dateFilterMode == 'single'
                        ? dateFormat.format(_selectedDate!)
                        : '${dateFormat.format(_selectedDateRange!.start)} - ${dateFormat.format(_selectedDateRange!.end)}',
                  ),
                  deleteIcon: const Icon(Icons.clear, size: 18),
                  onDeleted: _clearDateFilter,
                  backgroundColor: theme.primaryColor.withOpacity(0.3),
                  labelStyle: TextStyle(color: theme.primaryColor),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(ThemeData theme, String label, String value, bool isDarkMode) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = selected ? value : 'all';
        });
      },
      backgroundColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
      selectedColor: theme.primaryColor.withOpacity(0.3),
      checkmarkColor: theme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected
            ? theme.primaryColor
            : isDarkMode
                ? Colors.white
                : Colors.black87,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? theme.primaryColor : Colors.transparent,
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
          Icon(Icons.arrow_upward, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Aucune entrée enregistrée',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez une entrée avec le bouton +',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildEntriesList(bool isDarkMode) {
    return FutureBuilder<List<Produit>>(
      future: DatabaseHelper.getProduits(),
      builder: (context, produitSnapshot) {
        if (produitSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (produitSnapshot.hasError) {
          debugPrint('Produits list error: ${produitSnapshot.error}');
          return Center(child: Text('Erreur : ${produitSnapshot.error}', style: const TextStyle(color: Colors.red)));
        }
        final produits = produitSnapshot.data ?? [];
        if (produits.isEmpty) {
          return _buildEmptyState();
        }

        return FutureBuilder<List<StockEntry>>(
          future: DatabaseHelper.getStockEntries(
            typeFilter: _selectedFilter == 'all' ? null : _selectedFilter,
            startDate: _dateFilterMode == 'single'
                ? _selectedDate
                : _dateFilterMode == 'range'
                    ? _selectedDateRange?.start
                    : null,
            endDate: _dateFilterMode == 'single'
                ? _selectedDate
                : _dateFilterMode == 'range'
                    ? _selectedDateRange?.end
                    : null,
          ),
          builder: (context, entrySnapshot) {
            if (entrySnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (entrySnapshot.hasError) {
              debugPrint('Entries list error: ${entrySnapshot.error}');
              return Center(child: Text('Erreur : ${entrySnapshot.error}', style: const TextStyle(color: Colors.red)));
            }
            final entries = entrySnapshot.data ?? [];

            // Group entries by produitId
            final entryMap = <int, List<StockEntry>>{};
            for (var entry in entries) {
              entryMap.putIfAbsent(entry.produitId, () => []).add(entry);
            }

            // Filter products based on search and entries
            final filteredProduits = produits.where((produit) {
              final searchTerm = (_searchQuery ?? '').toLowerCase();
              final productMatch = produit.nom.toLowerCase().contains(searchTerm);
              final entriesForProduct = entryMap[produit.id] ?? [];
              final sourceMatch = entriesForProduct.any((entry) =>
                  entry.source != null && entry.source!.toLowerCase().contains(searchTerm));
              final hasMatchingEntries = _selectedFilter == 'all' || entriesForProduct.isNotEmpty;
              return hasMatchingEntries && (productMatch || sourceMatch);
            }).toList();

            // Sort products
            filteredProduits.sort((a, b) {
              final Comparable<dynamic> aValue;
              final Comparable<dynamic> bValue;
              switch (_sortColumnIndex) {
                case 1: // Product Name
                  aValue = a.nom;
                  bValue = b.nom;
                  break;
                case 2: // Category
                  aValue = a.categorie ?? '';
                  bValue = b.categorie ?? '';
                  break;
                case 3: // Unit
                  aValue = a.unite ?? '';
                  bValue = b.unite ?? '';
                  break;
                case 4: // Initial Stock
                  aValue = a.quantiteInitiale;
                  bValue = b.quantiteInitiale;
                  break;
                case 5: // Current Stock
                  aValue = a.quantiteStock;
                  bValue = b.quantiteStock;
                  break;
                default: // ID
                  aValue = produits.indexOf(a);
                  bValue = produits.indexOf(b);
              }
              return _sortAscending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
            });

            if (filteredProduits.isEmpty) {
              return _buildEmptyState();
            }

            return SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 1000),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Produits avec entrées (${filteredProduits.length})',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        DataTable(
                          sortColumnIndex: _sortColumnIndex,
                          sortAscending: _sortAscending,
                          columnSpacing: 16,
                          headingRowHeight: 56,
                          dataRowMinHeight: 52,
                          dataRowMaxHeight: 52,
                          dividerThickness: 1,
                          border: TableBorder(
                            horizontalInside: BorderSide(
                              color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade200,
                              width: 1,
                            ),
                            verticalInside: BorderSide(
                              color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade200,
                              width: 1,
                            ),
                            top: BorderSide(
                              color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade200,
                              width: 1,
                            ),
                            bottom: BorderSide(
                              color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade200,
                              width: 1,
                            ),
                            left: BorderSide(
                              color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade200,
                              width: 1,
                            ),
                            right: BorderSide(
                              color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                          headingTextStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                          dataTextStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: isDarkMode ? Colors.white70 : Colors.black87,
                              ),
                          headingRowColor: MaterialStateProperty.resolveWith<Color>(
                            (states) => isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                          ),
                          columns: [
                            const DataColumn(
                              label: SizedBox(
                                width: 60,
                                child: Text('ID', textAlign: TextAlign.center),
                              ),
                            ),
                            const DataColumn(
                              label: SizedBox(
                                width: 200,
                                child: Text('Nom du produit'),
                              ),
                            ),
                            const DataColumn(
                              label: SizedBox(
                                width: 150,
                                child: Text('Catégorie'),
                              ),
                            ),
                            const DataColumn(
                              label: SizedBox(
                                width: 100,
                                child: Text('Unité'),
                              ),
                            ),
                            const DataColumn(
                              label: SizedBox(
                                width: 120,
                                child: Text('Stock initial', textAlign: TextAlign.right),
                              ),
                            ),
                            const DataColumn(
                              label: SizedBox(
                                width: 120,
                                child: Text('Stock actuel', textAlign: TextAlign.right),
                              ),
                            ),
                            const DataColumn(
                              label: SizedBox(
                                width: 200,
                                child: Text('Entrées de stock'),
                              ),
                            ),
                          ],
                          rows: filteredProduits.asMap().entries.map((entry) {
                            final index = entry.key;
                            final produit = entry.value;
                            final entriesForProduct = entryMap[produit.id] ?? [];
                            return DataRow(
                              color: MaterialStateProperty.resolveWith<Color>(
                                (states) {
                                  if (states.contains(MaterialState.hovered)) {
                                    return isDarkMode
                                        ? Colors.grey.shade700
                                        : Colors.grey.shade100;
                                  }
                                  return index % 2 == 0
                                      ? (isDarkMode ? Colors.grey.shade900 : Colors.white)
                                      : (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50);
                                },
                              ),
                              cells: [
                                DataCell(
                                  SizedBox(
                                    width: 60,
                                    child: Text(
                                      (index + 1).toString(),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 200,
                                    child: _highlightText(
                                      produit.nom,
                                      _searchQuery,
                                      Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                      isDarkMode,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 150,
                                    child: Text(produit.categorie ?? 'N/A'),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 100,
                                    child: Text(produit.unite ?? 'N/A'),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 120,
                                    child: Text(
                                      _numberFormat.format(produit.quantiteInitiale),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 120,
                                    child: Text(
                                      _numberFormat.format(produit.quantiteStock),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 200,
                                    child: GestureDetector(
                                      onTap: () => _showEntriesDialog(context, entriesForProduct, isDarkMode),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.history,
                                            size: 20,
                                            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            entriesForProduct.isEmpty
                                                ? 'Aucune entrée'
                                                : '${entriesForProduct.length} entrée${entriesForProduct.length > 1 ? 's' : ''}',
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  color: Theme.of(context).primaryColor,
                                                  decoration: TextDecoration.underline,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
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
    final productSearchController = TextEditingController();
    String productSearchQuery = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nouvelle entrée de stock'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: productSearchController,
                  decoration: InputDecoration(
                    labelText: 'Rechercher un produit',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: productSearchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setDialogState(() {
                                productSearchController.clear();
                                productSearchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade800
                        : Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                  onChanged: (value) {
                    setDialogState(() {
                      productSearchQuery = value.trim();
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Produit>(
                  decoration: InputDecoration(
                    labelText: 'Produit',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade800
                        : Colors.grey.shade100,
                  ),
                  value: selectedProduit,
                  items: produits
                      .where((produit) =>
                          productSearchQuery.isEmpty ||
                          produit.nom.toLowerCase().contains(productSearchQuery.toLowerCase()))
                      .map((produit) {
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
                  isExpanded: true,
                  hint: const Text('Sélectionnez un produit'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Type d\'entrée',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade800
                        : Colors.grey.shade100,
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
                  decoration: InputDecoration(
                    labelText: 'Quantité',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade800
                        : Colors.grey.shade100,
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
                  decoration: InputDecoration(
                    labelText: 'Source (optionnel)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade800
                        : Colors.grey.shade100,
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
                          produitId: selectedProduit!.id,
                          produitNom: selectedProduit!.nom,
                          quantite: quantite!,
                          type: selectedType!,
                          source: source.isEmpty ? null : source,
                          date: DateTime.now(),
                          utilisateur: 'Admin',
                        );
                        await DatabaseHelper.addStockEntry(entry);
                        if (context.mounted) {
                          Navigator.pop(context);
                          setState(() {});
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
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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