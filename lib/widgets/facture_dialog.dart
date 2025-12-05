import 'dart:io';
import 'dart:typed_data';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:printing/printing.dart';
import 'package:file_picker/file_picker.dart';

import '../helpers/database_helper.dart';
import '../models/models.dart';
import '../services/ticket_service.dart';
import '../services/pdf_service.dart';
import '../services/invoice_service.dart';

class FactureDialog {
  static Future<void> showAddFactureDialog(
    BuildContext context,
    VoidCallback onFactureCreated, {
    String? vendeurNom,
  }) async {
    try {
      final clients = await DatabaseHelper.getClients();
      final produits = await DatabaseHelper.getProduits();
      if (clients.isEmpty || produits.isEmpty) {
        // Rien à faire si vide
        await showDialog(
          context: context,
          builder: (context) => const AlertDialog(
            title: Text('Erreur'),
            content: Text('Aucun client ou produit disponible'),
          ),
        );
        return;
      }

      final formatter = NumberFormat('#,##0.00', 'fr_FR');
      Widget _detailRow(String label, String value, ThemeData theme) {
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
      void _showEnlargedImage(BuildContext ctx, String? imageUrl) {
        final isDarkMode = Theme.of(ctx).brightness == Brightness.dark;
        showDialog(
          context: ctx,
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
                            errorBuilder: (context, error, stack) => const Icon(
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
      void _showProductDetails(BuildContext ctx, Produit produit) {
        final theme = Theme.of(ctx);
        final currency = NumberFormat('#,##0.00', 'fr_FR');
        showDialog(
          context: ctx,
          barrierDismissible: true,
          builder: (dCtx) => AlertDialog(
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
                  child: Text(produit.nom, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                _detailRow('Catégorie', produit.categorie, theme),
                if (produit.marque != null && produit.marque!.isNotEmpty) _detailRow('Marque', produit.marque!, theme),
                if (produit.sku != null && produit.sku!.isNotEmpty) _detailRow('SKU', produit.sku!, theme),
                if (produit.codeBarres != null && produit.codeBarres!.isNotEmpty) _detailRow('Code-barres', produit.codeBarres!, theme),
                _detailRow('Unité', produit.unite, theme),
                _detailRow('Stock', '${produit.quantiteStock}', theme),
                _detailRow('Prix vente', '${currency.format(produit.prixVente)} FCFA', theme),
                if (produit.prixVenteGros > 0) _detailRow('Prix gros', '${currency.format(produit.prixVenteGros)} FCFA', theme),
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
                    label: const Text('Voir l\'image'),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Fermer')),
            ],
          ),
        );
      }
      final selectedItems = <Map<String, dynamic>>[];
      final quantiteControllers = <int, TextEditingController>{};
      final insuffisant = <int, bool>{};
      final lineModes = <int, String>{};
      final venteUnitModes = <int, String>{};
      String globalTarifMode = 'Auto';

      Client? selectedClient;
      String? clientNom;
      String? adresse;
      String? magasinAdresse;
      String? methodePaiement = 'Espèces';
      final clientNomController = TextEditingController();
      final adresseController = TextEditingController();
      final magasinAdresseController = TextEditingController();
      final ristourneController = TextEditingController();
      final paiementController = TextEditingController();
      String productSearchQuery = '';

      await showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              double sousTotal = selectedItems.fold(0.0, (sum, item) => sum + (item['quantite'] as num) * (item['prixUnitaire'] as num));
              double ristourne = double.tryParse(ristourneController.text.trim().replaceAll(' ', '').replaceAll(',', '.')) ?? 0.0;
              double total = (sousTotal - (ristourne > 0 ? ristourne : 0)).clamp(0, double.infinity);
              double montantPaye = double.tryParse(paiementController.text.trim().replaceAll(' ', '').replaceAll(',', '.')) ?? 0.0;
              double resteAPayer = (total - montantPaye).clamp(0, double.infinity);
              double monnaie = montantPaye > total ? (montantPaye - total) : 0.0;
              const allowDecimalUnits = {
                'kg',
                'kilogramme',
                'kilogrammes',
                'litre',
                'litres',
                'l',
                'liter'
              };

              double _parseQuantity(String value, {required bool allowDecimal}) {
                double parse(String s) => double.tryParse(s.replaceAll(' ', '').replaceAll(',', '.')) ?? 0.0;
                final parsed = parse(value);
                return allowDecimal ? parsed : parsed.roundToDouble();
              }

              double _effectiveSeuil(Produit produit) {
                if (produit.prixVenteGros <= 0) return 0;
                return (produit.seuilGros > 0) ? produit.seuilGros : 1;
              }

              String _resolveMode(Produit produit, double quantite) {
                final hasGros = produit.prixVenteGros > 0;
                if (!hasGros) return 'Détail';
                final override = lineModes[produit.id];
                final baseMode = override ?? globalTarifMode;
                if (baseMode == 'Détail') return 'Détail';
                if (baseMode == 'Gros') return 'Gros';
                final seuil = _effectiveSeuil(produit);
                return (seuil > 0 && quantite >= seuil) ? 'Gros' : 'Détail';
              }

              double _resolvePrice(Produit produit, double quantite, String mode) {
                if (mode == 'Gros' && produit.prixVenteGros > 0) {
                  return produit.prixVenteGros;
                }
                return produit.prixVente;
              }

              void _rebuildSelection() {
                selectedItems.clear();
                insuffisant.clear();
                for (final produit in produits) {
                  final controller = quantiteControllers[produit.id];
                  if (controller == null) continue;
                  final allowDecimal = allowDecimalUnits.contains(produit.unite.toLowerCase());
                  final q = _parseQuantity(controller.text, allowDecimal: allowDecimal);
                  if (q <= 0) continue;
                  final hasPack = (produit.conditionnementQuantite > 0);
                  final selectedUnit = hasPack ? (venteUnitModes[produit.id] ?? 'Unité') : 'Unité';
                  final isPack = hasPack && selectedUnit == 'Conditionnement';
                  final packFactor = isPack ? (produit.conditionnementQuantite > 0 ? produit.conditionnementQuantite : 1) : 1;
                  final qBase = q * packFactor;
                  insuffisant[produit.id] = qBase > produit.quantiteStock;
                  final mode = _resolveMode(produit, qBase);
                  final unitPriceBaseMode = _resolvePrice(produit, qBase, mode); // prix unitaire en base
                  final saleUnitPrice = isPack
                      ? (produit.prixConditionnement > 0 ? produit.prixConditionnement : unitPriceBaseMode * packFactor)
                      : unitPriceBaseMode;
                  final unitPriceBase = isPack ? (saleUnitPrice / packFactor) : saleUnitPrice;
                  final uniteVente = isPack
                      ? (produit.conditionnementLabel?.isNotEmpty == true ? produit.conditionnementLabel! : 'Conditionnement')
                      : produit.unite;
                  selectedItems.add({
                    'produitId': produit.id,
                    'produitNom': produit.nom,
                    'quantite': q,
                    'quantiteBase': qBase,
                    'prixUnitaire': saleUnitPrice,
                    'prixUnitaireBase': unitPriceBase,
                    'unite': uniteVente,
                    'tarifMode': mode,
                    'uniteBase': produit.unite,
                    'conditionnementQuantite': packFactor,
                  });
                }
              }

              final filteredProduits = produits.where((p) {
                final q = productSearchQuery.toLowerCase();
                return p.nom.toLowerCase().contains(q) ||
                    (p.sku?.toLowerCase().contains(q) ?? false) ||
                    (p.codeBarres?.toLowerCase().contains(q) ?? false);
              }).toList();

              return AlertDialog(
                title: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Créer une facture',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Fermer',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                content: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.95,
                  height: MediaQuery.of(context).size.height * 0.85,
                  child: DefaultTabController(
                    length: 3,
                    child: Column(
                      children: [
                        const TabBar(
                          tabs: [
                            Tab(text: 'Détails'),
                            Tab(text: 'Produits'),
                            Tab(text: 'Aperçu'),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              // Onglet 1: Détails
                              SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 12),
                                    DropdownButton<Client>(
                                      value: selectedClient,
                                      hint: const Text('Sélectionner un client (ou laisser vide)'),
                                      isExpanded: true,
                                      items: [
                                        const DropdownMenuItem<Client>(value: null, child: Text('Aucun (saisie manuelle)')),
                                        ...clients.map((c) => DropdownMenuItem<Client>(value: c, child: Text(c.nom)))
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          selectedClient = value;
                                          if (value != null) {
                                            clientNom = value.nom;
                                            adresse = value.adresse;
                                            clientNomController.text = value.nom;
                                            adresseController.text = value.adresse ?? '';
                                          } else {
                                            clientNom = null;
                                            adresse = null;
                                            clientNomController.clear();
                                            adresseController.clear();
                                          }
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: clientNomController,
                                      decoration: const InputDecoration(labelText: 'Nom client', border: OutlineInputBorder()),
                                      onChanged: (v) => setState(() => clientNom = v.isEmpty ? null : v),
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: adresseController,
                                      decoration: const InputDecoration(labelText: 'Adresse client', border: OutlineInputBorder()),
                                      onChanged: (v) => setState(() => adresse = v.isEmpty ? null : v),
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: magasinAdresseController,
                                      decoration: const InputDecoration(labelText: 'Adresse fournisseur', border: OutlineInputBorder()),
                                      onChanged: (v) => setState(() => magasinAdresse = v.isEmpty ? null : v),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: ristourneController,
                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                            decoration: const InputDecoration(labelText: 'Ristourne (FCFA)', border: OutlineInputBorder()),
                                            onChanged: (_) => setState(() {}),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: TextField(
                                            controller: paiementController,
                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                            decoration: const InputDecoration(labelText: 'Montant payé (FCFA)', border: OutlineInputBorder()),
                                            onChanged: (_) => setState(() {}),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    DropdownButton<String>(
                                      value: methodePaiement,
                                      isExpanded: true,
                                      items: ['Espèces', 'Carte', 'Virement']
                                          .map((v) => DropdownMenuItem<String>(value: v, child: Text(v)))
                                          .toList(),
                                      onChanged: (v) => setState(() => methodePaiement = v),
                                    ),
                                  ],
                                ),
                              ),

                              // Onglet 2: Produits
                              SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 12),
                                    TextField(
                                      onChanged: (v) => setState(() => productSearchQuery = v),
                                      decoration: InputDecoration(
                                        hintText: 'Rechercher un produit (nom, SKU, code-barres)',
                                        prefixIcon: const Icon(Icons.search),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Mode de vente global',
                                      style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      children: ['Auto', 'Détail', 'Gros'].map((mode) {
                                        final isSelected = globalTarifMode == mode;
                                        return ChoiceChip(
                                          label: Text(mode),
                                          selected: isSelected,
                                          onSelected: (_) {
                                            setState(() {
                                              globalTarifMode = mode;
                                              _rebuildSelection();
                                            });
                                          },
                                        );
                                      }).toList(),
                                    ),
                                    const SizedBox(height: 12),
                                    if (filteredProduits.isEmpty)
                                      const Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: Text('Aucun produit trouvé'),
                                      )
                                    else
                                      ...filteredProduits.map((produit) {
                                        final controller = quantiteControllers.putIfAbsent(
                                          produit.id,
                                          () => TextEditingController(),
                                        );
                                        final hasGros = (produit.prixVenteGros) > 0;
                                        final hasPack = produit.conditionnementQuantite > 0;
                                        final effectiveSeuil = _effectiveSeuil(produit);
                                        final allowDecimal = allowDecimalUnits.contains(produit.unite.toLowerCase());
                                        final currentQty = _parseQuantity(controller.text, allowDecimal: allowDecimal);
                                        final resolvedMode = _resolveMode(produit, currentQty);
                                      return Card(
                                        child: ListTile(
                                          title: Text(produit.nom),
                                          subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              hasGros
                                                  ? Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text('Détail: ${formatter.format(produit.prixVente)}\u00A0FCFA - Gros: ${formatter.format(produit.prixVenteGros)}\u00A0FCFA (≥ ${effectiveSeuil.toStringAsFixed(0)})'),
                                                        const SizedBox(height: 4),
                                                        Row(
                                                          children: [
                                                            const Text('Mode : ', style: TextStyle(fontWeight: FontWeight.w600)),
                                                            DropdownButton<String>(
                                                              value: lineModes[produit.id] ?? 'Auto',
                                                              underline: const SizedBox.shrink(),
                                                              items: ['Auto', 'Détail', 'Gros']
                                                                  .map((mode) => DropdownMenuItem<String>(value: mode, child: Text(mode)))
                                                                  .toList(),
                                                              onChanged: (value) {
                                                                if (value == null) return;
                                                                setState(() {
                                                                  if (value == 'Auto') {
                                                                    lineModes.remove(produit.id);
                                                                  } else {
                                                                    lineModes[produit.id] = value;
                                                                  }
                                                                  _rebuildSelection();
                                                                });
                                                              },
                                                            ),
                                                            const SizedBox(width: 8),
                                                            if (lineModes[produit.id] != null)
                                                              Text('(ligne)', style: TextStyle(color: Colors.grey.shade600)),
                                                            if (lineModes[produit.id] == null)
                                                              Text('(global: $globalTarifMode)', style: TextStyle(color: Colors.grey.shade600)),
                                                          ],
                                                        ),
                                                        if (hasGros && hasPack)
                                                          const SizedBox(height: 4),
                                                        if (hasPack)
                                                          Row(
                                                            children: [
                                                              const Text('Vente : ', style: TextStyle(fontWeight: FontWeight.w600)),
                                                              DropdownButton<String>(
                                                                value: venteUnitModes[produit.id] ?? 'Unité',
                                                                underline: const SizedBox.shrink(),
                                                                items: ['Unité', 'Conditionnement']
                                                                    .map((mode) => DropdownMenuItem<String>(value: mode, child: Text(mode)))
                                                                    .toList(),
                                                                onChanged: (value) {
                                                                  if (value == null) return;
                                                                  setState(() {
                                                                    if (value == 'Unité') {
                                                                      venteUnitModes.remove(produit.id);
                                                                    } else {
                                                                      venteUnitModes[produit.id] = value;
                                                                    }
                                                                    _rebuildSelection();
                                                                  });
                                                                },
                                                              ),
                                                              const SizedBox(width: 8),
                                                              Text(
                                                                '1 ${produit.conditionnementLabel?.isNotEmpty == true ? produit.conditionnementLabel : 'pack'} = ${NumberFormat('#,##0.###', 'fr_FR').format(produit.conditionnementQuantite)} ${produit.unite}',
                                                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                                              ),
                                                            ],
                                                          ),
                                                      ],
                                                    )
                                                  : Text('${formatter.format(produit.prixVente)}\u00A0FCFA / ${produit.unite}'),
                                              if ((insuffisant[produit.id] ?? false))
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 4.0),
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.red.shade50,
                                                      borderRadius: BorderRadius.circular(12),
                                                      border: Border.all(color: Colors.red.shade300),
                                                    ),
                                                    child: const Text(
                                                      'Stock insuffisant',
                                                      style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600),
                                                    ),
                                                  ),
                                                ),
                                              if (hasGros && resolvedMode == 'Gros' && effectiveSeuil > 0 && currentQty > 0 && currentQty < effectiveSeuil)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 4.0),
                                                  child: Text(
                                                    'Attention: seuil gros ${effectiveSeuil.toStringAsFixed(0)} non atteint',
                                                    style: TextStyle(color: Colors.orange.shade700, fontSize: 12, fontWeight: FontWeight.w600),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          trailing: SizedBox(
                                            width: 90,
                                            child: TextField(
                                              controller: controller,
                                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                              decoration: InputDecoration(
                                                hintText: () {
                                                  final qtyFmt = NumberFormat(allowDecimal ? '#,##0.###' : '#,##0', 'fr_FR');
                                                  return qtyFmt.format(produit.quantiteStock);
                                                }(),
                                                border: const OutlineInputBorder(),
                                              ),
                                              onChanged: (value) {
                                                setState(() {
                                                  _rebuildSelection();
                                                });
                                              },
                                            ),
                                          ),
                                          onTap: () => _showProductDetails(context, produit),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),

                              // Onglet 3: Aperçu
                              SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 12),
                                    const Text('Articles:', style: TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    ...selectedItems.map((it) => Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  () {
                                                    final condFactor = (it['conditionnementQuantite'] as num?) ?? 1;
                                                    final qBase = it['quantiteBase'] as num?;
                                                    final uniteBase = it['uniteBase'] as String?;
                                                    final qtyFmt = NumberFormat('#,##0.###', 'fr_FR');
                                                    final baseInfo = (condFactor > 1 && qBase != null && uniteBase != null)
                                                        ? ' ≈ ${qtyFmt.format(qBase)} $uniteBase'
                                                        : '';
                                                    return '${it['produitNom']} x ${it['quantite']} ${it['unite']} - ${it['tarifMode'] ?? 'Détail'}$baseInfo';
                                                  }(),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Text('${formatter.format((it['quantite'] as num) * (it['prixUnitaire'] as num))}\u00A0FCFA'),
                                            ],
                                          ),
                                        )),
                                    const Divider(),
                                    Text('Sous-total: ${formatter.format(sousTotal)}\u00A0FCFA'),
                                    Text('Ristourne: ${formatter.format(ristourne)}\u00A0FCFA'),
                                    Text('Total: ${formatter.format(total)}\u00A0FCFA'),
                                    Text('Payé: ${formatter.format(montantPaye)}\u00A0FCFA'),
                                    if (montantPaye > total) Text('Monnaie: ${formatter.format(monnaie)}\u00A0FCFA'),
                                    Text('Reste à payer: ${formatter.format(resteAPayer)}\u00A0FCFA'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
                  TextButton(
                    onPressed: () async {
                      final numero = 'FACT${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch % 10000}'.padLeft(4, '0');
                      await showPrintOptions(
                        context: context,
                        numero: numero,
                        date: DateTime.now(),
                        clientNom: clientNom,
                        adresse: adresse,
                        magasinAdresse: magasinAdresse,
                        vendeurNom: vendeurNom ?? 'Non spécifié',
                        modePaiement: methodePaiement,
                        items: selectedItems,
                        sousTotal: sousTotal,
                        ristourne: ristourne,
                        total: total,
                        montantPaye: montantPaye,
                        resteAPayer: resteAPayer,
                        montantRemis: montantPaye,
                        monnaie: monnaie,
                      );
                    },
                    child: const Text('Aperçu'),
                  ),
                  TextButton(
                    onPressed: () async {
                      if (selectedItems.isEmpty) {
                        await showDialog(
                          context: context,
                          builder: (context) => const AlertDialog(
                            title: Text('Erreur'),
                            content: Text('Sélectionnez au moins un produit'),
                          ),
                        );
                        return;
                      }
                      if (ristourne > sousTotal) {
                        await showDialog(
                          context: context,
                          builder: (context) => const AlertDialog(
                            title: Text('Erreur'),
                            content: Text('La ristourne ne peut pas dépasser le sous-total'),
                          ),
                        );
                        return;
                      }

                      try {
                        final db = await DatabaseHelper.database;
                        await db.transaction((txn) async {
                          final bonCommandeId = await txn.insert('bons_commande', {
                            'clientId': selectedClient?.id ?? 0,
                            'clientNom': clientNom,
                            'date': DateTime.now().millisecondsSinceEpoch,
                            'statut': 'Confirmé',
                            'total': total,
                          });

                          final cols = await txn.rawQuery('PRAGMA table_info(bon_commande_items)');
                          final hasTarifMode = cols.any((c) => (c['name'] as String?) == 'tarifMode');
                          final hasUniteVente = cols.any((c) => (c['name'] as String?) == 'uniteVente');

                          for (var it in selectedItems) {
                            // Vérifier stock
                            final produit = produits.firstWhere((p) => p.id == it['produitId']);
                            final quantiteBase = (it['quantiteBase'] as num?) ?? (it['quantite'] as num);
                            if (produit.quantiteStock < quantiteBase) {
                              throw Exception('Stock insuffisant pour ${produit.nom}');
                            }
                            // Décrémenter les lots (FEFO)
                            double remaining = quantiteBase.toDouble();
                            final lots = await txn.query(
                              'lots',
                              where: 'produitId = ? AND quantiteDisponible > 0',
                              whereArgs: [produit.id],
                              orderBy: 'dateExpiration IS NULL, dateExpiration ASC',
                            );
                            for (final lot in lots) {
                              if (remaining <= 0) break;
                              final dispo = (lot['quantiteDisponible'] as num?)?.toDouble() ?? 0;
                              if (dispo <= 0) continue;
                              final use = min(dispo, remaining);
                              final newDispo = dispo - use;
                              await txn.update(
                                'lots',
                                {'quantiteDisponible': newDispo},
                                where: 'id = ?',
                                whereArgs: [lot['id']],
                              );
                              remaining -= use;
                            }
                            if (remaining > 0 && lots.isNotEmpty) {
                              throw Exception('Stock insuffisant par lot pour ${produit.nom}');
                            }
                            await txn.update(
                              'produits',
                              {
                                'quantiteStock': produit.quantiteStock - quantiteBase,
                              },
                              where: 'id = ?',
                              whereArgs: [produit.id],
                            );

                            final row = {
                              'bonCommandeId': bonCommandeId,
                              'produitId': it['produitId'],
                              'quantite': quantiteBase,
                              'prixUnitaire': it['prixUnitaireBase'] ?? it['prixUnitaire'],
                            };
                            if (hasTarifMode) {
                              row['tarifMode'] = it['tarifMode'] ?? 'Détail';
                            }
                            if (hasUniteVente) {
                              row['uniteVente'] = it['unite'];
                            }
                            await txn.insert('bon_commande_items', row);
                          }

                          final factureCount = await txn.query('factures');
                          final numero = 'FACT${DateTime.now().year}-${(factureCount.length + 1).toString().padLeft(4, '0')}';
                          final factureId = await txn.insert('factures', {
                            'numero': numero,
                            'bonCommandeId': bonCommandeId,
                            'clientId': selectedClient?.id ?? 0,
                            'clientNom': clientNom,
                            'adresse': adresse,
                            'vendeurNom': vendeurNom,
                            'magasinAdresse': magasinAdresse,
                            'ristourne': ristourne,
                            'date': DateTime.now().millisecondsSinceEpoch,
                            'total': total,
                            'statutPaiement': montantPaye >= total ? 'Payé' : 'En attente',
                            'montantPaye': montantPaye,
                            'montantRemis': montantPaye,
                            'monnaie': monnaie,
                            'statut': 'Active',
                          });

                          // Sorties de stock (journal)
                          for (var it in selectedItems) {
                            await txn.insert('stock_exits', {
                              'produitId': it['produitId'],
                              'produitNom': it['produitNom'],
                              'quantite': (it['quantiteBase'] as num?) ?? it['quantite'],
                              'type': 'sale',
                              'raison': numero,
                              'date': DateTime.now().millisecondsSinceEpoch,
                              'utilisateur': vendeurNom ?? 'Non spécifié',
                            });
                          }

                          if (montantPaye > 0) {
                            await txn.insert('paiements', {
                              'factureId': factureId,
                              'montant': montantPaye,
                              'montantRemis': montantPaye,
                              'monnaie': monnaie,
                              'date': DateTime.now().millisecondsSinceEpoch,
                              'methode': methodePaiement!,
                            });
                          }
                        });

                        onFactureCreated();
                        if (context.mounted) Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Facture créée avec succès')),
                        );
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erreur lors de la création de la facture : $e')),
                          );
                        }
                      }
                    },
                    child: const Text('Créer'),
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
    }
  }

  // Utilisé par SalesScreen
  static Future<void> showPrintOptions({
    required BuildContext context,
    required String numero,
    required DateTime date,
    required String? clientNom,
    required String? adresse,
    required String? magasinAdresse,
    required String vendeurNom,
    String? modePaiement,
    required List<Map<String, dynamic>> items,
    required double sousTotal,
    required double ristourne,
    required double total,
    required double montantPaye,
    required double resteAPayer,
    double? montantRemis,
    double? monnaie,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export PDF'),
        content: const Text('Que souhaitez-vous faire ?'),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                final bytes = await InvoiceService.getInvoiceBytes(
                  numero: numero,
                  date: date,
                  clientNom: clientNom,
                  clientAdresse: adresse,
                  magasinAdresse: magasinAdresse,
                  vendeurNom: vendeurNom,
                  modePaiement: modePaiement,
                  items: items,
                  sousTotal: sousTotal,
                  ristourne: ristourne,
                  total: total,
                  montantPaye: montantPaye,
                  resteAPayer: resteAPayer,
                  montantRemis: montantRemis,
                  monnaie: monnaie,
                );
                if (context.mounted) Navigator.pop(context);
                final directoryPath = await _pickSaveDirectory(context);
                if (directoryPath == null) return;
                final filePath = path.join(directoryPath, 'facture_$numero.pdf');
                await File(filePath).writeAsBytes(bytes);
                await _openFile(context, filePath);
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Facture $numero enregistrée : $filePath')));
                }
              } catch (e) {
                if (context.mounted) Navigator.pop(context);
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Erreur lors de l\'ouverture du PDF : $e')));
              }
            },
            child: const Text('Voir PDF'),
          ),
          TextButton(
            onPressed: () async {
              final directoryPath = await _pickSaveDirectory(context);
              if (directoryPath == null) return;
              try {
                final bytes = await InvoiceService.getInvoiceBytes(
                  numero: numero,
                  date: date,
                  clientNom: clientNom,
                  clientAdresse: adresse,
                  magasinAdresse: magasinAdresse,
                  vendeurNom: vendeurNom,
                  modePaiement: modePaiement,
                  items: items,
                  sousTotal: sousTotal,
                  ristourne: ristourne,
                  total: total,
                  montantPaye: montantPaye,
                  resteAPayer: resteAPayer,
                  montantRemis: montantRemis,
                  monnaie: monnaie,
                );
                final filePath = path.join(directoryPath, 'facture_$numero.pdf');
                await File(filePath).writeAsBytes(bytes);
                if (context.mounted) Navigator.pop(context);
                await _openFile(context, filePath);
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Facture $numero enregistrée : $filePath')));
                }
              } catch (e) {
                if (context.mounted) Navigator.pop(context);
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Erreur lors de l\'enregistrement : $e')));
              }
            },
            child: const Text('Enregistrer'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await InvoiceService.shareInvoice(
                  numero: numero,
                  date: date,
                  clientNom: clientNom,
                  clientAdresse: adresse,
                  magasinAdresse: magasinAdresse,
                  vendeurNom: vendeurNom,
                  modePaiement: modePaiement,
                  items: items,
                  sousTotal: sousTotal,
                  ristourne: ristourne,
                  total: total,
                  montantPaye: montantPaye,
                  resteAPayer: resteAPayer,
                  montantRemis: montantRemis,
                  monnaie: monnaie,
                );
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) Navigator.pop(context);
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Erreur lors du partage : $e')));
              }
            },
            child: const Text('Partager'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final bytes = await TicketService.getTicketBytes(
                  numero: numero,
                  date: date,
                  clientNom: clientNom,
                  clientAdresse: adresse,
                  magasinAdresse: magasinAdresse,
                  vendeurNom: vendeurNom,
                  modePaiement: modePaiement,
                  items: items,
                  sousTotal: sousTotal,
                  ristourne: ristourne,
                  total: total,
                  montantPaye: montantPaye,
                  resteAPayer: resteAPayer,
                  montantRemis: montantRemis,
                  monnaie: monnaie,
                );
                final directoryPath = await _pickSaveDirectory(context);
                if (directoryPath == null) return;
                final filePath = path.join(directoryPath, 'ticket_$numero.pdf');
                await File(filePath).writeAsBytes(bytes);
                if (context.mounted) Navigator.pop(context);
                await _openFile(context, filePath);
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Ticket enregistré : $filePath')));
                }
              } catch (e) {
                if (context.mounted) Navigator.pop(context);
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Erreur lors de la génération du ticket : $e')));
              }
            },
            child: const Text('Ticket'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final bytes = await InvoiceService.getInvoiceBytes(
                  numero: numero,
                  date: date,
                  clientNom: clientNom,
                  clientAdresse: adresse,
                  magasinAdresse: magasinAdresse,
                  vendeurNom: vendeurNom,
                  modePaiement: modePaiement,
                  items: items,
                  sousTotal: sousTotal,
                  ristourne: ristourne,
                  total: total,
                  montantPaye: montantPaye,
                  resteAPayer: resteAPayer,
                  montantRemis: montantRemis,
                  monnaie: monnaie,
                );
                await Printing.sharePdf(bytes: Uint8List.fromList(bytes), filename: 'facture_$numero.pdf');
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Choisissez Imprimer ou Enregistrer en PDF dans la feuille système')));
                }
              } catch (e) {
                if (context.mounted) Navigator.pop(context);
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Erreur lors de l\'impression : $e')));
              }
            },
            child: const Text('Imprimer'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  static Future<String?> _pickSaveDirectory(BuildContext context) async {
    try {
      final selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Choisissez un dossier de sauvegarde',
      );
      if (selectedDirectory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export annulé')),
        );
      }
      return selectedDirectory;
    } catch (e) {
      print('Erreur lors de la sélection du dossier : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Impossible de sélectionner un dossier : $e")),
      );
      return null;
    }
  }

  static Future<void> _openFile(BuildContext context, String filePath) async {
    try {
      if (Platform.isMacOS) {
        await Process.run('open', [filePath]);
      } else if (Platform.isWindows) {
        final windowsPath = filePath.replaceAll('/', '\\');
        await Process.run('explorer', [windowsPath]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [filePath]);
      }
    } catch (e) {
      print('Erreur lors de l\'ouverture du fichier : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Impossible d'ouvrir le fichier : $e")),
      );
    }
  }
}
