
import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import '../models/models.dart';
import '../constants/app_constants.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isAuthenticated = false;
  String? _errorMessage;

  User? get currentUser {
    print('Accessing currentUser: ${_currentUser?.name}');
    return _currentUser;
  }

  bool get isAuthenticated {
    print('Checking isAuthenticated: $_isAuthenticated');
    return _isAuthenticated;
  }

  bool get isAdmin {
    print('Checking isAdmin: ${_currentUser?.role == AppConstants.ROLE_ADMIN}');
    return _currentUser?.role == AppConstants.ROLE_ADMIN;
  }

  String? get userRole {
    print('Accessing userRole: ${_currentUser?.role}');
    return _currentUser?.role;
  }

  String? get errorMessage => _errorMessage;

  Future<bool> login(String name, String password) async {
    try {
      print('Tentative de connexion pour : $name');
      await DatabaseHelper.debugDatabaseState();
      _errorMessage = null;

      final user = await DatabaseHelper.loginUser(name, password);

      if (user == null) {
        _errorMessage = 'Identifiants incorrects';
        print('Échec de connexion : $_errorMessage');
        notifyListeners();
        return false;
      }

      // Vérifier si le rôle est valide
      if (!AppConstants.isValidRole(user.role)) {
        _errorMessage = 'Rôle utilisateur non reconnu : ${user.role}';
        print('Échec de connexion : $_errorMessage');
        notifyListeners();
        return false;
      }

      _currentUser = user;
      _isAuthenticated = true;
      print('Connexion réussie pour : ${user.name} avec le rôle : ${user.role}');
      notifyListeners();
      return true;

    } catch (e) {
      _errorMessage = 'Erreur technique : $e';
      print('Erreur de connexion : $_errorMessage');
      notifyListeners();
      return false;
    }
  }

  void logout() {
    print('Déconnexion effectuée');
    _currentUser = null;
    _isAuthenticated = false;
    _errorMessage = null;
    notifyListeners();
  }
}
