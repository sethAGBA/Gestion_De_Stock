import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import '../models/models.dart';

class ProductService {
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    print('Initialisation de la base de données...');
    return openDatabase(
      path.join(await getDatabasesPath(), 'dashboard.db'),
      version: 16, // Updated to 16 to match ProductsScreen
      onCreate: (db, version) async {
        print('Création des tables pour version $version...');
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
              quantiteInitiale INTEGER NOT NULL DEFAULT 0, -- Added
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
              clientNom TEXT,
              date INTEGER NOT NULL,
              statut TEXT NOT NULL,
              total REAL
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
              clientNom TEXT,
              adresse TEXT,
              vendeurNom TEXT,
              magasinAdresse TEXT,
              ristourne REAL DEFAULT 0.0,
              date INTEGER NOT NULL,
              total REAL NOT NULL,
              statutPaiement TEXT NOT NULL,
              montantPaye REAL DEFAULT 0.0,
              montantRemis REAL,
              monnaie REAL,
              statut TEXT NOT NULL DEFAULT 'Active',
              FOREIGN KEY (bonCommandeId) REFERENCES bons_commande(id),
              FOREIGN KEY (clientId) REFERENCES clients(id)
            )
          ''');
          await txn.execute('''
            CREATE TABLE IF NOT EXISTS paiements (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              factureId INTEGER NOT NULL,
              montant REAL NOT NULL,
              montantRemis REAL,
              monnaie REAL,
              date INTEGER NOT NULL,
              methode TEXT NOT NULL,
              FOREIGN KEY (factureId) REFERENCES factures(id)
            )
          ''');
          await txn.execute('''
            CREATE TABLE IF NOT EXISTS factures_archivees (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              facture_id INTEGER NOT NULL,
              numero TEXT NOT NULL,
              bonCommandeId INTEGER NOT NULL,
              clientId INTEGER NOT NULL,
              clientNom TEXT,
              adresse TEXT,
              vendeurNom TEXT,
              magasinAdresse TEXT,
              ristourne REAL DEFAULT 0.0,
              date INTEGER NOT NULL,
              total REAL NOT NULL,
              statutPaiement TEXT NOT NULL,
              montantPaye REAL DEFAULT 0.0,
              montantRemis REAL,
              monnaie REAL,
              motif_annulation TEXT NOT NULL,
              date_annulation INTEGER NOT NULL,
              FOREIGN KEY (bonCommandeId) REFERENCES bons_commande(id),
              FOREIGN KEY (clientId) REFERENCES clients(id)
            )
          ''');
          await txn.execute('''
            CREATE TABLE IF NOT EXISTS stock_exits (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              produitId INTEGER NOT NULL,
              produitNom TEXT NOT NULL,
              quantite INTEGER NOT NULL,
              type TEXT NOT NULL,
              raison TEXT,
              date INTEGER NOT NULL,
              utilisateur TEXT NOT NULL,
              FOREIGN KEY (produitId) REFERENCES produits(id)
            )
          ''');
          await txn.execute('''
            CREATE TABLE IF NOT EXISTS stock_entries (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              produitId INTEGER NOT NULL,
              produitNom TEXT NOT NULL,
              quantite INTEGER NOT NULL,
              type TEXT NOT NULL,
              source TEXT,
              date INTEGER NOT NULL,
              utilisateur TEXT NOT NULL,
              FOREIGN KEY (produitId) REFERENCES produits(id)
            )
          ''');
          // Seed initial data
          await txn.execute('''
            INSERT OR IGNORE INTO unites (nom) VALUES ('Pièce'), ('Litre'), ('kg'), ('Boîte')
          ''');
          await txn.execute('''
            INSERT OR IGNORE INTO categories (nom) VALUES ('Électronique'), ('Vêtements'), ('Alimentation'), ('Autres')
          ''');
          await txn.insert(
            'suppliers',
            {
              'name': 'Supplier X',
              'productName': 'Article A',
              'category': 'Électronique',
              'price': 50.00,
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
          await txn.insert(
            'users',
            {
              'name': 'Admin',
              'role': 'Administrateur',
              'password': 'admin123',
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
          await txn.insert(
            'clients',
            {
              'nom': 'client X',
              'email': 'jean.dupont@example.com',
              'telephone': '123456789',
              'adresse': '123 Rue Exemple, Lomé',
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
          print('Base de données initialisée avec données par défaut.');
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
                produitNom TEXT NOT NULL,
                quantite REAL NOT NULL,
                action TEXT NOT NULL,
                utilisateur TEXT NOT NULL,
                date INTEGER NOT NULL,
                FOREIGN KEY (produitId) REFERENCES produits(id)
              )
            ''');
          }
          if (oldVersion < 4) {
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
                role TEXT NOT NULL,
                password TEXT NOT NULL
              )
            ''');
            await txn.execute('''
              INSERT INTO users_new (name, role, password)
              SELECT name, role, 'password' AS password
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
          if (oldVersion < 5) {
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
                clientNom TEXT,
                date INTEGER NOT NULL,
                statut TEXT NOT NULL,
                total REAL
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
                clientNom TEXT,
                adresse TEXT,
                vendeurNom TEXT,
                magasinAdresse TEXT,
                ristourne REAL DEFAULT 0.0,
                date INTEGER NOT NULL,
                total REAL NOT NULL,
                statutPaiement TEXT NOT NULL,
                montantPaye REAL DEFAULT 0.0,
                montantRemis REAL,
                monnaie REAL,
                statut TEXT NOT NULL DEFAULT 'Active',
                FOREIGN KEY (bonCommandeId) REFERENCES bons_commande(id),
                FOREIGN KEY (clientId) REFERENCES clients(id)
              )
            ''');
            await txn.execute('''
              CREATE TABLE IF NOT EXISTS paiements (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                factureId INTEGER NOT NULL,
                montant REAL NOT NULL,
                montantRemis REAL,
                monnaie REAL,
                date INTEGER NOT NULL,
                methode TEXT NOT NULL,
                FOREIGN KEY (factureId) REFERENCES factures(id)
              )
            ''');
            await txn.insert(
              'clients',
              {
                'nom': 'client X',
                'email': 'jean.dupont@example.com',
                'telephone': '123456789',
                'adresse': '123 Rue Exemple, Lomé',
              },
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
          }
          if (oldVersion < 6) {
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
              INSERT OR IGNORE INTO unites (nom) VALUES ('Pièce'), ('Litre'), ('kg'), ('Boîte')
            ''');
            await txn.execute('''
              INSERT OR IGNORE INTO categories (nom) VALUES ('Électronique'), ('Vêtements'), ('Alimentation'), ('Autres')
            ''');
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
            await txn.insert(
              'users',
              {
                'name': 'Admin',
                'role': 'Administrateur',
                'password': 'admin123',
              },
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
            await txn.insert(
              'clients',
              {
                'nom': 'client X',
                'email': 'jean.dupont@example.com',
                'telephone': '123456789',
                'adresse': '123 Rue Exemple, Lomé',
              },
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
          }
          if (oldVersion < 8) {
            await txn.execute('ALTER TABLE factures ADD COLUMN ristourne REAL DEFAULT 0.0');
            await txn.execute('ALTER TABLE factures ADD COLUMN magasinAdresse TEXT');
          }
          if (oldVersion < 9) {
            await txn.execute('ALTER TABLE paiements ADD COLUMN montantRemis REAL');
            await txn.execute('ALTER TABLE paiements ADD COLUMN monnaie REAL');
          }
          if (oldVersion < 10) {
            await txn.execute('ALTER TABLE factures ADD COLUMN montantRemis REAL');
            await txn.execute('ALTER TABLE factures ADD COLUMN monnaie REAL');
          }
          if (oldVersion < 11) {
            await txn.execute('ALTER TABLE factures ADD COLUMN statut TEXT NOT NULL DEFAULT "Active"');
            await txn.execute('''
              CREATE TABLE IF NOT EXISTS factures_archivees (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                facture_id INTEGER NOT NULL,
                numero TEXT NOT NULL,
                bonCommandeId INTEGER NOT NULL,
                clientId INTEGER NOT NULL,
                clientNom TEXT,
                adresse TEXT,
                vendeurNom TEXT,
                magasinAdresse TEXT,
                ristourne REAL DEFAULT 0.0,
                date INTEGER NOT NULL,
                total REAL NOT NULL,
                statutPaiement TEXT NOT NULL,
                montantPaye REAL DEFAULT 0.0,
                montantRemis REAL,
                monnaie REAL,
                motif_annulation TEXT NOT NULL,
                date_annulation INTEGER NOT NULL,
                FOREIGN KEY (bonCommandeId) REFERENCES bons_commande(id),
                FOREIGN KEY (clientId) REFERENCES clients(id)
              )
            ''');
          }
          if (oldVersion < 12) {
            await txn.execute('''
              CREATE TABLE IF NOT EXISTS stock_exits (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                produitId INTEGER NOT NULL,
                produitNom TEXT NOT NULL,
                quantite REAL NOT NULL,
                type TEXT NOT NULL,
                raison TEXT,
                date INTEGER NOT NULL,
                utilisateur TEXT NOT NULL,
                FOREIGN KEY (produitId) REFERENCES produits(id)
              )
            ''');
          }
          if (oldVersion < 13) {
            await txn.execute('''
              CREATE TABLE IF NOT EXISTS stock_entries (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                produitId INTEGER NOT NULL,
                produitNom TEXT NOT NULL,
                quantite REAL NOT NULL,
                type TEXT NOT NULL,
                source TEXT,
                date INTEGER NOT NULL,
                utilisateur TEXT NOT NULL,
                FOREIGN KEY (produitId) REFERENCES produits(id)
              )
            ''');
          }
          if (oldVersion < 14) {
            await txn.execute('ALTER TABLE users ADD COLUMN password TEXT NOT NULL DEFAULT "password"');
            await txn.update(
              'users',
              {'password': 'admin123'},
              where: 'name = ?',
              whereArgs: ['Admin'],
            );
          }
          if (oldVersion < 15) {
            final columns = await db.rawQuery('PRAGMA table_info(factures)');
            final hasVendeurNom = columns.any((col) => col['name'] == 'vendeurNom');
            if (!hasVendeurNom) {
              await txn.execute('ALTER TABLE factures ADD COLUMN vendeurNom TEXT');
              print('Colonne vendeurNom ajoutée à factures');
            }
            await txn.insert(
              'users',
              {
                'name': 'Admin',
                'role': 'Administrateur',
                'password': 'admin123',
              },
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
            await txn.insert(
              'clients',
              {
                'nom': 'client X',
                'email': 'jean.dupont@example.com',
                'telephone': '123456789',
                'adresse': '123 Rue Exemple, Lomé',
              },
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
          }
          if (oldVersion < 16) {
            final columns = await db.rawQuery('PRAGMA table_info(produits)');
            final hasQuantiteInitiale = columns.any((col) => col['name'] == 'quantiteInitiale');
            if (!hasQuantiteInitiale) {
              await txn.execute('ALTER TABLE produits ADD COLUMN quantiteInitiale INTEGER NOT NULL DEFAULT 0');
              print('Colonne quantiteInitiale ajoutée à produits');
              await txn.execute('UPDATE produits SET quantiteInitiale = quantiteStock WHERE quantiteInitiale IS NULL');
              print('quantiteInitiale initialisée avec quantiteStock pour les produits existants');
            }
          }
        });
        print('Mise à jour de la base de données terminée.');
      },
    );
  }

  Future<bool> checkProductExists(String nom, {int? excludeId}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'produits',
      where: excludeId != null ? 'nom = ? AND id != ?' : 'nom = ?',
      whereArgs: excludeId != null ? [nom, excludeId] : [nom],
    );
    return maps.isNotEmpty;
  }

  Future<void> addProduct(Produit produit) async {
    final db = await database;
    await db.insert('produits', produit.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateProduct(Produit produit) async {
    final db = await database;
    await db.update(
      'produits',
      produit.toMap(),
      where: 'id = ?',
      whereArgs: [produit.id],
    );
  }

  Future<void> logDamagedAction(int produitId, String produitNom, double quantite, String action, String utilisateur) async {
    final db = await database;
    final log = DamagedAction(
      id: 0,
      produitId: produitId,
      produitNom: produitNom,
      quantite: quantite,
      action: action,
      utilisateur: utilisateur,
      date: DateTime.now().millisecondsSinceEpoch,
    );
    await db.insert('historique_avaries', log.toMap());
  }

  Future<void> declareDamaged(Produit produit, int quantite) async {
    final db = await database;
    await db.update(
      'produits',
      {
        'quantiteStock': produit.quantiteStock - quantite,
        'quantiteAvariee': produit.quantiteAvariee + quantite,
      },
      where: 'id = ?',
      whereArgs: [produit.id],
    );
    await logDamagedAction(produit.id, produit.nom, quantite.toDouble(), 'declare', 'Admin');
  }

  Future<void> handleDamagedAction(Produit produit, String action) async {
    final db = await database;
    if (action == 'retour') {
      await db.update(
        'produits',
        {
          'quantiteAvariee': 0,
          'quantiteStock': produit.quantiteStock + produit.quantiteAvariee,
        },
        where: 'id = ?',
        whereArgs: [produit.id],
      );
      await logDamagedAction(produit.id, produit.nom, produit.quantiteAvariee, 'retour', 'Admin');
    } else if (action == 'detruit') {
      await db.update(
        'produits',
        {'quantiteAvariee': 0},
        where: 'id = ?',
        whereArgs: [produit.id],
      );
      await logDamagedAction(produit.id, produit.nom, produit.quantiteAvariee, 'detruit', 'Admin');
    }
  }

  Future<List<Produit>> getProducts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('produits');
    return List.generate(maps.length, (i) => Produit.fromMap(maps[i]));
  }

  Future<List<String>> getUnites() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('unites');
    return maps.map((m) => m['nom'] as String).toList();
  }

  Future<void> addUnite(String unite) async {
    final db = await database;
    await db.insert('unites', {'nom': unite}, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<List<String>> getCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('categories');
    return maps.map((m) => m['nom'] as String).toList();
  }

  Future<void> addCategory(String category) async {
    final db = await database;
    await db.insert('categories', {'nom': category}, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
