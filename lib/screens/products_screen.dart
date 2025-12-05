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
  Map<int, int> _lotCounts = {};
  Map<int, DateTime?> _lotMinExp = {};

  String get _currentUserName => _currentUser?.name ?? 'Utilisateur';

  String _fmtQty(num value, String unite) {
    final pattern = unite.toLowerCase() == 'kg' ? '#,##0.###' : '#,##0.##';
    final nf = NumberFormat(pattern, 'fr_FR');
    final s = nf.format(value);
    return unite.toLowerCase() == 'kg' ? '$s kg' : s;
  }

  Widget _buildSummaryCard(BuildContext context,
      {required String title,
      required String value,
      required Color color,
      required IconData icon}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
                                            width: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? color.withOpacity(0.2) : color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color,
            radius: 18,
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.grey.shade800)),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _showEnlargedImage(BuildContext context, String? imagePath) {
    if (imagePath == null || imagePath.isEmpty || !File(imagePath).existsSync()) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: InteractiveViewer(
          child: Image.file(File(imagePath)),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Future<void> _showProductDetails(BuildContext context, Produit produit) async {
    final currency = NumberFormat('#,##0.00', 'fr_FR');
    final lots = await _database.query(
      'lots',
      where: 'produitId = ?',
      whereArgs: [produit.id],
      orderBy: 'dateExpiration IS NULL, dateExpiration ASC',
    );

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final isDarkMode = Theme.of(ctx).brightness == Brightness.dark;
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 740,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: (produit.imageUrl != null && produit.imageUrl!.isNotEmpty && File(produit.imageUrl!).existsSync())
                          ? Image.file(File(produit.imageUrl!), fit: BoxFit.cover)
                          : Icon(Icons.inventory_2_outlined, color: Colors.blue.shade600),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(produit.nom, style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Chip(label: Text(produit.categorie)),
                              if (produit.statutPrescription?.isNotEmpty ?? false) Chip(label: Text(produit.statutPrescription!)),
                              if (produit.dci?.isNotEmpty ?? false) Chip(label: Text('DCI: ${produit.dci}')),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _infoRow('Forme', produit.forme ?? '-'),
                          _infoRow('Dosage', produit.dosage ?? '-'),
                          _infoRow('Conditionnement', produit.conditionnement ?? '-'),
                          _infoRow('CIP/GTIN', produit.cip ?? '-'),
                          _infoRow('Fabricant', produit.fabricant ?? '-'),
                          _infoRow('AMM', produit.amm ?? '-'),
                          _infoRow('Statut', produit.statutPrescription ?? '-'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _infoRow('SKU', produit.sku ?? '-'),
                          _infoRow('Code-barres', produit.codeBarres ?? '-'),
                          _infoRow('Unité', produit.unite),
                          _infoRow('Stock', '${produit.quantiteStock}'),
                          _infoRow('Avarié', '${produit.quantiteAvariee}'),
                          _infoRow('Prix vente', '${currency.format(produit.prixVente)} FCFA'),
                          if (produit.prixVenteGros > 0) _infoRow('Prix gros', '${currency.format(produit.prixVenteGros)} FCFA'),
                        ],
                      ),
                    ),
                  ],
                ),
                if (produit.description != null && produit.description!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('Description', style: Theme.of(ctx).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(produit.description!),
                ],
                const SizedBox(height: 12),
                if (lots.isNotEmpty) ...[
                  Text('Lots', style: Theme.of(ctx).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 140,
                    child: ListView.separated(
                      itemCount: lots.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final lot = lots[index];
                        final exp = lot['dateExpiration'] != null
                            ? DateTime.fromMillisecondsSinceEpoch(lot['dateExpiration'] as int)
                            : null;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Lot ${lot['numeroLot']}'),
                            Text(
                              'Dispo: ${(lot['quantiteDisponible'] as num).toDouble()}'
                              '${exp != null ? ' • exp: ${DateFormat('dd/MM/yy').format(exp)}' : ''}',
                              style: TextStyle(
                                color: exp != null && exp.isBefore(DateTime.now().add(const Duration(days: 30)))
                                    ? Colors.red
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
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
          ),
        );
      },
    );
  }

  double? _parseDoubleLocale(String? input) {
    if (input == null) return null;
    final normalized = input.replaceAll(' ', '').replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  Future<void> _showLotsDialog(BuildContext context, Produit produit) async {
    final dateFormat = DateFormat('dd/MM/yyyy');
    List<Map<String, dynamic>> lots = [];
    await showDialog(
      context: context,
      builder: (ctx) {
        String? numeroLot;
        DateTime? expiration;
        double quantite = 0;

        Future<void> loadLots() async {
          lots = await _database.query(
            'lots',
            where: 'produitId = ?',
            whereArgs: [produit.id],
            orderBy: 'dateExpiration IS NULL, dateExpiration ASC',
          );
        }

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return FutureBuilder(
              future: loadLots(),
              builder: (context, snapshot) {
                return AlertDialog(
                  title: Text('Lots - ${produit.nom}'),
                  content: SizedBox(
                    width: 500,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (lots.isNotEmpty)
                          SizedBox(
                            height: 200,
                            child: ListView.separated(
                              itemCount: lots.length,
                              separatorBuilder: (_, __) => const Divider(),
                              itemBuilder: (context, index) {
                                final lot = lots[index];
                                final exp = lot['dateExpiration'] != null
                                    ? DateTime.fromMillisecondsSinceEpoch(lot['dateExpiration'] as int)
                                    : null;
                                return ListTile(
                                  dense: true,
                                  title: Text('Lot: ${lot['numeroLot']}'),
                                  subtitle: Text(
                                    'Quantité: ${lot['quantiteDisponible']} / ${lot['quantite']}'
                                    '${exp != null ? ' - Péremption: ${dateFormat.format(exp)}' : ''}',
                                  ),
                                );
                              },
                            ),
                          )
                        else
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text('Aucun lot enregistré'),
                          ),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Ajouter un lot', style: Theme.of(context).textTheme.titleSmall),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          decoration: const InputDecoration(labelText: 'Numéro de lot'),
                          onChanged: (v) => numeroLot = v,
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          decoration: const InputDecoration(labelText: 'Quantité'),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (v) => quantite = double.tryParse(v.replaceAll(',', '.')) ?? 0,
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: expiration ?? DateTime.now().add(const Duration(days: 365)),
                              firstDate: DateTime.now().subtract(const Duration(days: 365)),
                              lastDate: DateTime.now().add(const Duration(days: 3650)),
                            );
                            if (picked != null) {
                              setStateDialog(() {
                                expiration = picked;
                              });
                            }
                          },
                          icon: const Icon(Icons.event),
                          label: Text(
                            expiration == null ? 'Date de péremption' : dateFormat.format(expiration!),
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
                    ElevatedButton(
                      onPressed: () async {
                        if ((numeroLot == null || numeroLot!.isEmpty) || quantite <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Numéro de lot et quantité requis')),
                          );
                          return;
                        }
                        await _database.insert('lots', {
                          'produitId': produit.id,
                          'numeroLot': numeroLot,
                          'dateExpiration': expiration?.millisecondsSinceEpoch,
                          'quantite': quantite,
                          'quantiteDisponible': quantite,
                        });
                        setState(() {
                          _produitsFuture = _getProducts();
                        });
                        setStateDialog(() {});
                      },
                      child: const Text('Enregistrer le lot'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
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
        _loadLotSummaries();
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

  Future<void> _loadLotSummaries() async {
    try {
      final rows = await _database.rawQuery('''
        SELECT produitId, COUNT(*) as countLots,
               MIN(dateExpiration) as minExp
        FROM lots
        GROUP BY produitId
      ''');
      final counts = <int, int>{};
      final minExp = <int, DateTime?>{};
      for (final row in rows) {
        final pid = (row['produitId'] as num).toInt();
        counts[pid] = (row['countLots'] as num?)?.toInt() ?? 0;
        final expRaw = row['minExp'] as int?;
        minExp[pid] = expRaw != null ? DateTime.fromMillisecondsSinceEpoch(expRaw) : null;
      }
      setState(() {
        _lotCounts = counts;
        _lotMinExp = minExp;
      });
    } catch (e) {
      print('Erreur lors du chargement des lots: $e');
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
                        final now = DateTime.now();
                        final lowStockCount = produits.where((p) => p.quantiteStock <= p.seuilAlerte).length;
                        final avariesCount = produits.where((p) => p.quantiteAvariee > 0).length;
                        final lotAlertCount = _lotMinExp.entries
                            .where((e) => e.value != null && e.value!.isBefore(now.add(const Duration(days: 30))))
                            .length;
                        final totalLots = _lotCounts.values.fold<int>(0, (a, b) => a + b);
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
                          delegate: SliverChildListDelegate(
                            [
                              // Summary bar
                              Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    _buildSummaryCard(
                                      context,
                                      title: 'Produits',
                                      value: produits.length.toString(),
                                      color: const Color(0xFF0E5A8A),
                                      icon: Icons.inventory_2_outlined,
                                    ),
                                    _buildSummaryCard(
                                      context,
                                      title: 'Stock bas',
                                      value: lowStockCount.toString(),
                                      color: Colors.orange,
                                      icon: Icons.warning_amber_rounded,
                                    ),
                                    _buildSummaryCard(
                                      context,
                                      title: 'Lots',
                                      value: '$totalLots (${lotAlertCount} à surveiller)',
                                      color: Colors.green.shade700,
                                      icon: Icons.qr_code_2,
                                    ),
                                    _buildSummaryCard(
                                      context,
                                      title: 'Avariés',
                                      value: avariesCount.toString(),
                                      color: Colors.red.shade700,
                                      icon: Icons.report_problem_outlined,
                                    ),
                                  ],
                                ),
                              ),
                              ...produits.map((produit) {
                                final isLowStock = produit.quantiteStock <= produit.seuilAlerte;
                                final hasDamaged = produit.quantiteAvariee > 0;
                                final lotCount = _lotCounts[produit.id] ?? 0;
                                final exp = _lotMinExp[produit.id];
                                return InkWell(
                                  onTap: () => _showProductDetails(context, produit),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: hasDamaged ? Colors.red.withOpacity(0.05) : (isDarkMode ? Colors.grey.shade900 : Colors.white),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300),
                                      boxShadow: [
                                        BoxShadow(
                                          color: isDarkMode ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.04),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: 160,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  _highlightText(
                                                    produit.nom,
                                                    _searchController.text,
                                                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                                    isDarkMode,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Wrap(
                                                    spacing: 6,
                                                    runSpacing: 4,
                                                    children: [
                                                      _buildBadge(produit.categorie, const Color(0xFF0E5A8A)),
                                                      if (produit.dci?.isNotEmpty ?? false)
                                                        _buildBadge('DCI: ${produit.dci}', Colors.green.shade700),
                                                      if (isLowStock) _buildBadge('Stock bas', Colors.orange),
                                                      if (hasDamaged) _buildBadge('Avarié', Colors.red.shade700),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(
                                              width: 120,
                                              child: _highlightText(
                                                produit.unite,
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
                                                style: const TextStyle(fontWeight: FontWeight.w600),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 140,
                                              child: _highlightText(
                                                produit.fournisseurPrincipal ?? 'N/A',
                                                _searchController.text,
                                                const TextStyle(),
                                                isDarkMode,
                                              ),
                                            ),
                                            SizedBox(
                                              width: 100,
                                              child: _highlightText(
                                                produit.statut,
                                                _searchController.text,
                                                const TextStyle(),
                                                isDarkMode,
                                              ),
                                            ),
                                            SizedBox(
                                              width: 170,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    mainAxisAlignment: MainAxisAlignment.start,
                                                    children: [
                                                      IconButton(
                                                        icon: const Icon(Icons.qr_code_2, color: Color(0xFF0E5A8A), size: 22),
                                                        padding: EdgeInsets.zero,
                                                        constraints: const BoxConstraints(),
                                                        tooltip: 'Lots / Codes-barres',
                                                        onPressed: () async {
                                                          await _showLotsDialog(context, produit);
                                                          await _loadLotSummaries();
                                                        },
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(CupertinoIcons.pen, color: Color(0xFF0E5A8A), size: 22),
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
                                                              _loadLotSummaries();
                                                            },
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      IconButton(
                                                        icon: const Icon(CupertinoIcons.exclamationmark_triangle, color: Colors.orange, size: 22),
                                                        padding: EdgeInsets.zero,
                                                        constraints: const BoxConstraints(),
                                                        onPressed: () => _declareDamaged(produit),
                                                      ),
                                                      const SizedBox(width: 6),
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
                                                  if (lotCount > 0)
                                                    Text(
                                                      'Lots: $lotCount${exp != null ? ' • Péremption min: ${DateFormat('dd/MM/yyyy').format(exp)}' : ''}',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: (exp != null && exp.isBefore(DateTime.now().add(const Duration(days: 30))))
                                                            ? Colors.red
                                                            : Colors.grey.shade700,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ],
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
