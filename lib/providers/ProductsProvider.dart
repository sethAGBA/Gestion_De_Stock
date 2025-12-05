import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import '../models/models.dart';

class ProductsProvider with ChangeNotifier {
  List<Produit> _produits = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Produit> get produits => _produits;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Database? _database;

  Future<void> initDatabase() async {
    if (_database != null) return;
    print('Initialisation de ProductsProvider database...');
    _database = await openDatabase(
      path.join(await getDatabasesPath(), 'dashboard.db'),
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
        print('Clés étrangères activées dans ProductsProvider');
      },
    );
    print('ProductsProvider database initialisée');
    await fetchProducts();
  }

  Future<void> fetchProducts({bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) return;
    _isLoading = true;
    notifyListeners();

    try {
      final List<Map<String, dynamic>> maps = await _database!.query('produits');
      _produits = List.generate(maps.length, (i) => Produit.fromMap(maps[i]));
      _errorMessage = null;
      print('Produits récupérés : ${_produits.length}');
    } catch (e) {
      _errorMessage = e.toString();
      print('Erreur lors de la récupération des produits : $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addProduct(Produit produit) async {
    try {
      await _database!.insert('produits', produit.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      await fetchProducts(forceRefresh: true);
      print('Produit ajouté : ${produit.nom}');
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      throw e;
    }
  }

  Future<void> updateProduct(Produit produit) async {
    try {
      await _database!.update(
        'produits',
        produit.toMap(),
        where: 'id = ?',
        whereArgs: [produit.id],
      );
      await fetchProducts(forceRefresh: true);
      print('Produit mis à jour : ${produit.nom}');
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      throw e;
    }
  }

  Future<void> declareDamaged(int produitId, String produitNom, int quantite, String utilisateur) async {
    try {
      final produit = _produits.firstWhere((p) => p.id == produitId);
      await _database!.update(
        'produits',
        {
          'quantiteStock': produit.quantiteStock - quantite,
          'quantiteAvariee': produit.quantiteAvariee + quantite,
        },
        where: 'id = ?',
        whereArgs: [produitId],
      );
      await _database!.insert(
        'historique_avaries',
        {
          'produitId': produitId,
          'produitNom': produitNom,
          'quantite': quantite,
          'action': 'declare',
          'utilisateur': utilisateur,
          'date': DateTime.now().millisecondsSinceEpoch,
        },
      );
      await fetchProducts(forceRefresh: true);
      print('Avarie déclarée pour produit $produitId');
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      throw e;
    }
  }

  Future<void> handleDamagedAction(int produitId, String produitNom, String action, String utilisateur) async {
    try {
      final produit = _produits.firstWhere((p) => p.id == produitId);
      await _database!.update(
        'produits',
        {'quantiteAvariee': 0},
        where: 'id = ?',
        whereArgs: [produitId],
      );
      await _database!.insert(
        'historique_avaries',
        {
          'produitId': produitId,
          'produitNom': produitNom,
          'quantite': produit.quantiteAvariee,
          'action': action,
          'utilisateur': utilisateur,
          'date': DateTime.now().millisecondsSinceEpoch,
        },
      );
      await fetchProducts(forceRefresh: true);
      print('Action $action effectuée pour produit $produitId');
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      throw e;
    }
  }

  @override
  void dispose() {
    _database?.close();
    super.dispose();
  }
}