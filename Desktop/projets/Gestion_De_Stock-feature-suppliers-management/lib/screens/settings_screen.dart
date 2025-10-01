import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
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
  String? _logoPath;

  @override
  void initState() {
    super.initState();
    _loadSocieteInfo();
  }

  Future<void> _loadSocieteInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _societeController.text = prefs.getString('societe_nom') ?? '';
      _emailController.text = prefs.getString('societe_email') ?? '';
      _telephoneController.text = prefs.getString('societe_telephone') ?? '';
      _adresseController.text = prefs.getString('societe_adresse') ?? '';
      _responsableController.text = prefs.getString('societe_responsable') ?? '';
      _logoPath = prefs.getString('societe_logo');
    });
  }

  Future<void> _saveSocieteInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('societe_nom', _societeController.text.trim());
    await prefs.setString('societe_email', _emailController.text.trim());
    await prefs.setString('societe_telephone', _telephoneController.text.trim());
    await prefs.setString('societe_adresse', _adresseController.text.trim());
    await prefs.setString('societe_responsable', _responsableController.text.trim());
    if (_logoPath != null) {
      await prefs.setString('societe_logo', _logoPath!);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informations société enregistrées !')),
      );
    }
  }

  Future<void> _pickLogo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _logoPath = result.files.single.path!;
      });
    }
  }

  @override
  void dispose() {
    _societeController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _adresseController.dispose();
    _responsableController.dispose();
    super.dispose();
  }

  Future<void> _backupDatabase(BuildContext context) async {
    try {
      final dbDir = await getDatabasesPath();
      final dbPath = '$dbDir/dashboard.db';
      final dbFile = File(dbPath);
      if (!await dbFile.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Base de données introuvable.')),
        );
        return;
      }
      final docsDir = await getApplicationDocumentsDirectory();
      final backupPath = '${docsDir.path}/dashboard_backup_${DateTime.now().millisecondsSinceEpoch}.db';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Informations société', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _societeController,
              decoration: const InputDecoration(labelText: 'Nom de la société'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _responsableController,
              decoration: const InputDecoration(labelText: 'Nom du responsable'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email de contact'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _telephoneController,
              decoration: const InputDecoration(labelText: 'Téléphone'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _adresseController,
              decoration: const InputDecoration(labelText: 'Adresse'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickLogo,
                  icon: const Icon(Icons.upload),
                  label: const Text('Logo (upload)'),
                ),
                const SizedBox(width: 16),
                _logoPath != null && File(_logoPath!).existsSync()
                    ? CircleAvatar(radius: 20, backgroundImage: FileImage(File(_logoPath!)))
                    : CircleAvatar(radius: 20, backgroundColor: Colors.grey.shade200, child: const Icon(Icons.image)),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _saveSocieteInfo,
              icon: const Icon(Icons.save),
              label: const Text('Enregistrer'),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Thème sombre', style: TextStyle(fontSize: 16)),
                Switch(value: false, onChanged: (v) {}),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _backupDatabase(context),
              icon: const Icon(Icons.save_alt),
              label: const Text('Sauvegarder la base'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _restoreDatabase(context),
              icon: const Icon(Icons.restore),
              label: const Text('Restaurer la base'),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.lock),
              label: const Text('Changer le mot de passe'),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 12),
            Text('À propos', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text('Stock Management v1.0\n© 2024 cabinet ACTe', style: TextStyle(color: Colors.grey)),
          ],
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