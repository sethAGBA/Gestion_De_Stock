import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:stock_management/helpers/database_helper.dart';
import '../models/models.dart';
import 'package:intl/intl.dart';
import '../services/pdf_service.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class FactureDialog {
  static void showAddFactureDialog(
    BuildContext context,
    VoidCallback onFactureCreated, {
    String? vendeurNom, // ADDED: Accept vendeurNom parameter
  }) async {
    final clients = await DatabaseHelper.getClients();
    final produits = await DatabaseHelper.getProduits();
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
    final selectedItems = <Map<String, dynamic>>[];
    final quantiteControllers = <int, TextEditingController>{};
    final formatter = NumberFormat('#,##0.00', 'fr_FR');
    String productSearchQuery = '';
    final tabController = TabController(length: 3, vsync: Navigator.of(context));

    if (clients.isEmpty || produits.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Erreur'),
          content: const Text('Aucun client ou produit disponible'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            double sousTotal =
                selectedItems.fold(0.0, (sum, item) => sum + item['quantite'] * item['prixUnitaire']);
            double ristourne = double.tryParse(ristourneController.text) ?? 0.0;
            double total = sousTotal - ristourne;
            double montantPaye = double.tryParse(paiementController.text) ?? 0.0;
            double resteAPayer = total - montantPaye;
            double monnaie = montantPaye > total ? montantPaye - total : 0.0;

            final filteredProduits = produits.where((produit) {
              final query = productSearchQuery.toLowerCase();
              return produit.nom.toLowerCase().contains(query) ||
                  (produit.sku?.toLowerCase().contains(query) ?? false) ||
                  (produit.codeBarres?.toLowerCase().contains(query) ?? false);
            }).toList();

            return AlertDialog(
              title: const Text('Créer une facture'),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.95,
                height: MediaQuery.of(context).size.height * 0.85,
                child: Column(
                  children: [
                    TabBar(
                      controller: tabController,
                      labelColor: Theme.of(context).primaryColor,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Theme.of(context).primaryColor,
                      tabs: const [
                        Tab(text: 'Détails'),
                        Tab(text: 'Produits'),
                        Tab(text: 'Aperçu'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: tabController,
                        children: [
                          SingleChildScrollView(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                DropdownButton<Client>(
                                  hint: const Text('Sélectionner un client (ou laisser vide)'),
                                  value: selectedClient,
                                  isExpanded: true,
                                  items: [
                                    const DropdownMenuItem<Client>(
                                      value: null,
                                      child: Text('Aucun client (saisie manuelle)'),
                                    ),
                                    ...clients.map((client) => DropdownMenuItem<Client>(
                                          value: client,
                                          child: Text(client.nom),
                                        )),
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
                                const SizedBox(height: 16.0),
                                TextField(
                                  controller: clientNomController,
                                  decoration: const InputDecoration(
                                    labelText: 'Nom du client',
                                    hintText: 'Entrez ou modifiez le nom',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      clientNom = value.isEmpty ? null : value;
                                    });
                                  },
                                ),
                                const SizedBox(height: 16.0),
                                TextField(
                                  controller: adresseController,
                                  decoration: const InputDecoration(
                                    labelText: 'Adresse du client',
                                    hintText: 'Entrez ou modifiez l\'adresse',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      adresse = value.isEmpty ? null : value;
                                    });
                                  },
                                ),
                                const SizedBox(height: 16.0),
                                TextField(
                                  controller: magasinAdresseController,
                                  decoration: const InputDecoration(
                                    labelText: 'Adresse du fournisseur',
                                    hintText: 'Entrez l\'adresse du fournisseur',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      magasinAdresse = value.isEmpty ? null : value;
                                    });
                                  },
                                ),
                                const SizedBox(height: 16.0),
                                TextField(
                                  controller: ristourneController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Ristourne (FCFA)',
                                    hintText: 'Entrez la ristourne',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (value) {
                                    setState(() {});
                                  },
                                ),
                                const SizedBox(height: 16.0),
                                TextField(
                                  controller: paiementController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Montant payé (FCFA)',
                                    hintText: 'Entrez le montant payé',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (value) {
                                    setState(() {});
                                  },
                                ),
                                const SizedBox(height: 16.0),
                                DropdownButton<String>(
                                  value: methodePaiement,
                                  isExpanded: true,
                                  items: ['Espèces', 'Carte', 'Virement']
                                      .map((value) => DropdownMenuItem<String>(value: value, child: Text(value)))
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      methodePaiement = value;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          SingleChildScrollView(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  onChanged: (value) {
                                    setState(() {
                                      productSearchQuery = value;
                                    });
                                  },
                                  decoration: InputDecoration(
                                    hintText: 'Rechercher un produit (nom, SKU, code-barres)',
                                    prefixIcon: const Icon(Icons.search),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    filled: true,
                                    fillColor: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.grey.shade800
                                        : Colors.grey.shade100,
                                  ),
                                ),
                                const SizedBox(height: 16.0),
                                const Text('Produits :', style: TextStyle(fontWeight: FontWeight.bold)),
                                if (filteredProduits.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Text('Aucun produit trouvé'),
                                  )
                                else
                                  ...filteredProduits.map((produit) {
                                    final controller =
                                        quantiteControllers.putIfAbsent(produit.id, () => TextEditingController());
                                    return Card(
                                      elevation: 2.0,
                                      margin: const EdgeInsets.symmetric(vertical: 8.0), // CHANGED: 4.0 -> 8.0 for better spacing
                                      child: ListTile(
                                        title: Text(produit.nom ?? 'Produit sans nom'), // CHANGED: Added null check
                                        subtitle:
                                            Text('${formatter.format(produit.prixVente ?? 0.0)} FCFA / ${produit.unite ?? 'Unité'}'), // CHANGED: Added null checks
                                        trailing: SizedBox(
                                          width: 80,
                                          child: TextField(
                                            controller: controller,
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(
                                              labelText: 'Qté',
                                              border: OutlineInputBorder(),
                                            ),
                                            onChanged: (value) {
                                              setState(() {
                                                final quantite = int.tryParse(value) ?? 0;
                                                selectedItems.removeWhere((item) => item['produitId'] == produit.id);
                                                if (quantite > 0) {
                                                  selectedItems.add({
                                                    'produitId': produit.id,
                                                    'produitNom': produit.nom,
                                                    'quantite': quantite,
                                                    'prixUnitaire': produit.prixVente,
                                                    'unite': produit.unite,
                                                  });
                                                }
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                              ],
                            ),
                          ),
                          SingleChildScrollView(
                            padding: const EdgeInsets.all(16.0),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              child: Card(
                                elevation: 4.0,
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Aperçu de la facture',
                                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                      const Divider(),
                                      Text(
                                          'Numéro: FACT${DateTime.now().year}-${(selectedItems.isNotEmpty ? 1 : 0).toString().padLeft(4, '0')}'),
                                      Text('Date: ${DateFormat('dd/MM/yyyy').format(DateTime.now())} à ${DateFormat('HH:mm').format(DateTime.now())}'),
                                      Text('Client: ${clientNom ?? '............................'}'),
                                      Text('Adresse client: ${adresse ?? 'Non spécifiée'}'),
                                      Text('Adresse fournisseur: ${magasinAdresse ?? 'Non spécifié'}'),
                                      Text('Vendeur: ${vendeurNom ?? 'Non spécifié'}'), // CHANGED: Use vendeurNom
                                      const SizedBox(height: 8.0),
                                      const Text('Articles:', style: TextStyle(fontWeight: FontWeight.bold)),
                                      ...selectedItems.map((item) => Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    '${item['produitNom']} x ${item['quantite']} ${item['unite']}',
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Text(
                                                    '${formatter.format(item['quantite'] * item['prixUnitaire'])} FCFA'),
                                              ],
                                            ),
                                          )),
                                      const Divider(),
                                      Text('Sous-total: ${formatter.format(sousTotal)} FCFA'),
                                      Text('Ristourne: ${formatter.format(ristourne)} FCFA'),
                                      Text('Total: ${formatter.format(total)} FCFA'),
                                      Text('Payé: ${formatter.format(montantPaye)} FCFA'),
                                      if (montantPaye > total)
                                        Text('Monnaie: ${formatter.format(monnaie)} FCFA'),
                                      Text('Reste à payer: ${formatter.format(resteAPayer >= 0 ? resteAPayer : 0)} FCFA'),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
                TextButton(
                  onPressed: () async {
                    try {
                      final numero =
                          'FACT${DateTime.now().year}-${(selectedItems.isNotEmpty ? 1 : 0).toString().padLeft(4, '0')}';
                      showPrintOptions(
                        context: context,
                        numero: numero,
                        date: DateTime.now(),
                        clientNom: clientNom,
                        adresse: adresse,
                        magasinAdresse: magasinAdresse,
                        vendeurNom: vendeurNom ?? 'Non spécifié', // CHANGED: Use vendeurNom
                        items: selectedItems,
                        sousTotal: sousTotal,
                        ristourne: ristourne,
                        total: total,
                        montantPaye: montantPaye,
                        resteAPayer: resteAPayer,
                        montantRemis: montantPaye,
                        monnaie: monnaie,
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text('Erreur : $e')));
                    }
                  },
                  child: const Text('Aperçu'),
                ),
                TextButton(
                  onPressed: () async {
                    if (selectedItems.isEmpty) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Erreur'),
                          content: const Text('Sélectionnez au moins un produit'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
                          ],
                        ),
                      );
                      return;
                    }
                    if (ristourne > sousTotal) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Erreur'),
                          content: const Text('La ristourne ne peut pas dépasser le sous-total'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
                          ],
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

                        for (var item in selectedItems) {
                          await txn.insert('bon_commande_items', {
                            'bonCommandeId': bonCommandeId,
                            'produitId': item['produitId'],
                            'quantite': item['quantite'],
                            'prixUnitaire': item['prixUnitaire'],
                          });

                          final produit =
                              produits.firstWhere((p) => p.id == item['produitId']);
                          if (produit.quantiteStock < item['quantite']) {
                            throw Exception('Stock insuffisant pour ${produit.nom}');
                          }
                          await txn.update(
                            'produits',
                            {'quantiteStock': produit.quantiteStock - item['quantite']},
                            where: 'id = ?',
                            whereArgs: [produit.id],
                          );
                        }

                        final factureCount = await txn.query('factures');
                        final numero =
                            'FACT${DateTime.now().year}-${(factureCount.length + 1).toString().padLeft(4, '0')}';
                        final factureId = await txn.insert('factures', {
                          'numero': numero,
                          'bonCommandeId': bonCommandeId,
                          'clientId': selectedClient?.id ?? 0,
                          'clientNom': clientNom,
                          'adresse': adresse,
                          'vendeurNom': vendeurNom, // CHANGED: Use vendeurNom
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

                        // AJOUT : Créer une sortie de stock de type 'sale' pour chaque produit vendu
                        for (var item in selectedItems) {
                          await txn.insert('stock_exits', {
                            'produitId': item['produitId'],
                            'produitNom': item['produitNom'],
                            'quantite': item['quantite'],
                            'type': 'sale',
                            'raison': numero, // numéro de facture comme raison
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
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Succès'),
                          content: const Text('Facture créée avec succès'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
                          ],
                        ),
                      );
                      print('Facture créée avec succès');
                    } catch (e) {
                      print('Erreur lors de la création de la facture : $e');
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Erreur'),
                          content: Text('Erreur lors de la création de la facture : $e'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
                          ],
                        ),
                      );
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
  }

  static void showPrintOptions({
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
    try {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Choisir une option'),
          content: const Text('Voulez-vous générer un PDF ou imprimer directement ?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Aperçu de la facture'),
                    content: SingleChildScrollView(
                      child: _buildPrintableFacture(
                        clientNom: clientNom,
                        adresse: adresse,
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
                        numero: numero,
                        date: date,
                      ),
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
                      TextButton(
                        onPressed: () async {
                          try {
                            final directory = await getApplicationDocumentsDirectory();
                            final path = '${directory.path}/facture_$numero.pdf';
                            await PdfService.saveFacture(
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
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Facture $numero enregistrée dans $path'),
                                action: SnackBarAction(
                                  label: 'Ouvrir dossier',
                                  onPressed: () async {
                                    final uri = Uri.parse(directory.path);
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri);
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Impossible d\'ouvrir le dossier')),
                                      );
                                    }
                                  },
                                ),
                              ),
                            );
                          } catch (e) {
                            Navigator.pop(context);
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
                            Navigator.pop(context);
                          } catch (e) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text('Erreur lors du partage : $e')));
                          }
                        },
                        child: const Text('Partager'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('PDF'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
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
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('Aucune imprimante sélectionnée')));
                    return;
                  }
                  await Printing.layoutPdf(onLayout: (_) => Uint8List.fromList(bytes), name: 'Facture $numero');
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Impression de $numero envoyée')));
                } catch (e) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Erreur lors de l\'impression : $e')));
                }
              },
              child: const Text('Imprimante'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
    }
  }

  static Future<String?> _getLogoPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('logo_path');
  }

  static Widget _buildPrintableFacture({
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
    required String numero,
    required DateTime date,
  }) {
    final formatter = NumberFormat('#,##0.00', 'fr_FR');
    return FutureBuilder<String?>(
      future: _getLogoPath(),
      builder: (context, snapshot) {
        Widget logoWidget = Container(
          height: 60,
          width: 120,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: const Center(child: Text('Logo', style: TextStyle(color: Colors.grey))),
        );
        if (snapshot.hasData && snapshot.data != null && File(snapshot.data!).existsSync()) {
          logoWidget = Image.file(
            File(snapshot.data!),
            height: 60,
            width: 120,
            fit: BoxFit.contain,
          );
        }
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black, width: 2.0),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              logoWidget,
              const SizedBox(height: 16.0),
              const Center(child: Text('FACTURE', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold))),
              const SizedBox(height: 24.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Adresse Fournisseur:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(magasinAdresse ?? 'Non spécifié', overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 16.0),
                        Text('Numéro: $numero', overflow: TextOverflow.ellipsis),
                        Text('Date: ${DateFormat('dd/MM/yyyy').format(date)} à ${DateFormat('HH:mm').format(date)}', overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Client:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(clientNom ?? '............................', overflow: TextOverflow.ellipsis),
                        Text(adresse ?? 'Non spécifiée', overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 16.0),
                        Text('Vendeur: $vendeurNom', overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24.0),
              const Text('Articles:', style: TextStyle(fontWeight: FontWeight.bold)),
              Table(
                border: TableBorder.all(color: Colors.black),
                columnWidths: const {
                  0: FlexColumnWidth(3),
                  1: FlexColumnWidth(1),
                  2: FlexColumnWidth(1),
                  3: FlexColumnWidth(1),
                },
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: Colors.grey.shade200),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text('Description', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text('Qté', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text('Prix Unitaire', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...items.map((item) {
                    final quantite = (item['quantite'] as num?)?.toInt() ?? 0;
                    final prixUnitaire = (item['prixUnitaire'] as num?)?.toDouble() ?? 0.0;
                    return TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('${item['produitNom']} (${item['unite']})', overflow: TextOverflow.ellipsis),
                        ),
                        Padding(padding: const EdgeInsets.all(8.0), child: Text('$quantite')),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('${formatter.format(prixUnitaire)} FCFA', overflow: TextOverflow.ellipsis),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('${formatter.format(quantite * prixUnitaire)} FCFA', overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    );
                  }),
                ],
              ),
              const SizedBox(height: 24.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Sous-total: ${formatter.format(sousTotal)} FCFA', overflow: TextOverflow.ellipsis),
                      Text('Ristourne: ${formatter.format(ristourne)} FCFA', overflow: TextOverflow.ellipsis),
                      Text('Total: ${formatter.format(total)} FCFA',
                          style: TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                      Text('Payé: ${formatter.format(montantPaye)} FCFA', overflow: TextOverflow.ellipsis),
                      if (montantRemis != null)
                        Text('Montant remis: ${formatter.format(montantRemis)} FCFA', overflow: TextOverflow.ellipsis),
                      if (monnaie != null && monnaie > 0)
                        Text('Monnaie: ${formatter.format(monnaie)} FCFA', overflow: TextOverflow.ellipsis),
                      Text('Reste à payer: ${formatter.format(resteAPayer >= 0 ? resteAPayer : 0)} FCFA',
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text('Signature du Client', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8.0),
                      Container(width: 200, child: CustomPaint(painter: DottedLinePainter(), size: Size(200, 2))),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('Signature du Vendeur', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8.0),
                      Container(width: 200, child: CustomPaint(painter: DottedLinePainter(), size: Size(200, 2))),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.square;

    const dashWidth = 5;
    const dashSpace = 5;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
