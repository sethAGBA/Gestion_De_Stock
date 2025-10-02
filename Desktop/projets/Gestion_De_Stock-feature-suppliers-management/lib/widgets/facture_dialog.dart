import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:printing/printing.dart';
import 'package:file_picker/file_picker.dart';

import '../helpers/database_helper.dart';
import '../models/models.dart';
import '../services/pdf_service.dart';

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
                                      return Card(
                                        child: ListTile(
                                          title: Text(produit.nom),
                                          subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              hasGros
                                                  ? Text('Détail: ${formatter.format(produit.prixVente)}\u00A0FCFA - Gros: ${formatter.format(produit.prixVenteGros)}\u00A0FCFA (≥ ${produit.seuilGros.toStringAsFixed(0)})')
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
                                            ],
                                          ),
                                          trailing: SizedBox(
                                            width: 90,
                                            child: TextField(
                                              controller: controller,
                                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                              decoration: InputDecoration(
                                                hintText: () {
                                                  final allowDecimal = {
                                                    'kg', 'kilogramme', 'kilogrammes', 'litre', 'litres', 'l', 'liter'
                                                  }.contains(produit.unite.toLowerCase());
                                                  final qtyFmt = NumberFormat(allowDecimal ? '#,##0.###' : '#,##0', 'fr_FR');
                                                  return qtyFmt.format(produit.quantiteStock);
                                                }(),
                                                border: const OutlineInputBorder(),
                                              ),
                                              onChanged: (value) {
                                                setState(() {
                                                  double parse(String s) => double.tryParse(s.replaceAll(' ', '').replaceAll(',', '.')) ?? 0.0;
                                                  final allowDecimal = {
                                                    'kg', 'kilogramme', 'kilogrammes', 'litre', 'litres', 'l', 'liter'
                                                  }.contains(produit.unite.toLowerCase());
                                                  double q = parse(value);
                                                  q = allowDecimal ? q : q.roundToDouble();
                                                  selectedItems.removeWhere((it) => it['produitId'] == produit.id);
                                                  insuffisant[produit.id] = q > produit.quantiteStock;
                                                  if (q > 0) {
                                                    final unitPrice = (hasGros && q >= produit.seuilGros) ? produit.prixVenteGros : produit.prixVente;
                                                    selectedItems.add({
                                                      'produitId': produit.id,
                                                      'produitNom': produit.nom,
                                                      'quantite': q,
                                                      'prixUnitaire': unitPrice,
                                                      'unite': produit.unite,
                                                      'tarifMode': (hasGros && q >= produit.seuilGros) ? 'Gros' : 'Détail',
                                                    });
                                                  }
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
                                                  '${it['produitNom']} x ${it['quantite']} ${it['unite']} - ${it['tarifMode'] ?? 'Détail'}',
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

                          for (var it in selectedItems) {
                            // Vérifier stock
                            final produit = produits.firstWhere((p) => p.id == it['produitId']);
                            if (produit.quantiteStock < (it['quantite'] as num)) {
                              throw Exception('Stock insuffisant pour ${produit.nom}');
                            }
                            await txn.update(
                              'produits',
                              {
                                'quantiteStock': produit.quantiteStock - (it['quantite'] as num),
                              },
                              where: 'id = ?',
                              whereArgs: [produit.id],
                            );

                            final row = {
                              'bonCommandeId': bonCommandeId,
                              'produitId': it['produitId'],
                              'quantite': it['quantite'],
                              'prixUnitaire': it['prixUnitaire'],
                            };
                            if (hasTarifMode) {
                              row['tarifMode'] = it['tarifMode'] ?? 'Détail';
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
                              'quantite': it['quantite'],
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
                final bytes = await PdfService.getPdfBytes(
                  numero: numero,
                  date: date,
                  clientNom: clientNom,
                  clientAdresse: adresse,
                  magasinAdresse: magasinAdresse,
                  vendeurNom: vendeurNom,
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
                await Printing.layoutPdf(
                  onLayout: (_) => Uint8List.fromList(bytes),
                  name: 'Facture $numero',
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Aperçu PDF de la facture $numero ouvert')));
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
                final bytes = await PdfService.getPdfBytes(
                  numero: numero,
                  date: date,
                  clientNom: clientNom,
                  clientAdresse: adresse,
                  magasinAdresse: magasinAdresse,
                  vendeurNom: vendeurNom,
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
                await PdfService.shareFacture(
                  numero: numero,
                  date: date,
                  clientNom: clientNom,
                  clientAdresse: adresse,
                  magasinAdresse: magasinAdresse,
                  vendeurNom: vendeurNom,
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
                final bytes = await PdfService.getPdfBytes(
                  numero: numero,
                  date: date,
                  clientNom: clientNom,
                  clientAdresse: adresse,
                  magasinAdresse: magasinAdresse,
                  vendeurNom: vendeurNom,
                  items: items,
                  sousTotal: sousTotal,
                  ristourne: ristourne,
                  total: total,
                  montantPaye: montantPaye,
                  resteAPayer: resteAPayer,
                  montantRemis: montantRemis,
                  monnaie: monnaie,
                );
                final printer = await Printing.pickPrinter(context: context);
                if (printer == null) {
                  if (context.mounted) Navigator.pop(context);
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('Aucune imprimante sélectionnée')));
                  return;
                }
                await Printing.layoutPdf(onLayout: (_) => Uint8List.fromList(bytes), name: 'Facture $numero');
                if (context.mounted) Navigator.pop(context);
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Impression de $numero envoyée')));
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
