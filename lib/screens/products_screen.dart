import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import '../models/models.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({Key? key}) : super(key: key);

  @override
  _ProductsScreenState createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late Database _database;
  final List<String> _unites = ['Pièce', 'Litre', 'kg', 'Boîte'];
  final List<String> _categories = ['Électronique', 'Vêtements', 'Alimentation', 'Autres'];
  final List<String> _statuts = ['disponible', 'en rupture', 'arrêté'];

  int _id = 0; // Changed to int
  String _nom = '';
  String? _description;
  String _categorie = 'Électronique';
  String? _marque;
  String? _imageUrl;
  String? _sku;
  String? _codeBarres;
  String _unite = 'Pièce';
  int _quantiteStock = 0;
  int _quantiteAvariee = 0;
  int _stockMin = 0;
  int _stockMax = 0;
  int _seuilAlerte = 0;
  List<Variante> _variantes = [];
  double _prixAchat = 0.0;
  double _prixVente = 0.0;
  double _tva = 0.0;
  String? _fournisseurPrincipal;
  List<String> _fournisseursSecondaires = [];
  DateTime? _derniereEntree;
  DateTime? _derniereSortie;
  String _statut = 'disponible';

  late Future<List<Produit>> _produitsFuture;
  List<Produit> _filteredProduits = [];

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
    });
    _searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchController.removeListener(_filterProducts);
    _database.close();
    super.dispose();
  }

  Future<void> _initDatabase() async {
    print('Initialisation de la base de données...');
    _database = await openDatabase(
      path.join(await getDatabasesPath(), 'dashboard.db'),
      version: 5,
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
          CREATE TABLE IF NOT EXISTS suppliers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            productName TEXT NOT NULL,
            category TEXT NOT NULL,
            price REAL NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            role TEXT NOT NULL
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
          print('Migration vers version 4 : conversion des ID en INTEGER');
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
            CREATE TABLE suppliers_new (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              productName TEXT NOT NULL,
              category TEXT NOT NULL,
              price REAL NOT NULL
            )
          ''');
          await db.execute('''
            INSERT INTO suppliers_new (name, productName, category, price)
            SELECT name, productName, category, price
            FROM suppliers
          ''');
          await db.execute('DROP TABLE suppliers');
          await db.execute('ALTER TABLE suppliers_new RENAME TO suppliers');

          await db.execute('''
            CREATE TABLE users_new (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              role TEXT NOT NULL
            )
          ''');
          await db.execute('''
            INSERT INTO users_new (name, role)
            SELECT name, role
            FROM users
          ''');
          await db.execute('DROP TABLE users');
          await db.execute('ALTER TABLE users_new RENAME TO users');

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
          print('Migration vers version 5 : ajout des tables pour facturation');
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
        }
      },
    );
  }

  Future<bool> _checkProductExists(String nom, {int? excludeId}) async {
    final List<Map<String, dynamic>> maps = await _database.query(
      'produits',
      where: excludeId != null ? 'nom = ? AND id != ?' : 'nom = ?',
      whereArgs: excludeId != null ? [nom, excludeId] : [nom],
    );
    return maps.isNotEmpty;
  }

  Future<void> _addProduct() async {
    print('Début de _addProduct...');
    if (_formKey.currentState!.validate()) {
      print('Formulaire validé !');
      _formKey.currentState!.save();
      final exists = await _checkProductExists(_nom);
      if (exists) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Erreur'),
            content: const Text('Un produit avec ce nom existe déjà.'),
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

      final produit = Produit(
        id: 0, // SQLite will auto-increment
        nom: _nom,
        description: _description,
        categorie: _categorie,
        marque: _marque,
        imageUrl: _imageUrl,
        sku: _sku,
        codeBarres: _codeBarres,
        unite: _unite,
        quantiteStock: _quantiteStock,
        quantiteAvariee: _quantiteAvariee,
        stockMin: _stockMin,
        stockMax: _stockMax,
        seuilAlerte: _seuilAlerte,
        variantes: _variantes,
        prixAchat: _prixAchat,
        prixVente: _prixVente,
        tva: _tva,
        fournisseurPrincipal: _fournisseurPrincipal,
        fournisseursSecondaires: _fournisseursSecondaires,
        derniereEntree: _derniereEntree,
        derniereSortie: _derniereSortie,
        statut: _statut,
      );
      try {
        print('Tentative d\'insertion du produit : $_nom');
        await _database.insert('produits', produit.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
        print('Produit inséré avec succès : $_nom');
      } catch (e) {
        print('Erreur lors de l\'insertion du produit : $e');
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Erreur'),
            content: Text('Erreur lors de l\'insertion : $e'),
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
      Navigator.pop(context);
      setState(() {
        _id = 0;
        _produitsFuture = _getProducts();
      });
    } else {
      print('Échec de la validation du formulaire.');
    }
  }

  Future<void> _updateProduct(Produit existingProduit) async {
    print('Début de _updateProduct...');
    if (_formKey.currentState!.validate()) {
      print('Formulaire validé !');
      _formKey.currentState!.save();
      final exists = await _checkProductExists(_nom, excludeId: existingProduit.id);
      if (exists) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Erreur'),
            content: const Text('Un produit avec ce nom existe déjà.'),
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

      final produit = Produit(
        id: existingProduit.id,
        nom: _nom,
        description: _description,
        categorie: _categorie,
        marque: _marque,
        imageUrl: _imageUrl,
        sku: _sku,
        codeBarres: _codeBarres,
        unite: _unite,
        quantiteStock: _quantiteStock,
        quantiteAvariee: _quantiteAvariee,
        stockMin: _stockMin,
        stockMax: _stockMax,
        seuilAlerte: _seuilAlerte,
        variantes: _variantes,
        prixAchat: _prixAchat,
        prixVente: _prixVente,
        tva: _tva,
        fournisseurPrincipal: _fournisseurPrincipal,
        fournisseursSecondaires: _fournisseursSecondaires,
        derniereEntree: _derniereEntree,
        derniereSortie: _derniereSortie,
        statut: _statut,
      );
      try {
        print('Tentative de mise à jour du produit : $_nom');
        await _database.update(
          'produits',
          produit.toMap(),
          where: 'id = ?',
          whereArgs: [produit.id],
        );
        print('Produit mis à jour avec succès : $_nom');
      } catch (e) {
        print('Erreur lors de la mise à jour du produit : $e');
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Erreur'),
            content: Text('Erreur lors de la mise à jour : $e'),
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
      Navigator.pop(context);
      setState(() {
        _produitsFuture = _getProducts();
      });
    } else {
      print('Échec de la validation du formulaire.');
    }
  }

  Future<void> _logDamagedAction(int produitId, String produitNom, int quantite, String action, String utilisateur) async {
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
    int quantiteADeclarer = 0;
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
              Text('Stock actuel : ${produit.quantiteStock}${produit.unite == 'kg' ? ' kg' : ''}'),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Quantité avariée',
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
                  if (num <= 0) {
                    return 'La quantité doit être positive';
                  }
                  if (num > produit.quantiteStock) {
                    return 'Quantité supérieure au stock';
                  }
                  return null;
                },
                onSaved: (value) {
                  quantiteADeclarer = int.parse(value!);
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
                  await _logDamagedAction(produit.id, produit.nom, quantiteADeclarer, 'declare', 'Admin');
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
        await _logDamagedAction(produit.id, produit.nom, produit.quantiteAvariee, 'retour', 'Admin');
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
        await _logDamagedAction(produit.id, produit.nom, produit.quantiteAvariee, 'detruit', 'Admin');
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
      return List.generate(maps.length, (i) => Produit.fromMap(maps[i]));
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

  void _showProductDialog({bool isEditing = false, Produit? produit}) {
    if (isEditing && produit != null) {
      _id = produit.id;
      _nom = produit.nom;
      _description = produit.description;
      _categorie = produit.categorie;
      _marque = produit.marque;
      _imageUrl = produit.imageUrl;
      _sku = produit.sku;
      _codeBarres = produit.codeBarres;
      _unite = produit.unite;
      _quantiteStock = produit.quantiteStock;
      _quantiteAvariee = produit.quantiteAvariee;
      _stockMin = produit.stockMin;
      _stockMax = produit.stockMax;
      _seuilAlerte = produit.seuilAlerte;
      _variantes = produit.variantes;
      _prixAchat = produit.prixAchat;
      _prixVente = produit.prixVente;
      _tva = produit.tva;
      _fournisseurPrincipal = produit.fournisseurPrincipal;
      _fournisseursSecondaires = produit.fournisseursSecondaires;
      _derniereEntree = produit.derniereEntree;
      _derniereSortie = produit.derniereSortie;
      _statut = produit.statut;
    } else {
      _id = 0;
      _nom = '';
      _description = null;
      _categorie = 'Électronique';
      _marque = null;
      _imageUrl = null;
      _sku = null;
      _codeBarres = null;
      _unite = 'Pièce';
      _quantiteStock = 0;
      _quantiteAvariee = 0;
      _stockMin = 0;
      _stockMax = 0;
      _seuilAlerte = 0;
      _variantes = [];
      _prixAchat = 0.0;
      _prixVente = 0.0;
      _tva = 0.0;
      _fournisseurPrincipal = null;
      _fournisseursSecondaires = [];
      _derniereEntree = null;
      _derniereSortie = null;
      _statut = 'disponible';
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.7,
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Modifier un produit' : 'Ajouter un produit',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          initialValue: _nom,
                          decoration: const InputDecoration(labelText: 'Nom *', border: OutlineInputBorder()),
                          validator: (value) => (value?.isEmpty ?? true) ? 'Requis' : null,
                          onSaved: (value) => _nom = value!,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          initialValue: _description,
                          decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                          maxLines: 3,
                          onSaved: (value) => _description = value,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: 'Catégorie *', border: OutlineInputBorder()),
                          items: _categories.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          value: _categorie,
                          onChanged: (value) => setState(() => _categorie = value!),
                          validator: (value) => value == null ? 'Requis' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          initialValue: _marque,
                          decoration: const InputDecoration(labelText: 'Marque', border: OutlineInputBorder()),
                          onSaved: (value) => _marque = value,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          initialValue: _imageUrl,
                          decoration: const InputDecoration(labelText: 'URL de l\'image', border: OutlineInputBorder()),
                          onSaved: (value) => _imageUrl = value,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          initialValue: _sku,
                          decoration: const InputDecoration(labelText: 'SKU', border: OutlineInputBorder()),
                          onSaved: (value) => _sku = value,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          initialValue: _codeBarres,
                          decoration: const InputDecoration(labelText: 'Code-barres', border: OutlineInputBorder()),
                          onSaved: (value) => _codeBarres = value,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: 'Unité *', border: OutlineInputBorder()),
                          items: _unites.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          value: _unite,
                          onChanged: (value) => setState(() => _unite = value!),
                          validator: (value) => value == null ? 'Requis' : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: _quantiteStock.toString(),
                                decoration: const InputDecoration(labelText: 'Quantité en stock', border: OutlineInputBorder()),
                                keyboardType: TextInputType.number,
                                validator: (value) => value != null && value.isNotEmpty && int.tryParse(value) == null ? 'Doit être un nombre' : null,
                                onSaved: (value) => _quantiteStock = int.tryParse(value ?? '0') ?? 0,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                initialValue: _quantiteAvariee.toString(),
                                decoration: const InputDecoration(labelText: 'Quantité avariée', border: OutlineInputBorder()),
                                keyboardType: TextInputType.number,
                                validator: (value) => value != null && value.isNotEmpty && int.tryParse(value) == null ? 'Doit être un nombre' : null,
                                onSaved: (value) => _quantiteAvariee = int.tryParse(value ?? '0') ?? 0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: _stockMin.toString(),
                                decoration: const InputDecoration(labelText: 'Stock minimum', border: OutlineInputBorder()),
                                keyboardType: TextInputType.number,
                                validator: (value) => value != null && value.isNotEmpty && int.tryParse(value) == null ? 'Doit être un nombre' : null,
                                onSaved: (value) => _stockMin = int.tryParse(value ?? '0') ?? 0,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                initialValue: _stockMax.toString(),
                                decoration: const InputDecoration(labelText: 'Stock maximum', border: OutlineInputBorder()),
                                keyboardType: TextInputType.number,
                                validator: (value) => value != null && value.isNotEmpty && int.tryParse(value) == null ? 'Doit être un nombre' : null,
                                onSaved: (value) => _stockMax = int.tryParse(value ?? '0') ?? 0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          initialValue: _seuilAlerte.toString(),
                          decoration: const InputDecoration(labelText: 'Seuil d\'alerte', border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                          validator: (value) => value != null && value.isNotEmpty && int.tryParse(value) == null ? 'Doit être un nombre' : null,
                          onSaved: (value) => _seuilAlerte = int.tryParse(value ?? '0') ?? 0,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          initialValue: _variantes.isNotEmpty
                              ? _variantes.map((v) => '${v.type}:${v.valeur}').join(',')
                              : '',
                          decoration: const InputDecoration(labelText: 'Variantes (ex: Taille:M,Couleur:Bleu)', border: OutlineInputBorder()),
                          onSaved: (value) {
                            _variantes = (value?.split(',').map((v) {
                              final parts = v.split(':');
                              if (parts.length == 2) {
                                return Variante(type: parts[0].trim(), valeur: parts[1].trim());
                              }
                              return Variante(type: 'N/A', valeur: 'N/A');
                            }).toList()) ?? [];
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: _prixAchat.toString(),
                                decoration: const InputDecoration(labelText: 'Prix d\'achat', border: OutlineInputBorder()),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: (value) => value != null && value.isNotEmpty && double.tryParse(value) == null ? 'Doit être un nombre valide' : null,
                                onSaved: (value) => _prixAchat = double.tryParse(value ?? '0.0') ?? 0.0,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                initialValue: _prixVente.toString(),
                                decoration: const InputDecoration(labelText: 'Prix de vente', border: OutlineInputBorder()),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: (value) => value != null && value.isNotEmpty && double.tryParse(value) == null ? 'Doit être un nombre valide' : null,
                                onSaved: (value) => _prixVente = double.tryParse(value ?? '0.0') ?? 0.0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          initialValue: _tva.toString(),
                          decoration: const InputDecoration(labelText: 'TVA (%)', border: OutlineInputBorder()),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (value) => value != null && value.isNotEmpty && double.tryParse(value) == null ? 'Doit être un nombre valide' : null,
                          onSaved: (value) => _tva = double.tryParse(value ?? '0.0') ?? 0.0,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          initialValue: _fournisseurPrincipal,
                          decoration: const InputDecoration(labelText: 'Fournisseur principal', border: OutlineInputBorder()),
                          onSaved: (value) => _fournisseurPrincipal = value,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          initialValue: _fournisseursSecondaires.join(','),
                          decoration: const InputDecoration(labelText: 'Fournisseurs secondaires (séparés par des virgules)', border: OutlineInputBorder()),
                          onSaved: (value) => _fournisseursSecondaires = (value?.split(',') ?? []).map((e) => e.trim()).toList(),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: 'Statut *', border: OutlineInputBorder()),
                          items: _statuts.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          value: _statut,
                          onChanged: (value) => setState(() => _statut = value!),
                          validator: (value) => value == null ? 'Requis' : null,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () => isEditing ? _updateProduct(produit!) : _addProduct(),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: const Color(0xFF0E5A8A),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      ),
                      child: Text(isEditing ? 'Modifier' : 'Enregistrer'),
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
                ElevatedButton(
                  onPressed: () => _showProductDialog(),
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
                                            produit.prixVente.toStringAsFixed(2),
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
                                                onPressed: () => _showProductDialog(isEditing: true, produit: produit),
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