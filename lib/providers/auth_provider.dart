import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import '../models/models.dart';
import '../constants/app_constants.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isAuthenticated = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;

  bool get isAuthenticated => _isAuthenticated;

  bool get isAdmin => _currentUser?.role == AppConstants.ROLE_ADMIN;

  String? get userRole => _currentUser?.role;

  String? get errorMessage => _errorMessage;

  Future<bool> login(String name, String password) async {
    try {
      debugPrint('Tentative de connexion pour : $name');
      _errorMessage = null; // Clear previous errors

      final user = await DatabaseHelper.loginUser(name, password);

      if (user == null) {
        _errorMessage = 'Nom d\'utilisateur ou mot de passe incorrect';
        debugPrint('Échec de connexion : $_errorMessage');
        notifyListeners();
        return false;
      }

      // Validate role against DatabaseHelper's allowed roles
      const validRoles = ['Administrateur', 'Vendeur', 'Client'];
      if (!validRoles.contains(user.role)) {
        _errorMessage = 'Rôle utilisateur non reconnu : ${user.role}';
        debugPrint('Échec de connexion : $_errorMessage');
        notifyListeners();
        return false;
      }

      _currentUser = user;
      _isAuthenticated = true;
      debugPrint('Connexion réussie pour : ${user.name} avec le rôle : ${user.role}');
      notifyListeners();
      return true;
    } catch (e) {
      // Differentiate error types
      String error;
      if (e.toString().contains('database_closed')) {
        error = 'Erreur de base de données : connexion fermée';
      } else if (e is FormatException) {
        error = 'Erreur de format des données';
      } else {
        error = 'Erreur technique : $e';
      }
      _errorMessage = error;
      debugPrint('Erreur de connexion : $_errorMessage');
      notifyListeners();
      return false;
    }
  }

  void logout() {
    debugPrint('Déconnexion de ${_currentUser?.name ?? "utilisateur inconnu"}');
    _currentUser = null;
    _isAuthenticated = false;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> checkSession() async {
    if (_currentUser == null || !_isAuthenticated) {
      return false;
    }
    try {
      final users = await DatabaseHelper.getUsers();
      final userExists = users.any((u) => u.id == _currentUser!.id && u.name == _currentUser!.name);
      if (!userExists) {
        logout();
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la vérification de session : $e');
      logout();
      return false;
    }
  }
}