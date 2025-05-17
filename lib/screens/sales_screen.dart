import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stock_management/helpers/database_helper.dart';
import 'package:stock_management/providers/auth_provider.dart';
import '../models/models.dart';
import 'package:intl/intl.dart';
import '../services/pdf_service.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class SalesScreen extends StatefulWidget {
  const SalesScreen({Key? key}) : super(key: key);

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<Facture>> _facturesFuture;
  late TabController _tabController;
  String _searchQuery = '';
  String _selectedFilter = 'Toutes';
  bool _isDatabaseInitialized = false;
  final ValueNotifier<bool> _refreshNotifier = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _facturesFuture = Future.value([]);
    _initDatabase();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshNotifier.dispose();
    super.dispose();
  }

  Future<void> _initDatabase() async {
    try {
      print('Initialisation de la base de données...');
      await DatabaseHelper.initializeDatabase();
      setState(() {
        _isDatabaseInitialized = true;
        _facturesFuture = DatabaseHelper.getFactures(includeArchived: true);
      });
      print('Base de données initialisée avec succès');
    } catch (e) {
      print('Erreur lors de l\'initialisation de la base de données : $e');
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Erreur'),
            content: Text('Erreur d\'initialisation : $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _refreshFactures() {
    setState(() {
      _facturesFuture = DatabaseHelper.getFactures(includeArchived: true);
      _refreshNotifier.value = !_refreshNotifier.value;
    });
  }

  void _showAddFactureDialog() async {
    if (!_isDatabaseInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Base de données non initialisée')),
      );
      return;
    }

    try {
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
     final loggedInUser = Provider.of<AuthProvider>(context, listen: false).currentUser?.name ?? 'Inconnu';

      if (clients.isEmpty || produits.isEmpty) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Erreur'),
              content: const Text('Aucun client ou produit disponible'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        return;
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) {
            return StatefulBuilder(
              builder: (context, setState) {
                double sousTotal = selectedItems.fold(
                  0.0,
                  (sum, item) => sum + item['quantite'] * item['prixUnitaire'],
                );
                double ristourne = double.tryParse(ristourneController.text) ?? 0.0;
                double total = sousTotal - ristourne;
                double montantPaye = double.tryParse(paiementController.text) ?? 0.0;
                double resteAPayer = total - montantPaye;
                double monnaie = montantPaye > total ? montantPaye - total : 0.0;

                return AlertDialog(
                  title: const Text('Créer une facture'),
                  content: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.9,
                    height: MediaQuery.of(context).size.height * 0.8,
                    child: Column(
                      children: [
                        TabBar(
                          controller: _tabController,
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
                            controller: _tabController,
                            children: [
                              SingleChildScrollView(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    DropdownButton<Client>(
                                      hint: const Text('Sélectionner un client'),
                                      value: selectedClient,
                                      isExpanded: true,
                                      items: clients.map((client) {
                                        return DropdownMenuItem<Client>(
                                          value: client,
                                          child: Text(client.nom),
                                        );
                                      }).toList(),
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
                                        clientNom = value.isEmpty ? null : value;
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
                                        adresse = value.isEmpty ? null : value;
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
                                        magasinAdresse = value.isEmpty ? null : value;
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
                                      items: ['Espèces', 'Carte', 'Virement'].map((String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value),
                                        );
                                      }).toList(),
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
                                    const Text(
                                      'Produits :',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    ...produits.map((produit) {
                                      final controller = quantiteControllers.putIfAbsent(
                                        produit.id,
                                        () => TextEditingController(),
                                      );
                                      return Card(
                                        elevation: 2.0,
                                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                                        child: ListTile(
                                          title: Text(produit.nom),
                                          subtitle: Text(
                                            '${formatter.format(produit.prixVente)} FCFA / ${produit.unite}',
                                          ),
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
                                                  selectedItems.removeWhere(
                                                    (item) => item['produitId'] == produit.id,
                                                  );
                                                  if (quantite > 0) {
                                                    if (quantite > produit.quantiteStock) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                              'Quantité demandée pour ${produit.nom} dépasse le stock disponible (${produit.quantiteStock})'),
                                                        ),
                                                      );
                                                      controller.text = produit.quantiteStock.toString();
                                                      return;
                                                    }
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
                                          const Text(
                                            'Aperçu de la facture',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const Divider(),
                                          Text(
                                            'Numéro: FACT${DateTime.now().year}-${(selectedItems.isNotEmpty ? 1 : 0).toString().padLeft(4, '0')}',
                                          ),
                                          Text(
                                            'Date: ${DateTime.now().toString().substring(0, 10)}',
                                          ),
                                          Text(
                                            'Client: ${clientNom ?? 'Non spécifié'}',
                                          ),
                                          Text(
                                            'Adresse client: ${adresse ?? 'Non spécifiée'}',
                                          ),
                                          Text(
                                            'Adresse fournisseur: ${magasinAdresse ?? 'Non spécifié'}',
                                          ),
                                          Text('Vendeur: $loggedInUser'),
                                          const SizedBox(height: 8.0),
                                          const Text(
                                            'Articles:',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          ...selectedItems.map((item) {
                                            return Padding(
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
                                                    '${formatter.format(item['quantite'] * item['prixUnitaire'])} FCFA',
                                                  ),
                                                ],
                                              ),
                                            );
                                          }),
                                          const Divider(),
                                          Text(
                                            'Sous-total: ${formatter.format(sousTotal)} FCFA',
                                          ),
                                          Text(
                                            'Ristourne: ${formatter.format(ristourne)} FCFA',
                                          ),
                                          Text(
                                            'Total: ${formatter.format(total)} FCFA',
                                          ),
                                          Text(
                                            'Payé: ${formatter.format(montantPaye)} FCFA',
                                          ),
                                          if (montantPaye > total)
                                            Text(
                                              'Monnaie: ${formatter.format(monnaie)} FCFA',
                                            ),
                                          Text(
                                            'Reste à payer: ${formatter.format(resteAPayer >= 0 ? resteAPayer : 0)} FCFA',
                                          ),
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
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                    TextButton(
                      onPressed: () async {
                        try {
                          final numero = 'FACT${DateTime.now().year}-${(selectedItems.isNotEmpty ? 1 : 0).toString().padLeft(4, '0')}';
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Choisir une option'),
                              content: const Text('Voulez-vous générer un PDF ou imprimer directement ?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Annuler'),
                                ),
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
                                            vendeurNom: loggedInUser,
                                            items: selectedItems,
                                            sousTotal: sousTotal,
                                            ristourne: ristourne,
                                            total: total,
                                            montantPaye: montantPaye,
                                            resteAPayer: resteAPayer,
                                            montantRemis: montantPaye,
                                            monnaie: monnaie,
                                            numero: numero,
                                            date: DateTime.now(),
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text('Fermer'),
                                          ),
                                          TextButton(
                                            onPressed: () async {
                                              try {
                                                final directory = await getApplicationDocumentsDirectory();
                                                final path = '${directory.path}/facture_$numero.pdf';
                                                await PdfService.saveFacture(
                                                  numero: numero,
                                                  date: DateTime.now(),
                                                  clientNom: clientNom,
                                                  clientAdresse: adresse,
                                                  magasinAdresse: magasinAdresse,
                                                  vendeurNom: loggedInUser,
                                                  items: selectedItems,
                                                  sousTotal: sousTotal,
                                                  ristourne: ristourne,
                                                  total: total,
                                                  montantPaye: montantPaye,
                                                  resteAPayer: resteAPayer,
                                                  montantRemis: montantPaye,
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
                                                            const SnackBar(
                                                              content: Text('Impossible d\'ouvrir le dossier'),
                                                            ),
                                                          );
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                );
                                              } catch (e) {
                                                Navigator.pop(context);
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Erreur lors de l\'enregistrement : $e')),
                                                );
                                              }
                                            },
                                            child: const Text('Enregistrer'),
                                          ),
                                          TextButton(
                                            onPressed: () async {
                                              try {
                                                await PdfService.shareFacture(
                                                  numero: numero,
                                                  date: DateTime.now(),
                                                  clientNom: clientNom,
                                                  clientAdresse: adresse,
                                                  magasinAdresse: magasinAdresse,
                                                  vendeurNom: loggedInUser,
                                                  items: selectedItems,
                                                  sousTotal: sousTotal,
                                                  ristourne: ristourne,
                                                  total: total,
                                                  montantPaye: montantPaye,
                                                  resteAPayer: resteAPayer,
                                                  montantRemis: montantPaye,
                                                  monnaie: monnaie,
                                                );
                                                Navigator.pop(context);
                                              } catch (e) {
                                                Navigator.pop(context);
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Erreur lors du partage : $e')),
                                                );
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
                                        date: DateTime.now(),
                                        clientNom: clientNom,
                                        clientAdresse: adresse,
                                        magasinAdresse: magasinAdresse,
                                        vendeurNom: loggedInUser,
                                        items: selectedItems,
                                        sousTotal: sousTotal,
                                        ristourne: ristourne,
                                        total: total,
                                        montantPaye: montantPaye,
                                        resteAPayer: resteAPayer,
                                        montantRemis: montantPaye,
                                        monnaie: monnaie,
                                      );
                                      final printer = await Printing.pickPrinter(context: context);
                                      if (printer == null) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Aucune imprimante sélectionnée')),
                                        );
                                        return;
                                      }
                                      await Printing.layoutPdf(
                                        onLayout: (_) => Uint8List.fromList(bytes),
                                        name: 'Facture $numero',
                                      );
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Impression de $numero envoyée')),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Erreur lors de l\'impression : $e')),
                                      );
                                    }
                                  },
                                  child: const Text('Imprimante'),
                                ),
                              ],
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erreur : $e')),
                          );
                        }
                      },
                      child: const Text('Aperçu'),
                    ),
                    TextButton(
                      onPressed: () async {
                        // Vérification si aucun client n'est sélectionné
                        if (selectedClient == null) {
                          await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Client requis'),
                              content: const Text('Veuillez sélectionner un client pour continuer.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                          return;
                        }

                        if (selectedItems.isEmpty) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Erreur'),
                              content: const Text('Sélectionnez au moins un produit'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('OK'),
                                ),
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
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                          return;
                        }
                        if (montantPaye < 0) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Erreur'),
                              content: const Text('Le montant payé ne peut pas être négatif'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                          return;
                        }

                        try {
                          final db = await DatabaseHelper.database;
                          await db.transaction((txn) async {
                            final bonCommandeId = await txn.insert('bons_commande', {
                              'clientId': selectedClient!.id, // Non-null
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

                              final produit = produits.firstWhere(
                                (p) => p.id == item['produitId'],
                              );
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
                            final numero = 'FACT${DateTime.now().year}-${(factureCount.length + 1).toString().padLeft(4, '0')}';
                            final factureId = await txn.insert('factures', {
                              'numero': numero,
                              'bonCommandeId': bonCommandeId,
                              'clientId': selectedClient!.id, // Non-null
                              'clientNom': clientNom,
                              'adresse': adresse,
                              'vendeurNom': loggedInUser,
                              'magasinAdresse': magasinAdresse,
                              'ristourne': ristourne,
                              'date': DateTime.now().millisecondsSinceEpoch,
                              'total': total,
                              'statutPaiement': montantPaye >= total ? 'Payé' : 'En attente',
                              'montantPaye': montantPaye,
                              'montantRemis': montantPaye > 0 ? montantPaye : null,
                              'monnaie': monnaie > 0 ? monnaie : null,
                              'statut': 'Active',
                            });

                            if (montantPaye > 0) {
                              await txn.insert('paiements', {
                                'factureId': factureId,
                                'montant': montantPaye,
                                'montantRemis': montantPaye > 0 ? montantPaye : null,
                                'monnaie': monnaie > 0 ? monnaie : null,
                                'date': DateTime.now().millisecondsSinceEpoch,
                                'methode': methodePaiement!,
                              });
                            }
                          });

                          _refreshFactures();
                          Navigator.pop(context);
                          if (mounted) {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Succès'),
                                content: const Text('Facture créée avec succès'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          }
                          print('Facture créée avec succès');
                        } catch (e) {
                          print('Erreur lors de la création de la facture : $e');
                          if (mounted) {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Erreur'),
                                content: Text('Erreur lors de la création de la facture : $e'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
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
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement des données : $e')),
      );
    }
  }

  void _showCancelFactureDialog(Facture facture) {
    final motifController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Annuler la facture ${facture.numero}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Veuillez entrer le motif de l\'annulation :'),
            const SizedBox(height: 16.0),
            TextField(
              controller: motifController,
              decoration: const InputDecoration(
                labelText: 'Motif',
                hintText: 'Ex. : Erreur de saisie',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              final motif = motifController.text.trim();
              if (motif.isEmpty) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Erreur'),
                    content: const Text('Le motif d\'annulation est requis.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
                return;
              }

              try {
                await DatabaseHelper.cancelFacture(facture.id, motif);
                _refreshFactures();
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Succès'),
                    content: Text('Facture ${facture.numero} annulée avec succès.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              } catch (e) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Erreur'),
                    content: Text('Erreur lors de l\'annulation : $e'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              }
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _showFactureDetails(Facture facture) async {
    try {
      final db = await DatabaseHelper.database;
      final items = await db.rawQuery(
        '''
        SELECT bci.*, p.nom AS produitNom, p.unite
        FROM bon_commande_items bci
        JOIN produits p ON bci.produitId = p.id
        WHERE bci.bonCommandeId = ?
        ''',
        [facture.bonCommandeId],
      );
      final paiements = await db.query(
        'paiements',
        where: 'factureId = ?',
        whereArgs: [facture.id],
      );
      FactureArchivee? archivedFacture;
      if (facture.statut == 'Annulée') {
        final archived = await DatabaseHelper.getArchivedFacture(facture.id);
        archivedFacture = archived;
      }
      final formatter = NumberFormat('#,##0.00', 'fr_FR');

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Détails de la facture ${facture.numero}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Client', facture.clientNom ?? 'Non spécifié'),
                _buildInfoRow('Adresse', facture.adresse ?? 'Non spécifiée'),
                _buildInfoRow('Adresse fournisseur', facture.magasinAdresse ?? 'Non spécifié'),
                _buildInfoRow('Vendeur', facture.vendeurNom ?? 'Non spécifié'),
                _buildInfoRow('Date', DateFormat('dd/MM/yyyy').format(facture.date)),
                _buildInfoRow('Statut', facture.statut),
                _buildInfoRow('Statut paiement', facture.statutPaiement),
                _buildInfoRow('Total', '${formatter.format(facture.total)} FCFA'),
                _buildInfoRow('Ristourne', '${formatter.format(facture.ristourne)} FCFA'),
                _buildInfoRow('Payé', '${formatter.format(facture.montantPaye ?? 0.0)} FCFA'),
                if (facture.montantRemis != null)
                  _buildInfoRow('Montant remis', '${formatter.format(facture.montantRemis)} FCFA'),
                if (facture.monnaie != null)
                  _buildInfoRow('Monnaie', '${formatter.format(facture.monnaie)} FCFA'),
                _buildInfoRow('Reste à payer', '${formatter.format(facture.total - (facture.montantPaye ?? 0.0))} FCFA'),
                if (facture.statut == 'Annulée' && archivedFacture != null) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Détails de l\'annulation:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  _buildInfoRow('Motif', archivedFacture.motifAnnulation),
                  _buildInfoRow(
                    'Date d\'annulation',
                    DateFormat('dd/MM/yyyy').format(archivedFacture.dateAnnulation),
                  ),
                ],
                const SizedBox(height: 16),
                const Text(
                  'Articles:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...items.map((item) {
                  final quantite = (item['quantite'] as num?)?.toInt() ?? 0;
                  final prixUnitaire = (item['prixUnitaire'] as num?)?.toDouble() ?? 0.0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${item['produitNom']} x $quantite ${item['unite']}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${formatter.format(quantite * prixUnitaire)} FCFA',
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
                const Text(
                  'Paiements:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...paiements.map(
                  (paiement) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${paiement['methode']} - ${DateFormat('dd/MM/yyyy').format(DateTime.fromMillisecondsSinceEpoch(paiement['date'] as int))}',
                            ),
                            Text(
                              '${formatter.format(paiement['montant'])} FCFA',
                            ),
                          ],
                        ),
                        if (paiement['montantRemis'] != null)
                          Text(
                            'Remis: ${formatter.format(paiement['montantRemis'])} FCFA',
                          ),
                        if (paiement['monnaie'] != null)
                          Text(
                            'Monnaie: ${formatter.format(paiement['monnaie'])} FCFA',
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
            if (facture.statut == 'Active') ...[
              TextButton(
                onPressed: () => _showCancelFactureDialog(facture),
                child: const Text('Annuler', style: TextStyle(color: Colors.red)),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    final db = await DatabaseHelper.database;
                    final items = await db.rawQuery(
                      '''
                      SELECT bci.*, p.nom AS produitNom, p.unite
                      FROM bon_commande_items bci
                      JOIN produits p ON bci.produitId = p.id
                      WHERE bci.bonCommandeId = ?
                      ''',
                      [facture.bonCommandeId],
                    );
                    _showPrintOptions(
                      numero: facture.numero,
                      date: facture.date,
                      clientNom: facture.clientNom,
                      adresse: facture.adresse,
                      magasinAdresse: facture.magasinAdresse,
                      vendeurNom: facture.vendeurNom ?? 'Admin',
                      items: items
                          .map((item) => {
                                'produitId': item['produitId'],
                                'produitNom': item['produitNom'],
                                'quantite': item['quantite'],
                                'prixUnitaire': item['prixUnitaire'],
                                'unite': item['unite'],
                              })
                          .toList(),
                      sousTotal: facture.total + (facture.ristourne ?? 0.0),
                      ristourne: facture.ristourne ?? 0.0,
                      total: facture.total,
                      montantPaye: facture.montantPaye ?? 0.0,
                      resteAPayer: facture.total - (facture.montantPaye ?? 0.0),
                      montantRemis: facture.montantRemis,
                      monnaie: facture.monnaie,
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur lors de l\'impression : $e')),
                    );
                  }
                },
                child: const Text('Imprimer/PDF'),
              ),
              if (facture.total - (facture.montantPaye ?? 0.0) > 0)
                TextButton(
                  onPressed: () => _showAddPaymentDialog(facture),
                  child: const Text('Ajouter paiement'),
                ),
            ],
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement des détails : $e')),
      );
    }
  }

  void _showAddPaymentDialog(Facture facture) {
    double montantPaye = facture.montantPaye ?? 0.0;
    final montantController = TextEditingController();
    final montantRemisController = TextEditingController();
    String? methode = 'Espèces';
    final formatter = NumberFormat('#,##0.00', 'fr_FR');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            double montant = double.tryParse(montantController.text) ?? 0.0;
            double montantRemis = double.tryParse(montantRemisController.text) ?? 0.0;
            double monnaie = montantRemis > montant ? montantRemis - montant : 0.0;

            return AlertDialog(
              title: const Text('Ajouter un paiement'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: montantController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Montant (FCFA)',
                        hintText: 'Entrez le montant',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 16.0),
                    TextField(
                      controller: montantRemisController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Montant remis (FCFA)',
                        hintText: 'Entrez le montant remis',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 16.0),
                    Text('Monnaie: ${formatter.format(monnaie)} FCFA'),
                    const SizedBox(height: 16.0),
                    DropdownButton<String>(
                      value: methode,
                      isExpanded: true,
                      items: ['Espèces', 'Carte', 'Virement'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          methode = value;
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
                TextButton(
                  onPressed: () async {
                    final montant = double.tryParse(montantController.text);
                    final montantRemis = double.tryParse(montantRemisController.text);
                    if (montant == null || montant <= 0) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Erreur'),
                          content: const Text('Veuillez entrer un montant valide.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                      return;
                    }
                    if (montantRemis == null || montantRemis < montant) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Erreur'),
                          content: const Text('Le montant remis doit être supérieur ou égal au montant.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                      return;
                    }
                    if (montantPaye + montant > facture.total) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Erreur'),
                          content: const Text('Le paiement dépasse le montant dû.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                      return;
                    }

                    try {
                      await DatabaseHelper.addPayment(
                        facture.id,
                        montant,
                        methode!,
                        montantRemis: montantRemis,
                        monnaie: monnaie,
                      );
                      _refreshFactures();
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Succès'),
                          content: Text('Paiement de ${formatter.format(montant)} FCFA ajouté avec succès'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    } catch (e) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Erreur'),
                          content: Text('Erreur lors de l\'ajout du paiement : $e'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  child: const Text('Ajouter'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showPrintOptions({
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
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
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
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Fermer'),
                      ),
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erreur lors de l\'enregistrement : $e')),
                            );
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erreur lors du partage : $e')),
                            );
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Aucune imprimante sélectionnée')),
                    );
                    return;
                  }
                  await Printing.layoutPdf(
                    onLayout: (_) => Uint8List.fromList(bytes),
                    name: 'Facture $numero',
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Impression de $numero envoyée')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur lors de l\'impression : $e')),
                  );
                }
              },
              child: const Text('Imprimante'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    }
  }

  Widget _buildPrintableFacture({
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
    required double? montantRemis,
    required double? monnaie,
    required String numero,
    required DateTime date,
  }) {
    final formatter = NumberFormat('#,##0.00', 'fr_FR');
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
          Container(
            height: 60,
            width: 120,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: const Center(
              child: Text('Logo', style: TextStyle(color: Colors.grey)),
            ),
          ),
          const SizedBox(height: 16.0),
          const Center(
            child: Text(
              'FACTURE',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 24.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Adresse Fournisseur:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      magasinAdresse ?? 'Non spécifié',
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16.0),
                    Text('Numéro: $numero', overflow: TextOverflow.ellipsis),
                    Text(
                      'Date: ${DateFormat('dd/MM/yyyy').format(date)}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Client:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Nom: ${clientNom ?? 'Non spécifié'}',
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Adresse: ${adresse ?? 'Non spécifiée'}',
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      'Vendeur: $vendeurNom',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24.0),
          const Text(
            'Articles:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
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
                    child: Text(
                      'Description',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Qté',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Prix Unitaire',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Total',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
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
                      child: Text(
                        '${item['produitNom']} (${item['unite']})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('$quantite'),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        '${formatter.format(prixUnitaire)} FCFA',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        '${formatter.format(quantite * prixUnitaire)} FCFA',
                        overflow: TextOverflow.ellipsis,
                      ),
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
                  Text(
                    'Sous-total: ${formatter.format(sousTotal)} FCFA',
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Ristourne: ${formatter.format(ristourne)} FCFA',
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Total: ${formatter.format(total)} FCFA',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Payé: ${formatter.format(montantPaye)} FCFA',
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (montantRemis != null)
                    Text(
                      'Montant remis: ${formatter.format(montantRemis)} FCFA',
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (monnaie != null && monnaie > 0)
                    Text(
                      'Monnaie: ${formatter.format(monnaie)} FCFA',
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text(
                    'Reste à payer: ${formatter.format(resteAPayer >= 0 ? resteAPayer : 0)} FCFA',
                    overflow: TextOverflow.ellipsis,
                  ),
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
                  const Text(
                    'Signature du Client',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8.0),
                  Container(
                    width: 200,
                    child: CustomPaint(
                      painter: DottedLinePainter(),
                      size: Size(200, 2),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text(
                    'Signature du Vendeur',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8.0),
                  Container(
                    width: 200,
                    child: CustomPaint(
                      painter: DottedLinePainter(),
                      size: Size(200, 2),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build( context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final formatter = NumberFormat('#,##0.00', 'fr_FR');

    if (!_isDatabaseInitialized) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Initialisation de la base de données...',
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        title: Text(
          'Gestion des Factures',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.grey.shade900,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: _showAddFactureDialog,
              icon: const Icon(Icons.add),
              label: const Text('Nouvelle Facture'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildSearchAndFilters(),
              const SizedBox(height: 16),
              SizedBox(
                height: MediaQuery.of(context).size.height - 200,
                child: ValueListenableBuilder<bool>(
                  valueListenable: _refreshNotifier,
                  builder: (context, _, child) {
                    return FutureBuilder<List<Facture>>(
                      future: _facturesFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          print('Erreur FutureBuilder: ${snapshot.error}');
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
                                Text(
                                  'Erreur de chargement',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: Colors.red.shade300,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  snapshot.error.toString(),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _refreshFactures,
                                  child: const Text('Réessayer'),
                                ),
                              ],
                            ),
                          );
                        }

                        final factures = snapshot.data ?? [];
                        print('Nombre de factures chargées: ${factures.length}');
                        final filteredFactures = factures.where((facture) {
                          final query = _searchQuery.toLowerCase();
                          final matchesSearch = facture.numero.toLowerCase().contains(query) ||
                              (facture.clientNom?.toLowerCase().contains(query) ?? false) ||
                              (facture.vendeurNom?.toLowerCase().contains(query) ?? false);
                          if (_selectedFilter == 'Toutes') return matchesSearch;
                          if (_selectedFilter == 'Payées') return matchesSearch && facture.statutPaiement == 'Payé';
                          if (_selectedFilter == 'En attente') return matchesSearch && facture.statutPaiement == 'En attente';
                          if (_selectedFilter == 'Annulées') return matchesSearch && facture.statut == 'Annulée';
                          if (_selectedFilter == 'Ce mois') {
                            final now = DateTime.now();
                            return matchesSearch && facture.date.year == now.year && facture.date.month == now.month;
                          }
                          return matchesSearch;
                        }).toList();
                        print('Nombre de factures filtrées: ${filteredFactures.length}');

                        if (filteredFactures.isEmpty) {
                          return Center(
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.receipt_long_outlined,
                                    size: 64,
                                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchQuery.isNotEmpty
                                        ? 'Aucun résultat pour "$_searchQuery"'
                                        : _selectedFilter != 'Toutes'
                                            ? 'Aucune facture pour le filtre "$_selectedFilter"'
                                            : 'Aucune facture disponible',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    onPressed: _showAddFactureDialog,
                                    icon: const Icon(Icons.add),
                                    label: const Text('Créer une facture'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: theme.primaryColor,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                  if (_selectedFilter != 'Toutes' || _searchQuery.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: TextButton(
                                        onPressed: () {
                                          setState(() {
                                            _searchQuery = '';
                                            _selectedFilter = 'Toutes';
                                            _refreshFactures();
                                          });
                                        },
                                        child: const Text('Réinitialiser filtre et recherche'),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }

                        return GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: screenWidth > 800 ? 2 : 1,
                            childAspectRatio: 1.6,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: filteredFactures.length,
                          itemBuilder: (context, index) {
                            final facture = filteredFactures[index];
                            final resteAPayer = facture.total - (facture.montantPaye ?? 0.0);
                            return _buildFactureCard(
                              facture: facture,
                              resteAPayer: resteAPayer,
                              formatter: formatter,
                              isDarkMode: isDarkMode,
                              theme: theme,
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _refreshFactures();
              });
            },
            decoration: InputDecoration(
              hintText: 'Rechercher une facture...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade100,
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Toutes'),
                const SizedBox(width: 8),
                _buildFilterChip('Payées'),
                const SizedBox(width: 8),
                _buildFilterChip('En attente'),
                const SizedBox(width: 8),
                _buildFilterChip('Annulées'),
                const SizedBox(width: 8),
                _buildFilterChip('Ce mois'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    return FilterChip(
      label: Text(label),
      selected: _selectedFilter == label,
      onSelected: (bool selected) {
        setState(() {
          _selectedFilter = selected ? label : 'Toutes';
          _refreshFactures();
        });
      },
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildFactureCard({
    required Facture facture,
    required double resteAPayer,
    required NumberFormat formatter,
    required bool isDarkMode,
    required ThemeData theme,
  }) {
    final statusColor = facture.statut == 'Annulée'
        ? Colors.red
        : facture.statutPaiement == 'Payé'
            ? Colors.green
            : Colors.orange;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: InkWell(
        onTap: () => _showFactureDetails(facture),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Facture ${facture.numero}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: facture.statut == 'Annulée' ? Colors.red : null,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (facture.statut == 'Annulée')
                              const Padding(
                                padding: EdgeInsets.only(left: 8.0),
                                child: Icon(Icons.cancel, color: Colors.red),
                              ),
                          ],
                        ),
                        Text(
                          DateFormat('dd/MM/yyyy').format(facture.date),
                          style: theme.textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      facture.statut == 'Annulée' ? 'Annulée' : facture.statutPaiement,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Client: ${facture.clientNom ?? 'Non spécifié'}',
                          style: theme.textTheme.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Total: ${formatter.format(facture.total)} FCFA',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (facture.statut == 'Active')
                    Column(
                      children: [
                        IconButton(
                          icon: Icon(Icons.print, color: theme.primaryColor),
                          onPressed: () async {
                            try {
                              final db = await DatabaseHelper.database;
                              final items = await db.rawQuery(
                                '''
                                SELECT bci.*, p.nom AS produitNom, p.unite
                                FROM bon_commande_items bci
                                JOIN produits p ON bci.produitId = p.id
                                WHERE bci.bonCommandeId = ?
                                ''',
                                [facture.bonCommandeId],
                              );
                              _showPrintOptions(
                                numero: facture.numero,
                                date: facture.date,
                                clientNom: facture.clientNom,
                                adresse: facture.adresse,
                                magasinAdresse: facture.magasinAdresse,
                                vendeurNom: facture.vendeurNom ?? 'Admin',
                                items: items
                                    .map((item) => {
                                          'produitId': item['produitId'],
                                          'produitNom': item['produitNom'],
                                          'quantite': item['quantite'],
                                          'prixUnitaire': item['prixUnitaire'],
                                          'unite': item['unite'],
                                        })
                                    .toList(),
                                sousTotal: facture.total + (facture.ristourne ?? 0.0),
                                ristourne: facture.ristourne ?? 0.0,
                                total: facture.total,
                                montantPaye: facture.montantPaye ?? 0.0,
                                resteAPayer: facture.total - (facture.montantPaye ?? 0.0),
                                montantRemis: facture.montantRemis,
                                monnaie: facture.monnaie,
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Erreur lors de l\'impression : $e')),
                              );
                            }
                          },
                          tooltip: 'Imprimer ou générer PDF',
                        ),
                        if (resteAPayer > 0)
                          IconButton(
                            icon: Icon(Icons.payment, color: theme.primaryColor),
                            onPressed: () => _showAddPaymentDialog(facture),
                            tooltip: 'Ajouter un paiement',
                          ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
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
      canvas.drawLine(
          Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}