
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../constants/app_constants.dart';
import 'dashboard_screen.dart';
import 'vendor_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureText = true;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final username = _nameController.text.trim();
    final password = _passwordController.text;

    // Validate inputs
    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez remplir tous les champs';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider?>();
      if (authProvider == null) {
        setState(() {
          _errorMessage = 'Erreur : AuthProvider non configuré';
          _isLoading = false;
        });
        debugPrint('AuthProvider not found in widget tree');
        return;
      }

      final success = await authProvider.login(username, password);
      if (success && context.mounted) {
        final userRole = authProvider.userRole;
        if (userRole == AppConstants.ROLE_ADMIN) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        } else if (userRole == AppConstants.ROLE_VENDEUR) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const VendorDashboardScreen()),
          );
        } else {
          setState(() {
            _errorMessage = 'Rôle non supporté : $userRole';
          });
        }
      } else if (context.mounted) {
        setState(() {
          _errorMessage = authProvider.errorMessage ?? 'Erreur de connexion inconnue';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur technique : $e';
      });
      debugPrint('Login error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [Colors.grey.shade900, Colors.grey.shade800]
                : [theme.primaryColor.withOpacity(0.8), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: screenSize.width > 1200
                    ? screenSize.width * 0.3
                    : screenSize.width > 600
                        ? screenSize.width * 0.1
                        : 24,
                vertical: 16,
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: isDarkMode ? Colors.grey.shade800 : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.store,
                            size: 64,
                            color: theme.primaryColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Gestion de Stock',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Connectez-vous pour gérer votre stock',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (_errorMessage != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error, color: Colors.red),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Nom d\'utilisateur',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.person),
                              filled: true,
                              fillColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade100,
                              errorText: _errorMessage != null &&
                                      _nameController.text.trim().isEmpty
                                  ? 'Champ requis'
                                  : null,
                            ),
                            textInputAction: TextInputAction.next,
                            onChanged: (_) => setState(() => _errorMessage = null),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'Mot de passe',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureText ? Icons.visibility : Icons.visibility_off,
                                  color: theme.iconTheme.color?.withOpacity(0.6),
                                ),
                                onPressed: () => setState(() => _obscureText = !_obscureText),
                              ),
                              filled: true,
                              fillColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade100,
                              errorText: _errorMessage != null && _passwordController.text.isEmpty
                                  ? 'Champ requis'
                                  : null,
                            ),
                            obscureText: _obscureText,
                            textInputAction: TextInputAction.done,
                            onChanged: (_) => setState(() => _errorMessage = null),
                            onSubmitted: (_) => _login(),
                          ),
                          const SizedBox(height: 24),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: _isLoading
                                ? const CircularProgressIndicator()
                                : ElevatedButton(
                                    onPressed: _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: theme.primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 32,
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 2,
                                      minimumSize: const Size(double.infinity, 50),
                                    ),
                                    child: const Text(
                                      'Se connecter',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
