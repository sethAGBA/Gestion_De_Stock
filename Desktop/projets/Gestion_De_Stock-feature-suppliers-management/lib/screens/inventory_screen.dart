import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:stock_management/data/data_initializer.dart';
import 'package:stock_management/services/pdf_service.dart';
import 'package:excel/excel.dart' as excel;
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import '../models/models.dart';
import '../providers/auth_provider.dart';

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
  final ScrollController _horizontalScrollController = ScrollController();
  int _page = 0;
  final int _pageSize = 15;
  bool _isLoading = false;
  bool _hasMore = true;
  int _totalProduits = 0;
  User? _currentUser;

  void _scrollListener() {
    // Listener conservé pour éviter les callbacks résiduels après hot reload.
  }

  void _loadProducts({int page = 0}) {
    setState(() {
      _isLoading = true;
      _page = page;
      _produitsFuture = _getProducts(
        page: page,
        pageSize: _pageSize,
        query: _searchQuery,
      );
    });
    _countProducts(query: _searchQuery)
        .then((total) {
          if (!mounted) return;
          setState(() {
            _totalProduits = total;
          });
        })
        .catchError(
          (error) => print('Erreur lors du comptage des produits : $error'),
        );
    _produitsFuture
        .then((produits) {
          if (!mounted) return;
          setState(() {
            _filteredProduits = produits;
            _hasMore = produits.length == _pageSize;
          });
        })
        .catchError((error) {
          print('Erreur lors du chargement des produits : $error');
        })
        .whenComplete(() {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
          });
    });
  }

  String get _currentUserName => _currentUser?.name ?? 'Utilisateur';

  void _goToPreviousPage() {
    if (_page == 0 || _isLoading) return;
    _loadProducts(page: _page - 1);
  }

  void _goToNextPage() {
    if (!_hasMore || _isLoading) return;
    _loadProducts(page: _page + 1);
  }

  Widget _buildPaginationControls(ThemeData theme, bool isDarkMode) {
    final totalPages =
        _totalProduits == 0 ? 0 : ((_totalProduits + _pageSize - 1) ~/ _pageSize);
    final currentPage = _totalProduits == 0 ? 0 : _page + 1;
    String rangeText = 'Aucun produit';
    if (_filteredProduits.isNotEmpty && _totalProduits > 0) {
      final start = _page * _pageSize + 1;
      final end = start + _filteredProduits.length - 1;
      rangeText = 'Produits $start-$end sur $_totalProduits';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Page $currentPage/$totalPages · $rangeText',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
          ),
        ),
        const SizedBox(width: 16),
        OutlinedButton.icon(
          onPressed: (_page == 0 || _isLoading) ? null : _goToPreviousPage,
          icon: const Icon(Icons.chevron_left),
          label: const Text('Précédent'),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: (!_hasMore || _isLoading) ? null : _goToNextPage,
          icon: const Icon(Icons.chevron_right),
          label: const Text('Suivant'),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _produitsFuture = Future.value([]);
    _initDatabase()
        .then((_) {
          if (!mounted) return;
          _loadProducts(page: 0);
        })
        .catchError((e) {
          print('Erreur lors de l\'initialisation : $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur d\'initialisation : $e')),
          );
        });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
      setState(() {
        _currentUser = user;
      });
    });
  }

  @override
  void dispose() {
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    _database.close();
    super.dispose();
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
                quantite REAL NOT NULL,
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
              await txn.insert('unites', {
                'nom': unite,
              }, conflictAlgorithm: ConflictAlgorithm.ignore);
            }
            for (var categorie in [
              'Électronique',
              'Vêtements',
              'Alimentation',
              'Autres',
            ]) {
              await txn.insert('categories', {
                'nom': categorie,
              }, conflictAlgorithm: ConflictAlgorithm.ignore);
            }
            await DataInitializer.initializeDefaultData(db);
          });
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          print(
            'Mise à jour de la base de données de $oldVersion à $newVersion...',
          );
          await db.transaction((txn) async {
            if (oldVersion < 2) {
              await txn.execute(
                'ALTER TABLE produits ADD COLUMN quantiteAvariee INTEGER NOT NULL DEFAULT 0',
              );
            }
            if (oldVersion < 3) {
              await txn.execute('''
                CREATE TABLE IF NOT EXISTS historique_avaries (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  produitId INTEGER NOT NULL,
                  quantite REAL NOT NULL,
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
              print(
                'Migration vers version 5 : ajout des tables pour facturation',
              );
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
              print(
                'Migration vers version 6 : ajout des tables unites et categories',
              );
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
                await txn.insert('unites', {
                  'nom': unite,
                }, conflictAlgorithm: ConflictAlgorithm.ignore);
              }
              for (var categorie in [
                'Électronique',
                'Vêtements',
                'Alimentation',
                'Autres',
              ]) {
                await txn.insert('categories', {
                  'nom': categorie,
                }, conflictAlgorithm: ConflictAlgorithm.ignore);
              }
              final produits = await txn.query(
                'produits',
                columns: ['categorie'],
                distinct: true,
              );
              for (var produit in produits) {
                if (produit['categorie'] != null) {
                  await txn.insert('categories', {
                    'nom': produit['categorie'],
                  }, conflictAlgorithm: ConflictAlgorithm.ignore);
                }
              }
              final unites = await txn.query(
                'produits',
                columns: ['unite'],
                distinct: true,
              );
              for (var unite in unites) {
                if (unite['unite'] != null) {
                  await txn.insert('unites', {
                    'nom': unite['unite'],
                  }, conflictAlgorithm: ConflictAlgorithm.ignore);
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
                await txn.insert('unites', {
                  'nom': unite,
                }, conflictAlgorithm: ConflictAlgorithm.ignore);
              }
              for (var categorie in [
                'Électronique',
                'Vêtements',
                'Alimentation',
                'Autres',
              ]) {
                await txn.insert('categories', {
                  'nom': categorie,
                }, conflictAlgorithm: ConflictAlgorithm.ignore);
              }
            }
            if (oldVersion < 8) {
              print('Migration vers version 8 : ajout de quantiteInitiale');
              final columns = await txn.rawQuery('PRAGMA table_info(produits)');
              bool hasQuantiteInitiale = columns.any(
                (col) => col['name'] == 'quantiteInitiale',
              );
              if (!hasQuantiteInitiale) {
                await txn.execute(
                  'ALTER TABLE produits ADD COLUMN quantiteInitiale INTEGER NOT NULL DEFAULT 0',
                );
                await txn.execute(
                  'UPDATE produits SET quantiteInitiale = quantiteStock WHERE quantiteInitiale = 0',
                );
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
            bool hasQuantiteInitiale = columns.any(
              (col) => col['name'] == 'quantiteInitiale',
            );
            if (!hasQuantiteInitiale) {
              print('Adding quantiteInitiale column in onOpen');
              await db.execute(
                'ALTER TABLE produits ADD COLUMN quantiteInitiale INTEGER NOT NULL DEFAULT 0',
              );
              await db.execute(
                'UPDATE produits SET quantiteInitiale = quantiteStock WHERE quantiteInitiale = 0',
              );
              print('quantiteInitiale column added and initialized');
            }
            print(
              'Produits columns: ${columns.map((c) => c['name']).toList()}',
            );
            final tables = await db.rawQuery(
              "SELECT name FROM sqlite_master WHERE type='table'",
            );
            print(
              'Tables in database: ${tables.map((t) => t['name']).toList()}',
            );
            final rowCount = Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM produits'),
            );
            print('Produits table has $rowCount rows');
          } catch (e) {
            print('Error in onOpen: $e');
          }
        },
      );
      print(
        'Base de données initialisée avec succès, version: ${await _database.getVersion()}',
      );
    } catch (e) {
      print(
        'Erreur critique lors de l\'initialisation de la base de données : $e',
      );
      rethrow;
    }
  }

  Future<List<Produit>> _getProducts({
    required int page,
    required int pageSize,
    String query = '',
  }) async {
    print(
      'Récupération des produits, page: $page, pageSize: $pageSize, query: "$query"',
    );
    try {
      List<Map<String, dynamic>> maps;
      final offset = page * pageSize;
      if (query.isEmpty) {
        maps = await _database.query(
          'produits',
          limit: pageSize,
          offset: offset,
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
          offset: offset,
        );
      }
      final produits = List.generate(
        maps.length,
        (i) => Produit.fromMap(maps[i]),
      );
      print('Produits récupérés : ${produits.length} pour page $page');
      return produits;
    } catch (e) {
      print('Erreur lors de la récupération des produits : $e');
      return [];
    }
  }

  Future<int> _countProducts({String query = ''}) async {
    try {
      if (query.isEmpty) {
        final countResult = await _database.rawQuery(
          'SELECT COUNT(*) as total FROM produits',
        );
        return _extractCount(countResult);
      }

      final lowerQuery = query.toLowerCase();
      final countResult = await _database.rawQuery(
        '''
        SELECT COUNT(*) as total FROM produits
        WHERE
          LOWER(nom) LIKE ? OR
          LOWER(categorie) LIKE ? OR
          LOWER(fournisseurPrincipal) LIKE ? OR
          LOWER(statut) LIKE ? OR
          (quantiteAvariee > 0 AND ? LIKE '%avarié%') OR
          (quantiteStock = 0 AND (? LIKE '%rupture%' OR ? LIKE '%out of stock%'))
        ''',
        [
          '%$lowerQuery%',
          '%$lowerQuery%',
          '%$lowerQuery%',
          '%$lowerQuery%',
          lowerQuery,
          lowerQuery,
          lowerQuery,
        ],
      );
      return _extractCount(countResult);
    } catch (e) {
      print('Erreur lors du comptage des produits : $e');
      return 0;
    }
  }

  int _extractCount(List<Map<String, Object?>> result) {
    if (result.isEmpty) return 0;
    final value = result.first['total'];
    if (value is int) return value;
    if (value is BigInt) return value.toInt();
    if (value is num) return value.toInt();
    return 0;
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
          },
      };
    } catch (e) {
      print('Erreur lors de la récupération des valeurs vendues : $e');
      return {};
    }
  }

  Future<List<String>> _getCategories() async {
    try {
      final List<Map<String, dynamic>> maps = await _database.query(
        'categories',
        columns: ['nom'],
        distinct: true,
      );
      return maps.map((map) => map['nom'] as String).toList();
    } catch (e) {
      print('Erreur lors de la récupération des catégories : $e');
      return ['Électronique', 'Vêtements', 'Alimentation', 'Autres'];
    }
  }

  Future<void> _logAdjustment(
    int produitId,
    String produitNom,
    double quantiteStockChange,
    double quantiteAvarieeChange,
    String utilisateur,
  ) async {
    try {
      final log = DamagedAction(
        id: 0,
        produitId: produitId,
        produitNom: produitNom,
        quantite: quantiteStockChange != 0.0
            ? quantiteStockChange
            : quantiteAvarieeChange,
        action: 'ajustement',
        utilisateur: utilisateur.isEmpty ? 'System' : utilisateur,
        date: DateTime.now().millisecondsSinceEpoch,
      );
      await _database.insert('historique_avaries', log.toMap());
      print(
        'Ajustement enregistré dans historique_avaries pour produit $produitId',
      );
    } catch (e) {
      print('Erreur lors de l\'enregistrement de l\'ajustement : $e');
    }
  }

  Future<void> _logDiscrepancy(
    int produitId,
    String produitNom,
    double ecart,
    String utilisateur,
  ) async {
    try {
      if (ecart != 0.0) {
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
        print(
          'Écart enregistré dans historique_avaries pour produit $produitId: $ecart',
        );
      }
    } catch (e) {
      print('Erreur lors de l\'enregistrement de l\'écart : $e');
    }
  }

  double? _parseDoubleLocale(String? input) {
    if (input == null) return null;
    final normalized = input.replaceAll(' ', '').replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  String _fmtQty(num value, String unite) {
    final pattern = unite.toLowerCase() == 'kg' ? '#,##0.###' : '#,##0.##';
    final nf = NumberFormat(pattern, 'fr_FR');
    final s = nf.format(value);
    return unite.toLowerCase() == 'kg' ? '$s kg' : s;
  }

  Future<void> _adjustStock(Produit produit) async {
    final formKey = GlobalKey<FormState>();
    double newQuantiteStock = produit.quantiteStock;
    double newQuantiteAvariee = produit.quantiteAvariee;
    double newQuantiteInitiale = produit.quantiteInitiale;

    await showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text('Ajuster le stock : ${produit.nom}'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Stock initial : ${_fmtQty(produit.quantiteInitiale, produit.unite)}'),
                    Text('Stock actuel : ${_fmtQty(produit.quantiteStock, produit.unite)}'),
                    Text('Quantité avariée : ${_fmtQty(produit.quantiteAvariee, produit.unite)}'),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: produit.quantiteInitiale.toString(),
                      decoration: const InputDecoration(
                        labelText: 'Quantité initiale',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer une quantité';
                        }
                        final num = _parseDoubleLocale(value);
                        if (num == null) {
                          return 'Doit être un nombre';
                        }
                        if (num < 0) {
                          return 'La quantité ne peut pas être négative';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        newQuantiteInitiale = _parseDoubleLocale(value)!;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: produit.quantiteStock.toString(),
                      decoration: const InputDecoration(
                        labelText: 'Nouvelle quantité en stock',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer une quantité';
                        }
                        final num = _parseDoubleLocale(value);
                        if (num == null) {
                          return 'Doit être un nombre';
                        }
                        if (num < 0) {
                          return 'La quantité ne peut pas être négative';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        newQuantiteStock = _parseDoubleLocale(value)!;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: produit.quantiteAvariee.toString(),
                      decoration: const InputDecoration(
                        labelText: 'Nouvelle quantité avariée',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer une quantité';
                        }
                        final num = _parseDoubleLocale(value);
                        if (num == null) {
                          return 'Doit être un nombre';
                        }
                        if (num < 0) {
                          return 'La quantité ne peut pas être négative';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        newQuantiteAvariee = _parseDoubleLocale(value)!;
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
                builder:
                    (builderContext) => TextButton(
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
                            if (quantiteStockChange != 0.0 || quantiteAvarieeChange != 0.0) {
                              await _logAdjustment(
                                produit.id,
                                produit.nom,
                                quantiteStockChange,
                                quantiteAvarieeChange,
                                _currentUserName,
                              );
                            }
                            if (ecart != 0.0) {
                              await _logDiscrepancy(
                                produit.id,
                                produit.nom,
                                ecart,
                                _currentUserName,
                              );
                            }
                            Navigator.pop(dialogContext);
                            _loadProducts(page: _page);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Stock ajusté avec succès'),
                              ),
                            );
                          } catch (e) {
                            print('Erreur lors de l\'ajustement du stock : $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Erreur lors de l\'ajustement : $e',
                                ),
                              ),
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
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
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
                                selectedProducts = {
                                  for (var p in produits) p.id: false,
                                };
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
                            items:
                                categories
                                    .map(
                                      (category) => DropdownMenuItem(
                                        value: category,
                                        child: Text(category),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (value) {
                              setDialogState(() {
                                selectedCategory = value;
                                selectedProducts = {
                                  for (var p in produits) p.id: false,
                                };
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          const Text('Sélectionner les produits :'),
                          ...produits
                              .where(
                                (p) =>
                                    selectedCategory == null ||
                                    p.categorie == selectedCategory,
                              )
                              .map(
                                (produit) => CheckboxListTile(
                                  title: Text(produit.nom ?? 'N/A'),
                                  value: selectedProducts[produit.id] ?? false,
                                  onChanged: (value) {
                                    setDialogState(() {
                                      selectedProducts[produit.id] = value!;
                                    });
                                  },
                                ),
                              )
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
                        List<Produit> selectedProduits =
                            isGlobal
                                ? produits
                                : produits
                                    .where(
                                      (p) =>
                                          selectedProducts[p.id] == true ||
                                          (selectedCategory != null &&
                                              p.categorie == selectedCategory),
                                    )
                                    .toList();
                        if (selectedProduits.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Aucun produit sélectionné'),
                            ),
                          );
                          return;
                        }
                        await _exportInventory(
                          selectedProduits,
                          isGlobal ? 'global' : 'partiel',
                        );
                      },
                      child: const Text('Exporter'),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<String?> _pickSaveDirectory() async {
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

  Future<void> _openFile(String filePath) async {
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

  Future<void> _exportInventory(List<Produit> produits, String type) async {
    try {
      if (produits.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucun produit à exporter')),
        );
        return;
      }

      final directoryPath = await _pickSaveDirectory();
      if (directoryPath == null) {
        return;
      }

      final soldStockValues = await _getSoldStockValues();
      final items =
          produits
              .map(
                (produit) => {
                  'nom': produit.nom ?? 'N/A',
                  'categorie': produit.categorie ?? 'N/A',
                  'quantiteStock': produit.quantiteStock,
                  'quantiteAvariee': produit.quantiteAvariee,
                  'quantiteInitiale': produit.quantiteInitiale,
                  'ecart': produit.quantiteStock - produit.quantiteInitiale,
                  'stockValue': (produit.quantiteStock * produit.prixVente)
                      .toStringAsFixed(2),
                  'soldValue': (soldStockValues[produit.id]?['valeurVendue'] ??
                          0.0)
                      .toStringAsFixed(2),
                  'prixVente': produit.prixVente,
                  'unite': produit.unite ?? 'N/A',
                },
              )
              .toList();

      print('Items for $type inventory export: $items');

      final totalStockValue = produits.fold<double>(
        0.0,
        (sum, produit) => sum + (produit.quantiteStock * produit.prixVente),
      );
      final totalSoldValue = produits.fold<double>(
        0.0,
        (sum, produit) =>
            sum + (soldStockValues[produit.id]?['valeurVendue'] ?? 0.0),
      );

      final numero = 'INV-${DateTime.now().millisecondsSinceEpoch}';
      final date = DateTime.now();
      final utilisateurNom = _currentUserName;
      const magasinAdresse = '';

      for (var produit in produits) {
        final ecart = produit.quantiteStock - produit.quantiteInitiale;
        if (ecart != 0) {
          await _logDiscrepancy(
            produit.id,
            produit.nom,
            ecart,
            _currentUserName,
          );
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

      final pdfTargetPath = path.join(
        directoryPath,
        path.basename(file.path),
      );
      final targetPdf = await File(pdfTargetPath).create(recursive: true);
      await targetPdf.writeAsBytes(await file.readAsBytes());
      if (await file.exists()) {
        await file.delete();
      }

      await _openFile(pdfTargetPath);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Inventaire $type exporté en PDF : $pdfTargetPath'),
        ),
      );

      await _exportInventoryToExcel(
        produits,
        type,
        numero,
        soldStockValues,
        totalStockValue,
        totalSoldValue,
        directoryPath: directoryPath,
      );
    } catch (e) {
      print('Erreur lors de l\'exportation de l\'inventaire $type : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'exportation : $e')),
      );
    }
  }

  Future<void> _exportInventoryToExcel(
    List<Produit> produits,
    String type,
    String numero,
    Map<int, Map<String, dynamic>> soldStockValues,
    double totalStockValue,
    double totalSoldValue,
    {required String directoryPath}
  ) async {
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
        final stockValue = (produit.quantiteStock * produit.prixVente)
            .toStringAsFixed(2);
        final soldValue = (soldStockValues[produit.id]?['valeurVendue'] ?? 0.0)
            .toStringAsFixed(2);
        final displayStatus = _getDisplayStatus(produit);
        final ecart = produit.quantiteStock - produit.quantiteInitiale;
        sheet.appendRow([
          excel.TextCellValue((i + 1).toString()),
          excel.TextCellValue(produit.nom ?? 'N/A'),
          excel.TextCellValue(produit.categorie ?? 'N/A'),
          excel.TextCellValue(_fmtQty(produit.quantiteInitiale, produit.unite)),
          excel.TextCellValue(_fmtQty(produit.quantiteStock, produit.unite)),
          excel.TextCellValue(_fmtQty(produit.quantiteAvariee, produit.unite)),
          excel.TextCellValue(_fmtQty(ecart, produit.unite)),
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

      final filePath = path.join(
        directoryPath,
        'inventaire_${type}_$numero.xlsx',
      );
      final file = File(filePath);
      await file.writeAsBytes(excelInstance.encode()!);

      await _openFile(filePath);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Inventaire $type exporté en Excel : $filePath'),
        ),
      );
    } catch (e) {
      print('Erreur lors de l\'exportation Excel : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'exportation Excel : $e')),
      );
    }
  }

  void _toggleEcartDisplay() {
    setState(() {
      _showEcart = !_showEcart;
    });
    _loadProducts(page: 0);
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
    _loadProducts(page: 0);
  }

  void _filterProduits(String query) {
    print('Filtering products with query: "$query"');
    setState(() {
      _searchQuery = query.trim();
    });
    _loadProducts(page: 0);
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

  Widget _buildSearchField(bool isDarkMode) {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Rechercher un produit (inclut "avarié", "rupture")',
        prefixIcon: Icon(
          Icons.search,
          color: isDarkMode ? Colors.white : Colors.grey.shade600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        filled: true,
        fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
      ),
      onChanged: _filterProduits,
    );
  }

  Widget _buildActionSection(
    String title,
    ThemeData theme,
    List<Widget> buttons,
  ) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 220),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: buttons,
          ),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          // removed outer padding so the table card can extend to the page edges
          padding: EdgeInsets.zero,
          child: SingleChildScrollView(
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
                        color:
                            isDarkMode ? Colors.white : const Color(0xFF0A3049),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 900;

                    if (isCompact) {
                      return SizedBox(
                        width: double.infinity,
                        child: _buildSearchField(isDarkMode),
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: _buildSearchField(isDarkMode),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 24,
                  runSpacing: 16,
                  crossAxisAlignment: WrapCrossAlignment.start,
                  children: [
                    _buildActionSection(
                      'Inventaire',
                      theme,
                      [
                        ElevatedButton.icon(
                          onPressed: _showInventoryDialog,
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: const Color(0xFF0E5A8A),
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.list_alt_rounded),
                          label: const Text('Inventaire global/partiel'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _refreshProducts,
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.teal.shade600,
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Actualiser'),
                        ),
                      ],
                    ),
                    _buildActionSection(
                      'Exports',
                      theme,
                      [
                        ElevatedButton(
                          onPressed: _exportInventoryToPdf,
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: const Color(0xFF0E5A8A),
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Exporter PDF'),
                        ),
                      ElevatedButton(
                        onPressed: () async {
                          final produits = await _produitsFuture;
                          if (produits.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Aucun produit à exporter'),
                              ),
                            );
                            return;
                          }
                          final directoryPath = await _pickSaveDirectory();
                          if (directoryPath == null) {
                            return;
                          }
                          final numero =
                              'INV-${DateTime.now().millisecondsSinceEpoch}';
                          final soldStockValues = await _getSoldStockValues();
                          final totalStockValue = produits.fold<double>(
                            0.0,
                              (sum, produit) =>
                                  sum +
                                  (produit.quantiteStock * produit.prixVente),
                            );
                          final totalSoldValue = produits.fold<double>(
                            0.0,
                            (sum, produit) =>
                                sum +
                                (soldStockValues[produit.id]?['valeurVendue'] ??
                                    0.0),
                          );
                          await _exportInventoryToExcel(
                            produits,
                            'global',
                            numero,
                            soldStockValues,
                            totalStockValue,
                            totalSoldValue,
                            directoryPath: directoryPath,
                          );
                        },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: const Color(0xFF0E5A8A),
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Exporter Excel'),
                        ),
                      ],
                    ),
                    _buildActionSection(
                      'Analyse',
                      theme,
                      [
                        ElevatedButton.icon(
                          onPressed: _toggleEcartDisplay,
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor:
                                _showEcart
                                    ? Colors.orange.shade600
                                    : const Color(0xFF0E5A8A),
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: Icon(
                            _showEcart
                                ? Icons.visibility_off_outlined
                                : Icons.insights_outlined,
                          ),
                          label: Text(
                            _showEcart
                                ? 'Masquer les écarts'
                                : 'Afficher les écarts',
                          ),
                        ),
                      ],
                    ),
                    if (_filteredProduits.length == 1)
                      _buildActionSection(
                        'Produit sélectionné',
                        theme,
                        [
                          ElevatedButton(
                            onPressed: () async {
                              await _exportInventory([
                                _filteredProduits.first,
                              ], 'produit');
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: const Color(0xFF0E5A8A),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Exporter ce produit (PDF)'),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              final produit = _filteredProduits.first;
                              final soldStockValues =
                                  await _getSoldStockValues();
                              final totalStockValue =
                                  produit.quantiteStock * produit.prixVente;
                              final totalSoldValue =
                                  soldStockValues[produit.id]?['valeurVendue'] ??
                                  0.0;
                              final directoryPath = await _pickSaveDirectory();
                              if (directoryPath == null) {
                                return;
                              }
                              await _exportInventoryToExcel(
                                [produit],
                                'produit',
                                'INV-${DateTime.now().millisecondsSinceEpoch}',
                                soldStockValues,
                                totalStockValue,
                                totalSoldValue,
                                directoryPath: directoryPath,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: const Color(0xFF0E5A8A),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Exporter ce produit (Excel)'),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                FutureBuilder<Map<int, Map<String, dynamic>>>(
                  future: _getSoldStockValues(),
                  builder: (context, soldSnapshot) {
                    print(
                      'SoldStockValues FutureBuilder state: ${soldSnapshot.connectionState}',
                    );
                    if (soldSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const SizedBox();
                    }
                    if (soldSnapshot.hasError) {
                      print(
                        'Erreur dans SoldStockValues FutureBuilder : ${soldSnapshot.error}',
                      );
                      return Text('Erreur : ${soldSnapshot.error}');
                    }
                    final soldStockValues = soldSnapshot.data ?? {};
                    return FutureBuilder<List<Produit>>(
                      future: _produitsFuture,
                      builder: (context, produitSnapshot) {
                        print(
                          'Produits FutureBuilder state: ${produitSnapshot.connectionState}, hasData: ${produitSnapshot.hasData}, hasError: ${produitSnapshot.hasError}',
                        );
                        if (produitSnapshot.connectionState ==
                                ConnectionState.waiting &&
                            _filteredProduits.isEmpty) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (produitSnapshot.hasError) {
                          print(
                            'Erreur dans Produits FutureBuilder : ${produitSnapshot.error}',
                          );
                          return Center(
                            child: Text('Erreur : ${produitSnapshot.error}'),
                          );
                        }
                        final produits = produitSnapshot.data ?? [];
                        print(
                          'Produits loaded: ${produits.length}, filtered: ${_filteredProduits.length}',
                        );
                        final totalStockValue = _filteredProduits.fold<double>(
                          0.0,
                          (sum, produit) =>
                              sum + (produit.quantiteStock * produit.prixVente),
                        );
                        final totalSoldValue = _filteredProduits.fold<double>(
                          0.0,
                          (sum, produit) =>
                              sum +
                              (soldStockValues[produit.id]?['valeurVendue'] ??
                                  0.0),
                        );
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Wrap(
                                    spacing: 24,
                                    runSpacing: 8,
                                    children: [
                                      Text(
                                        'Valeur totale du stock : ${NumberFormat('#,##0.00', 'fr_FR').format(totalStockValue)}\u00A0FCFA',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              isDarkMode
                                                  ? Colors.green.shade300
                                                  : Colors.green.shade700,
                                        ),
                                      ),
                                      Text(
                                        'Valeur totale vendue : ${NumberFormat('#,##0.00', 'fr_FR').format(totalSoldValue)}\u00A0FCFA',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              isDarkMode
                                                  ? Colors.blue.shade300
                                                  : Colors.blue.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_totalProduits > 0) ...[
                                  const SizedBox(width: 16),
                                  _buildPaginationControls(
                                    theme,
                                    isDarkMode,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 16),
                            Builder(
                              builder: (context) {
                                final maxHeight =
                                    MediaQuery.of(context).size.height * 0.7;
                                final estimatedHeight =
                                    (_filteredProduits.length + 1) * 48.0 + 32.0;
                                final tableHeight = math.min(
                                  maxHeight,
                                  estimatedHeight,
                                );

                                return SizedBox(
                                  height: tableHeight,
                                  child: _filteredProduits.isNotEmpty
                                      ? Scrollbar(
                                          controller:
                                              _verticalScrollController,
                                          thumbVisibility: true,
                                          child: SingleChildScrollView(
                                            controller:
                                                _verticalScrollController,
                                            scrollDirection: Axis.vertical,
                                            padding:
                                                const EdgeInsets.only(bottom: 32),
                                            child: Scrollbar(
                                              controller:
                                                  _horizontalScrollController,
                                              thumbVisibility: true,
                                              notificationPredicate:
                                                  (notification) =>
                                                      notification
                                                          .metrics.axis ==
                                                      Axis.horizontal,
                                              child: SingleChildScrollView(
                                                controller:
                                                    _horizontalScrollController,
                                                scrollDirection:
                                                    Axis.horizontal,
                                                child: ConstrainedBox(
                                                  constraints:
                                                      const BoxConstraints(
                                                    minWidth: 1600,
                                                  ),
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      // make container background transparent so it doesn't form
                                                      // a visible white band around the table
                                                      color: Colors.transparent,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color:
                                                          isDarkMode
                                                              ? Colors.black26
                                                              : Colors.grey
                                                                  .withOpacity(
                                                                    0.05,
                                                                  ),
                                                      blurRadius: 4,
                                                      offset: const Offset(
                                                        0,
                                                        2,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        ClipRRect(
                                                          borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                      child: DataTable(
                                                        columnSpacing: 24.0,
                                                        horizontalMargin: 16.0,
                                                        dividerThickness: 0.5,
                                                        headingRowHeight: 48,
                                                        dataRowHeight: 48,
                                                        headingTextStyle: theme
                                                            .textTheme
                                                            .bodyMedium
                                                            ?.copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color:
                                                                  isDarkMode
                                                                      ? Colors
                                                                          .grey
                                                                          .shade300
                                                                      : Colors
                                                                          .grey
                                                                          .shade700,
                                                            ),
                                                        dataTextStyle:
                                                            theme
                                                                .textTheme
                                                                .bodyMedium,
                                                        headingRowColor:
                                                            MaterialStateProperty.resolveWith<
                                                              Color
                                                            >(
                                                              (states) =>
                                                                  isDarkMode
                                                                      ? Colors
                                                                          .grey
                                                                          .shade700
                                                                      : Colors
                                                                          .grey
                                                                          .shade100,
                                                            ),
                                                        columns: [
                                                          const DataColumn(
                                                            label: Text('ID'),
                                                          ),
                                                          const DataColumn(
                                                            label: Text(
                                                              'Image',
                                                            ),
                                                          ),
                                                          const DataColumn(
                                                            label: Text('Nom'),
                                                          ),
                                                          const DataColumn(
                                                            label: Text(
                                                              'Catégorie',
                                                            ),
                                                          ),
                                                          const DataColumn(
                                                            label: Text(
                                                              'Stock Initial',
                                                            ),
                                                          ),
                                                          const DataColumn(
                                                            label: Text(
                                                              'Stock',
                                                            ),
                                                          ),
                                                          const DataColumn(
                                                            label: Text(
                                                              'Avarié',
                                                            ),
                                                          ),
                                                          if (_showEcart)
                                                            const DataColumn(
                                                              label: Text(
                                                                'Écart',
                                                              ),
                                                            ),
                                                          const DataColumn(
                                                            label: Text(
                                                              'Valeur Stock',
                                                            ),
                                                          ),
                                                          const DataColumn(
                                                            label: Text(
                                                              'Valeur Vendue',
                                                            ),
                                                          ),
                                                          const DataColumn(
                                                            label: Text(
                                                              'Prix Vente',
                                                            ),
                                                          ),
                                                          const DataColumn(
                                                            label: Text(
                                                              'Fournisseur',
                                                            ),
                                                          ),
                                                          const DataColumn(
                                                            label: Text(
                                                              'Statut',
                                                            ),
                                                          ),
                                                          const DataColumn(
                                                            label: Text(
                                                              'Actions',
                                                            ),
                                                          ),
                                                        ],
                                                        rows: [
                                                          ..._filteredProduits.asMap().entries.map((
                                                            entry,
                                                          ) {
                                                            final int index =
                                                                entry.key;
                                                            final Produit
                                                            produit =
                                                                entry.value;
                                                            final String
                                                            displayStatus =
                                                                _getDisplayStatus(
                                                                  produit,
                                                                );
                                                            final stockValue = (produit
                                                                        .quantiteStock *
                                                                    produit
                                                                        .prixVente)
                                                                .toStringAsFixed(
                                                                  2,
                                                                );
                                                            final soldValue =
                                                                (soldStockValues[produit
                                                                            .id]?['valeurVendue'] ??
                                                                        0.0)
                                                                    .toStringAsFixed(
                                                                      2,
                                                                    );
                                                            final ecart =
                                                                produit
                                                                    .quantiteStock -
                                                                produit
                                                                    .quantiteInitiale;
                                                            return DataRow(
                                                              color: MaterialStateProperty.resolveWith<
                                                                Color
                                                              >(
                                                                (states) =>
                                                                    _getStockColor(
                                                                      produit,
                                                                    ),
                                                              ),
                                                              cells: [
                                                                DataCell(
                                                                  Text(
                                                                    (index + 1)
                                                                        .toString(),
                                                                    style:
                                                                        theme
                                                                            .textTheme
                                                                            .bodyMedium,
                                                                  ),
                                                                ),
                                                                DataCell(
                                                                  GestureDetector(
                                                                    onTap:
                                                                        () => _showEnlargedImage(
                                                                          context,
                                                                          produit
                                                                              .imageUrl,
                                                                        ),
                                                                    child:
                                                                        produit.imageUrl !=
                                                                                    null &&
                                                                                File(
                                                                                  produit.imageUrl!,
                                                                                ).existsSync()
                                                                            ? Image.file(
                                                                              File(
                                                                                produit.imageUrl!,
                                                                              ),
                                                                              width:
                                                                                  40,
                                                                              height:
                                                                                  40,
                                                                              fit:
                                                                                  BoxFit.cover,
                                                                              errorBuilder:
                                                                                  (
                                                                                    context,
                                                                                    error,
                                                                                    stackTrace,
                                                                                  ) => const Icon(
                                                                                    Icons.image_not_supported,
                                                                                    size:
                                                                                        40,
                                                                                    color:
                                                                                        Colors.grey,
                                                                                  ),
                                                                            )
                                                                            : const Icon(
                                                                              Icons.image_not_supported,
                                                                              size:
                                                                                  40,
                                                                              color:
                                                                                  Colors.grey,
                                                                            ),
                                                                  ),
                                                                ),
                                                                DataCell(
                                                                  _highlightText(
                                                                    produit.nom ??
                                                                        'N/A',
                                                                    _searchQuery,
                                                                    theme
                                                                        .textTheme
                                                                        .bodyMedium
                                                                        ?.copyWith(
                                                                          fontWeight:
                                                                              FontWeight.w500,
                                                                        ),
                                                                    isDarkMode,
                                                                  ),
                                                                ),
                                                                DataCell(
                                                                  _highlightText(
                                                                    produit.categorie ??
                                                                        'N/A',
                                                                    _searchQuery,
                                                                    theme
                                                                        .textTheme
                                                                        .bodyMedium
                                                                        ?.copyWith(
                                                                          color:
                                                                              isDarkMode
                                                                                  ? Colors.blue.shade200
                                                                                  : Colors.blue.shade700,
                                                                        ),
                                                                    isDarkMode,
                                                                  ),
                                                                ),
                                                                DataCell(
                                                                  Text(
                                                                    '${produit.quantiteInitiale}${produit.unite == 'kg' ? ' kg' : ''}',
                                                                    style:
                                                                        theme
                                                                            .textTheme
                                                                            .bodyMedium,
                                                                  ),
                                                                ),
                                                                DataCell(
                                                                  Text(
                                                                    '${produit.quantiteStock}${produit.unite == 'kg' ? ' kg' : ''}',
                                                                    style: theme.textTheme.bodyMedium?.copyWith(
                                                                      color:
                                                                          produit.quantiteStock ==
                                                                                  0
                                                                              ? Colors.red.shade500
                                                                              : produit.quantiteStock <=
                                                                                  produit.stockMin
                                                                              ? Colors.red.shade500
                                                                              : produit.quantiteStock <=
                                                                                  produit.seuilAlerte
                                                                              ? Colors.orange.shade500
                                                                              : null,
                                                                      fontWeight:
                                                                          produit.quantiteStock <=
                                                                                  produit.seuilAlerte
                                                                              ? FontWeight.w600
                                                                              : null,
                                                                    ),
                                                                  ),
                                                                ),
                                                                DataCell(
                                                                  Text(
                                                                    '${produit.quantiteAvariee}${produit.unite == 'kg' ? ' kg' : ''}',
                                                                    style: theme.textTheme.bodyMedium?.copyWith(
                                                                      color:
                                                                          produit.quantiteAvariee >
                                                                                  0
                                                                              ? Colors.red.shade500
                                                                              : null,
                                                                      fontWeight:
                                                                          produit.quantiteAvariee >
                                                                                  0
                                                                              ? FontWeight.w600
                                                                              : null,
                                                                    ),
                                                                  ),
                                                                ),
                                                                if (_showEcart)
                                                                  DataCell(
                                                                    Text(
                                                                      '$ecart${produit.unite == 'kg' ? ' kg' : ''}',
                                                                      style: theme.textTheme.bodyMedium?.copyWith(
                                                                        color:
                                                                            ecart < 0
                                                                                ? Colors.red.shade500
                                                                                : ecart >
                                                                                    0
                                                                                ? Colors.green.shade500
                                                                                : null,
                                                                        fontWeight:
                                                                            ecart !=
                                                                                    0
                                                                                ? FontWeight.w600
                                                                                : null,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                DataCell(
                                                                  Text(
                                                                    '${NumberFormat('#,##0.00', 'fr_FR').format(stockValue)}\u00A0FCFA',
                                                                    style: theme
                                                                        .textTheme
                                                                        .bodyMedium
                                                                        ?.copyWith(
                                                                          color:
                                                                              isDarkMode
                                                                                  ? Colors.green.shade300
                                                                                  : Colors.green.shade700,
                                                                          fontWeight:
                                                                              FontWeight.w500,
                                                                        ),
                                                                  ),
                                                                ),
                                                                DataCell(
                                                                  Text(
                                                                    '${NumberFormat('#,##0.00', 'fr_FR').format(soldValue)}\u00A0FCFA',
                                                                    style: theme
                                                                        .textTheme
                                                                        .bodyMedium
                                                                        ?.copyWith(
                                                                          color:
                                                                              isDarkMode
                                                                                  ? Colors.blue.shade300
                                                                                  : Colors.blue.shade700,
                                                                          fontWeight:
                                                                              FontWeight.w500,
                                                                        ),
                                                                  ),
                                                                ),
                                                                DataCell(
                                                                  Text(
                                                                    produit
                                                                        .prixVente
                                                                        .toStringAsFixed(
                                                                          2,
                                                                        ),
                                                                    style: theme
                                                                        .textTheme
                                                                        .bodyMedium
                                                                        ?.copyWith(
                                                                          color:
                                                                              isDarkMode
                                                                                  ? Colors.green.shade300
                                                                                  : Colors.green.shade700,
                                                                          fontWeight:
                                                                              FontWeight.w500,
                                                                        ),
                                                                  ),
                                                                ),
                                                                DataCell(
                                                                  _highlightText(
                                                                    produit.fournisseurPrincipal ??
                                                                        'N/A',
                                                                    _searchQuery,
                                                                    theme
                                                                        .textTheme
                                                                        .bodyMedium,
                                                                    isDarkMode,
                                                                  ),
                                                                ),
                                                                DataCell(
                                                                  Chip(
                                                                    materialTapTargetSize:
                                                                        MaterialTapTargetSize
                                                                            .shrinkWrap,
                                                                    visualDensity:
                                                                        VisualDensity
                                                                            .compact,
                                                                    padding:
                                                                        const EdgeInsets.symmetric(
                                                                          horizontal:
                                                                              8,
                                                                        ),
                                                                    label: _highlightText(
                                                                      displayStatus,
                                                                      _searchQuery,
                                                                      theme.textTheme.labelSmall?.copyWith(
                                                                        color:
                                                                            displayStatus ==
                                                                                    'disponible'
                                                                                ? isDarkMode
                                                                                    ? Colors.green.shade200
                                                                                    : Colors.green.shade800
                                                                                : displayStatus ==
                                                                                    'Bientôt en rupture'
                                                                                ? isDarkMode
                                                                                    ? Colors.orange.shade200
                                                                                    : Colors.orange.shade800
                                                                                : displayStatus ==
                                                                                    'Contient avariés'
                                                                                ? isDarkMode
                                                                                    ? Colors.red.shade200
                                                                                    : Colors.red.shade800
                                                                                : displayStatus ==
                                                                                    'En rupture'
                                                                                ? isDarkMode
                                                                                    ? Colors.red.shade200
                                                                                    : Colors.red.shade800
                                                                                : isDarkMode
                                                                                ? Colors.red.shade200
                                                                                : Colors.red.shade800,
                                                                      ),
                                                                      isDarkMode,
                                                                    ),
                                                                    backgroundColor:
                                                                        displayStatus ==
                                                                                'disponible'
                                                                            ? isDarkMode
                                                                                ? Colors.green.shade900.withOpacity(
                                                                                  0.3,
                                                                                )
                                                                                : Colors.green.shade100
                                                                            : displayStatus ==
                                                                                'Bientôt en rupture'
                                                                            ? isDarkMode
                                                                                ? Colors.orange.shade900.withOpacity(
                                                                                  0.3,
                                                                                )
                                                                                : Colors.orange.shade100
                                                                            : displayStatus ==
                                                                                'Contient avariés'
                                                                            ? isDarkMode
                                                                                ? Colors.red.shade900.withOpacity(
                                                                                  0.3,
                                                                                )
                                                                                : Colors.red.shade100
                                                                            : displayStatus ==
                                                                                'En rupture'
                                                                            ? isDarkMode
                                                                                ? Colors.red.shade900.withOpacity(
                                                                                  0.3,
                                                                                )
                                                                                : Colors.red.shade100
                                                                            : isDarkMode
                                                                            ? Colors.red.shade900.withOpacity(
                                                                              0.3,
                                                                            )
                                                                            : Colors.red.shade100,
                                                                    shape: RoundedRectangleBorder(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            8,
                                                                          ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                DataCell(
                                                                  IconButton(
                                                                    icon: const Icon(
                                                                      Icons
                                                                          .edit,
                                                                      color: Color(
                                                                        0xFF0E5A8A,
                                                                      ),
                                                                    ),
                                                                    onPressed:
                                                                        () => _adjustStock(
                                                                          produit,
                                                                        ),
                                                                  ),
                                                                ),
                                                              ],
                                                            );
                                                          }),
                                                          if (_isLoading)
                                                            DataRow(
                                                              cells: List.generate(
                                                                _showEcart
                                                                    ? 14
                                                                    : 13,
                                                                (
                                                                  index,
                                                                ) => DataCell(
                                                                  index == 0
                                                                      ? const Center(
                                                                        child:
                                                                            CircularProgressIndicator(),
                                                                      )
                                                                      : const SizedBox(),
                                                                ),
                                                              ),
                                                            ),
                                                        ],
                                                    ),
                                                     ) ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                     )) : Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                _searchQuery.isNotEmpty
                                                    ? Icons.search_off
                                                    : Icons
                                                        .inventory_2_outlined,
                                                size: 48,
                                                color: isDarkMode
                                                    ? Colors.grey.shade400
                                                    : Colors.grey.shade600,
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                _searchQuery.isNotEmpty
                                                    ? 'Aucun produit trouvé pour cette recherche'
                                                    : 'Aucun produit disponible',
                                                style: theme
                                                    .textTheme.bodyMedium
                                                    ?.copyWith(
                                                      color: isDarkMode
                                                          ? Colors
                                                              .grey
                                                              .shade400
                                                          : Colors
                                                              .grey
                                                              .shade600,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                );
                              },
                            ),
                            const SizedBox(height: 32),
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
      ),
    );
  }
}
