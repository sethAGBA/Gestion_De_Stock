import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _societeController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _adresseController = TextEditingController();
  final _responsableController = TextEditingController();
  final _rcController = TextEditingController();
  final _nifController = TextEditingController();
  final _siteController = TextEditingController();
  final _mentionController = TextEditingController();
  final _messageController = TextEditingController();
  String? _logoPath;
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _loadSocieteInfo();
  }

  Future<void> _loadSocieteInfo() async {
    final prefs = await SharedPreferences.getInstance();
    String? persistedLogo = prefs.getString('societe_logo');
    if (persistedLogo != null && !File(persistedLogo).existsSync()) {
      persistedLogo = null;
    }
    setState(() {
      _societeController.text = prefs.getString('societe_nom') ?? '';
      _emailController.text = prefs.getString('societe_email') ?? '';
      _telephoneController.text = prefs.getString('societe_telephone') ?? '';
      _adresseController.text = prefs.getString('societe_adresse') ?? '';
      _responsableController.text = prefs.getString('societe_responsable') ?? '';
      _rcController.text = prefs.getString('societe_rc') ?? '';
      _nifController.text = prefs.getString('societe_nif') ?? '';
      _siteController.text = prefs.getString('societe_site') ?? '';
      _mentionController.text = prefs.getString('societe_mention') ?? '';
      _messageController.text = prefs.getString('societe_message') ?? 'Merci pour votre achat !';
      _logoPath = persistedLogo;
      _darkMode = prefs.getBool('dark_mode_pref') ?? false;
    });
  }

  Future<void> _saveSocieteInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('societe_nom', _societeController.text.trim());
    await prefs.setString('societe_email', _emailController.text.trim());
    await prefs.setString('societe_telephone', _telephoneController.text.trim());
    await prefs.setString('societe_adresse', _adresseController.text.trim());
    await prefs.setString('societe_responsable', _responsableController.text.trim());
    await prefs.setString('societe_rc', _rcController.text.trim());
    await prefs.setString('societe_nif', _nifController.text.trim());
    await prefs.setString('societe_site', _siteController.text.trim());
    await prefs.setString('societe_mention', _mentionController.text.trim());
    await prefs.setString('societe_message', _messageController.text.trim());
    if (_logoPath != null) {
      await prefs.setString('societe_logo', _logoPath!);
    }
    await prefs.setBool('dark_mode_pref', _darkMode);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informations société enregistrées !')),
      );
    }
  }

  Future<void> _pickLogo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      final saved = await _saveLogoLocally(result.files.single.path!);
      setState(() {
        _logoPath = saved;
      });
    }
  }

  Future<String> _saveLogoLocally(String sourcePath) async {
    final docs = await getApplicationDocumentsDirectory();
    final ext = path.extension(sourcePath);
    final targetPath = path.join(docs.path, 'company_logo$ext');
    await File(sourcePath).copy(targetPath);
    return targetPath;
  }

  @override
  void dispose() {
    _societeController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _adresseController.dispose();
    _responsableController.dispose();
    _rcController.dispose();
    _nifController.dispose();
    _siteController.dispose();
    _mentionController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _backupDatabase(BuildContext context) async {
    try {
      final targetDir = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Choisissez un dossier pour la sauvegarde',
      );
      if (targetDir == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sauvegarde annulée')),
        );
        return;
      }
      final dbDir = await getDatabasesPath();
      final dbPath = '$dbDir/dashboard.db';
      final dbFile = File(dbPath);
      if (!await dbFile.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Base de données introuvable.')),
        );
        return;
      }
      final backupPath = path.join(targetDir, 'dashboard_backup_${DateTime.now().millisecondsSinceEpoch}.db');
      await dbFile.copy(backupPath);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sauvegarde réussie : $backupPath')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sauvegarde : $e')),
      );
    }
  }

  Future<void> _restoreDatabase(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);
      if (result == null || result.files.single.path == null) return;
      final pickedFile = File(result.files.single.path!);
      final dbDir = await getDatabasesPath();
      final dbPath = '$dbDir/dashboard.db';
      await pickedFile.copy(dbPath);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restauration réussie. Redémarrez l\'application.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la restauration : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headline = theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.2);
    final cardRadius = BorderRadius.circular(16);
    InputDecoration _field(String label, {String? hint, IconData? icon}) => InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: icon != null ? Icon(icon) : null,
          filled: true,
          fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.6),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.2),
          ),
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.colorScheme.primary,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.08),
              theme.colorScheme.secondary.withOpacity(0.06),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: cardRadius,
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                            color: Colors.black.withOpacity(0.05),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  color: theme.colorScheme.primary.withOpacity(0.08),
                                ),
                                child: _logoPath != null && File(_logoPath!).existsSync()
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: Image.file(File(_logoPath!), fit: BoxFit.cover),
                                      )
                                    : Icon(Icons.store_mall_directory, size: 32, color: theme.colorScheme.primary),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Profil de l\'entreprise', style: headline),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Logo, identité et coordonnées utilisées sur les factures.',
                                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _pickLogo,
                                icon: const Icon(Icons.image_outlined),
                                label: const Text('Téléverser le logo'),
                                style: TextButton.styleFrom(
                                  foregroundColor: theme.colorScheme.primary,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          GridView.count(
                            shrinkWrap: true,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            crossAxisCount: MediaQuery.of(context).size.width > 900 ? 2 : 1,
                            childAspectRatio: 3.6,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              TextField(
                                controller: _societeController,
                                decoration: _field('Nom de la société', hint: 'Ex: ACTe SARL', icon: Icons.business),
                              ),
                              TextField(
                                controller: _responsableController,
                                decoration: _field('Nom du responsable', hint: 'Contact principal', icon: Icons.badge_outlined),
                              ),
                              TextField(
                                controller: _emailController,
                                decoration: _field('Email de contact', hint: 'contact@exemple.com', icon: Icons.alternate_email),
                                keyboardType: TextInputType.emailAddress,
                              ),
                              TextField(
                                controller: _telephoneController,
                                decoration: _field('Téléphone', hint: '+225 xx xx xx xx', icon: Icons.call_outlined),
                                keyboardType: TextInputType.phone,
                              ),
                              TextField(
                                controller: _adresseController,
                                decoration: _field('Adresse', hint: 'Quartier, ville, pays', icon: Icons.place_outlined),
                              ),
                              TextField(
                                controller: _rcController,
                                decoration: _field('RCCM / Registre commerce', hint: 'Ex: CI-ABJ-2024-XXXX', icon: Icons.badge),
                              ),
                              TextField(
                                controller: _nifController,
                                decoration: _field('NIF / ID fiscal', hint: 'Ex: 123456789', icon: Icons.confirmation_number_outlined),
                                keyboardType: TextInputType.number,
                              ),
                              TextField(
                                controller: _siteController,
                                decoration: _field('Site web', hint: 'www.exemple.com', icon: Icons.language),
                                keyboardType: TextInputType.url,
                              ),
                              TextField(
                                controller: _mentionController,
                                decoration: _field('Mention légale', hint: 'Non assujetti à la TVA…', icon: Icons.gavel_outlined),
                                maxLines: 2,
                              ),
                              TextField(
                                controller: _messageController,
                                decoration: _field('Message pied de facture', hint: 'Merci pour votre achat !', icon: Icons.favorite_border),
                                maxLines: 2,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: _saveSocieteInfo,
                                icon: const Icon(Icons.save_outlined),
                                label: const Text('Enregistrer'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                onPressed: _pickLogo,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Changer de logo'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: cardRadius,
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                            color: Colors.black.withOpacity(0.05),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Préférences', style: headline),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: theme.colorScheme.primary.withOpacity(0.05),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.dark_mode, color: theme.colorScheme.primary),
                                const SizedBox(width: 10),
                                const Expanded(child: Text('Thème sombre (préférence stockée localement)')),
                                Switch(
                                  value: _darkMode,
                                  onChanged: (v) => setState(() => _darkMode = v),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text('Base de données', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => _backupDatabase(context),
                                icon: const Icon(Icons.save_alt),
                                label: const Text('Sauvegarder la base'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => _restoreDatabase(context),
                                icon: const Icon(Icons.restore),
                                label: const Text('Restaurer la base'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.lock_outline),
                                label: const Text('Changer le mot de passe'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: cardRadius,
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                            color: Colors.black.withOpacity(0.05),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('À propos', style: headline),
                          const SizedBox(height: 8),
                          Text(
                            'Stock Management v1.0\n© 2024 cabinet ACTe',
                            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Placeholder for RestorationScreen
class RestorationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Restauration des Données'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Center(
        child: Text(
          'Interface pour restaurer les données (À implémenter)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
