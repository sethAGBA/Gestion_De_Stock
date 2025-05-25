import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:stock_management/data/data_initializer.dart';
import 'package:stock_management/services/pdf_service.dart';
import 'package:excel/excel.dart' as excel;
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({Key? key}) : super(key: key);

  @override
  _InventoryScreenState createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  late Database _database;
  late Future<List<Produit>> _produitsFuture;
  String _searchQuery = '';
  List<Produit> _filteredProduits = [];
  bool _showEcart = false;
  final ScrollController _verticalScrollController = ScrollController();
  int _page = 0;
  final int _pageSize = 20;
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _produitsFuture = Future.value([]);
    _verticalScrollController.addListener(_scrollListener);
    _initDatabase().then((_) {
      setState(() {
        _produitsFuture = _getProducts(page: _page, pageSize: _pageSize);
        _produitsFuture.then((produits) {
          setState(() {
            _filteredProduits = produits;
            _hasMore = produits.length == _pageSize;
            print('Initial _filteredProduits set with ${produits.length} products, hasMore: $_hasMore');
          });
        });
      });
    }).catchError((e) {
      print('Erreur lors de l\'initialisation : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur d\'initialisation : $e')),
      );
    });
  }

  @override
  void dispose() {
    _verticalScrollController.removeListener(_scrollListener);
    _verticalScrollController.dispose();
    _database.close();
    super.dispose();
  }

  void _scrollListener() {
    if (_isLoading || !_hasMore) return;
    if (_verticalScrollController.position.pixels >=
        _verticalScrollController.position.maxScrollExtent * 0.8) {
      _loadMoreProducts();
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoading || !_hasMore) return;
    setState(() {
      _isLoading = true;
      print('Loading more products, page: ${_page + 1}');
    });
    final produits = await _getProducts(page: _page + 1, pageSize: _pageSize);
    setState(() {
      _page++;
      _filteredProduits.addAll(produits);
      _hasMore = produits.length == _pageSize;
      _isLoading = false;
      print('Loaded ${produits.length} more products, total: ${_filteredProduits.length}, hasMore: $_hasMore');
    });
  }

  Future<void> _initDatabase() async {
    print('Initialisation de la base de données pour InventoryScreen...');
    try {
      _database = await openDatabase(
        path.join(await getDatabasesPath(), 'dashboard.db'),
        version: 8,
        onCreate: (db, version) async {
          print('Création des tables...');
          await db.transaction((txn) async {
            await txn.execute('''
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
                quantiteInitiale INTEGER NOT NULL DEFAULT 0,
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
            await txn.execute('''
              CREATE TABLE IF NOT EXISTS unites (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                nom TEXT NOT NULL UNIQUE
              )
            ''');
            await txn.execute('''
              CREATE TABLE IF NOT EXISTS categories (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                nom TEXT NOT NULL UNIQUE
              )
            ''');
            await txn.execute('''
              CREATE TABLE IF NOT EXISTS suppliers (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                productName TEXT NOT NULL,
                category TEXT NOT NULL,
                price REAL NOT NULL
              )
            ''');
            await txn.execute('''
              CREATE TABLE IF NOT EXISTS users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                role TEXT NOT NULL,
                password TEXT NOT NULL
              )
            ''');
            await txn.execute('''
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
            await txn.execute('''
              CREATE TABLE IF NOT EXISTS clients (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                nom TEXT NOT NULL,
                email TEXT,
                telephone TEXT,
                adresse TEXT
              )
            ''');
            await txn.execute('''
              CREATE TABLE IF NOT EXISTS bons_commande (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                clientId INTEGER NOT NULL,
                date INTEGER NOT NULL,
                statut TEXT NOT NULL,
                FOREIGN KEY (clientId) REFERENCES clients(id)
              )
            ''');
            await txn.execute('''
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
            await txn.execute('''
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
            await txn.execute('''
              CREATE TABLE IF NOT EXISTS paiements (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                factureId INTEGER NOT NULL,
                montant REAL NOT NULL,
                date INTEGER NOT NULL,
                methode TEXT NOT NULL,
                FOREIGN KEY (factureId) REFERENCES factures(id)
              )
            ''');
            for (var unite in ['Pièce', 'Litre', 'kg', 'Boîte']) {
              await txn.insert('unites', {'nom': unite}, conflictAlgorithm: ConflictAlgorithm.ignore);
            }
            for (var categorie in ['Électronique', 'Vêtements', 'Alimentation', 'Autres']) {
              await txn.insert('categories', {'nom': categorie}, conflictAlgorithm: ConflictAlgorithm.ignore);
            }
            await DataInitializer.initializeDefaultData(db);
          });
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          print('Mise à jour de la base de données de $oldVersion à $newVersion...');
          await db.transaction((txn) async {
            if (oldVersion < 2) {
              await txn.execute('ALTER TABLE produits ADD COLUMN quantiteAvariee INTEGER NOT NULL DEFAULT 0');
            }
            if (oldVersion < 3) {
              await txn.execute('''
                CREATE TABLE IF NOT EXISTS historique_avaries (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  produitId INTEGER NOT NULL,
                  quantite INTEGER NOT NULL,
                  action TEXT NOT NULL,
                  utilisateur TEXT NOT NULL,
                  date INTEGER NOT NULL,
                  FOREIGN KEY (produitId) REFERENCES produits(id)
                )
              ''');
            }
            if (oldVersion < 4) {
              print('Migration vers version 4 : conversion des ID en INTEGER');
              await txn.execute('''
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
              await txn.execute('''
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
              await txn.execute('DROP TABLE produits');
              await txn.execute('ALTER TABLE produits_new RENAME TO produits');
            }
            if (oldVersion < 5) {
              print('Migration vers version 5 : ajout des tables pour facturation');
              await txn.execute('''
                CREATE TABLE IF NOT EXISTS clients (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  nom TEXT NOT NULL,
                  email TEXT,
                  telephone TEXT,
                  adresse TEXT
                )
              ''');
              await txn.execute('''
                CREATE TABLE IF NOT EXISTS bons_commande (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  clientId INTEGER NOT NULL,
                  date INTEGER NOT NULL,
                  statut TEXT NOT NULL,
                  FOREIGN KEY (clientId) REFERENCES clients(id)
                )
              ''');
              await txn.execute('''
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
              await txn.execute('''
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
              await txn.execute('''
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
              print('Migration vers version 6 : ajout des tables unites et categories');
              await txn.execute('''
                CREATE TABLE IF NOT EXISTS unites (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  nom TEXT NOT NULL UNIQUE
                )
              ''');
              await txn.execute('''
                CREATE TABLE IF NOT EXISTS categories (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  nom TEXT NOT NULL UNIQUE
                )
              ''');
              for (var unite in ['Pièce', 'Litre', 'kg', 'Boîte']) {
                await txn.insert('unites', {'nom': unite}, conflictAlgorithm: ConflictAlgorithm.ignore);
              }
              for (var categorie in ['Électronique', 'Vêtements', 'Alimentation', 'Autres']) {
                await txn.insert('categories', {'nom': categorie}, conflictAlgorithm: ConflictAlgorithm.ignore);
              }
              final produits = await txn.query('produits', columns: ['categorie'], distinct: true);
              for (var produit in produits) {
                if (produit['categorie'] != null) {
                  await txn.insert('categories', {'nom': produit['categorie']}, conflictAlgorithm: ConflictAlgorithm.ignore);
                }
              }
              final unites = await txn.query('produits', columns: ['unite'], distinct: true);
              for (var unite in unites) {
                if (unite['unite'] != null) {
                  await txn.insert('unites', {'nom': unite['unite']}, conflictAlgorithm: ConflictAlgorithm.ignore);
                }
              }
            }
            if (oldVersion < 7) {
              print('Migration vers version 7 : vérification des tables');
              await txn.execute('''
                CREATE TABLE IF NOT EXISTS unites (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  nom TEXT NOT NULL UNIQUE
                )
              ''');
              await txn.execute('''
                CREATE TABLE IF NOT EXISTS categories (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  nom TEXT NOT NULL UNIQUE
                )
              ''');
              for (var unite in ['Pièce', 'Litre', 'kg', 'Boîte']) {
                await txn.insert('unites', {'nom': unite}, conflictAlgorithm: ConflictAlgorithm.ignore);
              }
              for (var categorie in ['Électronique', 'Vêtements', 'Alimentation', 'Autres']) {
                await txn.insert('categories', {'nom': categorie}, conflictAlgorithm: ConflictAlgorithm.ignore);
              }
            }
            if (oldVersion < 8) {
              print('Migration vers version 8 : ajout de quantiteInitiale');
              final columns = await txn.rawQuery('PRAGMA table_info(produits)');
              bool hasQuantiteInitiale = columns.any((col) => col['name'] == 'quantiteInitiale');
              if (!hasQuantiteInitiale) {
                await txn.execute('ALTER TABLE produits ADD COLUMN quantiteInitiale INTEGER NOT NULL DEFAULT 0');
                await txn.execute('UPDATE produits SET quantiteInitiale = quantiteStock WHERE quantiteInitiale = 0');
                print('quantiteInitiale column added and initialized');
              } else {
                print('quantiteInitiale column already exists');
              }
            }
            await DataInitializer.initializeDefaultData(db);
          });
        },
        onOpen: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
          print('Clés étrangères activées');
          final version = await db.getVersion();
          print('Current database version: $version');
          try {
            final columns = await db.rawQuery('PRAGMA table_info(produits)');
            bool hasQuantiteInitiale = columns.any((col) => col['name'] == 'quantiteInitiale');
            if (!hasQuantiteInitiale) {
              print('Adding quantiteInitiale column in onOpen');
              await db.execute('ALTER TABLE produits ADD COLUMN quantiteInitiale INTEGER NOT NULL DEFAULT 0');
              await db.execute('UPDATE produits SET quantiteInitiale = quantiteStock WHERE quantiteInitiale = 0');
              print('quantiteInitiale column added and initialized');
            }
            print('Produits columns: ${columns.map((c) => c['name']).toList()}');
            final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
            print('Tables in database: ${tables.map((t) => t['name']).toList()}');
            final rowCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM produits'));
            print('Produits table has $rowCount rows');
          } catch (e) {
            print('Error in onOpen: $e');
          }
        },
      );
      print('Base de données initialisée avec succès, version: ${await _database.getVersion()}');
    } catch (e) {
      print('Erreur critique lors de l\'initialisation de la base de données : $e');
      rethrow;
    }
  }

  Future<List<Produit>> _getProducts({required int page, required int pageSize, String query = ''}) async {
    print('Récupération des produits, page: $page, pageSize: $pageSize, query: "$query"');
    try {
      List<Map<String, dynamic>> maps;
      if (query.isEmpty) {
        maps = await _database.query(
          'produits',
          limit: pageSize,
          offset: page * pageSize,
        );
      } else {
        final lowerQuery = query.toLowerCase();
        maps = await _database.query(
          'produits',
          where: '''
            LOWER(nom) LIKE ? OR 
            LOWER(categorie) LIKE ? OR 
            LOWER(fournisseurPrincipal) LIKE ? OR 
            LOWER(statut) LIKE ? OR 
            (quantiteAvariee > 0 AND ? LIKE '%avarié%') OR 
            (quantiteStock = 0 AND (? LIKE '%rupture%' OR ? LIKE '%out of stock%'))
          ''',
          whereArgs: [
            '%$lowerQuery%',
            '%$lowerQuery%',
            '%$lowerQuery%',
            '%$lowerQuery%',
            lowerQuery,
            lowerQuery,
            lowerQuery,
          ],
          limit: pageSize,
          offset: page * pageSize,
        );
      }
      final produits = List.generate(maps.length, (i) => Produit.fromMap(maps[i]));
      print('Produits récupérés : ${produits.length} pour page $page');
      return produits;
    } catch (e) {
      print('Erreur lors de la récupération des produits : $e');
      return [];
    }
  }

  Future<Map<int, Map<String, dynamic>>> _getSoldStockValues() async {
    try {
      final List<Map<String, dynamic>> maps = await _database.rawQuery('''
        SELECT 
          p.id,
          COALESCE(SUM(bci.quantite), 0) as quantiteVendue,
          COALESCE(SUM(bci.quantite * bci.prixUnitaire), 0) as valeurVendue
        FROM produits p
        LEFT JOIN bon_commande_items bci ON p.id = bci.produitId
        GROUP BY p.id
      ''');
      return {
        for (var map in maps)
          map['id']: {
            'quantiteVendue': map['quantiteVendue'],
            'valeurVendue': map['valeurVendue'],
          }
      };
    } catch (e) {
      print('Erreur lors de la récupération des valeurs vendues : $e');
      return {};
    }
  }

  Future<List<String>> _getCategories() async {
    try {
      final List<Map<String, dynamic>> maps = await _database.query('categories', columns: ['nom'], distinct: true);
      return maps.map((map) => map['nom'] as String).toList();
    } catch (e) {
      print('Erreur lors de la récupération des catégories : $e');
      return ['Électronique', 'Vêtements', 'Alimentation', 'Autres'];
    }
  }

  Future<void> _logAdjustment(int produitId, String produitNom, int quantiteStockChange, int quantiteAvarieeChange, String utilisateur) async {
    try {
      final log = DamagedAction(
        id: 0,
        produitId: produitId,
        produitNom: produitNom,
        quantite: quantiteStockChange != 0 ? quantiteStockChange : quantiteAvarieeChange,
        action: 'ajustement',
        utilisateur: utilisateur.isEmpty ? 'System' : utilisateur,
        date: DateTime.now().millisecondsSinceEpoch,
      );
      await _database.insert('historique_avaries', log.toMap());
      print('Ajustement enregistré dans historique_avaries pour produit $produitId');
    } catch (e) {
      print('Erreur lors de l\'enregistrement de l\'ajustement : $e');
    }
  }

  Future<void> _logDiscrepancy(int produitId, String produitNom, int ecart, String utilisateur) async {
    try {
      if (ecart != 0) {
        final log = DamagedAction(
          id: 0,
          produitId: produitId,
          produitNom: produitNom,
          quantite: ecart,
          action: 'écart_inventaire',
          utilisateur: utilisateur.isEmpty ? 'System' : utilisateur,
          date: DateTime.now().millisecondsSinceEpoch,
        );
        await _database.insert('historique_avaries', log.toMap());
        print('Écart enregistré dans historique_avaries pour produit $produitId: $ecart');
      }
    } catch (e) {
      print('Erreur lors de l\'enregistrement de l\'écart : $e');
    }
  }

  Future<void> _adjustStock(Produit produit) async {
    final formKey = GlobalKey<FormState>();
    int newQuantiteStock = produit.quantiteStock;
    int newQuantiteAvariee = produit.quantiteAvariee;
    int newQuantiteInitiale = produit.quantiteInitiale;

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Ajuster le stock : ${produit.nom}'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Stock initial : ${produit.quantiteInitiale}${produit.unite == 'kg' ? ' kg' : ''}'),
                Text('Stock actuel : ${produit.quantiteStock}${produit.unite == 'kg' ? ' kg' : ''}'),
                Text('Quantité avariée : ${produit.quantiteAvariee}${produit.unite == 'kg' ? ' kg' : ''}'),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: produit.quantiteInitiale.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Quantité initiale',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer une quantité';
                    }
                    final num = int.tryParse(value);
                    if (num == null) {
                      return 'Doit être un nombre';
                    }
                    if (num < 0) {
                      return 'La quantité ne peut pas être négative';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    newQuantiteInitiale = int.parse(value!);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: produit.quantiteStock.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Nouvelle quantité en stock',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer une quantité';
                    }
                    final num = int.tryParse(value);
                    if (num == null) {
                      return 'Doit être un nombre';
                    }
                    if (num < 0) {
                      return 'La quantité ne peut pas être négative';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    newQuantiteStock = int.parse(value!);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: produit.quantiteAvariee.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Nouvelle quantité avariée',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer une quantité';
                    }
                    final num = int.tryParse(value);
                    if (num == null) {
                      return 'Doit être un nombre';
                    }
                    if (num < 0) {
                      return 'La quantité ne peut pas être négative';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    newQuantiteAvariee = int.parse(value!);
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          Builder(
            builder: (builderContext) => TextButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  try {
                    await _database.update(
                      'produits',
                      {
                        'quantiteStock': newQuantiteStock,
                        'quantiteAvariee': newQuantiteAvariee,
                        'quantiteInitiale': newQuantiteInitiale,
                      },
                      where: 'id = ?',
                      whereArgs: [produit.id],
                    );
                    final quantiteStockChange = newQuantiteStock - produit.quantiteStock;
                    final quantiteAvarieeChange = newQuantiteAvariee - produit.quantiteAvariee;
                    final ecart = newQuantiteStock - newQuantiteInitiale;
                    if (quantiteStockChange != 0 || quantiteAvarieeChange != 0) {
                      await _logAdjustment(
                        produit.id,
                        produit.nom,
                        quantiteStockChange,
                        quantiteAvarieeChange,
                        'System',
                      );
                    }
                    if (ecart != 0) {
                      await _logDiscrepancy(
                        produit.id,
                        produit.nom,
                        ecart,
                        'System',
                      );
                    }
                    Navigator.pop(dialogContext);
                    setState(() {
                      _page = 0;
                      _hasMore = true;
                      _produitsFuture = _getProducts(page: _page, pageSize: _pageSize, query: _searchQuery);
                      _produitsFuture.then((produits) {
                        setState(() {
                          _filteredProduits = produits;
                          print('Filtered products refreshed with ${produits.length} products after stock adjustment');
                        });
                      });
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Stock ajusté avec succès')),
                    );
                  } catch (e) {
                    print('Erreur lors de l\'ajustement du stock : $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur lors de l\'ajustement : $e')),
                    );
                  }
                }
              },
              child: const Text('Confirmer'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showInventoryDialog() async {
    final produits = await _produitsFuture;
    final categories = await _getCategories();
    String? selectedCategory;
    Map<int, bool> selectedProducts = {for (var p in produits) p.id: false};
    bool isGlobal = true;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Inventaire Global ou Partiel'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Inventaire Global'),
                  leading: Radio<bool>(
                    value: true,
                    groupValue: isGlobal,
                    onChanged: (value) {
                      setDialogState(() {
                        isGlobal = value!;
                        selectedCategory = null;
                        selectedProducts = {for (var p in produits) p.id: false};
                      });
                    },
                  ),
                ),
                ListTile(
                  title: const Text('Inventaire Partiel'),
                  leading: Radio<bool>(
                    value: false,
                    groupValue: isGlobal,
                    onChanged: (value) {
                      setDialogState(() {
                        isGlobal = value!;
                      });
                    },
                  ),
                ),
                if (!isGlobal) ...[
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Catégorie',
                      border: OutlineInputBorder(),
                    ),
                    value: selectedCategory,
                    items: categories
                        .map((category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedCategory = value;
                        selectedProducts = {for (var p in produits) p.id: false};
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Sélectionner les produits :'),
                  ...produits
                      .where((p) => selectedCategory == null || p.categorie == selectedCategory)
                      .map((produit) => CheckboxListTile(
                            title: Text(produit.nom ?? 'N/A'),
                            value: selectedProducts[produit.id] ?? false,
                            onChanged: (value) {
                              setDialogState(() {
                                selectedProducts[produit.id] = value!;
                              });
                            },
                          ))
                      .toList(),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                List<Produit> selectedProduits = isGlobal
                    ? produits
                    : produits
                        .where((p) => selectedProducts[p.id] == true || (selectedCategory != null && p.categorie == selectedCategory))
                        .toList();
                if (selectedProduits.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Aucun produit sélectionné')),
                  );
                  return;
                }
                await _exportInventory(selectedProduits, isGlobal ? 'global' : 'partiel');
              },
              child: const Text('Exporter'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportInventory(List<Produit> produits, String type) async {
    try {
      if (produits.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucun produit à exporter')),
        );
        return;
      }

      final soldStockValues = await _getSoldStockValues();
      final items = produits
          .map((produit) => {
                'nom': produit.nom ?? 'N/A',
                'categorie': produit.categorie ?? 'N/A',
                'quantiteStock': produit.quantiteStock,
                'quantiteAvariee': produit.quantiteAvariee,
                'quantiteInitiale': produit.quantiteInitiale,
                'ecart': produit.quantiteStock - produit.quantiteInitiale,
                'stockValue': (produit.quantiteStock * produit.prixVente).toStringAsFixed(2),
                'soldValue': (soldStockValues[produit.id]?['valeurVendue'] ?? 0.0).toStringAsFixed(2),
                'prixVente': produit.prixVente,
                'unite': produit.unite ?? 'N/A',
              })
          .toList();

      print('Items for $type inventory export: $items');

      final totalStockValue = produits.fold<double>(
        0.0,
        (sum, produit) => sum + (produit.quantiteStock * produit.prixVente),
      );
      final totalSoldValue = produits.fold<double>(
        0.0,
        (sum, produit) => sum + (soldStockValues[produit.id]?['valeurVendue'] ?? 0.0),
      );

      final numero = 'INV-${DateTime.now().millisecondsSinceEpoch}';
      final date = DateTime.now();
      const utilisateurNom = '';
      const magasinAdresse = '';

      for (var produit in produits) {
        final ecart = produit.quantiteStock - produit.quantiteInitiale;
        if (ecart != 0) {
          await _logDiscrepancy(produit.id, produit.nom, ecart, 'System');
        }
      }

      final file = await PdfService.saveInventory(
        numero: numero,
        date: date,
        magasinAdresse: magasinAdresse,
        utilisateurNom: utilisateurNom,
        items: items,
        totalStockValue: totalStockValue,
        totalSoldValue: totalSoldValue,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Inventaire $type exporté en PDF : ${file.path}')),
      );

      await _exportInventoryToExcel(produits, type, numero, soldStockValues, totalStockValue, totalSoldValue);
    } catch (e) {
      print('Erreur lors de l\'exportation de l\'inventaire $type : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'exportation : $e')),
      );
    }
  }

  Future<void> _exportInventoryToExcel(
      List<Produit> produits, String type, String numero, Map<int, Map<String, dynamic>> soldStockValues, double totalStockValue, double totalSoldValue) async {
    try {
      if (produits.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucun produit à exporter')),
        );
        return;
      }

      var excelInstance = excel.Excel.createExcel();
      excel.Sheet sheet = excelInstance['Inventaire_$type'];

      sheet.appendRow([
        excel.TextCellValue('ID'),
        excel.TextCellValue('Nom'),
        excel.TextCellValue('Catégorie'),
        excel.TextCellValue('Stock Initial'),
        excel.TextCellValue('Stock'),
        excel.TextCellValue('Avarié'),
        excel.TextCellValue('Écart'),
        excel.TextCellValue('Valeur Stock (FCFA)'),
        excel.TextCellValue('Valeur Vendue (FCFA)'),
        excel.TextCellValue('Prix Vente (FCFA)'),
        excel.TextCellValue('Fournisseur'),
        excel.TextCellValue('Statut'),
      ]);

      for (var i = 0; i < produits.length; i++) {
        final produit = produits[i];
        final stockValue = (produit.quantiteStock * produit.prixVente).toStringAsFixed(2);
        final soldValue = (soldStockValues[produit.id]?['valeurVendue'] ?? 0.0).toStringAsFixed(2);
        final displayStatus = _getDisplayStatus(produit);
        final ecart = produit.quantiteStock - produit.quantiteInitiale;
        sheet.appendRow([
          excel.TextCellValue((i + 1).toString()),
          excel.TextCellValue(produit.nom ?? 'N/A'),
          excel.TextCellValue(produit.categorie ?? 'N/A'),
          excel.TextCellValue('${produit.quantiteInitiale}${produit.unite == 'kg' ? ' kg' : ''}'),
          excel.TextCellValue('${produit.quantiteStock}${produit.unite == 'kg' ? ' kg' : ''}'),
          excel.TextCellValue('${produit.quantiteAvariee}${produit.unite == 'kg' ? ' kg' : ''}'),
          excel.TextCellValue('$ecart${produit.unite == 'kg' ? ' kg' : ''}'),
          excel.TextCellValue(stockValue),
          excel.TextCellValue(soldValue),
          excel.TextCellValue(produit.prixVente.toStringAsFixed(2)),
          excel.TextCellValue(produit.fournisseurPrincipal ?? 'N/A'),
          excel.TextCellValue(displayStatus),
        ]);
      }

      sheet.appendRow([]);
      sheet.appendRow([
        excel.TextCellValue(''),
        excel.TextCellValue('Total'),
        excel.TextCellValue(''),
        excel.TextCellValue(''),
        excel.TextCellValue(''),
        excel.TextCellValue(''),
        excel.TextCellValue(''),
        excel.TextCellValue(totalStockValue.toStringAsFixed(2)),
        excel.TextCellValue(totalSoldValue.toStringAsFixed(2)),
        excel.TextCellValue(''),
        excel.TextCellValue(''),
        excel.TextCellValue(''),
      ]);

      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/inventaire_${type}_$numero.xlsx';
      final file = File(filePath);
      await file.writeAsBytes(excelInstance.encode()!);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Inventaire $type exporté en Excel : $filePath')),
      );
    } catch (e) {
      print('Erreur lors de l\'exportation Excel : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'exportation Excel : $e')),
      );
    }
  }

  Future<void> _toggleEcartDisplay() async {
    setState(() {
      _showEcart = !_showEcart;
      _page = 0;
      _hasMore = true;
      _produitsFuture = _getProducts(page: _page, pageSize: _pageSize, query: _searchQuery);
      _produitsFuture.then((produits) {
        setState(() {
          _filteredProduits = produits;
          print('Filtered products reset with ${produits.length} products after toggling ecart');
        });
      });
    });
  }

  Future<void> _exportInventoryToPdf() async {
    try {
      final produits = await _produitsFuture;
      if (produits.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucun produit à exporter')),
        );
        return;
      }
      await _exportInventory(produits, 'global');
    } catch (e) {
      print('Erreur lors de l\'exportation PDF : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'exportation PDF : $e')),
      );
    }
  }

  Future<void> _refreshProducts() async {
    setState(() {
      _page = 0;
      _hasMore = true;
      _searchQuery = '';
      _produitsFuture = _getProducts(page: _page, pageSize: _pageSize);
      _produitsFuture.then((produits) {
        setState(() {
          _filteredProduits = produits;
          print('Filtered products refreshed with ${produits.length} products after refresh');
        });
      });
    });
  }

  void _filterProduits(String query) {
    print('Filtering products with query: "$query"');
    setState(() {
      _searchQuery = query.trim();
      _page = 0;
      _hasMore = true;
      _filteredProduits = [];
      _produitsFuture = _getProducts(page: _page, pageSize: _pageSize, query: _searchQuery);
      _produitsFuture.then((produits) {
        setState(() {
          _filteredProduits = produits;
          _hasMore = produits.length == _pageSize;
          print('Filtered products: ${_filteredProduits.length}, hasMore: $_hasMore');
        });
      });
    });
  }

  Color _getStockColor(Produit produit) {
    if (produit.quantiteStock == 0) {
      return Colors.red.withOpacity(0.2);
    } else if (produit.quantiteAvariee > 0) {
      return Colors.red.withOpacity(0.1);
    } else if (produit.quantiteStock <= produit.stockMin) {
      return Colors.red.withOpacity(0.05);
    } else if (produit.quantiteStock <= produit.seuilAlerte) {
      return Colors.orange.withOpacity(0.05);
    }
    return Colors.transparent;
  }

  String _getDisplayStatus(Produit produit) {
    if (produit.quantiteStock == 0) {
      return 'En rupture';
    } else if (produit.quantiteAvariee > 0) {
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

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
      body: RefreshIndicator(
        onRefresh: _refreshProducts,
        color: const Color(0xFF0E5A8A),
        backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Inventaire',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : const Color(0xFF0A3049),
                    ),
                  ),
                  Row(
                    children: [
                      SizedBox(
                        width: 300,
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Rechercher un produit (inclut "avarié", "rupture")',
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
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _showInventoryDialog,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: const Color(0xFF0E5A8A),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Inventaire global/partiel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _exportInventoryToPdf,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: const Color(0xFF0E5A8A),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Exporter PDF'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          final produits = await _produitsFuture;
                          if (produits.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Aucun produit à exporter')),
                            );
                            return;
                          }
                          final numero = 'INV-${DateTime.now().millisecondsSinceEpoch}';
                          final soldStockValues = await _getSoldStockValues();
                          final totalStockValue = produits.fold<double>(
                            0.0,
                            (sum, produit) => sum + (produit.quantiteStock * produit.prixVente),
                          );
                          final totalSoldValue = produits.fold<double>(
                            0.0,
                            (sum, produit) => sum + (soldStockValues[produit.id]?['valeurVendue'] ?? 0.0),
                          );
                          await _exportInventoryToExcel(produits, 'global', numero, soldStockValues, totalStockValue, totalSoldValue);
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: const Color(0xFF0E5A8A),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Exporter Excel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _toggleEcartDisplay,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: const Color(0xFF0E5A8A),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(_showEcart ? 'Masquer écarts' : 'Afficher écarts'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FutureBuilder<Map<int, Map<String, dynamic>>>(
                future: _getSoldStockValues(),
                builder: (context, soldSnapshot) {
                  print('SoldStockValues FutureBuilder state: ${soldSnapshot.connectionState}');
                  if (soldSnapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox();
                  }
                  if (soldSnapshot.hasError) {
                    print('Erreur dans SoldStockValues FutureBuilder : ${soldSnapshot.error}');
                    return Text('Erreur : ${soldSnapshot.error}');
                  }
                  final soldStockValues = soldSnapshot.data ?? {};
                  return FutureBuilder<List<Produit>>(
                    future: _produitsFuture,
                    builder: (context, produitSnapshot) {
                      print('Produits FutureBuilder state: ${produitSnapshot.connectionState}, hasData: ${produitSnapshot.hasData}, hasError: ${produitSnapshot.hasError}');
                      if (produitSnapshot.connectionState == ConnectionState.waiting && _filteredProduits.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (produitSnapshot.hasError) {
                        print('Erreur dans Produits FutureBuilder : ${produitSnapshot.error}');
                        return Center(child: Text('Erreur : ${produitSnapshot.error}'));
                      }
                      final produits = produitSnapshot.data ?? [];
                      print('Produits loaded: ${produits.length}, filtered: ${_filteredProduits.length}');
                      final totalStockValue = _filteredProduits.fold<double>(
                        0.0,
                        (sum, produit) => sum + (produit.quantiteStock * produit.prixVente),
                      );
                      final totalSoldValue = _filteredProduits.fold<double>(
                        0.0,
                        (sum, produit) => sum + (soldStockValues[produit.id]?['valeurVendue'] ?? 0.0),
                      );
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Valeur totale du stock : ${totalStockValue.toStringAsFixed(2)} FCFA',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode ? Colors.green.shade300 : Colors.green.shade700,
                                ),
                              ),
                              const SizedBox(width: 24),
                              Text(
                                'Valeur totale vendue : ${totalSoldValue.toStringAsFixed(2)} FCFA',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.7,
                            child: _filteredProduits.isNotEmpty
                                ? Scrollbar(
                                    controller: _verticalScrollController,
                                    thumbVisibility: true,
                                    child: SingleChildScrollView(
                                      controller: _verticalScrollController,
                                      scrollDirection: Axis.vertical,
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(
                                            minWidth: 1600,
                                          ),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(10),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: isDarkMode ? Colors.black26 : Colors.grey.withOpacity(0.1),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(10),
                                              child: DataTable(
                                                columnSpacing: 24.0,
                                                horizontalMargin: 16.0,
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
                                                columns: [
                                                  const DataColumn(label: Text('ID')),
                                                  const DataColumn(label: Text('Image')),
                                                  const DataColumn(label: Text('Nom')),
                                                  const DataColumn(label: Text('Catégorie')),
                                                  const DataColumn(label: Text('Stock Initial')),
                                                  const DataColumn(label: Text('Stock')),
                                                  const DataColumn(label: Text('Avarié')),
                                                  if (_showEcart) const DataColumn(label: Text('Écart')),
                                                  const DataColumn(label: Text('Valeur Stock')),
                                                  const DataColumn(label: Text('Valeur Vendue')),
                                                  const DataColumn(label: Text('Prix Vente')),
                                                  const DataColumn(label: Text('Fournisseur')),
                                                  const DataColumn(label: Text('Statut')),
                                                  const DataColumn(label: Text('Actions')),
                                                ],
                                                rows: [
                                                  ..._filteredProduits.asMap().entries.map(
                                                        (entry) {
                                                          final int index = entry.key;
                                                          final Produit produit = entry.value;
                                                          final String displayStatus = _getDisplayStatus(produit);
                                                          final stockValue = (produit.quantiteStock * produit.prixVente).toStringAsFixed(2);
                                                          final soldValue = (soldStockValues[produit.id]?['valeurVendue'] ?? 0.0).toStringAsFixed(2);
                                                          final ecart = produit.quantiteStock - produit.quantiteInitiale;
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
                                                                  '${produit.quantiteInitiale}${produit.unite == 'kg' ? ' kg' : ''}',
                                                                  style: theme.textTheme.bodyMedium,
                                                                ),
                                                              ),
                                                              DataCell(
                                                                Text(
                                                                  '${produit.quantiteStock}${produit.unite == 'kg' ? ' kg' : ''}',
                                                                  style: theme.textTheme.bodyMedium?.copyWith(
                                                                    color: produit.quantiteStock == 0
                                                                        ? Colors.red.shade500
                                                                        : produit.quantiteStock <= produit.stockMin
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
                                                              if (_showEcart)
                                                                DataCell(
                                                                  Text(
                                                                    '$ecart${produit.unite == 'kg' ? ' kg' : ''}',
                                                                    style: theme.textTheme.bodyMedium?.copyWith(
                                                                      color: ecart < 0
                                                                          ? Colors.red.shade500
                                                                          : ecart > 0
                                                                              ? Colors.green.shade500
                                                                              : null,
                                                                      fontWeight: ecart != 0 ? FontWeight.w600 : null,
                                                                    ),
                                                                  ),
                                                                ),
                                                              DataCell(
                                                                Text(
                                                                  '$stockValue FCFA',
                                                                  style: theme.textTheme.bodyMedium?.copyWith(
                                                                    color: isDarkMode ? Colors.green.shade300 : Colors.green.shade700,
                                                                    fontWeight: FontWeight.w500,
                                                                  ),
                                                                ),
                                                              ),
                                                              DataCell(
                                                                Text(
                                                                  '$soldValue FCFA',
                                                                  style: theme.textTheme.bodyMedium?.copyWith(
                                                                    color: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700,
                                                                    fontWeight: FontWeight.w500,
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
                                                                                  : displayStatus == 'En rupture'
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
                                                                          : displayStatus == 'Contient avariés'
                                                                              ? isDarkMode
                                                                                  ? Colors.red.shade900.withOpacity(0.3)
                                                                                  : Colors.red.shade100
                                                                              : displayStatus == 'En rupture'
                                                                                  ? isDarkMode
                                                                                      ? Colors.red.shade900.withOpacity(0.3)
                                                                                      : Colors.red.shade100
                                                                                  : isDarkMode
                                                                                      ? Colors.red.shade900.withOpacity(0.3)
                                                                                      : Colors.red.shade100,
                                                                  shape: RoundedRectangleBorder(
                                                                    borderRadius: BorderRadius.circular(8),
                                                                  ),
                                                                ),
                                                              ),
                                                              DataCell(
                                                                IconButton(
                                                                  icon: const Icon(Icons.edit, color: Color(0xFF0E5A8A)),
                                                                  onPressed: () => _adjustStock(produit),
                                                                ),
                                                              ),
                                                            ],
                                                          );
                                                        },
                                                      ),
                                                  if (_isLoading)
                                                    DataRow(
                                                      cells: List.generate(
                                                        _showEcart ? 14 : 13,
                                                        (index) => DataCell(
                                                          index == 0
                                                              ? const Center(child: CircularProgressIndicator())
                                                              : const SizedBox(),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _searchQuery.isNotEmpty ? Icons.search_off : Icons.inventory_2_outlined,
                                          size: 48,
                                          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          _searchQuery.isNotEmpty
                                              ? 'Aucun produit trouvé pour cette recherche'
                                              : 'Aucun produit disponible',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}