
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import '../models/models.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../constants/app_constants.dart';

class DatabaseHelper {
  static Database? _database;
  static bool _isInitializing = false;

  // Initialize database explicitly
  static Future<void> initializeDatabase() async {
    await database;
  }

  // Singleton-like database access
  static Future<Database> get database async {
    if (_database != null && await _database!.isOpen) {
      print('Base de données déjà ouverte');
      return _database!;
    }
    if (_isInitializing) {
      print('Initialisation de la base de données en cours, en attente...');
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return _database!;
    }
    print('Base de données fermée ou null, réinitialisation...');
    _isInitializing = true;
    try {
      _database = await _initDatabase();
      print('Base de données initialisée avec succès');
      return _database!;
    } catch (e) {
      print('Erreur lors de l\'initialisation de la base de données : $e');
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  static Future<Database> _initDatabase() async {
    final pathDb = path.join(await getDatabasesPath(), 'dashboard.db');
    print('Initialisation de la base de données à : $pathDb');
    return await openDatabase(
      pathDb,
      version: 14,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  static Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
    print('Clés étrangères activées');
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
        role TEXT NOT NULL,
        password TEXT NOT NULL
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
        quantite INTEGER NOT NULL,
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
        quantite INTEGER NOT NULL,
        type TEXT NOT NULL,
        source TEXT,
        date INTEGER NOT NULL,
        utilisateur TEXT NOT NULL,
        FOREIGN KEY (produitId) REFERENCES produits(id)
      )
    ''');

    print('Insertion de données initiales...');
    await db.insert('suppliers', Supplier(
      id: 0,
      name: 'Supplier X',
      productName: 'Article A',
      category: 'Électronique',
      price: 50.00,
    ).toMap());
    final adminPassword = _hashPassword('admin123');
    await db.insert('users', {
      'name': 'Admin',
      'role': AppConstants.ROLE_ADMIN,
      'password': adminPassword,
    });
    await db.insert('clients', Client(
      id: 0,
      nom: 'client X',
      email: 'jean.dupont@example.com',
      telephone: '123456789',
      adresse: '123 Rue Exemple, Lomé',
    ).toMap());
    print('Base de données initialisée avec succès.');
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
          quantite INTEGER NOT NULL,
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
      await db.insert('clients', Client(
        id: 0,
        nom: 'client X',
        email: 'jean.dupont@example.com',
        telephone: '123456789',
        adresse: '123 Rue Exemple, Lomé',
      ).toMap());
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
          quantite INTEGER NOT NULL,
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
          quantite INTEGER NOT NULL,
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
      await db.execute('ALTER TABLE users ADD COLUMN password TEXT NOT NULL DEFAULT "${_hashPassword("password")}"');
      await db.update(
        'users',
        {'password': _hashPassword('admin123')},
        where: 'name = ?',
        whereArgs: ['Admin'],
      );
    }
    print('Mise à jour terminée.');
  }

  static String _hashPassword(String password) {
    final hashed = sha256.convert(utf8.encode(password)).toString();
    print('Hachage du mot de passe : **** -> $hashed');
    return hashed;
  }

  static Future<void> resetAdminPassword() async {
    final db = await database;
    try {
      print('Réinitialisation du mot de passe Admin...');
      final adminPassword = _hashPassword('admin123');
      final result = await db.update(
        'users',
        {'password': adminPassword},
        where: 'name = ?',
        whereArgs: ['Admin'],
      );
      if (result > 0) {
        print('Mot de passe Admin réinitialisé avec succès');
      } else {
        print('Aucun utilisateur Admin trouvé, création...');
        await db.insert('users', {
          'name': 'Admin',
          'role': AppConstants.ROLE_ADMIN,
          'password': adminPassword,
        });
        print('Utilisateur Admin créé avec succès');
      }
    } catch (e) {
      print('Erreur lors de la réinitialisation du mot de passe : $e');
      throw e;
    }
  }

  static Future<List<Produit>> getProduits() async {
    final db = await database;
    try {
      print('Récupération des produits...');
      final maps = await db.query('produits');
      print('Produits récupérés : ${maps.length}');
      return maps.map((map) => Produit.fromMap(map)).toList();
    } catch (e) {
      print('Erreur lors de la récupération des produits : $e');
      return [];
    }
  }

  static Future<List<Supplier>> getSuppliers() async {
    final db = await database;
    try {
      print('Récupération des fournisseurs...');
      final maps = await db.query('suppliers');
      print('Fournisseurs récupérés : ${maps.length}');
      return maps.map((map) => Supplier.fromMap(map)).toList();
    } catch (e) {
      print('Erreur lors de la récupération des fournisseurs : $e');
      return [];
    }
  }

  static Future<List<User>> getUsers() async {
    final db = await database;
    try {
      print('Récupération des utilisateurs...');
      final maps = await db.query('users');
      print('Utilisateurs récupérés : ${maps.length}');
      return maps.map((map) => User.fromMap(map)).toList();
    } catch (e) {
      print('Erreur lors de la récupération des utilisateurs : $e');
      return [];
    }
  }

  static Future<void> addUser(User user) async {
    final db = await database;
    try {
      print('Ajout de l\'utilisateur : ${user.name}...');
      if (!AppConstants.isValidRole(user.role)) {
        throw Exception('Rôle utilisateur non valide : ${user.role}');
      }
      final hashedUser = User(
        id: user.id,
        name: user.name,
        role: user.role,
        password: _hashPassword(user.password),
      );
      await db.insert('users', hashedUser.toMap());
      print('Utilisateur ajouté avec succès avec le rôle : ${user.role}');
      await debugUsers();
    } catch (e) {
      print('Erreur lors de l\'ajout de l\'utilisateur : $e');
      throw e;
    }
  }

  static Future<void> updateUser(User user) async {
    final db = await database;
    try {
      print('Mise à jour de l\'utilisateur : ${user.name}...');
      if (!AppConstants.isValidRole(user.role)) {
        throw Exception('Rôle utilisateur non valide : ${user.role}');
      }
      final hashedUser = User(
        id: user.id,
        name: user.name,
        role: user.role,
        password: user.password.startsWith('\$') ? user.password : _hashPassword(user.password),
      );
      final result = await db.update(
        'users',
        hashedUser.toMap(),
        where: 'id = ?',
        whereArgs: [user.id],
      );
      if (result == 0) throw Exception('Utilisateur non trouvé');
      print('Utilisateur mis à jour avec succès');
      await debugUsers();
    } catch (e) {
      print('Erreur lors de la mise à jour de l\'utilisateur : $e');
      throw e;
    }
  }

  static Future<void> deleteUser(int id) async {
    final db = await database;
    try {
      print('Suppression de l\'utilisateur avec id : $id...');
      final result = await db.delete(
        'users',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (result == 0) throw Exception('Utilisateur non trouvé');
      print('Utilisateur supprimé avec succès');
      await debugUsers();
    } catch (e) {
      print('Erreur lors de la suppression de l\'utilisateur : $e');
      throw e;
    }
  }

  static Future<User?> loginUser(String name, String password) async {
    final db = await database;
    try {
      print('Tentative de connexion pour l\'utilisateur : $name...');
      final hashedPassword = _hashPassword(password);
      final maps = await db.query(
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
      throw e;
    }
  }

  static Future<List<Client>> getClients() async {
    final db = await database;
    try {
      print('Récupération des clients...');
      final maps = await db.query('clients');
      print('Clients récupérés : ${maps.length}');
      return maps.map((map) => Client.fromMap(map)).toList();
    } catch (e) {
      print('Erreur lors de la récupération des clients : $e');
      return [];
    }
  }

  static Future<List<Facture>> getFactures({bool includeArchived = false}) async {
    final db = await database;
    try {
      print('Récupération des factures...');
      final maps = await db.query(
        'factures',
        where: includeArchived ? null : 'statut = ?',
        whereArgs: includeArchived ? null : ['Active'],
      );
      print('Factures récupérées : ${maps.length}');
      return maps.map((map) => Facture.fromMap(map)).toList();
    } catch (e) {
      print('Erreur lors de la récupération des factures : $e');
      return [];
    }
  }

  static Future<FactureArchivee?> getArchivedFacture(int factureId) async {
    final db = await database;
    try {
      print('Récupération de la facture archivée pour factureId $factureId...');
      final maps = await db.query(
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
      final totalPaye = paiements.fold<double>(0.0, (sum, p) => sum + (p['montant'] as num));

      final facture = await db.query(
        'factures',
        where: 'id = ?',
        whereArgs: [factureId],
      );
      if (facture.isEmpty) throw Exception('Facture non trouvée');
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
      final result = await db.update(
        'produits',
        produit.toMap(),
        where: 'id = ?',
        whereArgs: [produit.id],
      );
      if (result == 0) throw Exception('Produit non trouvé');
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
      if (produit.isEmpty) throw Exception('Produit non trouvé');
      final currentStock = (produit.first['quantiteStock'] as num).toInt();
      final newStock = currentStock - quantite;
      if (newStock < 0) throw Exception('Stock insuffisant');
      await db.update(
        'produits',
        {'quantiteStock': newStock},
        where: 'id = ?',
        whereArgs: [produitId],
      );
      print('Stock mis à jour : $newStock');
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

  static Future<List<StockExit>> getStockExits({String? typeFilter}) async {
    final db = await database;
    try {
      print('Récupération des sorties de stock...');
      final maps = await db.query(
        'stock_exits',
        where: typeFilter != null ? 'type = ?' : null,
        whereArgs: typeFilter != null ? [typeFilter] : null,
        orderBy: 'date DESC',
      );
      print('Sorties de stock récupérées : ${maps.length}');
      return maps.map((map) => StockExit.fromMap(map)).toList();
    } catch (e) {
      print('Erreur lors de la récupération des sorties de stock : $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getAllExits({String? typeFilter}) async {
    final db = await database;
    try {
      print('Récupération de toutes les sorties (ventes + autres)...');
      List<Map<String, dynamic>> exits = [];

      final stockExits = await db.query(
        'stock_exits',
        where: typeFilter != null && typeFilter != 'sale' ? 'type = ?' : null,
        whereArgs: typeFilter != null && typeFilter != 'sale' ? [typeFilter] : null,
      );
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

      if (typeFilter == null || typeFilter == 'sale') {
        final saleExits = await db.rawQuery('''
          SELECT bci.id, bci.produitId, p.nom as produitNom, bci.quantite, 'sale' as type, 
                 f.numero as raison, f.date, u.name as utilisateur
          FROM bon_commande_items bci
          JOIN factures f ON f.bonCommandeId = bci.bonCommandeId
          JOIN produits p ON p.id = bci.produitId
          JOIN users u ON u.id = (SELECT id FROM users LIMIT 1)
          WHERE f.statut != 'Annulée'
        ''');
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
            'derniereEntree': entry.date,
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

  static Future<List<StockEntry>> getStockEntries({String? typeFilter}) async {
    final db = await database;
    try {
      print('Récupération des entrées de stock...');
      final maps = await db.query(
        'stock_entries',
        where: typeFilter != null ? 'type = ?' : null,
        whereArgs: typeFilter != null ? [typeFilter] : null,
        orderBy: 'date DESC',
      );
      print('Entrées de stock récupérées : ${maps.length}');
      return maps.map((map) => StockEntry.fromMap(map)).toList();
    } catch (e) {
      print('Erreur lors de la récupération des entrées de stock : $e');
      return [];
    }
  }

  static Future<List<Produit>> getLowStockProducts() async {
    final db = await database;
    try {
      print('Récupération des produits à faible stock...');
      final maps = await db.query(
        'produits',
        where: 'quantiteStock <= seuilAlerte',
      );
      print('Produits à faible stock récupérés : ${maps.length}');
      return maps.map((map) => Produit.fromMap(map)).toList();
    } catch (e) {
      print('Erreur lors de la récupération des produits à faible stock : $e');
      return [];
    }
  }

  static Future<void> debugUsers() async {
    final db = await database;
    try {
      print('Débogage des utilisateurs...');
      final users = await db.query('users');
      for (var user in users) {
        print('User: ${user['name']}, Password: ${user['password'].toString().substring(0, 8)}..., Role: ${user['role']}');
      }
      print('Total utilisateurs : ${users.length}');
    } catch (e) {
      print('Erreur lors du débogage des utilisateurs : $e');
    }
  }

  static Future<void> debugDatabaseState() async {
    final db = await database;
    try {
      print('Débogage de l\'état de la base de données...');
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      print('Tables: ${tables.map((t) => t['name']).join(', ')}');
      for (var table in tables) {
        final count = await db.rawQuery('SELECT COUNT(*) as count FROM ${table['name']}');
        print('Table ${table['name']}: ${count.first['count']} rows');
      }
    } catch (e) {
      print('Erreur lors du débogage de l\'état de la base de données : $e');
    }
  }

  static Future<void> addTestUser(String name, String password, String role) async {
    final db = await database;
    try {
      print('Ajout de l\'utilisateur test : $name avec le rôle : $role');
      if (!AppConstants.isValidRole(role)) {
        throw Exception('Rôle utilisateur non valide : $role');
      }
      final hashedPassword = _hashPassword(password);
      await db.insert('users', {
        'name': name,
        'role': role,
        'password': hashedPassword,
      });
      print('Utilisateur test ajouté avec succès');
      await debugUsers();
    } catch (e) {
      print('Erreur lors de l\'ajout de l\'utilisateur test : $e');
      throw e;
    }
  }
}
