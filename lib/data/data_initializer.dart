
import 'package:sqflite/sqflite.dart';

class DataInitializer {
  static Future<void> initializeDefaultData(Database db) async {
    print('Initialisation des données par défaut...');
    await _initializeDefaultUsers(db);
    await _initializeDefaultProducts(db);
    await _initializeDefaultClients(db);
    print('Données par défaut initialisées avec succès.');
  }

  static Future<void> _initializeDefaultUsers(Database db) async {
    print('Insertion des utilisateurs par défaut...');
    final users = [
      {
        'name': 'Admin',
        'role': 'Administrateur',
        'password': 'admin123', // À hasher dans la production
      },
      {
        'name': 'Employee',
        'role': 'Employé',
        'password': 'employee123', // À hasher dans la production
      },
    ];

    for (var user in users) {
      await db.insert('users', user, conflictAlgorithm: ConflictAlgorithm.ignore);
      print('Utilisateur ${user['name']} inséré.');
    }
  }

  static Future<void> _initializeDefaultProducts(Database db) async {
    print('Insertion des produits par défaut...');
    final products = [
      {
        'nom': 'Huile végétale',
        'description': 'Huile de cuisson',
        'categorie': 'Alimentation',
        'unite': 'Litre',
        'quantiteStock': 100,
        'quantiteAvariee': 0,
        'stockMin': 20,
        'stockMax': 200,
        'seuilAlerte': 30,
        'prixAchat': 800.0,
        'prixVente': 1000.0,
        'tva': 0.0,
        'statut': 'disponible',
      },
    ];

    for (var product in products) {
      await db.insert('produits', product, conflictAlgorithm: ConflictAlgorithm.ignore);
      print('Produit ${product['nom']} inséré.');
    }
  }

  static Future<void> _initializeDefaultClients(Database db) async {
    print('Insertion des clients par défaut...');
    final clients = [
      {
        'nom': 'Client Régulier',
        'email': 'client@example.com',
        'telephone': '90123456',
        'adresse': 'Lomé, Togo',
      },
      {
        'nom': 'client X',
        'email': 'jean.dupont@example.com',
        'telephone': '123456789',
        'adresse': '123 Rue Exemple, Lomé',
      },
    ];

    for (var client in clients) {
      await db.insert('clients', client, conflictAlgorithm: ConflictAlgorithm.ignore);
      print('Client ${client['nom']} inséré.');
    }
  }
}
