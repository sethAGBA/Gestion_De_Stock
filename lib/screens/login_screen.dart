
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:otp/otp.dart';
import '../providers/auth_provider.dart';
import '../constants/app_constants.dart';
import '../helpers/database_helper.dart';
import '../models/models.dart';
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
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _obscureText = true;
  String? _errorMessage;
  bool _isOtpStep = false;
  String? _lastGeneratedOtp;
  bool _isTotpFlow = false;
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
    _otpController.dispose();
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

    if (_isOtpStep) {
      await _verifyOtp();
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

      final response = await authProvider.login(username, password);
      if (!mounted) return;

      switch (response.status) {
        case AuthStatus.success:
          _navigateAfterLogin(authProvider.userRole);
          break;
        case AuthStatus.requiresOtp:
          setState(() {
            _isOtpStep = true;
            _isTotpFlow = response.otp == null;
            _lastGeneratedOtp = response.otp;
            _errorMessage = null;
          });
          _otpController.clear();
          if (response.otp != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Code OTP (démo) : ${response.otp}'),
                duration: const Duration(seconds: 6),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ouvrez votre application d\'authentification pour générer un code à 6 chiffres.'),
                duration: Duration(seconds: 6),
              ),
            );
          }
          break;
        case AuthStatus.failure:
          setState(() {
            _isOtpStep = false;
            _lastGeneratedOtp = null;
            _isTotpFlow = false;
            _otpController.clear();
            _errorMessage = response.message ??
                authProvider.errorMessage ??
                'Erreur de connexion inconnue';
          });
          break;
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

  Future<void> _verifyOtp() async {
    final code = _otpController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _errorMessage = 'Entrez le code de vérification';
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
        return;
      }

      final response = await authProvider.verifyOtp(code);
      if (!mounted) return;

      if (response.status == AuthStatus.success) {
        setState(() {
          _isOtpStep = false;
          _lastGeneratedOtp = null;
          _isTotpFlow = false;
        });
        _navigateAfterLogin(authProvider.userRole);
      } else {
        setState(() {
          _errorMessage = response.message ?? 'Code OTP invalide';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur technique : $e';
      });
      debugPrint('OTP verification error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendOtp() async {
    if (_isTotpFlow) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Utilisez votre application d\'authentification pour générer un nouveau code.'),
        ),
      );
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
        return;
      }

      final newOtp = await authProvider.resendOtp();
      if (!mounted) return;
      if (newOtp == null) {
        setState(() {
          _errorMessage = authProvider.errorMessage ?? 'Impossible de renvoyer le code';
        });
      } else {
        setState(() {
          _lastGeneratedOtp = newOtp;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nouveau code OTP (démo) : $newOtp'),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur technique : $e';
      });
      debugPrint('Resend OTP error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _cancelOtpFlow() {
    final authProvider = context.read<AuthProvider?>();
    authProvider?.cancelOtp();
    setState(() {
      _isOtpStep = false;
      _lastGeneratedOtp = null;
      _isTotpFlow = false;
      _otpController.clear();
      _errorMessage = null;
    });
  }

  void _navigateAfterLogin(String? userRole) {
    if (!mounted) return;
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
  }

  Future<void> _restoreAdminAccount() async {
    _cancelOtpFlow();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await DatabaseHelper.restoreAdminAccount();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Compte administrateur restauré (Admin / admin123).'),
        ),
      );
    } catch (e) {
      debugPrint('Restore admin error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Impossible de restaurer le compte administrateur';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _confirmRestoreAdmin() async {
    final shouldRestore = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurer le compte admin'),
        content: const Text(
          'Cette action réinitialise le compte administrateur avec le mot de passe par défaut (admin123). \nVoulez-vous continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restaurer'),
          ),
        ],
      ),
    );
    if (shouldRestore == true) {
      final allowed = await _verifyAdminOtpIfNeeded();
      if (!allowed) {
        return;
      }
      await _restoreAdminAccount();
      if (mounted) {
        _nameController.text = 'Admin';
        _passwordController.text = 'admin123';
      }
    }
  }

  Future<bool> _verifyAdminOtpIfNeeded() async {
    try {
      final users = await DatabaseHelper.getUsers();
      final admin = users.firstWhere(
        (u) => u.name.toLowerCase() == 'admin',
        orElse: () => User(id: 0, name: '', role: '', password: ''),
      );
      if (admin.id == 0 || !admin.otpEnabled || admin.otpSecret == null || admin.otpSecret!.isEmpty) {
        return true;
      }
      return await _promptForAdminOtp(admin) ?? false;
    } catch (e) {
      debugPrint('Erreur lors de la vérification OTP admin: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de vérifier le code OTP: $e')),
      );
      return false;
    }
  }

  Future<bool?> _promptForAdminOtp(User admin) async {
    final controller = TextEditingController();
    String? localError;
    bool isVerifying = false;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Code de vérification requis'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Entrez le code à 6 chiffres généré par votre application d\'authentification pour l\'administrateur.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: 'Code OTP',
                  counterText: '',
                  errorText: localError,
                  prefixIcon: const Icon(Icons.shield),
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) {
                  if (localError != null) {
                    setDialogState(() => localError = null);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isVerifying ? null : () => Navigator.of(dialogContext).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: isVerifying
                  ? null
                  : () async {
                      final code = controller.text.trim();
                      if (code.length != 6) {
                        setDialogState(() => localError = 'Code invalide');
                        return;
                      }
                      setDialogState(() {
                        isVerifying = true;
                        localError = null;
                      });
                      final valid = _validateTotpCode(admin.otpSecret!, code);
                      if (valid) {
                        Navigator.of(dialogContext).pop(true);
                      } else {
                        setDialogState(() {
                          isVerifying = false;
                          localError = 'Code incorrect';
                        });
                      }
                    },
              child: isVerifying
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Valider'),
            ),
          ],
        ),
      ),
    );
  }

  bool _validateTotpCode(String secret, String code) {
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
                            enabled: !_isOtpStep && !_isLoading,
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
                            enabled: !_isOtpStep && !_isLoading,
                            obscureText: _obscureText,
                            textInputAction: TextInputAction.done,
                            onChanged: (_) => setState(() => _errorMessage = null),
                            onSubmitted: (_) => _login(),
                          ),
                          if (_isOtpStep) ...[
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: theme.primaryColor.withOpacity(0.4)),
                              ),
                              child: Text(
                                _isTotpFlow
                                    ? 'Ouvrez votre application d\'authentification et saisissez le code à 6 chiffres affiché.'
                                    : _lastGeneratedOtp == null
                                        ? 'Entrez le code à 6 chiffres reçu pour valider la connexion.'
                                        : 'Entrez le code à 6 chiffres reçu pour valider la connexion. (Code démo : $_lastGeneratedOtp)',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _otpController,
                              decoration: InputDecoration(
                                labelText: 'Code de vérification',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.verified_user),
                                filled: true,
                                fillColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade100,
                              ),
                              enabled: !_isLoading,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              buildCounter: (
                                context, {
                                required int currentLength,
                                required bool isFocused,
                                int? maxLength,
                              }) => null,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              textInputAction: TextInputAction.done,
                              onChanged: (_) => setState(() => _errorMessage = null),
                              onSubmitted: (_) => _verifyOtp(),
                            ),
                          ],
                          const SizedBox(height: 24),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: _isLoading
                                ? const CircularProgressIndicator()
                                : ElevatedButton(
                                    onPressed: _isOtpStep ? _verifyOtp : _login,
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
                                    child: Text(
                                      _isOtpStep ? 'Vérifier le code' : 'Se connecter',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 12),
                          if (_isOtpStep) ...[
                            Row(
                              children: [
                                if (!_isTotpFlow) ...[
                                  Expanded(
                                    child: TextButton(
                                      onPressed: _isLoading ? null : _resendOtp,
                                      child: const Text('Renvoyer le code'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                ],
                                Expanded(
                                  child: TextButton(
                                    onPressed: _isLoading ? null : _cancelOtpFlow,
                                    child: const Text('Annuler'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                          TextButton.icon(
                            onPressed: _isLoading ? null : _confirmRestoreAdmin,
                            icon: const Icon(Icons.restore),
                            label: const Text('Restaurer le compte administrateur'),
                            style: TextButton.styleFrom(
                              foregroundColor: theme.primaryColor,
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
