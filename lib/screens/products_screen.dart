import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:stock_management/widgets/product_dialog.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../services/barcode_service.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({Key? key}) : super(key: key);

  @override
  _ProductsScreenState createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _searchController = TextEditingController();
  late Database _database;
  late List<String> _unites;
  late List<String> _categories;
  final List<String> _statuts = ['disponible', 'en rupture', 'arrêté'];
  late Future<List<Produit>> _produitsFuture;
  List<Produit> _filteredProduits = [];
  User? _currentUser;

  String get _currentUserName => _currentUser?.name ?? 'Utilisateur';

  String _fmtQty(num value, String unite) {
    final pattern = unite.toLowerCase() == 'kg' ? '#,##0.###' : '#,##0.##';
    final nf = NumberFormat(pattern, 'fr_FR');
    final s = nf.format(value);
    return unite.toLowerCase() == 'kg' ? '$s kg' : s;
  }

  double? _parseDoubleLocale(String? input) {
    if (input == null) return null;
    final normalized = input.replaceAll(' ', '').replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  @override
  void initState() {
    super.initState();
    _produitsFuture = Future.value([]);
    _unites = ['Pièce', 'Litre', 'kg', 'Boîte'];
    _categories = ['Électronique', 'Vêtements', 'Alimentation', 'Autres'];
    _initDatabase().then((_) {
      setState(() {
        _produitsFuture = _getProducts();
        _loadUnitesAndCategories();
      });
    }).catchError((e) {
      print('Erreur lors de l\'initialisation : $e');
    });
    _searchController.addListener(_filterProducts);
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
    _searchController.dispose();
    _searchController.removeListener(_filterProducts);
    _database.close();
    super.dispose();
  }

  Future<void> _exportBarcodes({List<Produit>? produits}) async {
    try {
      final list = produits ??
          (_filteredProduits.isNotEmpty || _searchController.text.isNotEmpty
              ? _filteredProduits
              : await _getProducts());
      if (list.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aucun produit à imprimer')),
          );
        }
        return;
      }
      final file = await BarcodeService.generateBarcodesPdf(list);
      if (Platform.isMacOS) {
        await Process.run('open', [file.path]);
      } else if (Platform.isWindows) {
        await Process.run('explorer', [file.path.replaceAll('/', '\\')]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [file.path]);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Étiquettes générées : ${file.path}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'export : $e')),
        );
      }
    }
  }

  Future<void> _initDatabase() async {
    print('Initialisation de la base de données...');
    try {
      _database = await openDatabase(
        path.join(await getDatabasesPath(), 'dashboard.db'),
        version: 8, // Bump for prixVenteGros/seuilGros
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
                stockMin INTEGER NOT NULL DEFAULT 0,
                stockMax INTEGER NOT NULL DEFAULT 0,
                seuilAlerte INTEGER NOT NULL DEFAULT 0,
                variantes TEXT,
                prixAchat REAL NOT NULL DEFAULT 0.0,
                prixVente REAL NOT NULL DEFAULT 0.0,
                prixVenteGros REAL NOT NULL DEFAULT 0.0,
                seuilGros REAL NOT NULL DEFAULT 0.0,
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
                role TEXT NOT NULL
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
                tarifMode TEXT,
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
            // Seed initial unites and categories
            for (var unite in ['Pièce', 'Litre', 'kg', 'Boîte']) {
              await txn.insert('unites', {'nom': unite}, conflictAlgorithm: ConflictAlgorithm.ignore);
            }
            for (var categorie in ['Électronique', 'Vêtements', 'Alimentation', 'Autres']) {
              await txn.insert('categories', {'nom': categorie}, conflictAlgorithm: ConflictAlgorithm.ignore);
            }
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

              await txn.execute('''
                CREATE TABLE suppliers_new (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  name TEXT NOT NULL,
                  productName TEXT NOT NULL,
                  category TEXT NOT NULL,
                  price REAL NOT NULL
                )
              ''');
              await txn.execute('''
                INSERT INTO suppliers_new (name, productName, category, price)
                SELECT name, productName, category, price
                FROM suppliers
              ''');
              await txn.execute('DROP TABLE suppliers');
              await txn.execute('ALTER TABLE suppliers_new RENAME TO suppliers');

              await txn.execute('''
                CREATE TABLE users_new (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  name TEXT NOT NULL,
                  role TEXT NOT NULL
                )
              ''');
              await txn.execute('''
                INSERT INTO users_new (name, role)
                SELECT name, role
                FROM users
              ''');
              await txn.execute('DROP TABLE users');
              await txn.execute('ALTER TABLE users_new RENAME TO users');

              await txn.execute('''
                CREATE TABLE historique_avaries_new (
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
                INSERT INTO historique_avaries_new (
                  produitId, produitNom, quantite, action, utilisateur, date
                )
                SELECT
                  CAST(produitId AS INTEGER), 'Inconnu', quantite, action, utilisateur, date
                FROM historique_avaries
              ''');
              await txn.execute('DROP TABLE historique_avaries');
              await txn.execute('ALTER TABLE historique_avaries_new RENAME TO historique_avaries');
            }
            if (oldVersion < 8) {
              final columns = await db.rawQuery('PRAGMA table_info(produits)');
              final names = columns.map((c) => c['name'] as String).toList();
              if (!names.contains('prixVenteGros')) {
                await txn.execute('ALTER TABLE produits ADD COLUMN prixVenteGros REAL NOT NULL DEFAULT 0.0');
              }
              if (!names.contains('seuilGros')) {
                await txn.execute('ALTER TABLE produits ADD COLUMN seuilGros REAL NOT NULL DEFAULT 0.0');
              }
            }
            if (oldVersion < 9) {
              final cols = await db.rawQuery('PRAGMA table_info(bon_commande_items)');
              final names = cols.map((c) => c['name'] as String).toList();
              if (!names.contains('tarifMode')) {
                await txn.execute('ALTER TABLE bon_commande_items ADD COLUMN tarifMode TEXT');
              }
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
              // Seed initial unites and categories
              for (var unite in ['Pièce', 'Litre', 'kg', 'Boîte']) {
                await txn.insert('unites', {'nom': unite}, conflictAlgorithm: ConflictAlgorithm.ignore);
              }
              for (var categorie in ['Électronique', 'Vêtements', 'Alimentation', 'Autres']) {
                await txn.insert('categories', {'nom': categorie}, conflictAlgorithm: ConflictAlgorithm.ignore);
              }
              // Migrate existing unites and categories from produits
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
              print('Migration vers version 7 : vérification des tables unites et categories');
              // Ensure tables exist
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
              // Re-seed default values
              for (var unite in ['Pièce', 'Litre', 'kg', 'Boîte']) {
                await txn.insert('unites', {'nom': unite}, conflictAlgorithm: ConflictAlgorithm.ignore);
              }
              for (var categorie in ['Électronique', 'Vêtements', 'Alimentation', 'Autres']) {
                await txn.insert('categories', {'nom': categorie}, conflictAlgorithm: ConflictAlgorithm.ignore);
              }
            }
          });
        },
      );
      print('Base de données initialisée avec succès, version: ${await _database.getVersion()}');
    } catch (e) {
      print('Erreur critique lors de l\'initialisation de la base de données : $e');
      rethrow;
    }
  }

  Future<void> _loadUnitesAndCategories() async {
    try {
      final unites = await _database.query('unites');
      final categories = await _database.query('categories');
      setState(() {
        // Nettoyer et dédupliquer (insensible à la casse)
        final rawUnites = unites.map((u) => (u['nom'] as String).trim()).toList();
        final rawCategories = categories.map((c) => (c['nom'] as String).trim()).toList();
        final seenUnites = <String>{};
        final seenCategories = <String>{};
        _unites = [
          for (final u in rawUnites)
            if (seenUnites.add(u.toLowerCase())) u
        ];
        _categories = [
          for (final c in rawCategories)
            if (seenCategories.add(c.toLowerCase())) c
        ];
      });
      print('Unités chargées : $_unites');
      print('Catégories chargées : $_categories');
    } catch (e) {
      print('Erreur lors du chargement des unités/catégories : $e');
      // Fallback to default lists if query fails
      setState(() {
        _unites = ['Pièce', 'Litre', 'kg', 'Boîte'];
        _categories = ['Électronique', 'Vêtements', 'Alimentation', 'Autres'];
      });
    }
  }

  Future<void> _logDamagedAction(int produitId, String produitNom, double quantite, String action, String utilisateur) async {
    try {
      final log = DamagedAction(
        id: 0,
        produitId: produitId,
        produitNom: produitNom,
        quantite: quantite,
        action: action,
        utilisateur: utilisateur,
        date: DateTime.now().millisecondsSinceEpoch,
      );
      await _database.insert('historique_avaries', log.toMap());
      print('Action enregistrée dans historique_avaries : $action pour produit $produitId');
    } catch (e) {
      print('Erreur lors de l\'enregistrement dans historique_avaries : $e');
    }
  }

  Future<void> _declareDamaged(Produit produit) async {
    double quantiteADeclarer = 0.0;
    final formKey = GlobalKey<FormState>();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déclarer des produits avariés'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Produit : ${produit.nom}'),
              Text('Stock actuel : ${_fmtQty(produit.quantiteStock, produit.unite)}'),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Quantité avariée',
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
                  if (num <= 0) {
                    return 'La quantité doit être positive';
                  }
                  if (num > produit.quantiteStock) {
                    return 'Quantité supérieure au stock';
                  }
                  return null;
                },
                onSaved: (value) {
                  quantiteADeclarer = _parseDoubleLocale(value)!;
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
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                try {
                  await _database.update(
                    'produits',
                    {
                      'quantiteStock': produit.quantiteStock - quantiteADeclarer,
                      'quantiteAvariee': produit.quantiteAvariee + quantiteADeclarer,
                    },
                    where: 'id = ?',
                    whereArgs: [produit.id],
                  );
                  await _logDamagedAction(produit.id, produit.nom, quantiteADeclarer, 'declare', _currentUserName);
                  Navigator.pop(context);
                  setState(() {
                    _produitsFuture = _getProducts();
                  });
                } catch (e) {
                  print('Erreur lors de la déclaration d\'avarie : $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur lors de la déclaration : $e')),
                  );
                }
              }
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDamagedAction(Produit produit, String action) async {
    try {
      if (action == 'retour') {
        await _database.update(
          'produits',
          {
            'quantiteAvariee': 0,
            'quantiteStock': produit.quantiteStock + produit.quantiteAvariee,
          },
          where: 'id = ?',
          whereArgs: [produit.id],
        );
        await _logDamagedAction(produit.id, produit.nom, produit.quantiteAvariee, 'retour', _currentUserName);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produits avariés retournés au fournisseur')),
        );
      } else if (action == 'detruit') {
        await _database.update(
          'produits',
          {'quantiteAvariee': 0},
          where: 'id = ?',
          whereArgs: [produit.id],
        );
        await _logDamagedAction(produit.id, produit.nom, produit.quantiteAvariee, 'detruit', _currentUserName);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produits avariés marqués comme détruits')),
        );
      }
      setState(() {
        _produitsFuture = _getProducts();
      });
    } catch (e) {
      print('Erreur lors de l\'action sur les avaries : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'action : $e')),
      );
    }
  }

  Future<List<Produit>> _getProducts() async {
    print('Récupération des produits...');
    try {
      final List<Map<String, dynamic>> maps = await _database.query('produits');
      print('Produits récupérés : ${maps.length}');
      final produits = List.generate(maps.length, (i) => Produit.fromMap(maps[i]));
      _filteredProduits = produits;
      return produits;
    } catch (e) {
      print('Erreur lors de la récupération des produits : $e');
      return [];
    }
  }

  void _filterProducts() {
    setState(() {
      _produitsFuture.then((produits) {
        final query = _searchController.text.trim().toLowerCase();
        _filteredProduits = produits.where((produit) {
          return (produit.nom.toLowerCase().contains(query)) ||
              (produit.categorie.toLowerCase().contains(query)) ||
              (produit.fournisseurPrincipal?.toLowerCase().contains(query) ?? false) ||
              (produit.statut.toLowerCase().contains(query)) ||
              (query.contains('avarié') && produit.quantiteAvariee > 0);
        }).toList();
      });
    });
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
                  'Produits',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : const Color(0xFF0A3049),
                  ),
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        final produits = _filteredProduits.isNotEmpty || _searchController.text.isNotEmpty
                            ? _filteredProduits
                            : await _getProducts();
                        await _exportBarcodes(produits: produits);
                      },
                      icon: const Icon(Icons.qr_code_2, color: Color(0xFF0E5A8A)),
                      label: const Text('Imprimer codes-barres'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        side: const BorderSide(color: Color(0xFF0E5A8A)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => showDialog(
                        context: context,
                        builder: (context) => ProductDialog(
                          database: _database,
                          unites: _unites,
                          categories: _categories,
                          statuts: _statuts,
                          onProductSaved: () {
                            setState(() {
                              _produitsFuture = _getProducts();
                              _loadUnitesAndCategories();
                            });
                          },
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: const Color(0xFF0E5A8A),
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Créer un produit'),
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
                        hintText: 'Rechercher un produit (inclut "avarié")',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
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
                    const SizedBox(width: 120, child: Text('Nom', style: TextStyle(fontWeight: FontWeight.bold))),
                    const SizedBox(width: 120, child: Text('Catégorie', style: TextStyle(fontWeight: FontWeight.bold))),
                    const SizedBox(width: 120, child: Text('Stock', style: TextStyle(fontWeight: FontWeight.bold))),
                    const SizedBox(width: 120, child: Text('Avarié', style: TextStyle(fontWeight: FontWeight.bold))),
                    const SizedBox(width: 120, child: Text('Prix vente', style: TextStyle(fontWeight: FontWeight.bold))),
                    const SizedBox(width: 120, child: Text('Fournisseur', style: TextStyle(fontWeight: FontWeight.bold))),
                    const SizedBox(width: 80, child: Text('Statut', style: TextStyle(fontWeight: FontWeight.bold))),
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
                    sliver: FutureBuilder<List<Produit>>(
                      future: _produitsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const SliverFillRemaining(
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (snapshot.hasError) {
                          print('Erreur dans FutureBuilder : ${snapshot.error}');
                          return SliverFillRemaining(
                            child: Center(child: Text('Erreur : ${snapshot.error}')),
                          );
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
                                    'Aucun produit disponible',
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
                        final produits = _filteredProduits.isNotEmpty || _searchController.text.isNotEmpty
                            ? _filteredProduits
                            : snapshot.data!;
                        if (produits.isEmpty && _searchController.text.isNotEmpty) {
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
                                    'Aucun produit trouvé pour cette recherche',
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
                        print('Affichage des produits : ${produits.map((p) => p.nom).toList()}');
                        return SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final produit = produits[index];
                              final isLowStock = produit.quantiteStock <= produit.seuilAlerte;
                              final hasDamaged = produit.quantiteAvariee > 0;
                              return Container(
                                decoration: BoxDecoration(
                                  color: hasDamaged ? Colors.red.withOpacity(0.05) : null,
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
                                          width: 120,
                                          child: _highlightText(
                                            produit.nom,
                                            _searchController.text,
                                            const TextStyle(fontWeight: FontWeight.w500),
                                            isDarkMode,
                                          ),
                                        ),
                                        SizedBox(
                                          width: 120,
                                          child: _highlightText(
                                            produit.categorie,
                                            _searchController.text,
                                            const TextStyle(),
                                            isDarkMode,
                                          ),
                                        ),
                                        SizedBox(
                                          width: 120,
                                          child: Text(
                                            _fmtQty(produit.quantiteStock, produit.unite),
                                            style: TextStyle(
                                              color: isLowStock ? Colors.red : null,
                                              fontWeight: isLowStock ? FontWeight.bold : null,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        SizedBox(
                                          width: 120,
                                          child: Text(
                                            _fmtQty(produit.quantiteAvariee, produit.unite),
                                            style: TextStyle(
                                              color: hasDamaged ? Colors.red : null,
                                              fontWeight: hasDamaged ? FontWeight.bold : null,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        SizedBox(
                                          width: 120,
                                          child: Text(
                                            '${NumberFormat('#,##0.00', 'fr_FR').format(produit.prixVente)}\u00A0FCFA',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        SizedBox(
                                          width: 120,
                                          child: _highlightText(
                                            produit.fournisseurPrincipal ?? 'N/A',
                                            _searchController.text,
                                            const TextStyle(),
                                            isDarkMode,
                                          ),
                                        ),
                                        SizedBox(
                                          width: 80,
                                          child: _highlightText(
                                            produit.statut,
                                            _searchController.text,
                                            const TextStyle(),
                                            isDarkMode,
                                          ),
                                        ),
                                        SizedBox(
                                          width: 120,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              IconButton(
                                                icon: const Icon(CupertinoIcons.pen, color: Color(0xFF0E5A8A), size: 20),
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                onPressed: () => showDialog(
                                                  context: context,
                                                  builder: (context) => ProductDialog(
                                                    database: _database,
                                                    unites: _unites,
                                                    categories: _categories,
                                                    statuts: _statuts,
                                                    produit: produit,
                                                    onProductSaved: () {
                                                      setState(() {
                                                        _produitsFuture = _getProducts();
                                                        _loadUnitesAndCategories();
                                                      });
                                                    },
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              IconButton(
                                                icon: const Icon(CupertinoIcons.exclamationmark_triangle, color: Colors.orange, size: 20),
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                onPressed: () => _declareDamaged(produit),
                                              ),
                                              const SizedBox(width: 10),
                                              PopupMenuButton<String>(
                                                icon: const Icon(CupertinoIcons.ellipsis_vertical, size: 20),
                                                onSelected: (value) => _handleDamagedAction(produit, value),
                                                itemBuilder: (context) => [
                                                  if (produit.quantiteAvariee > 0)
                                                    const PopupMenuItem(
                                                      value: 'retour',
                                                      child: Text('Retour au fournisseur'),
                                                    ),
                                                  if (produit.quantiteAvariee > 0)
                                                    const PopupMenuItem(
                                                      value: 'detruit',
                                                      child: Text('Marquer comme détruit'),
                                                    ),
                                                ],
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
                            childCount: produits.length,
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
      ),
    );
  }
}
