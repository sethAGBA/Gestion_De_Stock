import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import '../models/models.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({Key? key}) : super(key: key);

  @override
  _SalesScreenState createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  late Database _database;
  late Future<List<Facture>> _facturesFuture;
  late Future<List<BonCommande>> _bonsCommandeFuture;
  List<Facture> _filteredFactures = [];
  List<BonCommande> _filteredBonsCommande = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _facturesFuture = Future.value([]);
    _bonsCommandeFuture = Future.value([]);
    _initDatabase().then((_) {
      setState(() {
        _facturesFuture = _getFactures();
        _bonsCommandeFuture = _getBonsCommande();
      });
    }).catchError((e) {
      print('Erreur lors de l\'initialisation : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur d\'initialisation : $e')),
      );
    });
    _searchController.addListener(_filterData);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchController.removeListener(_filterData);
    _tabController.dispose();
    _database.close();
    super.dispose();
  }

  Future<void> _initDatabase() async {
    print('Initialisation de la base de données...');
    _database = await openDatabase(
      path.join(await getDatabasesPath(), 'dashboard.db'),
      version: 6,
      onCreate: (db, version) async {
        print('Création des tables...');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS produits (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nom TEXT NOT NULL,
            description TEXT,
            categorie TEXT NOT NULL,
            marque TEXT,
            imageUrl TEXT,
            sku TEXT,
            codeBarres TEXT,
            unite TEXT NOT NULL,
            quantiteStock INTEGER NOT NULL DEFAULT 0,
            quantiteAvariee INTEGER NOT NULL DEFAULT 0,
            stockMin INTEGER NOT NULL DEFAULT 0,
            stockMax INTEGER NOT NULL DEFAULT 0,
            seuilAlerte INTEGER NOT NULL DEFAULT 0,
            variantes TEXT,
            prixAchat REAL NOT NULL DEFAULT 0.0,
            prixVente REAL NOT NULL DEFAULT 0.0,
            tva REAL NOT NULL DEFAULT 0.0,
            fournisseurPrincipal TEXT,
            fournisseursSecondaires TEXT,
            derniereEntree INTEGER,
            derniereSortie INTEGER,
            statut TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS historique_avaries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            produitId INTEGER NOT NULL,
            produitNom TEXT NOT NULL,
            quantite INTEGER NOT NULL,
            action TEXT NOT NULL,
            utilisateur TEXT NOT NULL,
            date INTEGER NOT NULL,
            FOREIGN KEY (produitId) REFERENCES produits(id)
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS clients (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nom TEXT NOT NULL,
            email TEXT,
            telephone TEXT,
            adresse TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS bons_commande (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            clientId INTEGER NOT NULL,
            clientNom TEXT,
            date INTEGER NOT NULL,
            statut TEXT NOT NULL,
            total REAL,
            FOREIGN KEY (clientId) REFERENCES clients(id)
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS bon_commande_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            bonCommandeId INTEGER NOT NULL,
            produitId INTEGER NOT NULL,
            quantite INTEGER NOT NULL,
            prixUnitaire REAL NOT NULL,
            FOREIGN KEY (bonCommandeId) REFERENCES bons_commande(id),
            FOREIGN KEY (produitId) REFERENCES produits(id)
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS factures (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            numero TEXT NOT NULL,
            bonCommandeId INTEGER NOT NULL,
            clientId INTEGER NOT NULL,
            date INTEGER NOT NULL,
            total REAL NOT NULL,
            statutPaiement TEXT NOT NULL,
            FOREIGN KEY (bonCommandeId) REFERENCES bons_commande(id),
            FOREIGN KEY (clientId) REFERENCES clients(id)
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS paiements (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            factureId INTEGER NOT NULL,
            montant REAL NOT NULL,
            date INTEGER NOT NULL,
            methode TEXT NOT NULL,
            FOREIGN KEY (factureId) REFERENCES factures(id)
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        print('Mise à jour de la base de données de $oldVersion à $newVersion...');
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE produits ADD COLUMN quantiteAvariee INTEGER NOT NULL DEFAULT 0');
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS historique_avaries (
              id TEXT PRIMARY KEY,
              produitId TEXT NOT NULL,
              quantite INTEGER NOT NULL,
              action TEXT NOT NULL,
              utilisateur TEXT NOT NULL,
              date INTEGER NOT NULL,
              FOREIGN KEY (produitId) REFERENCES produits(id)
            )
          ''');
        }
        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE produits_new (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              nom TEXT NOT NULL,
              description TEXT,
              categorie TEXT NOT NULL,
              marque TEXT,
              imageUrl TEXT,
              sku TEXT,
              codeBarres TEXT,
              unite TEXT NOT NULL,
              quantiteStock INTEGER NOT NULL DEFAULT 0,
              quantiteAvariee INTEGER NOT NULL DEFAULT 0,
              stockMin INTEGER NOT NULL DEFAULT 0,
              stockMax INTEGER NOT NULL DEFAULT 0,
              seuilAlerte INTEGER NOT NULL DEFAULT 0,
              variantes TEXT,
              prixAchat REAL NOT NULL DEFAULT 0.0,
              prixVente REAL NOT NULL DEFAULT 0.0,
              tva REAL NOT NULL DEFAULT 0.0,
              fournisseurPrincipal TEXT,
              fournisseursSecondaires TEXT,
              derniereEntree INTEGER,
              derniereSortie INTEGER,
              statut TEXT NOT NULL
            )
          ''');
          await db.execute('''
            INSERT INTO produits_new (
              nom, description, categorie, marque, imageUrl, sku, codeBarres, unite,
              quantiteStock, quantiteAvariee, stockMin, stockMax, seuilAlerte, variantes,
              prixAchat, prixVente, tva, fournisseurPrincipal, fournisseursSecondaires,
              derniereEntree, derniereSortie, statut
            )
            SELECT
              nom, description, categorie, marque, imageUrl, sku, codeBarres, unite,
              quantiteStock, quantiteAvariee, stockMin, stockMax, seuilAlerte, variantes,
              prixAchat, prixVente, tva, fournisseurPrincipal, fournisseursSecondaires,
              derniereEntree, derniereSortie, statut
            FROM produits
          ''');
          await db.execute('DROP TABLE produits');
          await db.execute('ALTER TABLE produits_new RENAME TO produits');

          await db.execute('''
            CREATE TABLE historique_avaries_new (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              produitId INTEGER NOT NULL,
              produitNom TEXT NOT NULL,
              quantite INTEGER NOT NULL,
              action TEXT NOT NULL,
              utilisateur TEXT NOT NULL,
              date INTEGER NOT NULL,
              FOREIGN KEY (produitId) REFERENCES produits(id)
            )
          ''');
          await db.execute('''
            INSERT INTO historique_avaries_new (
              produitId, produitNom, quantite, action, utilisateur, date
            )
            SELECT
              CAST(produitId AS INTEGER), 'Inconnu', quantite, action, utilisateur, date
            FROM historique_avaries
          ''');
          await db.execute('DROP TABLE historique_avaries');
          await db.execute('ALTER TABLE historique_avaries_new RENAME TO historique_avaries');
        }
        if (oldVersion < 5) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS clients (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              nom TEXT NOT NULL,
              email TEXT,
              telephone TEXT,
              adresse TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS bons_commande (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              clientId INTEGER NOT NULL,
              date INTEGER NOT NULL,
              statut TEXT NOT NULL,
              FOREIGN KEY (clientId) REFERENCES clients(id)
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS bon_commande_items (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              bonCommandeId INTEGER NOT NULL,
              produitId INTEGER NOT NULL,
              quantite INTEGER NOT NULL,
              prixUnitaire REAL NOT NULL,
              FOREIGN KEY (bonCommandeId) REFERENCES bons_commande(id),
              FOREIGN KEY (produitId) REFERENCES produits(id)
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS factures (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              bonCommandeId INTEGER NOT NULL,
              clientId INTEGER NOT NULL,
              date INTEGER NOT NULL,
              total REAL NOT NULL,
              statutPaiement TEXT NOT NULL,
              FOREIGN KEY (bonCommandeId) REFERENCES bons_commande(id),
              FOREIGN KEY (clientId) REFERENCES clients(id)
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS paiements (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              factureId INTEGER NOT NULL,
              montant REAL NOT NULL,
              date INTEGER NOT NULL,
              methode TEXT NOT NULL,
              FOREIGN KEY (factureId) REFERENCES factures(id)
            )
          ''');
        }
        if (oldVersion < 6) {
          await db.execute('ALTER TABLE bons_commande ADD COLUMN clientNom TEXT');
          await db.execute('ALTER TABLE bons_commande ADD COLUMN total REAL');
          await db.execute('ALTER TABLE factures ADD COLUMN numero TEXT');
          final factures = await db.query('factures');
          for (var i = 0; i < factures.length; i++) {
            final numero = 'FACT${DateTime.now().year}-${(i + 1).toString().padLeft(4, '0')}';
            await db.update(
              'factures',
              {'numero': numero},
              where: 'id = ?',
              whereArgs: [factures[i]['id']],
            );
          }
        }
      },
    );
  }

  Future<List<Client>> _getClients() async {
    try {
      final List<Map<String, dynamic>> maps = await _database.query('clients');
      print('Clients récupérés : ${maps.length}');
      return List.generate(maps.length, (i) => Client.fromMap(maps[i]));
    } catch (e) {
      print('Erreur lors de la récupération des clients : $e');
      return [];
    }
  }

  Future<List<Produit>> _getProduits() async {
    try {
      final List<Map<String, dynamic>> maps = await _database.query('produits');
      print('Produits récupérés : ${maps.length}');
      final produits = List.generate(maps.length, (i) {
        print('Produit ${i + 1}: ${maps[i]}');
        return Produit.fromMap(maps[i]);
      });
      return produits;
    } catch (e) {
      print('Erreur lors de la récupération des produits : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la récupération des produits : $e')),
      );
      return [];
    }
  }

  Future<List<Facture>> _getFactures() async {
    try {
      final List<Map<String, dynamic>> maps = await _database.query('factures');
      print('Factures récupérées : ${maps.length}');
      final factures = List.generate(maps.length, (i) => Facture.fromMap(maps[i]));
      for (var facture in factures) {
        final client = await _database.query('clients', where: 'id = ?', whereArgs: [facture.clientId]);
        facture.clientNom = client.isNotEmpty ? client.first['nom'] as String : 'Inconnu';
      }
      return factures;
    } catch (e) {
      print('Erreur lors de la récupération des factures : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la récupération des factures : $e')),
      );
      return [];
    }
  }

  Future<List<BonCommande>> _getBonsCommande() async {
    try {
      final List<Map<String, dynamic>> maps = await _database.query('bons_commande');
      print('Bons de commande récupérés : ${maps.length}');
      final bonsCommande = <BonCommande>[];
      for (var map in maps) {
        final client = await _database.query('clients', where: 'id = ?', whereArgs: [map['clientId']]);
        final itemsMaps = await _database.query('bon_commande_items', where: 'bonCommandeId = ?', whereArgs: [map['id']]);
        final items = List.generate(itemsMaps.length, (j) => BonCommandeItem.fromMap(itemsMaps[j]));
        for (var item in items) {
          final produit = await _database.query('produits', where: 'id = ?', whereArgs: [item.produitId]);
          item.produitNom = produit.isNotEmpty ? produit.first['nom'] as String : 'Inconnu';
        }
        double total = 0;
        for (var item in items) {
          final produit = await _database.query('produits', where: 'id = ?', whereArgs: [item.produitId]);
          if (produit.isNotEmpty) {
            final tva = produit.first['tva'] as double;
            total += item.quantite * item.prixUnitaire * (1 + tva / 100);
          }
        }
        bonsCommande.add(BonCommande(
          id: map['id'] as int,
          clientId: map['clientId'] as int,
          clientNom: client.isNotEmpty ? client.first['nom'] as String : 'Inconnu',
          date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
          statut: map['statut'] as String,
          total: total,
          items: items,
        ));
      }
      return bonsCommande;
    } catch (e) {
      print('Erreur lors de la récupération des bons de commande : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la récupération des bons de commande : $e')),
      );
      return [];
    }
  }

  Future<BonCommande?> _getBonCommande(int bonCommandeId) async {
    try {
      final maps = await _database.query('bons_commande', where: 'id = ?', whereArgs: [bonCommandeId]);
      if (maps.isEmpty) {
        print('Aucun bon de commande trouvé pour ID $bonCommandeId');
        return null;
      }
      final client = await _database.query('clients', where: 'id = ?', whereArgs: [maps.first['clientId']]);
      final itemsMaps = await _database.query('bon_commande_items', where: 'bonCommandeId = ?', whereArgs: [bonCommandeId]);
      final items = List.generate(itemsMaps.length, (i) => BonCommandeItem.fromMap(itemsMaps[i]));
      for (var item in items) {
        final produit = await _database.query('produits', where: 'id = ?', whereArgs: [item.produitId]);
        item.produitNom = produit.isNotEmpty ? produit.first['nom'] as String : 'Inconnu';
      }
      double total = 0;
      for (var item in items) {
        final produit = await _database.query('produits', where: 'id = ?', whereArgs: [item.produitId]);
        if (produit.isNotEmpty) {
          final tva = produit.first['tva'] as double;
          total += item.quantite * item.prixUnitaire * (1 + tva / 100);
        }
      }
      final bonCommande = BonCommande(
        id: maps.first['id'] as int,
        clientId: maps.first['clientId'] as int,
        clientNom: client.isNotEmpty ? client.first['nom'] as String : 'Inconnu',
        date: DateTime.fromMillisecondsSinceEpoch(maps.first['date'] as int),
        statut: maps.first['statut'] as String,
        total: total,
        items: items,
      );
      print('Bon de commande récupéré : ${bonCommande.id} avec ${bonCommande.items.length} items');
      return bonCommande;
    } catch (e) {
      print('Erreur lors de la récupération du bon de commande : $e');
      return null;
    }
  }

  Future<List<Paiement>> _getPaiements(int factureId) async {
    try {
      final maps = await _database.query('paiements', where: 'factureId = ?', whereArgs: [factureId]);
      print('Paiements récupérés pour facture $factureId : ${maps.length}');
      return List.generate(maps.length, (i) => Paiement.fromMap(maps[i]));
    } catch (e) {
      print('Erreur lors de la récupération des paiements : $e');
      return [];
    }
  }

  void _filterData() {
    setState(() {
      final query = _searchController.text.trim().toLowerCase();
      _facturesFuture.then((factures) {
        _filteredFactures = factures.where((facture) {
          return (facture.clientNom?.toLowerCase().contains(query) ?? false) ||
              (facture.id.toString().contains(query)) ||
              (facture.numero.toLowerCase().contains(query)) ||
              (facture.statutPaiement.toLowerCase().contains(query));
        }).toList();
      });
      _bonsCommandeFuture.then((bonsCommande) {
        _filteredBonsCommande = bonsCommande.where((bonCommande) {
          return (bonCommande.clientNom?.toLowerCase().contains(query) ?? false) ||
              (bonCommande.id.toString().contains(query)) ||
              (bonCommande.statut.toLowerCase().contains(query));
        }).toList();
      });
    });
  }

  Future<void> _createBonCommande() async {
    final clients = await _getClients();
    final produits = await _getProduits();
    if (clients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun client disponible. Ajoutez un client d\'abord.')),
      );
      return;
    }
    if (produits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun produit disponible. Ajoutez un produit via l\'écran Produits.')),
      );
      return;
    }

    Client? selectedClient;
    final items = <BonCommandeItem>[];
    final formKey = GlobalKey<FormState>();
    String statut = 'en attente';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.7,
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Créer un bon de commande', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<Client>(
                    decoration: const InputDecoration(labelText: 'Client *', border: OutlineInputBorder()),
                    items: clients.map((client) => DropdownMenuItem(value: client, child: Text(client.nom))).toList(),
                    value: selectedClient,
                    onChanged: (value) => setState(() => selectedClient = value),
                    validator: (value) => value == null ? 'Requis' : null,
                  ),
                  const SizedBox(height: 16),
                  const Text('Produits', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('Aucun produit ajouté. Cliquez sur "Ajouter un produit" pour commencer.'),
                    ),
                  ...items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final selectedProduit = produits.firstWhere(
                      (p) => p.id == item.produitId,
                      orElse: () => produits.first,
                    );
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<Produit>(
                              decoration: const InputDecoration(labelText: 'Produit'),
                              items: produits.map((p) => DropdownMenuItem(value: p, child: Text(p.nom))).toList(),
                              value: selectedProduit,
                              onChanged: (value) {
                                setState(() {
                                  items[index] = BonCommandeItem(
                                    id: item.id,
                                    bonCommandeId: item.bonCommandeId,
                                    produitId: value!.id,
                                    produitNom: value.nom,
                                    quantite: item.quantite,
                                    prixUnitaire: value.prixVente,
                                  );
                                });
                              },
                              validator: (value) => value == null ? 'Requis' : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              initialValue: item.quantite.toString(),
                              decoration: const InputDecoration(labelText: 'Quantité'),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                final num = int.tryParse(value ?? '');
                                if (num == null || num <= 0) return 'Quantité invalide';
                                final produit = produits.firstWhere((p) => p.id == item.produitId);
                                if (num > produit.quantiteStock) return 'Stock insuffisant (${produit.quantiteStock} disponible)';
                                return null;
                              },
                              onSaved: (value) {
                                items[index] = BonCommandeItem(
                                  id: item.id,
                                  bonCommandeId: item.bonCommandeId,
                                  produitId: item.produitId,
                                  produitNom: item.produitNom,
                                  quantite: int.parse(value!),
                                  prixUnitaire: item.prixUnitaire,
                                );
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => setState(() => items.removeAt(index)),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        items.add(BonCommandeItem(
                          id: 0,
                          bonCommandeId: 0,
                          produitId: produits.first.id,
                          produitNom: produits.first.nom,
                          quantite: 1,
                          prixUnitaire: produits.first.prixVente,
                        ));
                      });
                    },
                    child: const Text('Ajouter un produit'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Statut *', border: OutlineInputBorder()),
                    items: ['en attente', 'validé', 'facturé']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    value: statut,
                    onChanged: (value) => setState(() => statut = value!),
                    validator: (value) => value == null ? 'Requis' : null,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            formKey.currentState!.save();
                            if (items.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Ajoutez au moins un produit.')),
                              );
                              return;
                            }
                            try {
                              final client = await _database.query('clients', where: 'id = ?', whereArgs: [selectedClient!.id]);
                              double total = 0;
                              for (var item in items) {
                                final produit = await _database.query('produits', where: 'id = ?', whereArgs: [item.produitId]);
                                if (produit.isNotEmpty) {
                                  final tva = produit.first['tva'] as double;
                                  total += item.quantite * item.prixUnitaire * (1 + tva / 100);
                                }
                              }
                              final bonCommande = BonCommande(
                                id: 0,
                                clientId: selectedClient!.id,
                                clientNom: client.isNotEmpty ? client.first['nom'] as String : 'Inconnu',
                                date: DateTime.now(),
                                statut: statut,
                                total: total,
                                items: items,
                              );
                              await _database.transaction((txn) async {
                                final bonCommandeId = await txn.insert('bons_commande', {
                                  'clientId': bonCommande.clientId,
                                  'clientNom': bonCommande.clientNom,
                                  'date': bonCommande.date.millisecondsSinceEpoch,
                                  'statut': bonCommande.statut,
                                  'total': bonCommande.total,
                                });
                                for (var item in items) {
                                  await txn.insert('bon_commande_items', {
                                    'bonCommandeId': bonCommandeId,
                                    'produitId': item.produitId,
                                    'quantite': item.quantite,
                                    'prixUnitaire': item.prixUnitaire,
                                  });
                                  if (bonCommande.statut == 'validé') {
                                    final produit = produits.firstWhere((p) => p.id == item.produitId);
                                    await txn.update(
                                      'produits',
                                      {'quantiteStock': produit.quantiteStock - item.quantite},
                                      where: 'id = ?',
                                      whereArgs: [item.produitId],
                                    );
                                  }
                                }
                              });
                              Navigator.pop(context);
                              setState(() {
                                _facturesFuture = _getFactures();
                                _bonsCommandeFuture = _getBonsCommande();
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Bon de commande créé avec succès.')),
                              );
                            } catch (e) {
                              print('Erreur lors de la création du bon de commande : $e');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Erreur : $e')),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: const Color(0xFF0E5A8A),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                        ),
                        child: const Text('Enregistrer'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<String> _generateFactureNumero() async {
    final factures = await _database.query('factures', orderBy: 'id DESC', limit: 1);
    int nextNumber = 1;
    if (factures.isNotEmpty) {
      final lastNumero = factures.first['numero'] as String;
      final lastNumber = int.parse(lastNumero.split('-').last);
      nextNumber = lastNumber + 1;
    }
    return 'FACT${DateTime.now().year}-${nextNumber.toString().padLeft(4, '0')}';
  }

  Future<void> _createFacture(BonCommande bonCommande) async {
    if (bonCommande.statut != 'validé') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le bon de commande doit être validé avant de créer une facture.')),
      );
      return;
    }
    final client = await _database.query('clients', where: 'id = ?', whereArgs: [bonCommande.clientId]);
    if (client.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Client introuvable.')),
      );
      return;
    }

    try {
      final numero = await _generateFactureNumero();
      await _database.transaction((txn) async {
        await txn.insert('factures', {
          'numero': numero,
          'bonCommandeId': bonCommande.id,
          'clientId': bonCommande.clientId,
          'date': DateTime.now().millisecondsSinceEpoch,
          'total': bonCommande.total ?? 0.0,
          'statutPaiement': 'en attente',
        });
        await txn.update(
          'bons_commande',
          {'statut': 'facturé'},
          where: 'id = ?',
          whereArgs: [bonCommande.id],
        );
      });
      setState(() {
        _facturesFuture = _getFactures();
        _bonsCommandeFuture = _getBonsCommande();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Facture créée avec succès.')),
      );
    } catch (e) {
      print('Erreur lors de la création de la facture : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    }
  }

  Future<void> _addClient() async {
    String nom = '';
    String? email;
    String? telephone;
    String? adresse;
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.5,
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ajouter un client', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Nom *', border: OutlineInputBorder()),
                  validator: (value) => (value?.isEmpty ?? true) ? 'Requis' : null,
                  onSaved: (value) => nom = value!,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                  onSaved: (value) => email = value,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Téléphone', border: OutlineInputBorder()),
                  onSaved: (value) => telephone = value,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Adresse', border: OutlineInputBorder()),
                  onSaved: (value) => adresse = value,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          formKey.currentState!.save();
                          try {
                            await _database.insert('clients', {
                              'nom': nom,
                              'email': email,
                              'telephone': telephone,
                              'adresse': adresse,
                            });
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Client ajouté avec succès.')),
                            );
                          } catch (e) {
                            print('Erreur lors de l\'ajout du client : $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erreur : $e')),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: const Color(0xFF0E5A8A),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      ),
                      child: const Text('Enregistrer'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addPaiement(Facture facture) async {
    double montant = 0;
    String methode = 'espèces';
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.5,
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ajouter un paiement', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Montant *', border: OutlineInputBorder()),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    final num = double.tryParse(value ?? '');
                    if (num == null || num <= 0) return 'Montant invalide';
                    return null;
                  },
                  onSaved: (value) => montant = double.parse(value!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Méthode *', border: OutlineInputBorder()),
                  items: ['espèces', 'carte', 'virement']
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  value: methode,
                  onChanged: (value) => methode = value!,
                  validator: (value) => value == null ? 'Requis' : null,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          formKey.currentState!.save();
                          try {
                            await _database.transaction((txn) async {
                              await txn.insert('paiements', {
                                'factureId': facture.id,
                                'montant': montant,
                                'date': DateTime.now().millisecondsSinceEpoch,
                                'methode': methode,
                              });
                              final paiements = await _getPaiements(facture.id);
                              final totalPaye = paiements.fold(0.0, (sum, p) => sum + p.montant);
                              if (totalPaye >= facture.total) {
                                await txn.update(
                                  'factures',
                                  {'statutPaiement': 'payé'},
                                  where: 'id = ?',
                                  whereArgs: [facture.id],
                                );
                              }
                            });
                            Navigator.pop(context);
                            setState(() {
                              _facturesFuture = _getFactures();
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Paiement ajouté avec succès.')),
                            );
                          } catch (e) {
                            print('Erreur lors de l\'ajout du paiement : $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erreur : $e')),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: const Color(0xFF0E5A8A),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      ),
                      child: const Text('Enregistrer'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showFactureDetails(Facture facture) async {
    final bonCommande = await _getBonCommande(facture.bonCommandeId);
    final paiements = await _getPaiements(facture.id);
    final client = await _database.query('clients', where: 'id = ?', whereArgs: [facture.clientId]);
    final clientNom = client.isNotEmpty ? client.first['nom'] as String : 'Inconnu';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.7,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Détails de la facture #${facture.numero}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text('Client: $clientNom'),
              Text('Date: ${facture.date.toString().substring(0, 16)}'),
              Text('Total: ${facture.total.toStringAsFixed(2)}'),
              Text('Statut: ${facture.statutPaiement}'),
              const SizedBox(height: 16),
              if (bonCommande != null) ...[
                Text('Bon de commande #${bonCommande.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ...bonCommande.items.map((item) => Text('${item.produitNom}: ${item.quantite} x ${item.prixUnitaire.toStringAsFixed(2)}')),
                const SizedBox(height: 16),
              ],
              const Text('Paiements', style: TextStyle(fontWeight: FontWeight.bold)),
              if (paiements.isEmpty)
                const Text('Aucun paiement enregistré')
              else
                ...paiements.map((p) => Text('${p.montant.toStringAsFixed(2)} - ${p.methode} - ${p.date.toString().substring(0, 16)}')),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
                  if (facture.statutPaiement != 'payé') ...[
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _addPaiement(facture);
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: const Color(0xFF0E5A8A),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      ),
                      child: const Text('Ajouter un paiement'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showBonCommandeDetails(BonCommande bonCommande) async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.7,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Détails du bon de commande #${bonCommande.id}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text('Client: ${bonCommande.clientNom ?? 'Inconnu'}'),
              Text('Date: ${bonCommande.date.toString().substring(0, 16)}'),
              Text('Statut: ${bonCommande.statut}'),
              Text('Total: ${bonCommande.total?.toStringAsFixed(2) ?? '0.00'}'),
              const SizedBox(height: 16),
              const Text('Produits', style: TextStyle(fontWeight: FontWeight.bold)),
              if (bonCommande.items.isEmpty)
                const Text('Aucun produit')
              else
                ...bonCommande.items.map((item) => Text('${item.produitNom}: ${item.quantite} x ${item.prixUnitaire.toStringAsFixed(2)}')),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
                  if (bonCommande.statut == 'validé') ...[
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _createFacture(bonCommande);
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: const Color(0xFF0E5A8A),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      ),
                      child: const Text('Créer une facture'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _highlightText(String text, String query, TextStyle? baseStyle, bool isDarkMode) {
    if (query.isEmpty || text.isEmpty) {
      return Text(
        text,
        style: baseStyle?.copyWith(color: isDarkMode ? null : Colors.black),
        overflow: TextOverflow.ellipsis,
      );
    }
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final matches = lowerText.indexOf(lowerQuery);
    if (matches == -1) {
      return Text(
        text,
        style: baseStyle?.copyWith(color: isDarkMode ? null : Colors.black),
        overflow: TextOverflow.ellipsis,
      );
    }

    final beforeMatch = text.substring(0, matches);
    final matchText = text.substring(matches, matches + query.length);
    final afterMatch = text.substring(matches + query.length);

    return RichText(
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: baseStyle?.copyWith(color: isDarkMode ? null : Colors.black),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ventes et Factures',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : const Color(0xFF0A3049),
                  ),
                ),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: _addClient,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: const Color(0xFF0E5A8A),
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Ajouter un client'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _createBonCommande,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: const Color(0xFF0E5A8A),
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Créer un bon de commande'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Icon(Icons.search, color: isDarkMode ? Colors.grey.shade400 : Colors.grey),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Rechercher (client, ID, statut)',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TabBar(
              controller: _tabController,
              labelColor: isDarkMode ? Colors.white : const Color(0xFF0E5A8A),
              unselectedLabelColor: isDarkMode ? Colors.grey.shade400 : Colors.grey,
              indicatorColor: const Color(0xFF0E5A8A),
              tabs: const [
                Tab(text: 'Factures'),
                Tab(text: 'Bons de Commande'),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Factures Tab
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              const SizedBox(width: 100, child: Text('Numéro', style: TextStyle(fontWeight: FontWeight.bold))),
                              const SizedBox(width: 150, child: Text('Client', style: TextStyle(fontWeight: FontWeight.bold))),
                              const SizedBox(width: 150, child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                              const SizedBox(width: 100, child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                              const SizedBox(width: 100, child: Text('Statut', style: TextStyle(fontWeight: FontWeight.bold))),
                              const SizedBox(width: 120, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: CustomScrollView(
                          scrollDirection: Axis.vertical,
                          slivers: [
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              sliver: FutureBuilder<List<Facture>>(
                                future: _facturesFuture,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
                                  }
                                  if (snapshot.hasError) {
                                    print('Erreur dans FutureBuilder (factures) : ${snapshot.error}');
                                    return SliverFillRemaining(child: Center(child: Text('Erreur : ${snapshot.error}')));
                                  }
                                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                    return SliverFillRemaining(
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              CupertinoIcons.exclamationmark_triangle,
                                              size: 48,
                                              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'Aucune facture disponible. Créez un bon de commande et validez-le pour générer une facture.',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                  final factures = _filteredFactures.isNotEmpty || _searchController.text.isNotEmpty
                                      ? _filteredFactures
                                      : snapshot.data!;
                                  if (factures.isEmpty && _searchController.text.isNotEmpty) {
                                    return SliverFillRemaining(
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              CupertinoIcons.search,
                                              size: 48,
                                              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'Aucune facture trouvée pour cette recherche',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                  return SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        final facture = factures[index];
                                        return Container(
                                          decoration: BoxDecoration(
                                            border: Border(bottom: BorderSide(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200)),
                                          ),
                                          child: SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                children: [
                                                  SizedBox(
                                                    width: 100,
                                                    child: Text(
                                                      facture.numero,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: 150,
                                                    child: _highlightText(
                                                      facture.clientNom ?? 'Inconnu',
                                                      _searchController.text,
                                                      const TextStyle(),
                                                      isDarkMode,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: 150,
                                                    child: Text(
                                                      facture.date.toString().substring(0, 16),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: 100,
                                                    child: Text(
                                                      facture.total.toStringAsFixed(2),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: 100,
                                                    child: Text(
                                                      facture.statutPaiement,
                                                      style: TextStyle(
                                                        color: facture.statutPaiement == 'payé' ? Colors.green : Colors.red,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: 120,
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        IconButton(
                                                          icon: const Icon(CupertinoIcons.eye, color: Color(0xFF0E5A8A), size: 20),
                                                          onPressed: () => _showFactureDetails(facture),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      childCount: factures.length,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Bons de Commande Tab
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              const SizedBox(width: 100, child: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
                              const SizedBox(width: 150, child: Text('Client', style: TextStyle(fontWeight: FontWeight.bold))),
                              const SizedBox(width: 150, child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                              const SizedBox(width: 100, child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                              const SizedBox(width: 100, child: Text('Statut', style: TextStyle(fontWeight: FontWeight.bold))),
                              const SizedBox(width: 120, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: CustomScrollView(
                          scrollDirection: Axis.vertical,
                          slivers: [
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              sliver: FutureBuilder<List<BonCommande>>(
                                future: _bonsCommandeFuture,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
                                  }
                                  if (snapshot.hasError) {
                                    print('Erreur dans FutureBuilder (bons de commande) : ${snapshot.error}');
                                    return SliverFillRemaining(child: Center(child: Text('Erreur : ${snapshot.error}')));
                                  }
                                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                    return SliverFillRemaining(
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              CupertinoIcons.exclamationmark_triangle,
                                              size: 48,
                                              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'Aucun bon de commande disponible. Créez-en un pour commencer.',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                  final bonsCommande = _filteredBonsCommande.isNotEmpty || _searchController.text.isNotEmpty
                                      ? _filteredBonsCommande
                                      : snapshot.data!;
                                  if (bonsCommande.isEmpty && _searchController.text.isNotEmpty) {
                                    return SliverFillRemaining(
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              CupertinoIcons.search,
                                              size: 48,
                                              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'Aucun bon de commande trouvé pour cette recherche',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                  return SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        final bonCommande = bonsCommande[index];
                                        return Container(
                                          decoration: BoxDecoration(
                                            border: Border(bottom: BorderSide(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200)),
                                          ),
                                          child: SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                children: [
                                                  SizedBox(
                                                    width: 100,
                                                    child: Text(
                                                      bonCommande.id.toString(),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: 150,
                                                    child: _highlightText(
                                                      bonCommande.clientNom ?? 'Inconnu',
                                                      _searchController.text,
                                                      const TextStyle(),
                                                      isDarkMode,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: 150,
                                                    child: Text(
                                                      bonCommande.date.toString().substring(0, 16),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: 100,
                                                    child: Text(
                                                      bonCommande.total?.toStringAsFixed(2) ?? '0.00',
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: 100,
                                                    child: Text(
                                                      bonCommande.statut,
                                                      style: TextStyle(
                                                        color: bonCommande.statut == 'validé' ? Colors.green : Colors.orange,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: 120,
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        IconButton(
                                                          icon: const Icon(CupertinoIcons.eye, color: Color(0xFF0E5A8A), size: 20),
                                                          onPressed: () => _showBonCommandeDetails(bonCommande),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      childCount: bonsCommande.length,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}