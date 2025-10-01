import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../helpers/database_helper.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../constants/screen_permissions.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';
import 'package:qr_flutter/qr_flutter.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  String _selectedFilter = 'all'; // Filter: 'all', 'Administrateur', 'Vendeur'
  final _searchController = TextEditingController();
  String? _searchQuery;
  bool _isLoading = false;
  final Random _secureRandom = Random.secure();

  static const String _otpIssuer = 'GestionDeStock';
  static const String _base32Alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

  String _generateOtpSecret({int length = 32}) {
    final buffer = StringBuffer();
    for (var i = 0; i < length; i++) {
      buffer.write(_base32Alphabet[_secureRandom.nextInt(_base32Alphabet.length)]);
    }
    return buffer.toString();
  }

  String _buildOtpAuthUri(String accountName, String secret) {
    final sanitizedAccount = accountName.isEmpty ? 'Utilisateur' : accountName;
    final label = Uri.encodeComponent('$_otpIssuer:$sanitizedAccount');
    final issuerParam = Uri.encodeComponent(_otpIssuer);
    return 'otpauth://totp/$label?secret=$secret&issuer=$issuerParam&digits=6&period=30';
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _searchQuery = _searchController.text.trim().toLowerCase();
          });
        }
      });
    });
    debugPrint('UsersScreen initialized');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des utilisateurs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Ajouter un utilisateur',
            onPressed: _isLoading ? null : () => _showAddUserDialog(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 80), // Space for FAB
            child: Column(
              children: [
                _buildHeader(theme, isDarkMode),
                _buildFilters(theme),
                Expanded(child: _buildUsersList(isDarkMode)),
              ],
            ),
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'users_fab',
        onPressed: _isLoading ? null : () => _showAddUserDialog(context),
        backgroundColor: theme.primaryColor,
        elevation: 6,
        tooltip: 'Ajouter un utilisateur',
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people, color: theme.primaryColor, size: 32),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Utilisateurs',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gestion des profils et rôles',
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher par nom...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(theme, 'Tous', 'all'),
            const SizedBox(width: 8),
            _buildFilterChip(theme, 'Administrateurs', 'Administrateur'),
            const SizedBox(width: 8),
            _buildFilterChip(theme, 'Vendeurs', 'Vendeur'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(ThemeData theme, String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = selected ? value : 'all';
        });
      },
      backgroundColor: isSelected ? theme.primaryColor.withOpacity(0.1) : null,
      selectedColor: theme.primaryColor.withOpacity(0.2),
      checkmarkColor: theme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? theme.primaryColor : theme.textTheme.bodyMedium?.color,
      ),
    );
  }

  Widget _buildUsersList(bool isDarkMode) {
    return FutureBuilder<List<User>>(
      future: DatabaseHelper.getUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          debugPrint('Users list error: ${snapshot.error}');
          return Center(
            child: Text(
              'Erreur : ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        final users = snapshot.data ?? [];
        if (users.isEmpty) {
          return _buildEmptyState();
        }

        final filteredUsers = users.where((user) {
          final matchesSearch = _searchQuery == null || user.name.toLowerCase().contains(_searchQuery!);
          final matchesFilter = _selectedFilter == 'all' || user.role == _selectedFilter;
          return matchesSearch && matchesFilter;
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Liste des utilisateurs (${filteredUsers.length})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredUsers.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  return _buildUserCard(filteredUsers[index], isDarkMode);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserCard(User user, bool isDarkMode) {
    final roleColor = user.role == 'Administrateur'
        ? Colors.blue
        : user.role == 'Vendeur'
            ? Colors.orange
            : Colors.green;
    return Card(
      elevation: 0,
      color: isDarkMode ? Colors.grey.shade800 : roleColor.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: roleColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                user.role == 'Administrateur'
                    ? Icons.admin_panel_settings
                    : user.role == 'Vendeur'
                        ? Icons.store
                        : Icons.person,
                color: roleColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rôle: ${user.role}',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        user.otpEnabled ? Icons.shield : Icons.shield_outlined,
                        size: 16,
                        color: user.otpEnabled ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        user.otpEnabled ? 'OTP activé' : 'OTP désactivé',
                        style: TextStyle(
                          fontSize: 13,
                          color: user.otpEnabled ? Colors.green : Colors.grey.shade600,
                          fontWeight: user.otpEnabled ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: _isLoading ? null : () => _showEditUserDialog(context, user),
              tooltip: 'Modifier',
            ),
            IconButton(
              icon: Icon(
                user.otpEnabled ? Icons.qr_code_2 : Icons.qr_code,
                color: user.otpEnabled ? Colors.green : Colors.grey.shade600,
              ),
              onPressed: _isLoading ? null : () => _showOtpDialog(context, user),
              tooltip: user.otpEnabled ? 'Gérer l\'authentification à deux facteurs' : 'Activer l\'authentification à deux facteurs',
            ),
            IconButton(
              icon: const Icon(Icons.rule_folder, color: Colors.teal),
              onPressed: _isLoading ? null : () => _showPermissionsDialog(context, user),
              tooltip: 'Autorisations des écrans',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _isLoading ? null : () => _confirmDeleteUser(context, user),
              tooltip: 'Supprimer',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'Aucun utilisateur enregistré',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez un utilisateur avec le bouton +',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddUserDialog(BuildContext context) async {
    debugPrint('Opening add user dialog');
    String? name;
    String? role;
    String? password;
    String? confirmPassword;
    bool isValid = false;
    bool obscurePassword = true;
    bool obscureConfirmPassword = true;
    final roles = ['Administrateur', 'Vendeur'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nouvel utilisateur'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Nom',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setDialogState(() {
                      name = value.trim();
                      isValid = _validateForm(
                        name,
                        role,
                        password,
                        confirmPassword: confirmPassword,
                      );
                    });
                  },
                  validator: (value) => value == null || value.trim().isEmpty ? 'Entrez un nom' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Rôle',
                    border: OutlineInputBorder(),
                  ),
                  items: roles.map((role) {
                    return DropdownMenuItem(value: role, child: Text(role));
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      role = value;
                      isValid = _validateForm(
                        name,
                        role,
                        password,
                        confirmPassword: confirmPassword,
                      );
                    });
                  },
                  validator: (value) => value == null ? 'Sélectionnez un rôle' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(obscurePassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setDialogState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                    ),
                  ),
                  obscureText: obscurePassword,
                  onChanged: (value) {
                    setDialogState(() {
                      password = value;
                      isValid = _validateForm(
                        name,
                        role,
                        password,
                        confirmPassword: confirmPassword,
                      );
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Entrez un mot de passe';
                    }
                    if (value.length < 6) {
                      return 'Minimum 6 caractères';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Confirmer le mot de passe',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          obscureConfirmPassword = !obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  obscureText: obscureConfirmPassword,
                  onChanged: (value) {
                    setDialogState(() {
                      confirmPassword = value;
                      isValid = _validateForm(
                        name,
                        role,
                        password,
                        confirmPassword: confirmPassword,
                      );
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Confirmez le mot de passe';
                    }
                    if (password != null && value != password) {
                      return 'Les mots de passe ne correspondent pas';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: isValid
                  ? () async {
                      setState(() => _isLoading = true);
                      try {
                        final existingUsers = await DatabaseHelper.getUsers();
                        if (existingUsers.any((u) => u.name.toLowerCase() == name!.toLowerCase())) {
                          throw Exception('Un utilisateur avec ce nom existe déjà');
                        }
                        final hashedPassword = _hashPassword(password!);
                        final user = User(
                          id: 0, // Auto-incremented by DB
                          name: name!,
                          role: role!,
                          password: hashedPassword,
                          otpEnabled: false,
                          otpSecret: null,
                        );
                        await DatabaseHelper.addUser(user);
                        final currentUser = context.read<AuthProvider?>()?.currentUser?.name ?? 'Inconnu';
                        debugPrint('User added by $currentUser: ${user.name}');
                        if (context.mounted) {
                          Navigator.pop(context);
                          setState(() => _isLoading = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Utilisateur ajouté avec succès')),
                          );
                        }
                      } catch (e) {
                        debugPrint('Error adding user: $e');
                        if (context.mounted) {
                          setState(() => _isLoading = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erreur : $e')),
                          );
                        }
                      }
                    }
                  : null,
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditUserDialog(BuildContext context, User user) async {
    debugPrint('Opening edit user dialog');
    final roles = ['Administrateur', 'Vendeur'];
    if (!roles.contains(user.role)) {
      debugPrint('Invalid role for user ${user.name}: ${user.role}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rôle invalide pour ${user.name}: ${user.role}')),
        );
      }
      return;
    }
    final users = await DatabaseHelper.getUsers();
    final adminUsers = users.where((u) => u.role == 'Administrateur').toList();
    final isLastAdmin =
        user.role == 'Administrateur' && adminUsers.where((u) => u.id != user.id).isEmpty;
    String? name = user.name;
    String? role = user.role;
    String? newPassword;
    String? confirmPassword;
    bool isValid = _validateForm(
      name,
      role,
      null,
      isEdit: true,
      confirmPassword: confirmPassword,
    );
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Modifier l\'utilisateur'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: user.name,
                  decoration: const InputDecoration(
                    labelText: 'Nom',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setDialogState(() {
                      name = value.trim();
                      isValid = _validateForm(
                        name,
                        role,
                        newPassword,
                        isEdit: true,
                        confirmPassword: confirmPassword,
                      );
                    });
                  },
                  validator: (value) => value == null || value.trim().isEmpty ? 'Entrez un nom' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(
                    labelText: 'Rôle',
                    border: OutlineInputBorder(),
                  ),
                  items: roles.map((role) {
                    return DropdownMenuItem(value: role, child: Text(role));
                  }).toList(),
                  onChanged: isLastAdmin
                      ? null
                      : (value) {
                          setDialogState(() {
                            role = value;
                            isValid = _validateForm(
                              name,
                              role,
                              newPassword,
                              isEdit: true,
                              confirmPassword: confirmPassword,
                            );
                          });
                        },
                  validator: (value) => value == null ? 'Sélectionnez un rôle' : null,
                ),
                if (isLastAdmin)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Le dernier administrateur doit conserver son rôle.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.orange.shade700),
                    ),
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Nouveau mot de passe',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNewPassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          obscureNewPassword = !obscureNewPassword;
                        });
                      },
                    ),
                  ),
                  obscureText: obscureNewPassword,
                  onChanged: (value) {
                    setDialogState(() {
                      newPassword = value.isEmpty ? null : value;
                      isValid = _validateForm(
                        name,
                        role,
                        newPassword,
                        isEdit: true,
                        confirmPassword: confirmPassword,
                      );
                    });
                  },
                  validator: (value) {
                    if (value != null && value.isNotEmpty && value.length < 6) {
                      return 'Minimum 6 caractères';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Confirmer le mot de passe',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          obscureConfirmPassword = !obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  obscureText: obscureConfirmPassword,
                  onChanged: (value) {
                    setDialogState(() {
                      confirmPassword = value.isEmpty ? null : value;
                      isValid = _validateForm(
                        name,
                        role,
                        newPassword,
                        isEdit: true,
                        confirmPassword: confirmPassword,
                      );
                    });
                  },
                  validator: (value) {
                    if (newPassword != null && newPassword!.isNotEmpty) {
                      if (value == null || value.isEmpty) {
                        return 'Confirmez le mot de passe';
                      }
                      if (value != newPassword) {
                        return 'Les mots de passe ne correspondent pas';
                      }
                    }
                    if (newPassword == null || newPassword!.isEmpty) {
                      return null;
                    }
                    if (value == null || value.isEmpty) {
                      return 'Confirmez le mot de passe';
                    }
                    if (newPassword != null && value != newPassword) {
                      return 'Les mots de passe ne correspondent pas';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: isValid
                  ? () async {
                      setState(() => _isLoading = true);
                      try {
                        final existingUsers = await DatabaseHelper.getUsers();
                        if (name != user.name &&
                            existingUsers.any((u) => u.name.toLowerCase() == name!.toLowerCase() && u.id != user.id)) {
                          throw Exception('Un utilisateur avec ce nom existe déjà');
                        }
                        final admins = existingUsers.where((u) => u.role == 'Administrateur').toList();
                        final isCurrentLastAdmin =
                            user.role == 'Administrateur' && admins.where((u) => u.id != user.id).isEmpty;
                        if (isCurrentLastAdmin && role != 'Administrateur') {
                          throw Exception('Impossible de retirer le dernier administrateur');
                        }
                        final updatedUser = User(
                          id: user.id,
                          name: name!,
                          role: role!,
                          password: newPassword != null && newPassword!.isNotEmpty
                              ? _hashPassword(newPassword!)
                              : user.password,
                          otpEnabled: user.otpEnabled,
                          otpSecret: user.otpSecret,
                        );
                        await DatabaseHelper.updateUser(updatedUser);
                        final currentUser = context.read<AuthProvider?>()?.currentUser?.name ?? 'Inconnu';
                        debugPrint('User updated by $currentUser: ${updatedUser.name}');
                        if (context.mounted) {
                          Navigator.pop(context);
                          setState(() => _isLoading = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Utilisateur modifié avec succès')),
                          );
                        }
                      } catch (e) {
                        debugPrint('Error updating user: $e');
                        if (context.mounted) {
                          setState(() => _isLoading = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erreur : $e')),
                          );
                        }
                      }
                    }
                  : null,
              child: const Text('Modifier'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteUser(BuildContext context, User user) async {
    debugPrint('Opening delete user confirmation');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer l\'utilisateur "${user.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              setState(() => _isLoading = true);
              try {
                final users = await DatabaseHelper.getUsers();
                final admins = users.where((u) => u.role == 'Administrateur').toList();
                if (user.role == 'Administrateur' && admins.length <= 1) {
                  throw Exception('Impossible de supprimer le dernier administrateur');
                }
                await DatabaseHelper.deleteUser(user.id);
                final currentUser = context.read<AuthProvider?>()?.currentUser?.name ?? 'Inconnu';
                debugPrint('User deleted by $currentUser: ${user.name}');
                if (context.mounted) {
                  Navigator.pop(context);
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Utilisateur supprimé avec succès')),
                  );
                }
              } catch (e) {
                debugPrint('Error deleting user: $e');
                if (context.mounted) {
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur : $e')),
                  );
                }
              }
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Future<void> _showPermissionsDialog(BuildContext context, User user) async {
    final allKeys = appScreenPermissions.map((p) => p.key).toList();
    final users = await DatabaseHelper.getUsers();
    final adminUsers = users.where((u) => u.role == 'Administrateur').toList();
    final isLastAdmin =
        user.role == 'Administrateur' && adminUsers.where((u) => u.id != user.id).isEmpty;
    final initialSelection = <String>{
      if (isLastAdmin)
        ...allKeys
      else if (user.permissions == null)
        ...allKeys
      else
        ...user.permissions!,
    };
    Set<String> selectedKeys = {...initialSelection};
    bool isSaving = false;

    await showDialog(
      context: context,
      barrierDismissible: !isSaving,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          void toggle(String key, bool value) {
            if (isLastAdmin) {
              return;
            }
            setDialogState(() {
              if (value) {
                selectedKeys.add(key);
              } else {
                selectedKeys.remove(key);
              }
            });
          }

          void toggleAll(bool value) {
            if (isLastAdmin) {
              return;
            }
            setDialogState(() {
              if (value) {
                selectedKeys = allKeys.toSet();
              } else {
                selectedKeys.clear();
              }
            });
          }

          Future<void> save() async {
            if (isSaving) return;
            setDialogState(() => isSaving = true);
            setState(() => _isLoading = true);
            try {
              if (isLastAdmin) {
                selectedKeys = allKeys.toSet();
              }
              final storedPermissions =
                  (isLastAdmin || selectedKeys.length == allKeys.length) ? null : selectedKeys.toList();
              final updatedUser = user.copyWith(permissions: storedPermissions);
              await DatabaseHelper.updateUser(updatedUser);
              if (!mounted) return;
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Autorisations mises à jour.')),
              );
              setState(() => _isLoading = false);
            } catch (e) {
              debugPrint('Error updating permissions: $e');
              if (mounted) {
                setState(() => _isLoading = false);
                setDialogState(() => isSaving = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur : $e')),
                );
              }
            }
          }

          final allSelected = selectedKeys.length == allKeys.length;
          return AlertDialog(
            title: Text('Autorisations - ${user.name}'),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: isSaving || isLastAdmin ? null : () => toggleAll(true),
                        icon: const Icon(Icons.select_all),
                        label: const Text('Tout sélectionner'),
                      ),
                      TextButton.icon(
                        onPressed: isSaving || isLastAdmin ? null : () => toggleAll(false),
                        icon: const Icon(Icons.clear_all),
                        label: const Text('Tout retirer'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 300,
                    child: ListView.builder(
                      itemCount: appScreenPermissions.length,
                      itemBuilder: (context, index) {
                        final option = appScreenPermissions[index];
                        final checked = selectedKeys.contains(option.key);
                        return CheckboxListTile(
                          value: checked,
                          title: Text(option.label),
                          secondary: Icon(option.icon),
                          onChanged: isSaving || isLastAdmin
                              ? null
                              : (value) {
                                  toggle(option.key, value ?? false);
                                },
                        );
                      },
                    ),
                  ),
                  if (selectedKeys.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Aucun écran sélectionné. L\'utilisateur sera redirigé vers la page de non-accès.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.orange),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (isLastAdmin)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Le dernier administrateur dispose automatiquement de tous les écrans.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.orange.shade700),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (allSelected)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Toutes les autorisations sont accordées.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.green),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.of(dialogContext).pop(),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: isSaving ? null : save,
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Enregistrer'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showOtpDialog(BuildContext context, User user) async {
    bool otpEnabled = user.otpEnabled;
    String? otpSecret = user.otpSecret;
    bool isSaving = false;

    await showDialog(
      context: context,
      barrierDismissible: !isSaving,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> handleSave() async {
            if (isSaving) return;
            if (otpEnabled && (otpSecret == null || otpSecret!.isEmpty)) {
              setDialogState(() {
                otpSecret = _generateOtpSecret();
              });
            }
            setDialogState(() => isSaving = true);
            setState(() => _isLoading = true);
            try {
              final updatedUser = user.copyWith(
                otpEnabled: otpEnabled,
                otpSecret: otpEnabled ? otpSecret : null,
              );
              await DatabaseHelper.updateUser(updatedUser);
              if (!mounted) return;
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    otpEnabled
                        ? 'Authentification à deux facteurs activée pour ${user.name}'
                        : 'Authentification à deux facteurs désactivée pour ${user.name}',
                  ),
                ),
              );
              setState(() => _isLoading = false);
            } catch (e) {
              debugPrint('Error updating OTP for ${user.name}: $e');
              if (mounted) {
                setState(() => _isLoading = false);
                setDialogState(() => isSaving = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur lors de la mise à jour : $e')),
                );
              }
            }
          }

          return AlertDialog(
            title: Text('Authentification à deux facteurs - ${user.name}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sécurisez ce compte avec une application d\'authentification comme Google Authenticator ou Authy.',
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: otpEnabled,
                    title: const Text('Activer Google Authenticator'),
                    subtitle: const Text('Un code à 6 chiffres sera demandé à chaque connexion.'),
                    onChanged: isSaving
                        ? null
                        : (value) {
                            setDialogState(() {
                              otpEnabled = value;
                              if (otpEnabled && (otpSecret == null || otpSecret!.isEmpty)) {
                                otpSecret = _generateOtpSecret();
                              }
                            });
                          },
                  ),
                  if (otpEnabled && otpSecret != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.25)),
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            width: 220,
                            height: 220,
                            child: RepaintBoundary(
                              child: CustomPaint(
                                painter: QrPainter(
                                  data: _buildOtpAuthUri(user.name, otpSecret!),
                                  version: QrVersions.auto,
                                  gapless: true,
                                  color: Theme.of(context).colorScheme.onSurface,
                                  emptyColor: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Scannez ce QR code avec votre application d\'authentification, puis saisissez le code généré.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          SelectableText(
                            otpSecret!,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: isSaving
                                    ? null
                                    : () {
                                        setDialogState(() {
                                          otpSecret = _generateOtpSecret();
                                        });
                                      },
                                icon: const Icon(Icons.refresh),
                                label: const Text('Régénérer le secret'),
                              ),
                              OutlinedButton.icon(
                                onPressed: isSaving
                                    ? null
                                    : () {
                                        setDialogState(() {
                                          otpEnabled = false;
                                          otpSecret = null;
                                        });
                                      },
                                icon: const Icon(Icons.visibility_off),
                                label: const Text('Désactiver'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.of(dialogContext).pop(),
                child: const Text('Fermer'),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () {
                        handleSave();
                      },
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Enregistrer'),
              ),
            ],
          );
        },
      ),
    );
  }

  bool _validateForm(
    String? name,
    String? role,
    String? password, {
    bool isEdit = false,
    String? confirmPassword,
  }) {
    final hasName = name != null && name.trim().isNotEmpty;
    final hasRole = role != null;
    if (!hasName || !hasRole) {
      return false;
    }

    if (isEdit) {
      if (password == null || password.isEmpty) {
        return true;
      }
      if (password.length < 6) {
        return false;
      }
      final hasConfirm = confirmPassword != null && confirmPassword.isNotEmpty;
      if (!hasConfirm) {
        return false;
      }
      return password == confirmPassword;
    }

    if (password == null || password.length < 6) {
      return false;
    }
    final hasConfirm = confirmPassword != null && confirmPassword.isNotEmpty;
    if (!hasConfirm) {
      return false;
    }
    return password == confirmPassword;
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
