import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../helpers/database_helper.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

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
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: _isLoading ? null : () => _showEditUserDialog(context, user),
              tooltip: 'Modifier',
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
    bool isValid = false;
    bool obscureText = true;
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
                      isValid = _validateForm(name, role, password);
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
                      isValid = _validateForm(name, role, password);
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
                      icon: Icon(obscureText ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setDialogState(() {
                          obscureText = !obscureText;
                        });
                      },
                    ),
                  ),
                  obscureText: obscureText,
                  onChanged: (value) {
                    setDialogState(() {
                      password = value;
                      isValid = _validateForm(name, role, password);
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
    String? name = user.name;
    String? role = user.role;
    String? newPassword;
    bool isValid = true;
    bool obscureText = true;

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
                      isValid = _validateForm(name, role, newPassword, isEdit: true);
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
                  onChanged: (value) {
                    setDialogState(() {
                      role = value;
                      isValid = _validateForm(name, role, newPassword, isEdit: true);
                    });
                  },
                  validator: (value) => value == null ? 'Sélectionnez un rôle' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Nouveau mot de passe (optionnel)',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(obscureText ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setDialogState(() {
                          obscureText = !obscureText;
                        });
                      },
                    ),
                  ),
                  obscureText: obscureText,
                  onChanged: (value) {
                    setDialogState(() {
                      newPassword = value.isEmpty ? null : value;
                      isValid = _validateForm(name, role, newPassword, isEdit: true);
                    });
                  },
                  validator: (value) {
                    if (value != null && value.isNotEmpty && value.length < 6) {
                      return 'Minimum 6 caractères';
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
                        final updatedUser = User(
                          id: user.id,
                          name: name!,
                          role: role!,
                          password: newPassword != null ? _hashPassword(newPassword!) : user.password,
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

  bool _validateForm(String? name, String? role, String? password, {bool isEdit = false}) {
    if (isEdit) {
      return name != null && name.trim().isNotEmpty && role != null;
    }
    return name != null && name.trim().isNotEmpty && role != null && password != null && password.length >= 6;
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}