import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import '../models/models.dart';

class DashboardProvider with ChangeNotifier {
  List<Produit> _produits = [];
  List<Supplier> _suppliers = [];
  List<User> _users = [];
  int _productsSold = 0;
  bool _isLoading = false;
  String? _errorMessage;
  int _fetchCount = 0;

  List<Produit> get produits => _produits;
  List<Supplier> get suppliers => _suppliers;
  List<User> get users => _users;
  int get productsSold => _productsSold;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchDashboardData() async {
    if (_isLoading) {
      print('Fetch already in progress, ignoring attempt #${_fetchCount + 1}');
      return;
    }
    _isLoading = true;
    _fetchCount++;
    _errorMessage = null;
    notifyListeners();

    try {
      print('Fetching dashboard data (attempt #$_fetchCount)...');
      final produitsFuture = DatabaseHelper.getProduits();
      final suppliersFuture = DatabaseHelper.getSuppliers();
      final usersFuture = DatabaseHelper.getUsers();
      final productsSoldFuture = DatabaseHelper.getTotalProductsSold();

      final results = await Future.wait([
        produitsFuture,
        suppliersFuture,
        usersFuture,
        productsSoldFuture,
      ]);

      _produits = results[0] as List<Produit>;
      _suppliers = results[1] as List<Supplier>;
      _users = results[2] as List<User>;
      _productsSold = results[3] as int;

      print('Fetched ${_produits.length} produits, ${_suppliers.length} fournisseurs, ${_users.length} utilisateurs, $_productsSold produits vendus');
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des données : $e';
      print(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearData() {
    _produits = [];
    _suppliers = [];
    _users = [];
    _productsSold = 0;
    _errorMessage = null;
    notifyListeners();
  }
}