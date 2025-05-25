import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:excel/excel.dart' as excel;
import 'package:stock_management/helpers/database_helper.dart';
import 'package:stock_management/models/models.dart';
import 'package:stock_management/providers/auth_provider.dart';
import 'package:stock_management/services/pdf_service.dart';
import 'dart:io';

class ExitsScreen extends StatefulWidget {
  const ExitsScreen({super.key});

  @override
  State<ExitsScreen> createState() => _ExitsScreenState();
}

class _ExitsScreenState extends State<ExitsScreen> {
  static const _filters = {
    'all': 'Tout',
    'sale': 'Ventes',
    'return': 'Retours',
    'internal': 'Usage interne',
    'other': 'Autres',
  };

  static const _typeIcons = {
    'sale': Icons.shopping_cart,
    'return': Icons.undo,
    'internal': Icons.arrow_downward,
    'other': Icons.arrow_downward,
  };

  static const _typeColors = {
    'sale': Colors.green,
    'return': Colors.red,
    'internal': Colors.blue,
    'other': Colors.grey,
  };

  final _searchController = TextEditingController();
  final _numberFormat = NumberFormat("#,##0", "fr_FR");
  String _selectedFilter = 'all';
  String _dateFilterMode = 'all';
  DateTime? _selectedDate;
  DateTimeRange? _selectedDateRange;
  String? _searchQuery;
  int _sortColumnIndex = 1; // Default sort by Product Name
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _searchQuery = _searchController.text.trim();
          });
        }
      });
    });
    debugPrint('ExitsScreen initialized');
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

  void _sortExits<T>(Comparable<T> Function(Produit) getField, int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  void _showExitsDialog(BuildContext context, List<Map<String, dynamic>> exits, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails des sorties de stock', style: GoogleFonts.roboto()),
        content: SizedBox(
          width: double.maxFinite,
          child: exits.isEmpty
              ? const Text('Aucune sortie disponible.')
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: exits.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final exit = exits[index];
                    final date = DateTime.fromMillisecondsSinceEpoch(exit['date'] as int);
                    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(date);
                    final exitText = 'Sortie: ${_numberFormat.format(exit['quantite'])} le $formattedDate (${_getTypeLabel(exit['type'])})';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exitText,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (exit['raison'] != null && (exit['raison'] as String).isNotEmpty)
                          _highlightText(
                            'Raison: ${exit['raison']}',
                            _searchQuery,
                            Theme.of(context).textTheme.bodySmall,
                            isDarkMode,
                          ),
                        Text(
                          'Par: ${exit['utilisateur']}',
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
            child: Text('Fermer', style: GoogleFonts.roboto()),
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
      final exits = await DatabaseHelper.getAllExits(
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
      if (produits.isEmpty || exits.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aucune donnée à exporter')),
          );
        }
        return;
      }

      final productMap = {for (var p in produits) p.id: p};
      final numberFormat = NumberFormat('#,##0.00', 'fr_FR');
      final items = exits.map((exit) {
        final produit = productMap[exit['produitId']]!;
        final valeurStock = (exit['quantite'] as int) * (produit.prixVente ?? 0.0);
        return {
          'produitId': exit['produitId'],
          'produitNom': exit['produitNom'],
          'categorie': produit.categorie ?? 'N/A',
          'unite': produit.unite ?? 'N/A',
          'quantiteInitiale': produit.quantiteInitiale,
          'quantiteStock': produit.quantiteStock,
          'quantite': exit['quantite'],
          'prixUnitaire': produit.prixVente ?? 0.0,
          'valeurStock': valeurStock,
          'type': _getTypeLabel(exit['type']),
          'raison': exit['raison'] ?? '',
          'date': DateTime.fromMillisecondsSinceEpoch(exit['date'] as int),
          'utilisateur': exit['utilisateur'],
        };
      }).toList()
        ..sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

      final totalValue = items.fold<double>(
          0.0, (sum, item) => sum + (item['valeurStock'] as double));

      final dateFormat = DateFormat('dd_MM_yyyy', 'fr_FR');
      final reportTitle = _dateFilterMode == 'single'
          ? 'RPT_SORTIES_${dateFormat.format(_selectedDate!)}'
          : _dateFilterMode == 'range'
              ? 'RPT_SORTIES_${dateFormat.format(_selectedDateRange!.start)}_to_${dateFormat.format(_selectedDateRange!.end)}'
              : 'RPT_SORTIES_${DateTime.now().millisecondsSinceEpoch}';

      final file = await PdfService.saveExitsReport(
        numero: reportTitle,
        date: DateTime.now(),
        magasinAdresse: '123 Rue Principale, Ville',
        utilisateurNom: Provider.of<AuthProvider>(context, listen: false).currentUser?.name ?? 'Admin',
        items: items,
        totalValue: totalValue,
      );

      if (mounted) {
        await Share.shareXFiles([XFile(file.path)], text: 'Rapport des sorties');
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
      final exits = await DatabaseHelper.getAllExits(
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
      if (produits.isEmpty || exits.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aucune donnée à exporter')),
          );
        }
        return;
      }

      final excelFile = excel.Excel.createExcel();
      final sheet = excelFile['Sorties'];

      sheet.appendRow([
        excel.TextCellValue('ID'),
        excel.TextCellValue('Nom du produit'),
        excel.TextCellValue('Catégorie'),
        excel.TextCellValue('Unité'),
        excel.TextCellValue('Stock initial'),
        excel.TextCellValue('Stock actuel'),
        excel.TextCellValue('Quantité sortie'),
        excel.TextCellValue('Prix Unitaire (FCFA)'),
        excel.TextCellValue('Valeur Stock (FCFA)'),
        excel.TextCellValue('Type'),
        excel.TextCellValue('Raison'),
        excel.TextCellValue('Date'),
        excel.TextCellValue('Utilisateur'),
      ]);

      final productMap = {for (var p in produits) p.id: p};
      final numberFormat = NumberFormat('#,##0.00', 'fr_FR');
      final excelDateFormat = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');
      for (var i = 0; i < exits.length; i++) {
        final exit = exits[i];
        final produit = productMap[exit['produitId']]!;
        final prixUnitaire = produit.prixVente ?? 0.0;
        final valeurStock = (exit['quantite'] as int) * prixUnitaire;
        final date = DateTime.fromMillisecondsSinceEpoch(exit['date'] as int);
        sheet.appendRow([
          excel.TextCellValue((i + 1).toString()),
          excel.TextCellValue(exit['produitNom'] as String),
          excel.TextCellValue(produit.categorie ?? 'N/A'),
          excel.TextCellValue(produit.unite ?? 'N/A'),
          excel.TextCellValue(produit.quantiteInitiale.toString()),
          excel.TextCellValue(produit.quantiteStock.toString()),
          excel.TextCellValue((exit['quantite'] as int).toString()),
          excel.TextCellValue(numberFormat.format(prixUnitaire)),
          excel.TextCellValue(numberFormat.format(valeurStock)),
          excel.TextCellValue(_getTypeLabel(exit['type'] as String)),
          excel.TextCellValue(exit['raison'] as String? ?? ''),
          excel.TextCellValue(excelDateFormat.format(date)),
          excel.TextCellValue(exit['utilisateur'] as String),
        ]);
      }

      final excelFileDateFormat = DateFormat('yyyyMMdd', 'fr_FR');
      final fileName = _dateFilterMode == 'single'
          ? 'sorties_${excelFileDateFormat.format(_selectedDate!)}'
          : _dateFilterMode == 'range'
              ? 'sorties_${excelFileDateFormat.format(_selectedDateRange!.start)}_to_${excelFileDateFormat.format(_selectedDateRange!.end)}'
              : 'sorties_${DateTime.now().millisecondsSinceEpoch}';
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName.xlsx';
      final fileBytes = excelFile.encode();
      final file = File(filePath);
      await file.writeAsBytes(fileBytes!);

      if (mounted) {
        await Share.shareXFiles([XFile(file.path)], text: 'Rapport des sorties Excel');
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
        title: Text('Sorties de stock', style: GoogleFonts.roboto()),
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
            tooltip: 'Ajouter une sortie',
            onPressed: () => _showAddExitDialog(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          children: [
            _Header(
              isDarkMode: isDarkMode,
              searchController: _searchController,
            ),
            _Filters(
              selectedFilter: _selectedFilter,
              dateFilterMode: _dateFilterMode,
              selectedDate: _selectedDate,
              selectedDateRange: _selectedDateRange,
              onFilterChanged: (value) => setState(() => _selectedFilter = value),
              onSingleDatePicked: () => _pickSingleDate(context),
              onDateRangePicked: () => _pickDateRange(context),
              onClearDateFilter: _clearDateFilter,
            ),
            Expanded(
              child: _ExitsList(
                isDarkMode: isDarkMode,
                searchQuery: _searchQuery,
                selectedFilter: _selectedFilter,
                dateFilterMode: _dateFilterMode,
                selectedDate: _selectedDate,
                selectedDateRange: _selectedDateRange,
                sortColumnIndex: _sortColumnIndex,
                sortAscending: _sortAscending,
                onSort: _sortExits,
                onShowExitsDialog: _showExitsDialog,
                highlightText: _highlightText,
                numberFormat: _numberFormat,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          debugPrint('FAB pressed');
          _showAddExitDialog(context);
        },
        backgroundColor: theme.primaryColor,
        elevation: 6,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Ajouter une sortie',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Future<void> _showAddExitDialog(BuildContext context) async {
    debugPrint('Opening add exit dialog');
    final produits = await DatabaseHelper.getProduits();
    if (produits.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucun produit disponible')),
        );
      }
      return;
    }
    await showDialog(
      context: context,
      builder: (_) => _AddExitDialog(produits: produits),
    );
    if (context.mounted) {
      setState(() {});
    }
  }

  String _getTypeLabel(String type) {
    return _filters[type] ?? type;
  }
}

class _Header extends StatelessWidget {
  final bool isDarkMode;
  final TextEditingController searchController;

  const _Header({required this.isDarkMode, required this.searchController});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
                Icons.arrow_downward,
                color: Theme.of(context).primaryColor,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sorties de stock',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFamily: GoogleFonts.roboto().fontFamily,
                          ),
                    ),
                    Text(
                      'Gestion des sorties (ventes, retours, usage interne)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                            fontFamily: GoogleFonts.roboto().fontFamily,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher par produit ou raison...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
            style: GoogleFonts.roboto(fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  final String selectedFilter;
  final String dateFilterMode;
  final DateTime? selectedDate;
  final DateTimeRange? selectedDateRange;
  final ValueChanged<String> onFilterChanged;
  final VoidCallback onSingleDatePicked;
  final VoidCallback onDateRangePicked;
  final VoidCallback onClearDateFilter;

  const _Filters({
    required this.selectedFilter,
    required this.dateFilterMode,
    required this.selectedDate,
    required this.selectedDateRange,
    required this.onFilterChanged,
    required this.onSingleDatePicked,
    required this.onDateRangePicked,
    required this.onClearDateFilter,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final dateFormat = DateFormat('dd/MM/yyyy', 'fr_FR');

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
      child: Row(
        children: [
          ..._ExitsScreenState._filters.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(entry.value, style: GoogleFonts.roboto()),
                  selected: selectedFilter == entry.key,
                  onSelected: (selected) => onFilterChanged(selected ? entry.key : 'all'),
                  backgroundColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
                  selectedColor: theme.primaryColor.withOpacity(0.3),
                  checkmarkColor: theme.primaryColor,
                  labelStyle: TextStyle(
                    color: selectedFilter == entry.key
                        ? theme.primaryColor
                        : isDarkMode
                            ? Colors.white
                            : Colors.black87,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: selectedFilter == entry.key ? theme.primaryColor : Colors.transparent,
                    ),
                  ),
                ),
              )),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: onSingleDatePicked,
            icon: const Icon(Icons.calendar_today, size: 20),
            label: Text('Choisir une date', style: GoogleFonts.roboto()),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: onDateRangePicked,
            icon: const Icon(Icons.date_range, size: 20),
            label: Text('Choisir une période', style: GoogleFonts.roboto()),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          if (dateFilterMode != 'all') ...[
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Chip(
                label: Text(
                  dateFilterMode == 'single'
                      ? dateFormat.format(selectedDate!)
                      : '${dateFormat.format(selectedDateRange!.start)} - ${dateFormat.format(selectedDateRange!.end)}',
                  style: GoogleFonts.roboto(color: theme.primaryColor),
                ),
                deleteIcon: const Icon(Icons.clear, size: 18),
                onDeleted: onClearDateFilter,
                backgroundColor: theme.primaryColor.withOpacity(0.3),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExitsList extends StatelessWidget {
  final bool isDarkMode;
  final String? searchQuery;
  final String selectedFilter;
  final String dateFilterMode;
  final DateTime? selectedDate;
  final DateTimeRange? selectedDateRange;
  final int sortColumnIndex;
  final bool sortAscending;
  final Function(Comparable Function(Produit), int, bool) onSort;
  final Function(BuildContext, List<Map<String, dynamic>>, bool) onShowExitsDialog;
  final Widget Function(String, String?, TextStyle?, bool) highlightText;
  final NumberFormat numberFormat;

  const _ExitsList({
    required this.isDarkMode,
    required this.searchQuery,
    required this.selectedFilter,
    required this.dateFilterMode,
    required this.selectedDate,
    required this.selectedDateRange,
    required this.sortColumnIndex,
    required this.sortAscending,
    required this.onSort,
    required this.onShowExitsDialog,
    required this.highlightText,
    required this.numberFormat,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Produit>>(
      future: DatabaseHelper.getProduits(),
      builder: (context, produitSnapshot) {
        if (produitSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (produitSnapshot.hasError) {
          debugPrint('Produits list error: ${produitSnapshot.error}');
          return Center(child: Text('Erreur : ${produitSnapshot.error}', style: GoogleFonts.roboto(color: Colors.red)));
        }
        final produits = produitSnapshot.data ?? [];
        if (produits.isEmpty) {
          return const _EmptyState();
        }

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: DatabaseHelper.getAllExits(
            typeFilter: selectedFilter == 'all' ? null : selectedFilter,
            startDate: dateFilterMode == 'single'
                ? selectedDate
                : dateFilterMode == 'range'
                    ? selectedDateRange?.start
                    : null,
            endDate: dateFilterMode == 'single'
                ? selectedDate
                : dateFilterMode == 'range'
                    ? selectedDateRange?.end
                    : null,
          ),
          builder: (context, exitSnapshot) {
            if (exitSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (exitSnapshot.hasError) {
              debugPrint('Exits list error: ${exitSnapshot.error}');
              return Center(child: Text('Erreur : ${exitSnapshot.error}', style: GoogleFonts.roboto(color: Colors.red)));
            }
            final exits = exitSnapshot.data ?? [];

            final exitMap = <int, List<Map<String, dynamic>>>{};
            for (var exit in exits) {
              exitMap.putIfAbsent(exit['produitId'] as int, () => []).add(exit);
            }

            final filteredProduits = produits.where((produit) {
              final searchTerm = (searchQuery ?? '').toLowerCase();
              final productMatch = produit.nom.toLowerCase().contains(searchTerm);
              final exitsForProduct = exitMap[produit.id] ?? [];
              final raisonMatch = exitsForProduct.any((exit) =>
                  exit['raison'] != null && (exit['raison'] as String).toLowerCase().contains(searchTerm));
              final hasMatchingExits = selectedFilter == 'all' || exitsForProduct.isNotEmpty;
              return hasMatchingExits && (productMatch || raisonMatch);
            }).toList();

            filteredProduits.sort((a, b) {
              final Comparable<dynamic> aValue;
              final Comparable<dynamic> bValue;
              switch (sortColumnIndex) {
                case 1: // Product Name
                  aValue = a.nom.toLowerCase();
                  bValue = b.nom.toLowerCase();
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
              return sortAscending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
            });

            if (filteredProduits.isEmpty) {
              return const _EmptyState();
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
                          'Produits avec sorties (${filteredProduits.length})',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontFamily: GoogleFonts.roboto().fontFamily,
                              ),
                        ),
                        const SizedBox(height: 16),
                        DataTable(
                          sortColumnIndex: sortColumnIndex,
                          sortAscending: sortAscending,
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
                                fontFamily: GoogleFonts.roboto().fontFamily,
                              ),
                          dataTextStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: isDarkMode ? Colors.white70 : Colors.black87,
                                fontFamily: GoogleFonts.roboto().fontFamily,
                              ),
                          headingRowColor: MaterialStateProperty.resolveWith<Color>(
                            (states) => isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                          ),
                          columns: [
                            DataColumn(
                              label: const SizedBox(
                                width: 60,
                                child: Text('ID', textAlign: TextAlign.center),
                              ),
                              onSort: (columnIndex, ascending) =>
                                  onSort((p) => produits.indexOf(p), columnIndex, ascending),
                            ),
                            DataColumn(
                              label: const SizedBox(
                                width: 200,
                                child: Text('Nom du produit'),
                              ),
                              onSort: (columnIndex, ascending) =>
                                  onSort((p) => p.nom.toLowerCase(), columnIndex, ascending),
                            ),
                            DataColumn(
                              label: const SizedBox(
                                width: 150,
                                child: Text('Catégorie'),
                              ),
                              onSort: (columnIndex, ascending) =>
                                  onSort((p) => p.categorie ?? '', columnIndex, ascending),
                            ),
                            DataColumn(
                              label: const SizedBox(
                                width: 100,
                                child: Text('Unité'),
                              ),
                              onSort: (columnIndex, ascending) =>
                                  onSort((p) => p.unite ?? '', columnIndex, ascending),
                            ),
                            DataColumn(
                              label: const SizedBox(
                                width: 120,
                                child: Text('Stock initial', textAlign: TextAlign.right),
                              ),
                              onSort: (columnIndex, ascending) =>
                                  onSort((p) => p.quantiteInitiale, columnIndex, ascending),
                            ),
                            DataColumn(
                              label: const SizedBox(
                                width: 120,
                                child: Text('Stock actuel', textAlign: TextAlign.right),
                              ),
                              onSort: (columnIndex, ascending) =>
                                  onSort((p) => p.quantiteStock, columnIndex, ascending),
                            ),
                            const DataColumn(
                              label: SizedBox(
                                width: 200,
                                child: Text('Sorties de stock'),
                              ),
                            ),
                          ],
                          rows: filteredProduits.asMap().entries.map((entry) {
                            final index = entry.key;
                            final produit = entry.value;
                            final exitsForProduct = exitMap[produit.id] ?? [];
                            return DataRow(
                              color: MaterialStateProperty.resolveWith<Color>(
                                (states) {
                                  if (states.contains(MaterialState.hovered)) {
                                    return isDarkMode ? Colors.grey.shade700 : Colors.grey.shade100;
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
                                      style: GoogleFonts.roboto(),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 200,
                                    child: highlightText(
                                      produit.nom,
                                      searchQuery,
                                      Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w500,
                                            fontFamily: GoogleFonts.roboto().fontFamily,
                                          ),
                                      isDarkMode,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 150,
                                    child: Text(produit.categorie ?? 'N/A', style: GoogleFonts.roboto()),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 100,
                                    child: Text(produit.unite ?? 'N/A', style: GoogleFonts.roboto()),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 120,
                                    child: Text(
                                      numberFormat.format(produit.quantiteInitiale),
                                      textAlign: TextAlign.right,
                                      style: GoogleFonts.roboto(),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 120,
                                    child: Text(
                                      numberFormat.format(produit.quantiteStock),
                                      textAlign: TextAlign.right,
                                      style: GoogleFonts.roboto(),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 200,
                                    child: GestureDetector(
                                      onTap: () => onShowExitsDialog(context, exitsForProduct, isDarkMode),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.history,
                                            size: 20,
                                            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            exitsForProduct.isEmpty
                                                ? 'Aucune sortie'
                                                : '${exitsForProduct.length} sortie${exitsForProduct.length > 1 ? 's' : ''}',
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                                  decoration: TextDecoration.underline,
                                                  fontFamily: GoogleFonts.roboto().fontFamily,
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
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.arrow_downward,
            size: 64,
            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune sortie enregistrée',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: GoogleFonts.roboto().fontFamily,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez une sortie avec le bouton +',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                  fontFamily: GoogleFonts.roboto().fontFamily,
                ),
          ),
        ],
      ),
    );
  }
}

class _AddExitDialog extends StatelessWidget {
  final List<Produit> produits;

  const _AddExitDialog({required this.produits});

  bool _validateForm(Produit? produit, String? type, int? quantite) {
    return produit != null && type != null && quantite != null && quantite > 0;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    Produit? selectedProduit;
    String? selectedType;
    int? quantite = 1;
    String raison = '';
    bool isValid = false;
    final types = const ['sale', 'internal', 'return', 'other'];
    final productSearchController = TextEditingController();
    String productSearchQuery = '';

    return StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Nouvelle sortie de stock'),
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
                  fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
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
                  fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
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
                  labelText: 'Type de sortie',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                ),
                items: types.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_ExitsScreenState._filters[type] ?? type),
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
                  fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                ),
                keyboardType: TextInputType.number,
                initialValue: '1',
                onChanged: (value) {
                  setDialogState(() {
                    quantite = int.tryParse(value) ?? 1;
                    isValid = _validateForm(selectedProduit, selectedType, quantite);
                  });
                },
                validator: (value) {
                  final num = int.tryParse(value ?? '');
                  if (num == null || num <= 0) {
                    return 'Entrez une quantité positive';
                  }
                  if (selectedProduit != null && num > selectedProduit!.quantiteStock) {
                    return 'Quantité supérieure au stock (${selectedProduit!.quantiteStock})';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Raison (optionnel)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                ),
                onChanged: (value) {
                  setDialogState(() {
                    raison = value.trim();
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
                      final exit = StockExit(
                        produitId: selectedProduit!.id!,
                        produitNom: selectedProduit!.nom,
                        quantite: quantite!,
                        type: selectedType!,
                        raison: raison.isEmpty ? null : raison,
                        date: DateTime.now(),
                        utilisateur: Provider.of<AuthProvider>(context, listen: false).currentUser?.name ?? 'Admin',
                      );
                      await DatabaseHelper.addStockExit(exit);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Sortie ajoutée avec succès')),
                        );
                      }
                    } catch (e) {
                      debugPrint('Error adding exit: $e');
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
    );
  }
}