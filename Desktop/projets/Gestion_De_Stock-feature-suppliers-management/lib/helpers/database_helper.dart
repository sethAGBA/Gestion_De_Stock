import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:stock_management/data/data_initializer.dart';
import '../models/models.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class DatabaseHelper {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null && await _isDatabaseOpen()) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  static Future<bool> _isDatabaseOpen() async {
    try {
      await _database!.rawQuery('SELECT 1');
      return true;
    } catch (e) {
      print('Database is closed or inaccessible: $e');
      return false;
    }
  }

  static Future<Database> _initDatabase() async {
    final pathDb = path.join(await getDatabasesPath(), 'dashboard.db');
    print('Initialisation de la base de données à : $pathDb');
    return await openDatabase(
      pathDb,
      version: 22,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        await ensureSupplierColumns(db);
        await ensureUserOtpColumns(db);
      },
    );
  }

  static Future<void> closeDatabase() async {
    print('Database connection retained (closeDatabase called but ignored)');
  }

  static Future<int> _countAdministrators(Database db) async {
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM users WHERE role = ?',
      ['Administrateur'],
    );
    final value = Sqflite.firstIntValue(result);
    return value ?? 0;
  }

  static Future<void> _onCreate(Database db, int version) async {
    print('Création des tables pour version $version...');
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
        quantiteInitiale INTEGER NOT NULL DEFAULT 0,
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
    await db.execute('''
      CREATE TABLE IF NOT EXISTS suppliers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        productName TEXT NOT NULL,
        category TEXT NOT NULL,
        price REAL NOT NULL,
        contact TEXT,
        email TEXT,
        telephone TEXT,
        adresse TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        role TEXT NOT NULL CHECK(role IN ('Administrateur', 'Vendeur', 'Client')),
        password TEXT NOT NULL,
        otpEnabled INTEGER NOT NULL DEFAULT 0,
        otpSecret TEXT,
        permissions TEXT
      )
    ''');
    await db.execute('''
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
        quantite REAL NOT NULL,
        prixUnitaire REAL NOT NULL,
        tarifMode TEXT,
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
    await db.execute('''
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
    await db.execute('''
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
    await db.execute('''
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
    await db.execute('''
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
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL UNIQUE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS unites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL UNIQUE
      )
    ''');
    await db.execute('''
      INSERT OR IGNORE INTO categories (nom) VALUES 
      ('Électronique'), ('Vêtements'), ('Alimentation'), ('Boissons'), ('Épicerie'), ('Autres')
    ''');
    await db.execute('''
      INSERT OR IGNORE INTO unites (nom) VALUES 
      ('Pièce'), ('Litre'), ('kg'), ('Boîte'), ('Paquet')
    ''');
    final adminPassword = _hashPassword('admin123');
    final vendeurPassword = _hashPassword('vendeur123');
    await db.execute('''
      INSERT OR IGNORE INTO users (name, role, password, otpEnabled) VALUES 
      ('Admin', 'Administrateur', ?, 0, NULL),
      ('Vendeur1', 'Vendeur', ?, 0, NULL)
    ''', [adminPassword, vendeurPassword]);
    await DataInitializer.initializeDefaultData(db);
    print('Base de données initialisée avec succès.');
  }

  static String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('Mise à jour de la base de données de $oldVersion à $newVersion...');
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE produits ADD COLUMN quantiteAvariee INTEGER NOT NULL DEFAULT 0');
    }
    if (oldVersion < 3) {
      await db.execute('''
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
      await db.execute('ALTER TABLE produits ADD COLUMN id_new INTEGER PRIMARY KEY AUTOINCREMENT');
      await db.execute('UPDATE produits SET id_new = id');
      await db.execute('ALTER TABLE produits DROP COLUMN id');
      await db.execute('ALTER TABLE produits RENAME COLUMN id_new TO id');
      await db.execute('ALTER TABLE suppliers ADD COLUMN id_new INTEGER PRIMARY KEY AUTOINCREMENT');
      await db.execute('UPDATE suppliers SET id_new = id');
      await db.execute('ALTER TABLE suppliers DROP COLUMN id');
      await db.execute('ALTER TABLE suppliers RENAME COLUMN id_new TO id');
      await db.execute('ALTER TABLE users ADD COLUMN id_new INTEGER PRIMARY KEY AUTOINCREMENT');
      await db.execute('UPDATE users SET id_new = id');
      await db.execute('ALTER TABLE users DROP COLUMN id');
      await db.execute('ALTER TABLE users RENAME COLUMN id_new TO id');
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
          quantite REAL NOT NULL,
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
      await DataInitializer.initializeDefaultData(db);
    }
    if (oldVersion < 6) {
      print('Migration vers version 6 : ajout de colonnes manquantes');
      await db.execute('ALTER TABLE bons_commande ADD COLUMN clientNom TEXT');
      await db.execute('ALTER TABLE bons_commande ADD COLUMN total REAL');
      await db.execute('ALTER TABLE factures ADD COLUMN montantPaye REAL DEFAULT 0.0');
      final factures = await db.query('factures');
      for (var i = 0; i < factures.length; i++) {
        final numero = 'FACT${DateTime.now().year}-${(i + 1).toString().padLeft(4, '0')}';
        await db.update(
          'factures',
          {'numero': numero, 'montantPaye': 0.0},
          where: 'id = ?',
          whereArgs: [factures[i]['id']],
        );
      }
      final bonsCommande = await db.query('bons_commande');
      for (var bc in bonsCommande) {
        final clientId = bc['clientId'] as int;
        final client = await db.query('clients', where: 'id = ?', whereArgs: [clientId]);
        if (client.isNotEmpty) {
          await db.update(
            'bons_commande',
            {'clientNom': client.first['nom'] as String},
            where: 'id = ?',
            whereArgs: [bc['id']],
          );
        }
      }
    }
    if (oldVersion < 7) {
      print('Migration vers version 7 : ajout de adresse et vendeurNom à factures');
      await db.execute('ALTER TABLE factures ADD COLUMN clientNom TEXT');
      await db.execute('ALTER TABLE factures ADD COLUMN adresse TEXT');
      await db.execute('ALTER TABLE factures ADD COLUMN vendeurNom TEXT');
      final factures = await db.query('factures');
      for (var facture in factures) {
        final bonCommandeId = facture['bonCommandeId'] as int;
        final bonCommande = await db.query(
          'bons_commande',
          where: 'id = ?',
          whereArgs: [bonCommandeId],
        );
        if (bonCommande.isNotEmpty) {
          final clientId = bonCommande.first['clientId'] as int;
          final client = await db.query(
            'clients',
            where: 'id = ?',
            whereArgs: [clientId],
          );
          if (client.isNotEmpty) {
            await db.update(
              'factures',
              {
                'clientNom': client.first['nom'] as String,
                'adresse': client.first['adresse'] as String?,
              },
              where: 'id = ?',
              whereArgs: [facture['id']],
            );
          }
        }
      }
    }
    if (oldVersion < 8) {
      print('Migration vers version 8 : ajout de ristourne et magasinAdresse à factures');
      await db.execute('ALTER TABLE factures ADD COLUMN ristourne REAL DEFAULT 0.0');
      await db.execute('ALTER TABLE factures ADD COLUMN magasinAdresse TEXT');
    }
    if (oldVersion < 9) {
      print('Migration vers version 9 : ajout de montantRemis et monnaie à paiements');
      await db.execute('ALTER TABLE paiements ADD COLUMN montantRemis REAL');
      await db.execute('ALTER TABLE paiements ADD COLUMN monnaie REAL');
    }
    if (oldVersion < 10) {
      print('Migration vers version 10 : ajout de montantRemis et monnaie à factures');
      await db.execute('ALTER TABLE factures ADD COLUMN montantRemis REAL');
      await db.execute('ALTER TABLE factures ADD COLUMN monnaie REAL');
    }
    if (oldVersion < 11) {
      print('Migration vers version 11 : ajout de statut à factures et création de factures_archivees');
      await db.execute('ALTER TABLE factures ADD COLUMN statut TEXT NOT NULL DEFAULT "Active"');
      await db.execute('''
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
      print('Migration vers version 12 : création de stock_exits');
      await db.execute('''
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
      print('Migration vers version 13 : création de stock_entries');
      await db.execute('''
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
      print('Migration vers version 14 : ajout de password à users');
      await db.execute('ALTER TABLE users ADD COLUMN password TEXT NOT NULL DEFAULT "password"');
      await db.update(
        'users',
        {'password': _hashPassword('admin123')},
        where: 'name = ?',
        whereArgs: ['Admin'],
      );
      await DataInitializer.initializeDefaultData(db);
    }
    if (oldVersion < 15) {
      print('Migration vers version 15 : ajout de vendeurNom à factures si manquant');
      final columns = await db.rawQuery('PRAGMA table_info(factures)');
      final hasVendeurNom = columns.any((col) => col['name'] == 'vendeurNom');
      if (!hasVendeurNom) {
        await db.execute('ALTER TABLE factures ADD COLUMN vendeurNom TEXT');
        print('Colonne vendeurNom ajoutée à factures');
      }
      await DataInitializer.initializeDefaultData(db);
    }
    if (oldVersion < 16) {
      print('Migration vers version 16 : vérification et ajout de clientNom à bons_commande');
      final columns = await db.rawQuery('PRAGMA table_info(bons_commande)');
      final hasClientNom = columns.any((col) => col['name'] == 'clientNom');
      if (!hasClientNom) {
        await db.execute('ALTER TABLE bons_commande ADD COLUMN clientNom TEXT');
        print('Colonne clientNom ajoutée à bons_commande');
        final bonsCommande = await db.query('bons_commande');
        for (var bc in bonsCommande) {
          final clientId = bc['clientId'] as int;
          final client = await db.query('clients', where: 'id = ?', whereArgs: [clientId]);
          if (client.isNotEmpty) {
            await db.update(
              'bons_commande',
              {'clientNom': client.first['nom'] as String},
              where: 'id = ?',
              whereArgs: [bc['id']],
            );
          }
        }
      }
      final hasTotal = columns.any((col) => col['name'] == 'total');
      if (!hasTotal) {
        await db.execute('ALTER TABLE bons_commande ADD COLUMN total REAL');
        print('Colonne total ajoutée à bons_commande');
      }
    }
    if (oldVersion < 17) {
      print('Migration vers version 17 : ajout des tables categories et unites');
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nom TEXT NOT NULL UNIQUE
          )
        ''');
        print('Table categories créée');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS unites (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nom TEXT NOT NULL UNIQUE
          )
        ''');
        print('Table unites créée');
        await db.execute('''
          INSERT OR IGNORE INTO categories (nom) VALUES 
          ('Électronique'), ('Vêtements'), ('Alimentation'), ('Boissons'), ('Épicerie'), ('Autres')
        ''');
        print('Données initiales insérées dans categories');
        await db.execute('''
          INSERT OR IGNORE INTO unites (nom) VALUES 
          ('Pièce'), ('Litre'), ('kg'), ('Boîte'), ('Paquet')
        ''');
        print('Données initiales insérées dans unites');
        final products = await db.query('produits');
        for (var product in products) {
          final categorie = product['categorie'] as String?;
          if (categorie == null || categorie.isEmpty || !['Électronique', 'Vêtements', 'Alimentation', 'Boissons', 'Épicerie', 'Autres'].contains(categorie)) {
            await db.update(
              'produits',
              {'categorie': 'Autres'},
              where: 'id = ?',
              whereArgs: [product['id']],
            );
            print('Produit ${product['nom']} mis à jour avec categorie=Autres');
          }
        }
        await db.execute('''
          ALTER TABLE users ADD COLUMN role_new TEXT NOT NULL DEFAULT 'Client' CHECK(role_new IN ('Administrateur', 'Vendeur', 'Client'))
        ''');
        await db.execute('UPDATE users SET role_new = role');
        await db.execute('ALTER TABLE users DROP COLUMN role');
        await db.execute('ALTER TABLE users RENAME COLUMN role_new TO role');
        print('Schéma de la table users mis à jour');
        print('Migration vers version 17 terminée avec succès');
      } catch (e) {
        print('ERREUR lors de la migration vers version 17 : $e');
        rethrow;
      }
    }
    if (oldVersion < 18) {
      print('Migration vers version 18 : mise à jour des mots de passe existants avec hachage SHA-256');
      try {
        final users = await db.query('users');
        for (var user in users) {
          final password = user['password'] as String;
          if (password.length != 64 || !RegExp(r'^[a-f0-9]{64}$').hasMatch(password)) {
            final hashedPassword = _hashPassword(password);
            await db.update(
              'users',
              {'password': hashedPassword},
              where: 'id = ?',
              whereArgs: [user['id']],
            );
            print('Mot de passe haché pour l\'utilisateur ${user['name']}');
          } else {
            print('Mot de passe déjà haché pour l\'utilisateur ${user['name']}');
          }
        }
        print('Migration vers version 18 terminée avec succès');
      } catch (e) {
        print('ERREUR lors de la migration vers version 18 : $e');
        rethrow;
      }
    }
    if (oldVersion < 19) {
      print('Migration vers version 19 : prise en charge de l\'OTP');
      final userColumns = await db.rawQuery('PRAGMA table_info(users)');
      final userColumnNames = userColumns.map((c) => c['name'] as String).toList();
      if (!userColumnNames.contains('otpEnabled')) {
        await db.execute('ALTER TABLE users ADD COLUMN otpEnabled INTEGER NOT NULL DEFAULT 0');
        print('Colonne otpEnabled ajoutée à users');
      }
      if (!userColumnNames.contains('otpSecret')) {
        await db.execute('ALTER TABLE users ADD COLUMN otpSecret TEXT');
        print('Colonne otpSecret ajoutée à users');
      }
    }
    if (oldVersion < 21) {
      print('Migration vers version 21 : ajout prixVenteGros/seuilGros dans produits');
      final columns = await db.rawQuery('PRAGMA table_info(produits)');
      final names = columns.map((c) => c['name'] as String).toList();
      if (!names.contains('prixVenteGros')) {
        await db.execute('ALTER TABLE produits ADD COLUMN prixVenteGros REAL NOT NULL DEFAULT 0.0');
      }
      if (!names.contains('seuilGros')) {
        await db.execute('ALTER TABLE produits ADD COLUMN seuilGros REAL NOT NULL DEFAULT 0.0');
      }
    }
    if (oldVersion < 22) {
      print('Migration vers version 22 : ajout tarifMode dans bon_commande_items');
      final cols = await db.rawQuery('PRAGMA table_info(bon_commande_items)');
      final names = cols.map((c) => c['name'] as String).toList();
      if (!names.contains('tarifMode')) {
        await db.execute('ALTER TABLE bon_commande_items ADD COLUMN tarifMode TEXT');
      }
    }
    if (oldVersion < 20) {
      print('Migration vers version 20 : gestion des permissions par utilisateur');
      final userColumns = await db.rawQuery('PRAGMA table_info(users)');
      final userColumnNames = userColumns.map((c) => c['name'] as String).toList();
      if (!userColumnNames.contains('permissions')) {
        await db.execute('ALTER TABLE users ADD COLUMN permissions TEXT');
        print('Colonne permissions ajoutée à users');
      }
    }
    // Ajout migration pour les nouveaux champs de suppliers
    final supplierColumns = await db.rawQuery('PRAGMA table_info(suppliers)');
    final supplierColumnNames = supplierColumns.map((c) => c['name'] as String).toList();
    if (!supplierColumnNames.contains('contact')) {
      await db.execute('ALTER TABLE suppliers ADD COLUMN contact TEXT');
      print('Colonne contact ajoutée à suppliers');
    }
    if (!supplierColumnNames.contains('email')) {
      await db.execute('ALTER TABLE suppliers ADD COLUMN email TEXT');
      print('Colonne email ajoutée à suppliers');
    }
    if (!supplierColumnNames.contains('telephone')) {
      await db.execute('ALTER TABLE suppliers ADD COLUMN telephone TEXT');
      print('Colonne telephone ajoutée à suppliers');
    }
    if (!supplierColumnNames.contains('adresse')) {
      await db.execute('ALTER TABLE suppliers ADD COLUMN adresse TEXT');
      print('Colonne adresse ajoutée à suppliers');
    }
    print('Mise à jour terminée.');
  }

  static Future<void> ensureSupplierColumns(Database db) async {
    final supplierColumns = await db.rawQuery('PRAGMA table_info(suppliers)');
    final supplierColumnNames = supplierColumns.map((c) => c['name'] as String).toList();
    if (!supplierColumnNames.contains('contact')) {
      await db.execute('ALTER TABLE suppliers ADD COLUMN contact TEXT');
      print('Colonne contact ajoutée à suppliers (onOpen)');
    }
    if (!supplierColumnNames.contains('email')) {
      await db.execute('ALTER TABLE suppliers ADD COLUMN email TEXT');
      print('Colonne email ajoutée à suppliers (onOpen)');
    }
    if (!supplierColumnNames.contains('telephone')) {
      await db.execute('ALTER TABLE suppliers ADD COLUMN telephone TEXT');
      print('Colonne telephone ajoutée à suppliers (onOpen)');
    }
    if (!supplierColumnNames.contains('adresse')) {
      await db.execute('ALTER TABLE suppliers ADD COLUMN adresse TEXT');
      print('Colonne adresse ajoutée à suppliers (onOpen)');
    }
  }

  static Future<void> ensureUserOtpColumns(Database db) async {
    final userColumns = await db.rawQuery('PRAGMA table_info(users)');
    final userColumnNames = userColumns.map((c) => c['name'] as String).toList();
    if (!userColumnNames.contains('otpEnabled')) {
      await db.execute('ALTER TABLE users ADD COLUMN otpEnabled INTEGER NOT NULL DEFAULT 0');
      print('Colonne otpEnabled ajoutée à users (onOpen)');
    }
    if (!userColumnNames.contains('otpSecret')) {
      await db.execute('ALTER TABLE users ADD COLUMN otpSecret TEXT');
      print('Colonne otpSecret ajoutée à users (onOpen)');
    }
    if (!userColumnNames.contains('permissions')) {
      await db.execute('ALTER TABLE users ADD COLUMN permissions TEXT');
      print('Colonne permissions ajoutée à users (onOpen)');
    }
  }

  static Future<User?> loginUser(String name, String password) async {
    try {
      final db = await database;
      print('Tentative de connexion pour l\'utilisateur : $name...');
      final hashedPassword = _hashPassword(password);
      final List<Map<String, dynamic>> maps = await db.query(
        'users',
        where: 'name = ? AND password = ?',
        whereArgs: [name, hashedPassword],
      );
      if (maps.isEmpty) {
        print('Échec de la connexion : utilisateur ou mot de passe incorrect');
        return null;
      }
      print('Connexion réussie pour l\'utilisateur : $name');
      return User.fromMap(maps.first);
    } catch (e) {
      print('Erreur lors de la connexion : $e');
      if (e.toString().contains('database_closed')) {
        print('Database closed detected, reinitializing...');
        _database = null;
        final db = await database;
        final hashedPassword = _hashPassword(password);
        final List<Map<String, dynamic>> maps = await db.query(
          'users',
          where: 'name = ? AND password = ?',
          whereArgs: [name, hashedPassword],
        );
        if (maps.isEmpty) {
          print('Échec de la connexion après réinitialisation : utilisateur ou mot de passe incorrect');
          return null;
        }
        print('Connexion réussie pour l\'utilisateur : $name après réinitialisation');
        return User.fromMap(maps.first);
      }
      throw e;
    }
  }

  static Future<void> checkAndInitializeData() async {
    final db = await database;
    try {
      print('Vérification des données initiales...');
      final userCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM users'),
      );
      final clientCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM clients'),
      );
      final productCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM produits'),
      );
      final categoryCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM categories'),
      );
      final uniteCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM unites'),
      );

      print('Utilisateurs: $userCount, Clients: $clientCount, Produits: $productCount, Catégories: $categoryCount, Unités: $uniteCount');

      if (userCount == 0 || clientCount == 0 || productCount == 0 || categoryCount == 0 || uniteCount == 0) {
        print('Données manquantes détectées, initialisation...');
        await DataInitializer.initializeDefaultData(db);
      } else {
        print('Données initiales déjà présentes.');
      }
    } catch (e) {
      print('Erreur lors de la vérification des données : $e');
    }
  }

  static Future<bool> tableExists(Database db, String tableName) async {
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [tableName],
    );
    return result.isNotEmpty;
  }

  static Future<List<Map<String, dynamic>>> getSalesByVendor({
    DateTime? specificDay,
    DateTime? startDate,
    DateTime? endDate,
    String? vendor,
  }) async {
    final db = await database;
    try {
      print('Récupération des ventes par vendeur...');
      String whereClause = 'f.statut = ?';
      List<dynamic> whereArgs = ['Active'];

      if (specificDay != null) {
        final start = DateTime(specificDay.year, specificDay.month, specificDay.day).millisecondsSinceEpoch;
        final end = DateTime(specificDay.year, specificDay.month, specificDay.day, 23, 59, 59).millisecondsSinceEpoch;
        whereClause += ' AND f.date BETWEEN ? AND ?';
        whereArgs.add(start);
        whereArgs.add(end);
      } else if (startDate != null && endDate != null) {
        final start = DateTime(startDate.year, startDate.month, startDate.day).millisecondsSinceEpoch;
        final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59).millisecondsSinceEpoch;
        whereClause += ' AND f.date BETWEEN ? AND ?';
        whereArgs.add(start);
        whereArgs.add(end);
      }

      if (vendor != null && vendor.isNotEmpty) {
        whereClause += ' AND f.vendeurNom = ?';
        whereArgs.add(vendor);
      }

      final result = await db.rawQuery(
        '''
        SELECT f.vendeurNom, COUNT(f.id) as invoiceCount, SUM(f.total) as totalCA
        FROM factures f
        LEFT JOIN users u ON f.vendeurNom = u.name
        WHERE $whereClause
        GROUP BY f.vendeurNom
        ''',
        whereArgs,
      );

      print('Ventes par vendeur récupérées : ${result.length}');
      return result;
    } catch (e) {
      print('Erreur lors de la récupération des ventes par vendeur : $e');
      return [];
    }
  }

  static Future<List<String>> getVendors() async {
    final db = await database;
    try {
      print('Récupération des vendeurs...');
      final result = await db.rawQuery('SELECT name FROM users WHERE role IN (?, ?)', ['Vendeur', 'Administrateur']);
      final vendors = result.map((row) => row['name'] as String).toList();
      print('Vendeurs récupérés : ${vendors.length}');
      return vendors;
    } catch (e) {
      print('Erreur lors de la récupération des vendeurs : $e');
      return [];
    }
  }

  static Future<double> getTotalCA({
    DateTime? specificDay,
    DateTime? startDate,
    DateTime? endDate,
    String? vendor,
  }) async {
    final db = await database;
    try {
      print('Récupération du chiffre d\'affaires total...');
      String whereClause = 'f.statut = ?';
      List<dynamic> whereArgs = ['Active'];

      if (specificDay != null) {
        final start = DateTime(specificDay.year, specificDay.month, specificDay.day).millisecondsSinceEpoch;
        final end = DateTime(specificDay.year, specificDay.month, specificDay.day, 23, 59, 59).millisecondsSinceEpoch;
        whereClause += ' AND f.date BETWEEN ? AND ?';
        whereArgs.add(start);
        whereArgs.add(end);
      } else if (startDate != null && endDate != null) {
        final start = DateTime(startDate.year, startDate.month, startDate.day).millisecondsSinceEpoch;
        final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59).millisecondsSinceEpoch;
        whereClause += ' AND f.date BETWEEN ? AND ?';
        whereArgs.add(start);
        whereArgs.add(end);
      }

      if (vendor != null && vendor.isNotEmpty) {
        whereClause += ' AND f.vendeurNom = ?';
        whereArgs.add(vendor);
      }

      final result = await db.rawQuery(
        '''
        SELECT SUM(f.total) as totalCA
        FROM factures f
        LEFT JOIN users u ON f.vendeurNom = u.name
        WHERE $whereClause
        ''',
        whereArgs,
      );

      final totalCA = (result.first['totalCA'] as num?)?.toDouble() ?? 0.0;
      print('Chiffre d\'affaires total : $totalCA');
      return totalCA;
    } catch (e) {
      print('Erreur lors de la récupération du CA total : $e');
      return 0.0;
    }
  }

  static Future<List<Produit>> getProduits() async {
    final db = await database;
    try {
      print('Récupération des produits...');
      final List<Map<String, dynamic>> maps = await db.query('produits');
      print('Produits récupérés : ${maps.length}');
      return List.generate(maps.length, (i) => Produit.fromMap(maps[i]));
    } catch (e) {
      print('Erreur lors de la récupération des produits : $e');
      return [];
    }
  }

  static Future<List<Supplier>> getSuppliers() async {
    final db = await database;
    try {
      print('Récupération des fournisseurs...');
      final List<Map<String, dynamic>> maps = await db.query('suppliers');
      print('Fournisseurs récupérés : ${maps.length}');
      return List.generate(maps.length, (i) => Supplier.fromMap(maps[i]));
    } catch (e) {
      print('Erreur lors de la récupération des fournisseurs : $e');
      return [];
    }
  }

  static Future<List<User>> getUsers() async {
    final db = await database;
    try {
      print('Récupération des utilisateurs...');
      final List<Map<String, dynamic>> maps = await db.query('users');
      print('Utilisateurs récupérés : ${maps.length}');
      return List.generate(maps.length, (i) => User.fromMap(maps[i]));
    } catch (e) {
      print('Erreur lors de la récupération des utilisateurs : $e');
      return [];
    }
  }

  static Future<void> addUser(User user) async {
    final db = await database;
    try {
      print('Ajout de l\'utilisateur : ${user.name}...');
      await db.insert('users', user.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      print('Utilisateur ajouté avec succès');
    } catch (e) {
      print('Erreur lors de l\'ajout de l\'utilisateur : $e');
      throw e;
    }
  }

  static Future<void> restoreAdminAccount() async {
    final db = await database;
    final defaultPassword = _hashPassword('admin123');
    try {
      final existingAdmin = await db.query(
        'users',
        where: 'LOWER(name) = ?',
        whereArgs: ['admin'],
        limit: 1,
      );

      if (existingAdmin.isEmpty) {
        await db.insert('users', {
          'name': 'Admin',
          'role': 'Administrateur',
          'password': defaultPassword,
          'otpEnabled': 0,
          'otpSecret': null,
        });
        print('Compte administrateur restauré (création).');
      } else {
        await db.update(
          'users',
          {
            'name': 'Admin',
            'role': 'Administrateur',
            'password': defaultPassword,
          },
          where: 'id = ?',
          whereArgs: [existingAdmin.first['id']],
        );
        print('Compte administrateur restauré (réinitialisation).');
      }
    } catch (e) {
      print('Erreur lors de la restauration du compte administrateur : $e');
      rethrow;
    }
  }

  static Future<void> updateUser(User user) async {
    final db = await database;
    try {
      print('Mise à jour de l\'utilisateur : ${user.name}...');
      final existing = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [user.id],
        limit: 1,
      );
      if (existing.isEmpty) {
        throw Exception('Utilisateur introuvable');
      }

      final wasAdmin = (existing.first['role'] as String?) == 'Administrateur';
      final adminCount = await _countAdministrators(db);
      final isAdminAfterUpdate = user.role == 'Administrateur';

      if (wasAdmin && !isAdminAfterUpdate && adminCount <= 1) {
        throw Exception('Impossible de retirer le dernier administrateur');
      }

      final data = user.toMap();
      if (isAdminAfterUpdate) {
        final adminCountAfter = wasAdmin ? adminCount : adminCount + 1;
        if (adminCountAfter <= 1) {
          data['permissions'] = null;
        }
      }

      await db.update(
        'users',
        data,
        where: 'id = ?',
        whereArgs: [user.id],
      );
      print('Utilisateur mis à jour avec succès');
    } catch (e) {
      print('Erreur lors de la mise à jour de l\'utilisateur : $e');
      throw e;
    }
  }

  static Future<void> deleteUser(int id) async {
    final db = await database;
    try {
      print('Suppression de l\'utilisateur avec id : $id...');
      final existing = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (existing.isEmpty) {
        print('Aucun utilisateur trouvé pour l\'id $id.');
        return;
      }

      final isAdmin = (existing.first['role'] as String?) == 'Administrateur';
      if (isAdmin) {
        final adminCount = await _countAdministrators(db);
        if (adminCount <= 1) {
          throw Exception('Impossible de supprimer le dernier administrateur');
        }
      }

      await db.delete(
        'users',
        where: 'id = ?',
        whereArgs: [id],
      );
      print('Utilisateur supprimé avec succès');
    } catch (e) {
      print('Erreur lors de la suppression de l\'utilisateur : $e');
      throw e;
    }
  }

  static Future<List<Client>> getClients() async {
    final db = await database;
    try {
      print('Récupération des clients...');
      final List<Map<String, dynamic>> maps = await db.query('clients');
      print('Clients récupérés : ${maps.length}');
      return List.generate(maps.length, (i) => Client.fromMap(maps[i]));
    } catch (e) {
      print('Erreur lors de la récupération des clients : $e');
      return [];
    }
  }

  static Future<List<Facture>> getFactures({bool includeArchived = false, String? vendeurNom}) async {
    final db = await database;
    try {
      print('Récupération des factures...');
      String? where;
      List<dynamic>? whereArgs;
      if (!includeArchived) {
        where = 'statut = ?';
        whereArgs = ['Active'];
      }
      if (vendeurNom != null) {
        if (where != null) {
          where += ' AND vendeurNom = ?';
          whereArgs!.add(vendeurNom);
        } else {
          where = 'vendeurNom = ?';
          whereArgs = [vendeurNom];
        }
      }
      final List<Map<String, dynamic>> maps = await db.query(
        'factures',
        where: where,
        whereArgs: whereArgs,
      );
      print('Factures récupérées : ${maps.length}');
      return List.generate(maps.length, (i) => Facture.fromMap(maps[i]));
    } catch (e) {
      print('Erreur lors de la récupération des factures : $e');
      return [];
    }
  }

  static Future<FactureArchivee?> getArchivedFacture(int factureId) async {
    final db = await database;
    try {
      print('Récupération de la facture archivée pour factureId $factureId...');
      final List<Map<String, dynamic>> maps = await db.query(
        'factures_archivees',
        where: 'facture_id = ?',
        whereArgs: [factureId],
      );
      if (maps.isEmpty) {
        print('Aucune facture archivée trouvée pour factureId $factureId');
        return null;
      }
      print('Facture archivée récupérée : ${maps.first}');
      return FactureArchivee.fromMap(maps.first);
    } catch (e) {
      print('Erreur lors de la récupération de la facture archivée : $e');
      return null;
    }
  }

  static Future<void> addPayment(int factureId, double montant, String methode, {double? montantRemis, double? monnaie}) async {
    final db = await database;
    try {
      print('Ajout du paiement pour facture $factureId...');
      await db.insert('paiements', {
        'factureId': factureId,
        'montant': montant,
        'montantRemis': montantRemis,
        'monnaie': monnaie,
        'date': DateTime.now().millisecondsSinceEpoch,
        'methode': methode,
      });

      final paiements = await db.query(
        'paiements',
        where: 'factureId = ?',
        whereArgs: [factureId],
      );
      final totalPaye = paiements.fold(0.0, (sum, p) => sum + (p['montant'] as num));

      final facture = await db.query(
        'factures',
        where: 'id = ?',
        whereArgs: [factureId],
      );
      final total = (facture.first['total'] as num).toDouble();
      final statutPaiement = totalPaye >= total ? 'Payé' : 'En attente';

      await db.update(
        'factures',
        {
          'montantPaye': totalPaye,
          'statutPaiement': statutPaiement,
          'montantRemis': montantRemis,
          'monnaie': monnaie,
        },
        where: 'id = ?',
        whereArgs: [factureId],
      );

      print('Paiement ajouté et montantPaye mis à jour : $totalPaye, statut: $statutPaiement');
    } catch (e) {
      print('Erreur lors de l\'ajout du paiement : $e');
      throw e;
    }
  }

  static Future<int> getTotalProductsSold() async {
    final db = await database;
    try {
      print('Récupération du total des produits vendus...');
      final result = await db.rawQuery('''
        SELECT SUM(bci.quantite) as totalSold
        FROM bon_commande_items bci
        JOIN factures f ON f.bonCommandeId = bci.bonCommandeId
        WHERE f.statut != 'Annulée'
      ''');
      final totalSold = (result.first['totalSold'] as num?)?.toInt() ?? 0;
      print('Total produits vendus : $totalSold');
      return totalSold;
    } catch (e) {
      print('Erreur lors de la récupération des produits vendus : $e');
      return 0;
    }
  }

  static Future<void> cancelFacture(int factureId, String motif) async {
    final db = await database;
    try {
      print('Annulation de la facture $factureId...');
      await db.transaction((txn) async {
        final facture = await txn.query(
          'factures',
          where: 'id = ?',
          whereArgs: [factureId],
        );
        if (facture.isEmpty) throw Exception('Facture non trouvée');
        final factureData = facture.first;
        if (factureData['statut'] == 'Annulée') throw Exception('Facture déjà annulée');

        final bonCommandeId = factureData['bonCommandeId'] as int;

        final items = await txn.query(
          'bon_commande_items',
          where: 'bonCommandeId = ?',
          whereArgs: [bonCommandeId],
        );

        for (var item in items) {
          final produitId = item['produitId'] as int;
          final quantite = (item['quantite'] as num).toInt();
          final produit = await txn.query(
            'produits',
            where: 'id = ?',
            whereArgs: [produitId],
          );
          if (produit.isEmpty) throw Exception('Produit $produitId non trouvé');
          final currentStock = (produit.first['quantiteStock'] as num).toInt();
          await txn.update(
            'produits',
            {'quantiteStock': currentStock + quantite},
            where: 'id = ?',
            whereArgs: [produitId],
          );
          print('Stock restauré pour produit $produitId : +$quantite');
        }

        await txn.insert('factures_archivees', {
          'facture_id': factureId,
          'numero': factureData['numero'],
          'bonCommandeId': factureData['bonCommandeId'],
          'clientId': factureData['clientId'],
          'clientNom': factureData['clientNom'],
          'adresse': factureData['adresse'],
          'vendeurNom': factureData['vendeurNom'],
          'magasinAdresse': factureData['magasinAdresse'],
          'ristourne': factureData['ristourne'],
          'date': factureData['date'],
          'total': factureData['total'],
          'statutPaiement': factureData['statutPaiement'],
          'montantPaye': factureData['montantPaye'],
          'montantRemis': factureData['montantRemis'],
          'monnaie': factureData['monnaie'],
          'motif_annulation': motif,
          'date_annulation': DateTime.now().millisecondsSinceEpoch,
        });

        await txn.update(
          'factures',
          {'statut': 'Annulée'},
          where: 'id = ?',
          whereArgs: [factureId],
        );

        await txn.delete(
          'paiements',
          where: 'factureId = ?',
          whereArgs: [factureId],
        );

        print('Facture $factureId annulée et archivée avec succès');
      });
    } catch (e) {
      print('Erreur lors de l\'annulation de la facture : $e');
      throw e;
    }
  }

  static Future<void> addProduit(Produit produit) async {
    final db = await database;
    try {
      print('Ajout du produit : ${produit.nom}...');
      await db.insert('produits', produit.toMap());
      print('Produit ajouté avec succès');
    } catch (e) {
      print('Erreur lors de l\'ajout du produit : $e');
      throw e;
    }
  }

  static Future<void> updateProduit(Produit produit) async {
    final db = await database;
    try {
      print('Mise à jour du produit : ${produit.nom}...');
      await db.update(
        'produits',
        produit.toMap(),
        where: 'id = ?',
        whereArgs: [produit.id],
      );
      print('Produit mis à jour avec succès');
    } catch (e) {
      print('Erreur lors de la mise à jour du produit : $e');
      throw e;
    }
  }

  static Future<void> addClient(Client client) async {
    final db = await database;
    try {
      print('Ajout du client : ${client.nom}...');
      await db.insert('clients', client.toMap());
      print('Client ajouté avec succès');
    } catch (e) {
      print('Erreur lors de l\'ajout du client : $e');
      throw e;
    }
  }

  static Future<void> addBonCommande(BonCommande bonCommande, List<BonCommandeItem> items) async {
    final db = await database;
    try {
      print('Ajout du bon de commande...');
      final bonCommandeId = await db.insert('bons_commande', bonCommande.toMap());
      for (var item in items) {
        await db.insert('bon_commande_items', {
          ...item.toMap(),
          'bonCommandeId': bonCommandeId,
        });
      }
      print('Bon de commande ajouté avec succès');
    } catch (e) {
      print('Erreur lors de l\'ajout du bon de commande : $e');
      throw e;
    }
  }

  static Future<void> addFacture(Facture facture) async {
    final db = await database;
    try {
      print('Ajout de la facture : ${facture.numero}...');
      await db.insert('factures', facture.toMap());
      print('Facture ajoutée avec succès');
    } catch (e) {
      print('Erreur lors de l\'ajout de la facture : $e');
      throw e;
    }
  }

  static Future<List<BonCommandeItem>> getBonCommandeItems(int bonCommandeId) async {
    final db = await database;
    try {
      print('Récupération des items du bon de commande $bonCommandeId...');
      final maps = await db.query(
        'bon_commande_items',
        where: 'bonCommandeId = ?',
        whereArgs: [bonCommandeId],
      );
      print('Items récupérés : ${maps.length}');
      return maps.map((map) => BonCommandeItem.fromMap(map)).toList();
    } catch (e) {
      print('Erreur lors de la récupération des items : $e');
      return [];
    }
  }

  static Future<void> updateStock(int produitId, int quantite) async {
    final db = await database;
    try {
      print('Mise à jour du stock pour le produit $produitId...');
      final produit = await db.query(
        'produits',
        where: 'id = ?',
        whereArgs: [produitId],
      );
      if (produit.isNotEmpty) {
        final currentStock = (produit.first['quantiteStock'] as num).toInt();
        final newStock = currentStock - quantite;
        if (newStock < 0) {
          throw Exception('Stock insuffisant');
        }
        await db.update(
          'produits',
          {'quantiteStock': newStock},
          where: 'id = ?',
          whereArgs: [produitId],
        );
        print('Stock mis à jour : $newStock');
      }
    } catch (e) {
      print('Erreur lors de la mise à jour du stock : $e');
      throw e;
    }
  }

  static Future<void> addDamagedAction(DamagedAction action) async {
    final db = await database;
    try {
      print('Ajout de l\'action d\'avarie pour le produit ${action.produitNom}...');
      await db.insert('historique_avaries', action.toMap());
      print('Action d\'avarie ajoutée avec succès');
    } catch (e) {
      print('Erreur lors de l\'ajout de l\'action d\'avarie : $e');
      throw e;
    }
  }

  static Future<List<DamagedAction>> getDamagedActions() async {
    final db = await database;
    try {
      print('Récupération des actions d\'avarie...');
      final maps = await db.query('historique_avaries');
      print('Actions d\'avarie récupérées : ${maps.length}');
      return maps.map((map) => DamagedAction.fromMap(map)).toList();
    } catch (e) {
      print('Erreur lors de la récupération des actions d\'avarie : $e');
      return [];
    }
  }

  static Future<void> addStockExit(StockExit exit) async {
    final db = await database;
    try {
      print('Ajout de la sortie de stock pour ${exit.produitNom}...');
      await db.transaction((txn) async {
        final produit = await txn.query(
          'produits',
          where: 'id = ?',
          whereArgs: [exit.produitId],
        );
        if (produit.isEmpty) throw Exception('Produit non trouvé');
        final currentStock = (produit.first['quantiteStock'] as num).toInt();
        if (currentStock < exit.quantite) throw Exception('Stock insuffisant');
        await txn.update(
          'produits',
          {'quantiteStock': currentStock - exit.quantite},
          where: 'id = ?',
          whereArgs: [exit.produitId],
        );
        await txn.insert('stock_exits', exit.toMap());
      });
      print('Sortie de stock ajoutée avec succès');
    } catch (e) {
      print('Erreur lors de l\'ajout de la sortie de stock : $e');
      throw e;
    }
  }

  static Future<List<StockExit>> getStockExits({
    String? typeFilter,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    try {
      print('Récupération des sorties de stock...');
      String? whereClause;
      List<dynamic> whereArgs = [];

      if (typeFilter != null) {
        whereClause = 'type = ?';
        whereArgs.add(typeFilter);
      }

      if (startDate != null) {
        final start = DateTime(startDate.year, startDate.month, startDate.day).millisecondsSinceEpoch;
        whereClause = whereClause == null ? 'date >= ?' : '$whereClause AND date >= ?';
        whereArgs.add(start);
      }

      if (endDate != null) {
        final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59).millisecondsSinceEpoch;
        whereClause = whereClause == null ? 'date <= ?' : '$whereClause AND date <= ?';
        whereArgs.add(end);
      }

      final maps = await db.query(
        'stock_exits',
        where: whereClause,
        whereArgs: whereArgs.isEmpty ? null : whereArgs,
        orderBy: 'date DESC',
      );

      print('Sorties de stock récupérées : ${maps.length}');
      return maps.map((map) => StockExit.fromMap(map)).toList();
    } catch (e) {
      print('Erreur lors de la récupération des sorties de stock : $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getAllExits({
    String? typeFilter,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    try {
      print('Récupération de toutes les sorties (ventes + autres)...');
      List<Map<String, dynamic>> exits = [];
      List<String> conditions = [];
      List<dynamic> args = [];

      // Construire les conditions pour stock_exits
      String stockExitsQuery = 'SELECT * FROM stock_exits';
      if (typeFilter != null && typeFilter != 'sale') {
        conditions.add('type = ?');
        args.add(typeFilter);
      }
      if (startDate != null) {
        conditions.add('date >= ?');
        args.add(DateTime(startDate.year, startDate.month, startDate.day).millisecondsSinceEpoch);
      }
      if (endDate != null) {
        conditions.add('date <= ?');
        args.add(DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59, 999).millisecondsSinceEpoch);
      }

      if (conditions.isNotEmpty) {
        stockExitsQuery += ' WHERE ${conditions.join(' AND ')}';
      }
      stockExitsQuery += ' ORDER BY date DESC';

      // Exécuter la requête pour stock_exits
      final stockExits = await db.rawQuery(stockExitsQuery, args);
      exits.addAll(stockExits.map((e) => {
            'id': e['id'],
            'produitId': e['produitId'],
            'produitNom': e['produitNom'],
            'quantite': e['quantite'],
            'type': e['type'],
            'raison': e['raison'],
            'date': e['date'],
            'utilisateur': e['utilisateur'],
            'source': 'stock_exit',
          }));

      // Réinitialiser conditions et arguments pour les ventes
      conditions.clear();
      args.clear();

      // Construire la requête pour les ventes (si nécessaire)
      if (typeFilter == null || typeFilter == 'sale') {
        String salesQuery = '''
          SELECT bci.id, bci.produitId, p.nom as produitNom, bci.quantite, 'sale' as type, 
                 f.numero as raison, f.date, u.name as utilisateur
          FROM bon_commande_items bci
          JOIN factures f ON f.bonCommandeId = bci.bonCommandeId
          JOIN produits p ON p.id = bci.produitId
          JOIN users u ON u.id = (SELECT id FROM users LIMIT 1)
          WHERE f.statut != 'Annulée'
        ''';
        if (startDate != null) {
          conditions.add('f.date >= ?');
          args.add(DateTime(startDate.year, startDate.month, startDate.day).millisecondsSinceEpoch);
        }
        if (endDate != null) {
          conditions.add('f.date <= ?');
          args.add(DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59, 999).millisecondsSinceEpoch);
        }

        if (conditions.isNotEmpty) {
          salesQuery += ' AND ${conditions.join(' AND ')}';
        }
        salesQuery += ' ORDER BY f.date DESC';

        // Exécuter la requête pour les ventes
        final saleExits = await db.rawQuery(salesQuery, args);
        exits.addAll(saleExits.map((e) => {
              'id': e['id'],
              'produitId': e['produitId'],
              'produitNom': e['produitNom'],
              'quantite': e['quantite'],
              'type': e['type'],
              'raison': e['raison'],
              'date': e['date'],
              'utilisateur': e['utilisateur'],
              'source': 'sale',
            }));
      }

      // Trier toutes les sorties par date décroissante
      exits.sort((a, b) => (b['date'] as int).compareTo(a['date'] as int));
      print('Total sorties récupérées : ${exits.length}');
      return exits;
    } catch (e) {
      print('Erreur lors de la récupération des sorties : $e');
      return [];
    }
  }

  static Future<void> addStockEntry(StockEntry entry) async {
    final db = await database;
    try {
      print('Ajout de l\'entrée de stock pour ${entry.produitNom}...');
      await db.transaction((txn) async {
        final produit = await txn.query(
          'produits',
          where: 'id = ?',
          whereArgs: [entry.produitId],
        );
        if (produit.isEmpty) throw Exception('Produit non trouvé');
        final currentStock = (produit.first['quantiteStock'] as num).toInt();
        await txn.update(
          'produits',
          {
            'quantiteStock': currentStock + entry.quantite,
            'derniereEntree': entry.date.millisecondsSinceEpoch,
          },
          where: 'id = ?',
          whereArgs: [entry.produitId],
        );
        await txn.insert('stock_entries', entry.toMap());
      });
      print('Entrée de stock ajoutée avec succès');
    } catch (e) {
      print('Erreur lors de l\'ajout de l\'entrée de stock : $e');
      throw e;
    }
  }

  static Future<List<StockEntry>> getStockEntries({
    String? typeFilter,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    try {
      print('Récupération des entrées de stock...');
      String? whereClause;
      List<dynamic> whereArgs = [];

      if (typeFilter != null) {
        whereClause = 'type = ?';
        whereArgs.add(typeFilter);
      }

      if (startDate != null && endDate != null) {
        final start = DateTime(startDate.year, startDate.month, startDate.day).millisecondsSinceEpoch;
        final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59).millisecondsSinceEpoch;
        whereClause = whereClause == null
            ? 'date BETWEEN ? AND ?'
            : '$whereClause AND date BETWEEN ? AND ?';
        whereArgs.add(start);
        whereArgs.add(end);
      }

      final maps = await db.query(
        'stock_entries',
        where: whereClause,
        whereArgs: whereArgs.isEmpty ? null : whereArgs,
        orderBy: 'date DESC',
      );

      print('Entrées de stock récupérées : ${maps.length}');
      return maps.map((map) {
        final dateMillis = map['date'] as int;
        return StockEntry(
          id: map['id'] as int,
          produitId: map['produitId'] as int,
          produitNom: map['produitNom'] as String,
          quantite: map['quantite'] as int,
          type: map['type'] as String,
          source: map['source'] as String?,
          date: DateTime.fromMillisecondsSinceEpoch(dateMillis),
          utilisateur: map['utilisateur'] as String,
        );
      }).toList();
    } catch (e) {
      print('Erreur lors de la récupération des entrées de stock : $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getSalesByProduct({
    DateTime? specificDay,
    DateTime? startDate,
    DateTime? endDate,
    String? vendor,
  }) async {
    final db = await database;
    try {
      print('Récupération des ventes par produit...');
      String whereClause = 'f.statut = ?';
      List<dynamic> whereArgs = ['Active'];

      if (specificDay != null) {
        final start = DateTime(specificDay.year, specificDay.month, specificDay.day).millisecondsSinceEpoch;
        final end = DateTime(specificDay.year, specificDay.month, specificDay.day, 23, 59, 59).millisecondsSinceEpoch;
        whereClause += ' AND f.date BETWEEN ? AND ?';
        whereArgs.add(start);
        whereArgs.add(end);
      } else if (startDate != null && endDate != null) {
        final start = DateTime(startDate.year, startDate.month, startDate.day).millisecondsSinceEpoch;
        final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59).millisecondsSinceEpoch;
        whereClause += ' AND f.date BETWEEN ? AND ?';
        whereArgs.add(start);
        whereArgs.add(end);
      }

      if (vendor != null && vendor.isNotEmpty) {
        whereClause += ' AND f.vendeurNom = ?';
        whereArgs.add(vendor);
      }

      final result = await db.rawQuery(
        '''
        SELECT p.id, p.nom, p.unite, SUM(bci.quantite) as totalQuantite, SUM(bci.quantite * bci.prixUnitaire) as totalCA
        FROM produits p
        JOIN bon_commande_items bci ON p.id = bci.produitId
        JOIN bons_commande bc ON bci.bonCommandeId = bc.id
        JOIN factures f ON bc.id = f.bonCommandeId
        LEFT JOIN users u ON f.vendeurNom = u.name
        WHERE $whereClause
        GROUP BY p.id, p.nom, p.unite
        ''',
        whereArgs,
      );

      print('Ventes par produit récupérées : ${result.length}');
      return result;
    } catch (e) {
      print('Erreur lors de la récupération des ventes par produit : $e');
      return [];
    }
  }

  static Future<List<Produit>> getLowStockProducts() async {
    final db = await database;
    try {
      print('Récupération des produits en rupture ou bientôt en rupture...');
      final List<Map<String, dynamic>> maps = await db.query(
        'produits',
        where: 'quantiteStock = 0 OR quantiteStock <= seuilAlerte',
      );
      print('Produits en rupture/bientôt en rupture récupérés : ${maps.length}');
      return List.generate(maps.length, (i) => Produit.fromMap(maps[i]));
    } catch (e) {
      print('Erreur lors de la récupération des produits en rupture : $e');
      return [];
    }
  }

  static Future<void> addSupplier(Supplier supplier) async {
    final db = await database;
    try {
      print('Ajout du fournisseur : ${supplier.name}...');
      await db.insert('suppliers', supplier.toMap());
      print('Fournisseur ajouté avec succès');
    } catch (e) {
      print('Erreur lors de l\'ajout du fournisseur : $e');
      throw e;
    }
  }

  static Future<void> updateSupplier(Supplier supplier) async {
    final db = await database;
    try {
      print('Mise à jour du fournisseur : ${supplier.name}...');
      await db.update(
        'suppliers',
        supplier.toMap(),
        where: 'id = ?',
        whereArgs: [supplier.id],
      );
      print('Fournisseur mis à jour avec succès');
    } catch (e) {
      print('Erreur lors de la mise à jour du fournisseur : $e');
      throw e;
    }
  }

  static Future<void> deleteSupplier(int id) async {
    final db = await database;
    try {
      print('Suppression du fournisseur avec id : $id...');
      await db.delete(
        'suppliers',
        where: 'id = ?',
        whereArgs: [id],
      );
      print('Fournisseur supprimé avec succès');
    } catch (e) {
      print('Erreur lors de la suppression du fournisseur : $e');
      throw e;
    }
  }

  static getDatabase() {}
}
