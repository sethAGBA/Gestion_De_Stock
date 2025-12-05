import 'package:flutter/material.dart';
import 'package:otp/otp.dart';
import '../helpers/database_helper.dart';
import '../models/models.dart';
import '../constants/app_constants.dart';

enum AuthStatus { success, requiresOtp, failure }

class AuthResponse {
  final AuthStatus status;
  final String? message;
  final String? otp;

  const AuthResponse({required this.status, this.message, this.otp});
}

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isAuthenticated = false;
  String? _errorMessage;
  User? _pendingUser;
  String? _pendingOtpSecret;
  bool _otpRequired = false;

  User? get currentUser => _currentUser;

  bool get isAuthenticated => _isAuthenticated;

  bool get isAdmin => _currentUser?.role == AppConstants.ROLE_ADMIN;

  String? get userRole => _currentUser?.role;

  String? get errorMessage => _errorMessage;

  bool get isOtpRequired => _otpRequired;

  void cancelOtp() {
    _pendingUser = null;
    _pendingOtpSecret = null;
    _otpRequired = false;
    _errorMessage = null;
    notifyListeners();
  }

  Future<AuthResponse> login(String name, String password) async {
    try {
      debugPrint('Tentative de connexion pour : $name');
      _errorMessage = null; // Clear previous errors
      _pendingUser = null;
      _pendingOtpSecret = null;
      _otpRequired = false;
      _isAuthenticated = false;
      _currentUser = null;

      final user = await DatabaseHelper.loginUser(name, password);

      if (user == null) {
        _errorMessage = 'Nom d\'utilisateur ou mot de passe incorrect';
        debugPrint('Échec de connexion : $_errorMessage');
        notifyListeners();
        return AuthResponse(status: AuthStatus.failure, message: _errorMessage);
      }

      // Validate role against DatabaseHelper's allowed roles
      const validRoles = ['Administrateur', 'Vendeur', 'Client'];
      if (!validRoles.contains(user.role)) {
        _errorMessage = 'Rôle utilisateur non reconnu : ${user.role}';
        debugPrint('Échec de connexion : $_errorMessage');
        notifyListeners();
        return AuthResponse(status: AuthStatus.failure, message: _errorMessage);
      }

      if (user.otpEnabled) {
        if (user.otpSecret == null || user.otpSecret!.isEmpty) {
          _errorMessage = 'La double authentification est mal configurée pour cet utilisateur.';
          debugPrint('Échec de connexion : $_errorMessage');
          notifyListeners();
          return AuthResponse(status: AuthStatus.failure, message: _errorMessage);
        }
        _pendingUser = user;
        _pendingOtpSecret = user.otpSecret;
        _otpRequired = true;
        debugPrint('OTP requis pour ${user.name}.');
        notifyListeners();
        return const AuthResponse(status: AuthStatus.requiresOtp);
      }

      _currentUser = user;
      _isAuthenticated = true;
      debugPrint('Connexion réussie pour : ${user.name} avec le rôle : ${user.role}');
      notifyListeners();
      return const AuthResponse(status: AuthStatus.success);
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
      return AuthResponse(status: AuthStatus.failure, message: _errorMessage);
    }
  }

  Future<AuthResponse> verifyOtp(String otpInput) async {
    if (!_otpRequired || _pendingUser == null) {
      _errorMessage = 'Aucune vérification en cours';
      notifyListeners();
      return AuthResponse(status: AuthStatus.failure, message: _errorMessage);
    }

    if (otpInput.isEmpty) {
      _errorMessage = 'Entrez le code de vérification';
      notifyListeners();
      return AuthResponse(status: AuthStatus.failure, message: _errorMessage);
    }

    final secret = _pendingOtpSecret ?? _pendingUser?.otpSecret;
    if (secret == null || secret.isEmpty) {
      _errorMessage = 'Secret OTP introuvable';
      notifyListeners();
      return AuthResponse(status: AuthStatus.failure, message: _errorMessage);
    }

    if (!_validateTotp(secret, otpInput)) {
      _errorMessage = 'Code de vérification invalide';
      notifyListeners();
      return AuthResponse(status: AuthStatus.failure, message: _errorMessage);
    }

    _currentUser = _pendingUser;
    _isAuthenticated = true;
    _pendingUser = null;
    _pendingOtpSecret = null;
    _otpRequired = false;
    _errorMessage = null;
    debugPrint('OTP validé, connexion établie pour ${_currentUser?.name}.');
    notifyListeners();
    return const AuthResponse(status: AuthStatus.success);
  }

  Future<String?> resendOtp() async {
    _errorMessage = 'Utilisez votre application d\'authentification pour générer un nouveau code.';
    notifyListeners();
    return null;
  }

  bool _validateTotp(String secret, String code) {
    final sanitized = code.replaceAll(' ', '');
    if (sanitized.length != 6) {
      return false;
    }
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    for (final offset in [-1, 0, 1]) {
      final currentTime = timestamp + (offset * 30000);
      final generated = OTP.generateTOTPCodeString(
        secret,
        currentTime,
        interval: 30,
        length: 6,
        algorithm: Algorithm.SHA1,
        isGoogle: true,
      );
      if (generated == sanitized) {
        return true;
      }
    }
    return false;
  }

  void logout() {
    debugPrint('Déconnexion de ${_currentUser?.name ?? "utilisateur inconnu"}');
    _currentUser = null;
    _isAuthenticated = false;
    _errorMessage = null;
    _pendingUser = null;
    _pendingOtpSecret = null;
    _otpRequired = false;
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
