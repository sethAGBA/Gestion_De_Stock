import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:stock_management/providers/auth_provider.dart';
import 'package:stock_management/services/pdf_service.dart';
import '../models/models.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({Key? key}) : super(key: key);

  @override
  _InventoryScreenState createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  late Database _database;
  late Future<List<Produit>> _produitsFuture;

  @override
  void initState() {
    super.initState();
    _produitsFuture = Future.value([]);
    _initDatabase().then((_) {
      setState(() {
        _produitsFuture = _getProducts();
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
    _database.close();
    super.dispose();
  }

  Future<void> _initDatabase() async {
    print('Initialisation de la base de données pour InventoryScreen...');
    try {
      _database = await openDatabase(
        '/Users/cavris/Documents/dashboard.db',
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
                role TEXT NOT NULL
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
            } else {
              print('quantiteInitiale column already present');
            }
            print('Produits columns: ${columns.map((c) => c['name']).toList()}');
            final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
            print('Tables in database: ${tables.map((t) => t['name']).toList()}');
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

  Future<List<Produit>> _getProducts() async {
    print('Récupération des produits...');
    try {
      final List<Map<String, dynamic>> maps = await _database.query('produits');
      print('Produits récupérés : ${maps.length}');
      final produits = List.generate(maps.length, (i) => Produit.fromMap(maps[i]));
      print('Produits : ${produits.map((p) => p.nom).toList()}');
      return produits;
    } catch (e) {
      print('Erreur lors de la récupération des produits : $e');
      return [];
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
        utilisateur: utilisateur.isEmpty ? 'Inconnu' : utilisateur,
        date: DateTime.now().millisecondsSinceEpoch,
      );
      await _database.insert('historique_avaries', log.toMap());
      print('Ajustement enregistré dans historique_avaries pour produit $produitId');
    } catch (e) {
      print('Erreur lors de l\'enregistrement de l\'ajustement : $e');
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
                    if (quantiteStockChange != 0 || quantiteAvarieeChange != 0) {
                      await _logAdjustment(
                        produit.id,
                        produit.nom,
                        quantiteStockChange,
                        quantiteAvarieeChange,
                        Provider.of<AuthProvider>(builderContext, listen: false).currentUser?.name ?? 'Inconnu',
                      );
                    }
                    Navigator.pop(dialogContext);
                    setState(() {
                      _produitsFuture = _getProducts();
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

  Future<void> _exportInventoryToPdf() async {
    try {
      final produits = await _getProducts();
      if (produits.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucun produit à exporter')),
        );
        return;
      }

      final items = produits.map((produit) => {
        'nom': produit.nom,
        'categorie': produit.categorie,
        'quantiteStock': produit.quantiteStock,
        'quantiteAvariee': produit.quantiteAvariee,
        'prixVente': produit.prixVente,
        'unite': produit.unite,
      }).toList();

      final totalStockValue = produits.fold<double>(
        0.0,
        (sum, produit) => sum + (produit.quantiteStock * produit.prixVente),
      );

      final numero = 'INV-${DateTime.now().millisecondsSinceEpoch}';
      final date = DateTime.now();
      // Safely access AuthProvider with a fallback
      final utilisateurNom = context.read<AuthProvider?>()?.currentUser?.name ?? 'Inconnu';
      const magasinAdresse = '123 Rue Exemple, Ville, Pays'; // Replace with actual address

      final file = await PdfService.saveInventory(
        numero: numero,
        date: date,
        magasinAdresse: magasinAdresse,
        utilisateurNom: utilisateurNom,
        items: items,
        totalStockValue: totalStockValue,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Inventaire exporté : ${file.path}')),
      );
    } catch (e) {
      print('Erreur lors de l\'exportation PDF : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'exportation : $e')),
      );
    }
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
                  'Inventaire',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : const Color(0xFF0A3049),
                  ),
                ),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: null,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.grey.shade400,
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
                      onPressed: null,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.grey.shade400,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Calculer écarts'),
                    ),
                  ],
                ),
              ],
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
                    const SizedBox(width: 120, child: Text('Stock Initial', style: TextStyle(fontWeight: FontWeight.bold))),
                    const SizedBox(width: 120, child: Text('Stock', style: TextStyle(fontWeight: FontWeight.bold))),
                    const SizedBox(width: 120, child: Text('Avarié', style: TextStyle(fontWeight: FontWeight.bold))),
                    const SizedBox(width: 120, child: Text('Valeur Stock', style: TextStyle(fontWeight: FontWeight.bold))),
                    const SizedBox(width: 120, child: Text('Fournisseur', style: TextStyle(fontWeight: FontWeight.bold))),
                    const SizedBox(width: 80, child: Text('Statut', style: TextStyle(fontWeight: FontWeight.bold))),
                    const SizedBox(width: 80, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Produit>>(
                future: _produitsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    print('Erreur dans FutureBuilder : ${snapshot.error}');
                    return Center(child: Text('Erreur : ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
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
                    );
                  }
                  final produits = snapshot.data!;
                  print('Affichage des produits : ${produits.map((p) => p.nom).toList()}');
                  return ListView.builder(
                    itemCount: produits.length,
                    itemBuilder: (context, index) {
                      final produit = produits[index];
                      final isLowStock = produit.quantiteStock <= produit.seuilAlerte;
                      final hasDamaged = produit.quantiteAvariee > 0;
                      final valeurStock = (produit.quantiteStock * produit.prixVente).toStringAsFixed(2);
                      return Container(
                        decoration: BoxDecoration(
                          color: hasDamaged ? Colors.red.withOpacity(0.05) : null,
                          border: Border(bottom: BorderSide(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 120,
                                  child: Text(
                                    produit.nom,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(
                                  width: 120,
                                  child: Text(
                                    produit.categorie,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(
                                  width: 120,
                                  child: Text(
                                    '${produit.quantiteInitiale}${produit.unite == 'kg' ? ' kg' : ''}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(
                                  width: 120,
                                  child: Text(
                                    '${produit.quantiteStock}${produit.unite == 'kg' ? ' kg' : ''}',
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
                                    '${produit.quantiteAvariee}${produit.unite == 'kg' ? ' kg' : ''}',
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
                                    '$valeurStock FCFA',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(
                                  width: 120,
                                  child: Text(
                                    produit.fournisseurPrincipal ?? 'N/A',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(
                                  width: 80,
                                  child: Text(
                                    produit.statut,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(
                                  width: 80,
                                  child: IconButton(
                                    icon: const Icon(Icons.edit, color: Color(0xFF0E5A8A)),
                                    onPressed: null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}