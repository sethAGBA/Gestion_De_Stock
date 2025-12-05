import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';

class ProductsTableWidget extends StatefulWidget {
  final List<Produit> produits;
  final bool embedInCard;

  const ProductsTableWidget({
    Key? key,
    required this.produits,
    this.embedInCard = false,
  }) : super(key: key);

  @override
  State<ProductsTableWidget> createState() => _ProductsTableWidgetState();
}

class _ProductsTableWidgetState extends State<ProductsTableWidget> {
  String _searchQuery = '';
  late List<Produit> _filteredProduits;

  String _fmtQty(num value, String unite) {
    final pattern = unite.toLowerCase() == 'kg' ? '#,##0.###' : '#,##0.##';
    final nf = NumberFormat(pattern, 'fr_FR');
    final s = nf.format(value);
    return unite.toLowerCase() == 'kg' ? '$s kg' : s;
  }

  @override
  void initState() {
    super.initState();
    _filteredProduits = widget.produits;
  }

  @override
  void didUpdateWidget(covariant ProductsTableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.produits, widget.produits)) {
      _filteredProduits = _applyFilter(widget.produits, _searchQuery);
    }
  }

  List<Produit> _applyFilter(List<Produit> source, String query) {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      return source;
    }

    final lowerQuery = trimmedQuery.toLowerCase();
    return source.where((produit) {
      final nom = produit.nom.toLowerCase();
      final categorie = produit.categorie.toLowerCase();
      final fournisseur = (produit.fournisseurPrincipal ?? '').toLowerCase();
      final statut = produit.statut.toLowerCase();
      final matchesGeneric =
          nom.contains(lowerQuery) ||
          categorie.contains(lowerQuery) ||
          fournisseur.contains(lowerQuery);
      final matchesStatus = statut.contains(lowerQuery);
      final matchesDamaged =
          lowerQuery.contains('avarié') && produit.quantiteAvariee > 0;

      return matchesGeneric || matchesStatus || matchesDamaged;
    }).toList();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _filteredProduits = _applyFilter(widget.produits, query);
    });
  }

  Color _getStockColor(Produit produit) {
    if (produit.quantiteAvariee > 0) {
      return Colors.red.withValues(alpha: 0.1);
    }
    if (produit.quantiteStock <= produit.stockMin) {
      return Colors.red.withValues(alpha: 0.05);
    }
    if (produit.quantiteStock <= produit.seuilAlerte) {
      return Colors.orange.withValues(alpha: 0.05);
    }
    return Colors.transparent;
  }

  String _getDisplayStatus(Produit produit) {
    if (produit.quantiteStock == 0) {
      return 'Produit en rupture';
    }
    if (produit.quantiteAvariee > 0) {
      return 'Contient avariés';
    }
    if (produit.quantiteStock <= produit.seuilAlerte) {
      return 'Bientôt en rupture';
    }
    return produit.statut;
  }

  Widget _highlightText(
    String text,
    String query,
    TextStyle? baseStyle,
    bool isDarkMode,
  ) {
    if (query.isEmpty || text.isEmpty) {
      return Text(text, style: baseStyle);
    }
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final matchIndex = lowerText.indexOf(lowerQuery);
    if (matchIndex == -1) {
      return Text(text, style: baseStyle);
    }

    final beforeMatch = text.substring(0, matchIndex);
    final matchText = text.substring(matchIndex, matchIndex + query.length);
    final afterMatch = text.substring(matchIndex + query.length);

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
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              constraints: const BoxConstraints(maxWidth: 300, maxHeight: 350),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child:
                        imageUrl != null && File(imageUrl).existsSync()
                            ? Image.file(
                              File(imageUrl),
                              fit: BoxFit.contain,
                              errorBuilder:
                                  (context, error, stackTrace) => const Icon(
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
                        color:
                            isDarkMode
                                ? Colors.blue.shade200
                                : Colors.blue.shade700,
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

  void _showProductDetails(BuildContext ctx, Produit produit) {
    final theme = Theme.of(ctx);
    final isDarkMode = theme.brightness == Brightness.dark;
    final currency = NumberFormat('#,##0.00', 'fr_FR');
    showDialog(
      context: ctx,
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
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.blue.shade50),
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
            if (produit.marque != null && produit.marque!.isNotEmpty) _detailRow('Marque', produit.marque!),
            if (produit.sku != null && produit.sku!.isNotEmpty) _detailRow('SKU', produit.sku!),
            if (produit.codeBarres != null && produit.codeBarres!.isNotEmpty) _detailRow('Code-barres', produit.codeBarres!),
            if (produit.dci != null && produit.dci!.isNotEmpty) _detailRow('DCI', produit.dci!),
            if (produit.forme != null && produit.forme!.isNotEmpty) _detailRow('Forme', produit.forme!),
            if (produit.dosage != null && produit.dosage!.isNotEmpty) _detailRow('Dosage', produit.dosage!),
            if (produit.conditionnement != null && produit.conditionnement!.isNotEmpty)
              _detailRow('Conditionnement', produit.conditionnement!),
            if (produit.cip != null && produit.cip!.isNotEmpty) _detailRow('CIP/GTIN', produit.cip!),
            if (produit.fabricant != null && produit.fabricant!.isNotEmpty) _detailRow('Fabricant', produit.fabricant!),
            _detailRow('Unité', produit.unite),
            _detailRow('Stock', '${produit.quantiteStock}'),
            _detailRow('Prix vente', '${currency.format(produit.prixVente)} FCFA'),
            if (produit.prixVenteGros > 0) _detailRow('Prix gros', '${currency.format(produit.prixVenteGros)} FCFA'),
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
                onPressed: () => _showEnlargedImage(ctx, produit.imageUrl),
                icon: const Icon(Icons.zoom_in),
                label: Text(
                  'Voir l\'image',
                  style: TextStyle(color: isDarkMode ? Colors.blue.shade200 : Colors.blue.shade700),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer')),
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

  Widget _buildInsightPill({
    required ThemeData theme,
    required bool isDarkMode,
    required String label,
    required String value,
    Color? accent,
  }) {
  // If no accent specified, use theme primary for 'Références' to give it more weight
  final defaultAccent = (label.toLowerCase().contains('ref') || label.toLowerCase().contains('réf'))
    ? theme.colorScheme.primary
    : null;
  final effectiveAccent = accent ?? defaultAccent;

  // Compute accessible colors with stronger presence than before
  final bgColor = effectiveAccent != null
    ? effectiveAccent.withOpacity(isDarkMode ? 0.32 : 0.22)
    : (isDarkMode ? Colors.white.withOpacity(0.06) : Colors.grey.shade100);
  final borderColor = effectiveAccent != null
    ? effectiveAccent.withOpacity(isDarkMode ? 0.7 : 0.36)
    : Colors.transparent;
  final foreground = effectiveAccent != null
    ? (effectiveAccent.computeLuminance() > 0.55 ? Colors.black87 : Colors.white)
    : (isDarkMode ? Colors.white : Colors.grey.shade800);

    // Choose an icon depending on the label for better affordance
    IconData iconData = Icons.inventory_2_outlined;
    final lower = label.toLowerCase();
    if (lower.contains('rupt')) {
      iconData = Icons.warning_amber_rounded;
    } else if (lower.contains('avari') || lower.contains('avar')) {
      iconData = Icons.report_problem_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      constraints: const BoxConstraints(minWidth: 120),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          if (!isDarkMode)
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: effectiveAccent != null
                  ? effectiveAccent.withOpacity(isDarkMode ? 0.65 : 0.28)
                  : (isDarkMode ? Colors.white12 : Colors.grey.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              iconData,
              size: 18,
              color: effectiveAccent != null
                  ? (effectiveAccent.computeLuminance() > 0.55 ? Colors.black87 : Colors.white)
                  : foreground,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: foreground.withOpacity(0.9),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: Colors.grey,
        size: 22,
      ),
    );
  }

  Widget _buildTable(ThemeData theme, bool isDarkMode) {
    final controller = ScrollController();
    final headingColor =
        isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50;

    final rows =
        _filteredProduits.asMap().entries.map((entry) {
          final index = entry.key;
          final produit = entry.value;
          final displayStatus = _getDisplayStatus(produit);

          return DataRow(
            onSelectChanged: (_) => _showProductDetails(context, produit),
            color: WidgetStatePropertyAll<Color>(_getStockColor(produit)),
            cells: [
              DataCell(Text((index + 1).toString())),
              DataCell(
                GestureDetector(
                  onTap: () => _showEnlargedImage(context, produit.imageUrl),
                  child:
                      produit.imageUrl != null &&
                              File(produit.imageUrl!).existsSync()
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(produit.imageUrl!),
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) =>
                                      _buildImagePlaceholder(),
                            ),
                          )
                          : _buildImagePlaceholder(),
                ),
              ),
              DataCell(
                _highlightText(
                  produit.nom,
                  _searchQuery,
                  theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  isDarkMode,
                ),
              ),
              DataCell(
                _highlightText(
                  produit.categorie,
                  _searchQuery,
                  theme.textTheme.bodyMedium?.copyWith(
                    color:
                        isDarkMode
                            ? Colors.blue.shade200
                            : theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                  isDarkMode,
                ),
              ),
              DataCell(
                Text(
                  _fmtQty(produit.quantiteStock, produit.unite),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color:
                        produit.quantiteStock <= produit.stockMin
                            ? Colors.red.shade400
                            : produit.quantiteStock <= produit.seuilAlerte
                            ? Colors.orange.shade500
                            : null,
                    fontWeight:
                        produit.quantiteStock <= produit.seuilAlerte
                            ? FontWeight.w600
                            : FontWeight.w500,
                  ),
                ),
              ),
              DataCell(
                Text(
                  _fmtQty(produit.quantiteAvariee, produit.unite),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color:
                        produit.quantiteAvariee > 0
                            ? Colors.red.shade400
                            : null,
                    fontWeight:
                        produit.quantiteAvariee > 0
                            ? FontWeight.w600
                            : FontWeight.w500,
                  ),
                ),
              ),
              DataCell(
                Text(
                  '${NumberFormat('#,##0.00', 'fr_FR').format(produit.prixVente)}\u00A0FCFA',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color:
                        isDarkMode
                            ? Colors.green.shade300
                            : Colors.green.shade700,
                    fontWeight: FontWeight.w600,
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
                  label: _highlightText(
                    displayStatus,
                    _searchQuery,
                    theme.textTheme.labelSmall?.copyWith(
                      color:
                          displayStatus == 'disponible'
                              ? (isDarkMode
                                  ? Colors.green.shade200
                                  : Colors.green.shade800)
                              : displayStatus == 'Bientôt en rupture'
                              ? (isDarkMode
                                  ? Colors.orange.shade200
                                  : Colors.orange.shade700)
                              : (isDarkMode
                                  ? Colors.red.shade200
                                  : Colors.red.shade700),
                    ),
                    isDarkMode,
                  ),
                  backgroundColor:
                      displayStatus == 'disponible'
                          ? (isDarkMode
                              ? Colors.green.shade900.withValues(alpha: 0.35)
                              : Colors.green.shade50)
                          : displayStatus == 'Bientôt en rupture'
                          ? (isDarkMode
                              ? Colors.orange.shade900.withValues(alpha: 0.35)
                              : Colors.orange.shade50)
                          : (isDarkMode
                              ? Colors.red.shade900.withValues(alpha: 0.35)
                              : Colors.red.shade50),
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          );
        }).toList();

    final dataTable = DataTable(
      showCheckboxColumn: false,
      columnSpacing: 40,
      horizontalMargin: 28,
      dividerThickness: 0.6,
      headingTextStyle: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: isDarkMode ? Colors.grey.shade200 : Colors.grey.shade700,
        letterSpacing: 0.2,
      ),
      dataTextStyle: theme.textTheme.bodyMedium?.copyWith(
        color: isDarkMode ? Colors.grey.shade200 : Colors.grey.shade800,
      ),
      headingRowColor: WidgetStatePropertyAll<Color?>(headingColor),
      columns: const [
        DataColumn(label: Text('#')),
        DataColumn(label: Text('Image')),
        DataColumn(label: Text('Nom')),
        DataColumn(label: Text('Catégorie')),
        DataColumn(label: Text('Stock')),
        DataColumn(label: Text('Avarié')),
        DataColumn(label: Text('Prix Vente')),
        DataColumn(label: Text('Fournisseur')),
        DataColumn(label: Text('Statut')),
      ],
      rows: rows,
    );

    return Scrollbar(
      controller: controller,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: controller,
        scrollDirection: Axis.horizontal,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: dataTable,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final lowStockCount =
        widget.produits.where((p) => p.quantiteStock <= p.stockMin).length;
    final damagedCount =
        widget.produits.where((p) => p.quantiteAvariee > 0).length;

    Widget buildSearchField() {
      return SizedBox(
        width: 360,
        child: TextField(
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search_rounded),
            hintText:
                'Rechercher un produit (nom, catégorie, fournisseur, avarié)',
            filled: true,
            fillColor:
                isDarkMode
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.grey.shade100,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color:
                    isDarkMode
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.grey.shade300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color:
                    isDarkMode
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 1.6,
              ),
            ),
          ),
          onChanged: _onSearchChanged,
        ),
      );
    }

    Widget buildEmptyState({
      required IconData icon,
      required String title,
      String? subtitle,
    }) {
      final textColor =
          isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: textColor),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: textColor.withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      );
    }

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Wrap(
                spacing: 16,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Inventaire produits',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDarkMode ? Colors.white : Colors.grey.shade900,
                      letterSpacing: -0.2,
                    ),
                  ),
                  _buildInsightPill(
                    theme: theme,
                    isDarkMode: isDarkMode,
                    label: 'Références',
                    value: widget.produits.length.toString(),
                    accent: theme.colorScheme.primary,
                  ),
                  _buildInsightPill(
                    theme: theme,
                    isDarkMode: isDarkMode,
                    label: 'Ruptures',
                    value: lowStockCount.toString(),
                    accent: Colors.orange.shade700,
                  ),
                  _buildInsightPill(
                    theme: theme,
                    isDarkMode: isDarkMode,
                    label: 'Avariés',
                    value: damagedCount.toString(),
                    accent: Colors.red.shade700,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            buildSearchField(),
          ],
        ),
        const SizedBox(height: 24),
        if (widget.produits.isEmpty)
          buildEmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'Aucun produit enregistré',
            subtitle:
                'Ajoutez vos premières références pour visualiser l\'inventaire.',
          )
        else if (_filteredProduits.isEmpty)
          buildEmptyState(
            icon: Icons.search_off_rounded,
            title: 'Aucun produit trouvé',
            subtitle: 'Ajustez votre recherche pour élargir les résultats.',
          )
        else
          _buildTable(theme, isDarkMode),
      ],
    );

    if (widget.embedInCard) {
      return content;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color:
              isDarkMode
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          if (!isDarkMode)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 28,
              offset: const Offset(0, 16),
            ),
        ],
      ),
      child: content,
    );
  }
}
