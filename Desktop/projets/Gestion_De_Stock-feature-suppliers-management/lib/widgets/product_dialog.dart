import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:file_picker/file_picker.dart';
import '../models/models.dart';

class ProductDialog extends StatefulWidget {
  final Database database;
  final List<String> unites;
  final List<String> categories;
  final List<String> statuts;
  final Produit? produit;
  final VoidCallback onProductSaved;

  const ProductDialog({
    Key? key,
    required this.database,
    required this.unites,
    required this.categories,
    required this.statuts,
    this.produit,
    required this.onProductSaved,
  }) : super(key: key);

  @override
  _ProductDialogState createState() => _ProductDialogState();
}

class _ProductDialogState extends State<ProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _categorieFieldKey = GlobalKey<FormFieldState<String>>();
  final _uniteFieldKey = GlobalKey<FormFieldState<String>>();
  int _id = 0;
  String _nom = '';
  String? _description;
  String _categorie = '';
  String? _marque;
  String? _imageUrl;
  String? _imagePath;
  String? _sku;
  String? _codeBarres;
  String _unite = '';
  double _quantiteStock = 0.0;
  double _quantiteAvariee = 0.0;
  double _quantiteInitiale = 0.0;
  double _stockMin = 0.0;
  double _stockMax = 0.0;
  double _seuilAlerte = 0.0;
  List<Variante> _variantes = [];
  double _prixAchat = 0.0;
  double _prixVente = 0.0;
  double _prixVenteGros = 0.0;
  double _seuilGros = 0.0;
  double _tva = 0.0;
  String? _fournisseurPrincipal;
  List<String> _fournisseursSecondaires = [];
  DateTime? _derniereEntree;
  DateTime? _derniereSortie;
  String _statut = 'disponible';
  final _newUniteController = TextEditingController();
  final _newCategorieController = TextEditingController();

  double? _parseDoubleLocale(String? input) {
    if (input == null) return null;
    final normalized = input.replaceAll(' ', '').replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  int? _parseIntLocale(String? input) {
    if (input == null) return null;
    final normalized = input.replaceAll(' ', '');
    if (normalized.contains('.') || normalized.contains(',')) {
      final asDouble = double.tryParse(normalized.replaceAll(',', '.'));
      if (asDouble == null) return null;
      if (asDouble % 1 == 0) return asDouble.toInt();
      return null; // valeur décimale non autorisée pour un champ entier
    }
    return int.tryParse(normalized);
  }

  @override
  void initState() {
    super.initState();
    void dedupeInPlace(List<String> list) {
      final seen = <String>{};
      final unique = <String>[];
      for (final e in list) {
        final k = e.trim().toLowerCase();
        if (seen.add(k)) unique.add(e.trim());
      }
      list
        ..clear()
        ..addAll(unique);
    }
    dedupeInPlace(widget.categories);
    dedupeInPlace(widget.unites);
    _categorie = widget.categories.isNotEmpty ? widget.categories.first : 'Électronique';
    _unite = widget.unites.isNotEmpty ? widget.unites.first : 'Pièce';
    if (widget.produit != null) {
      _id = widget.produit!.id;
      _nom = widget.produit!.nom;
      _description = widget.produit!.description;
      _categorie = widget.categories.contains(widget.produit!.categorie) ? widget.produit!.categorie : widget.categories.first;
      _marque = widget.produit!.marque;
      _imageUrl = widget.produit!.imageUrl;
      _imagePath = widget.produit!.imageUrl;
      _sku = widget.produit!.sku;
      _codeBarres = widget.produit!.codeBarres;
      _unite = widget.unites.contains(widget.produit!.unite) ? widget.produit!.unite : widget.unites.first;
      _quantiteStock = widget.produit!.quantiteStock;
      _quantiteAvariee = widget.produit!.quantiteAvariee;
      _quantiteInitiale = widget.produit!.quantiteInitiale;
      _stockMin = widget.produit!.stockMin;
      _stockMax = widget.produit!.stockMax;
      _seuilAlerte = widget.produit!.seuilAlerte;
      _variantes = widget.produit!.variantes;
      _prixAchat = widget.produit!.prixAchat;
      _prixVente = widget.produit!.prixVente;
      _prixVenteGros = widget.produit!.prixVenteGros;
      _seuilGros = widget.produit!.seuilGros;
      _tva = widget.produit!.tva;
      _fournisseurPrincipal = widget.produit!.fournisseurPrincipal;
      _fournisseursSecondaires = widget.produit!.fournisseursSecondaires;
      _derniereEntree = widget.produit!.derniereEntree;
      _derniereSortie = widget.produit!.derniereSortie;
      _statut = widget.produit!.statut;
    }
  }

  @override
  void dispose() {
    _newUniteController.dispose();
    _newCategorieController.dispose();
    super.dispose();
  }

  Future<bool> _checkProductExists(String nom, {int? excludeId}) async {
    try {
      final List<Map<String, dynamic>> maps = await widget.database.query(
        'produits',
        where: excludeId != null ? 'nom = ? AND id != ?' : 'nom = ?',
        whereArgs: excludeId != null ? [nom, excludeId] : [nom],
      );
      return maps.isNotEmpty;
    } catch (e) {
      print('Erreur lors de la vérification du produit existant : $e');
      return false;
    }
  }

  Future<void> _addProduct() async {
    print('Début de _addProduct...');
    if (_formKey.currentState!.validate()) {
      print('Formulaire validé !');
      _formKey.currentState!.save();
      final exists = await _checkProductExists(_nom);
      if (exists) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Erreur'),
            content: const Text('Un produit avec ce nom existe déjà.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      final produit = Produit(
        id: 0,
        nom: _nom,
        description: _description,
        categorie: _categorie,
        marque: _marque,
        imageUrl: _imageUrl,
        sku: _sku,
        codeBarres: _codeBarres,
        unite: _unite,
        quantiteStock: _quantiteStock,
        quantiteAvariee: _quantiteAvariee,
        quantiteInitiale: _quantiteInitiale,
        stockMin: _stockMin,
        stockMax: _stockMax,
        seuilAlerte: _seuilAlerte,
        variantes: _variantes,
        prixAchat: _prixAchat,
        prixVente: _prixVente,
        prixVenteGros: _prixVenteGros,
        seuilGros: _seuilGros,
        tva: _tva,
        fournisseurPrincipal: _fournisseurPrincipal,
        fournisseursSecondaires: _fournisseursSecondaires,
        derniereEntree: _derniereEntree,
        derniereSortie: _derniereSortie,
        statut: _statut,
      );
      try {
        print('Tentative d\'insertion du produit : $_nom');
        await widget.database.insert('produits', produit.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
        print('Produit inséré avec succès : $_nom');
      } catch (e) {
        print('Erreur lors de l\'insertion du produit : $e');
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Erreur'),
            content: Text('Erreur lors de l\'insertion : $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }
      widget.onProductSaved();
      // Au lieu de fermer le formulaire, on réinitialise pour faciliter l'ajout en série
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produit enregistré. Vous pouvez ajouter un autre produit.')),
      );
      setState(() {
        // Effacer l'image sélectionnée et champs auxiliaires
        _imagePath = null;
        _imageUrl = null;
        _newUniteController.clear();
        _newCategorieController.clear();
        // Conserver la dernière catégorie et unité sélectionnées pour accélérer les ajouts en série
      });
      // Réinitialiser tous les champs du formulaire à leurs valeurs initiales (vides/0)
      _formKey.currentState!.reset();
      // Puis rétablir la dernière catégorie et unité sélectionnées
      _categorieFieldKey.currentState?.didChange(_categorie);
      _uniteFieldKey.currentState?.didChange(_unite);
    } else {
      print('Échec de la validation du formulaire.');
    }
  }

  Future<void> _updateProduct() async {
    print('Début de _updateProduct...');
    if (_formKey.currentState!.validate()) {
      print('Formulaire validé !');
      _formKey.currentState!.save();
      final exists = await _checkProductExists(_nom, excludeId: widget.produit!.id);
      if (exists) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Erreur'),
            content: const Text('Un produit avec ce nom existe déjà.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      final produit = Produit(
        id: widget.produit!.id,
        nom: _nom,
        description: _description,
        categorie: _categorie,
        marque: _marque,
        imageUrl: _imageUrl,
        sku: _sku,
        codeBarres: _codeBarres,
        unite: _unite,
        quantiteStock: _quantiteStock,
        quantiteAvariee: _quantiteAvariee,
        quantiteInitiale: _quantiteInitiale,
        stockMin: _stockMin,
        stockMax: _stockMax,
        seuilAlerte: _seuilAlerte,
        variantes: _variantes,
        prixAchat: _prixAchat,
        prixVente: _prixVente,
        prixVenteGros: _prixVenteGros,
        seuilGros: _seuilGros,
        tva: _tva,
        fournisseurPrincipal: _fournisseurPrincipal,
        fournisseursSecondaires: _fournisseursSecondaires,
        derniereEntree: _derniereEntree,
        derniereSortie: _derniereSortie,
        statut: _statut,
      );
      try {
        print('Tentative de mise à jour du produit : $_nom');
        await widget.database.update(
          'produits',
          produit.toMap(),
          where: 'id = ?',
          whereArgs: [produit.id],
        );
        print('Produit mis à jour avec succès : $_nom');
      } catch (e) {
        print('Erreur lors de la mise à jour du produit : $e');
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Erreur'),
            content: Text('Erreur lors de la mise à jour : $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }
      widget.onProductSaved();
      Navigator.pop(context);
    } else {
      print('Échec de la validation du formulaire.');
    }
  }

  Future<bool> _tableExists(String tableName) async {
    try {
      final result = await widget.database.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        [tableName],
      );
      return result.isNotEmpty;
    } catch (e) {
      print('Erreur lors de la vérification de la table $tableName : $e');
      return false;
    }
  }

  Future<void> _addNewUnite() async {
    final newUnite = _newUniteController.text.trim();
    if (newUnite.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer une unité valide')),
      );
      return;
    }
    try {
      if (!(await _tableExists('unites'))) {
        await widget.database.execute('''
          CREATE TABLE IF NOT EXISTS unites (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nom TEXT NOT NULL UNIQUE
          )
        ''');
      }
      // Vérifier l'existence (insensible à la casse) côté base et côté liste
      final existingDb = await widget.database.rawQuery(
        'SELECT nom FROM unites WHERE lower(trim(nom)) = lower(?) LIMIT 1',
        [newUnite],
      );
      final existingListIndex = widget.unites.indexWhere(
        (e) => e.trim().toLowerCase() == newUnite.toLowerCase(),
      );
      if (existingDb.isNotEmpty || existingListIndex != -1) {
        setState(() {
          _unite = existingListIndex != -1
              ? widget.unites[existingListIndex]
              : (existingDb.first['nom'] as String);
          _newUniteController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('L\'unité "${_unite}" existe déjà')),
        );
        return;
      }
      await widget.database.insert(
        'unites',
        {'nom': newUnite},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      setState(() {
        // Ajout dans la liste si non présent (insensible à la casse)
        final exists = widget.unites.any(
          (e) => e.trim().toLowerCase() == newUnite.toLowerCase(),
        );
        if (!exists) {
          widget.unites.add(newUnite);
        }
        _unite = widget.unites.firstWhere(
          (e) => e.trim().toLowerCase() == newUnite.toLowerCase(),
          orElse: () => newUnite,
        );
        _newUniteController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unité "$newUnite" ajoutée')),
      );
    } catch (e) {
      print('Erreur lors de l\'ajout de l\'unité : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'ajout de l\'unité : $e')),
      );
    }
  }

  Future<void> _addNewCategorie() async {
    final newCategorie = _newCategorieController.text.trim();
    if (newCategorie.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer une catégorie valide')),
      );
      return;
    }
    try {
      if (!(await _tableExists('categories'))) {
        await widget.database.execute('''
          CREATE TABLE IF NOT EXISTS categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nom TEXT NOT NULL UNIQUE
          )
        ''');
      }
      // Vérifier l'existence (insensible à la casse) côté base et côté liste
      final existingDb = await widget.database.rawQuery(
        'SELECT nom FROM categories WHERE lower(trim(nom)) = lower(?) LIMIT 1',
        [newCategorie],
      );
      final existingListIndex = widget.categories.indexWhere(
        (e) => e.trim().toLowerCase() == newCategorie.toLowerCase(),
      );
      if (existingDb.isNotEmpty || existingListIndex != -1) {
        setState(() {
          _categorie = existingListIndex != -1
              ? widget.categories[existingListIndex]
              : (existingDb.first['nom'] as String);
          _newCategorieController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('La catégorie "${_categorie}" existe déjà')),
        );
        return;
      }
      await widget.database.insert(
        'categories',
        {'nom': newCategorie},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      setState(() {
        // Ajout dans la liste si non présent (insensible à la casse)
        final exists = widget.categories.any(
          (e) => e.trim().toLowerCase() == newCategorie.toLowerCase(),
        );
        if (!exists) {
          widget.categories.add(newCategorie);
        }
        _categorie = widget.categories.firstWhere(
          (e) => e.trim().toLowerCase() == newCategorie.toLowerCase(),
          orElse: () => newCategorie,
        );
        _newCategorieController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Catégorie "$newCategorie" ajoutée')),
      );
    } catch (e) {
      print('Erreur lors de l\'ajout de la catégorie : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'ajout de la catégorie : $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: false,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _imagePath = result.files.single.path;
          _imageUrl = _imagePath; // Update _imageUrl for saving
          print('Image selected: $_imagePath');
        });
      }
    } catch (e) {
      print('Erreur lors de la sélection de l\'image : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sélection : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.produit != null;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.7,
        padding: const EdgeInsets.all(24),
        child: Shortcuts(
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.enter): SubmitFormIntent(),
            SingleActivator(LogicalKeyboardKey.numpadEnter): SubmitFormIntent(),
          },
          child: Actions(
            actions: <Type, Action<Intent>>{
              SubmitFormIntent: CallbackAction<SubmitFormIntent>(
                onInvoke: (intent) {
                  if (_formKey.currentState?.validate() ?? false) {
                    if (isEditing) {
                      _updateProduct();
                    } else {
                      _addProduct();
                    }
                  }
                  return null;
                },
              ),
            },
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isEditing ? 'Modifier un produit' : 'Ajouter un produit',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Fermer',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        initialValue: _nom,
                        decoration: const InputDecoration(labelText: 'Nom *', border: OutlineInputBorder()),
                        validator: (value) => (value?.isEmpty ?? true) ? 'Requis' : null,
                        onSaved: (value) => _nom = value!,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: _description,
                        decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                        maxLines: 3,
                        onSaved: (value) => _description = value,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              key: _categorieFieldKey,
                              decoration: const InputDecoration(labelText: 'Catégorie *', border: OutlineInputBorder()),
                              items: widget.categories.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                              value: _categorie,
                              onChanged: (value) => setState(() => _categorie = value!),
                              validator: (value) => value == null ? 'Requis' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _newCategorieController,
                              decoration: const InputDecoration(
                                labelText: 'Nouvelle catégorie',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: _addNewCategorie,
                            child: const Text('Ajouter'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: _marque,
                        decoration: const InputDecoration(labelText: 'Marque', border: OutlineInputBorder()),
                        onSaved: (value) => _marque = value,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Image', style: TextStyle(fontSize: 16)),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: _pickImage,
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: const Color(0xFF0E5A8A),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text('Sélectionner une image'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          _imagePath != null && File(_imagePath!).existsSync()
                              ? Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(_imagePath!),
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => const Icon(
                                        Icons.broken_image,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                    color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                                  ),
                                  child: const Icon(
                                    Icons.image,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: _sku,
                        decoration: const InputDecoration(labelText: 'SKU', border: OutlineInputBorder()),
                        onSaved: (value) => _sku = value,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: _codeBarres,
                        decoration: const InputDecoration(labelText: 'Code-barres', border: OutlineInputBorder()),
                        onSaved: (value) => _codeBarres = value,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              key: _uniteFieldKey,
                              decoration: const InputDecoration(labelText: 'Unité *', border: OutlineInputBorder()),
                              items: widget.unites.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                              value: _unite,
                              onChanged: (value) => setState(() => _unite = value!),
                              validator: (value) => value == null ? 'Requis' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _newUniteController,
                              decoration: const InputDecoration(
                                labelText: 'Nouvelle unité',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: _addNewUnite,
                            child: const Text('Ajouter'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: _quantiteInitiale.toString(),
                              decoration: const InputDecoration(labelText: 'Quantité initiale *', border: OutlineInputBorder()),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Requis';
                                }
                                final num = _parseDoubleLocale(value);
                                if (num == null) {
                                  return 'Doit être un nombre';
                                }
                                if (num < 0) {
                                  return 'Ne peut pas être négatif';
                                }
                                return null;
                              },
                              onSaved: (value) => _quantiteInitiale = _parseDoubleLocale(value) ?? 0.0,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              initialValue: _quantiteStock.toString(),
                              decoration: const InputDecoration(labelText: 'Quantité en stock *', border: OutlineInputBorder()),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Requis';
                                }
                                final num = _parseDoubleLocale(value);
                                if (num == null) {
                                  return 'Doit être un nombre';
                                }
                                if (num < 0) {
                                  return 'Ne peut pas être négatif';
                                }
                                return null;
                              },
                              onSaved: (value) => _quantiteStock = _parseDoubleLocale(value) ?? 0.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: _prixVenteGros.toString(),
                              decoration: const InputDecoration(labelText: 'Prix de gros', border: OutlineInputBorder()),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\\s-]')),
                              ],
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  final num = _parseDoubleLocale(value);
                                  if (num == null) {
                                    return 'Doit être un nombre valide';
                                  }
                                  if (num < 0) {
                                    return 'Ne peut pas être négatif';
                                  }
                                }
                                return null;
                              },
                              onSaved: (value) => _prixVenteGros = _parseDoubleLocale(value) ?? 0.0,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              initialValue: _seuilGros.toString(),
                              decoration: const InputDecoration(labelText: 'Seuil (Qté) pour gros', border: OutlineInputBorder()),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\\s-]')),
                              ],
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  final num = _parseDoubleLocale(value);
                                  if (num == null) {
                                    return 'Doit être un nombre valide';
                                  }
                                  if (num < 0) {
                                    return 'Ne peut pas être négatif';
                                  }
                                }
                                return null;
                              },
                              onSaved: (value) => _seuilGros = _parseDoubleLocale(value) ?? 0.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: _quantiteAvariee.toString(),
                              decoration: const InputDecoration(labelText: 'Quantité avariée', border: OutlineInputBorder()),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  final num = _parseDoubleLocale(value);
                                  if (num == null) {
                                    return 'Doit être un nombre';
                                  }
                                  if (num < 0) {
                                    return 'Ne peut pas être négatif';
                                  }
                                }
                                return null;
                              },
                              onSaved: (value) => _quantiteAvariee = _parseDoubleLocale(value) ?? 0.0,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              initialValue: _stockMin.toString(),
                              decoration: const InputDecoration(labelText: 'Stock minimum', border: OutlineInputBorder()),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  final num = _parseDoubleLocale(value);
                                  if (num == null) {
                                    return 'Doit être un nombre';
                                  }
                                  if (num < 0) {
                                    return 'Ne peut pas être négatif';
                                  }
                                }
                                return null;
                              },
                              onSaved: (value) => _stockMin = _parseDoubleLocale(value) ?? 0.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: _stockMax.toString(),
                              decoration: const InputDecoration(labelText: 'Stock maximum', border: OutlineInputBorder()),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  final num = _parseDoubleLocale(value);
                                  if (num == null) {
                                    return 'Doit être un nombre';
                                  }
                                  if (num < 0) {
                                    return 'Ne peut pas être négatif';
                                  }
                                }
                                return null;
                              },
                              onSaved: (value) => _stockMax = _parseDoubleLocale(value) ?? 0.0,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              initialValue: _seuilAlerte.toString(),
                              decoration: const InputDecoration(labelText: 'Seuil d\'alerte', border: OutlineInputBorder()),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  final num = _parseDoubleLocale(value);
                                  if (num == null) {
                                    return 'Doit être un nombre';
                                  }
                                  if (num < 0) {
                                    return 'Ne peut pas être négatif';
                                  }
                                }
                                return null;
                              },
                              onSaved: (value) => _seuilAlerte = _parseDoubleLocale(value) ?? 0.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: _variantes.isNotEmpty
                            ? _variantes.map((v) => '${v.type}:${v.valeur}').join(',')
                            : '',
                        decoration: const InputDecoration(labelText: 'Variantes (ex: Taille:M,Couleur:Bleu)', border: OutlineInputBorder()),
                        onSaved: (value) {
                          _variantes = (value?.split(',').map((v) {
                            final parts = v.split(':');
                            if (parts.length == 2) {
                              return Variante(type: parts[0].trim(), valeur: parts[1].trim());
                            }
                            return Variante(type: 'N/A', valeur: 'N/A');
                          }).toList()) ?? [];
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: _prixAchat.toString(),
                              decoration: const InputDecoration(labelText: 'Prix d\'achat *', border: OutlineInputBorder()),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\s-]')),
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Requis';
                                }
                                final num = _parseDoubleLocale(value);
                                if (num == null) {
                                  return 'Doit être un nombre valide';
                                }
                                if (num < 0) {
                                  return 'Ne peut pas être négatif';
                                }
                                return null;
                              },
                              onSaved: (value) => _prixAchat = _parseDoubleLocale(value) ?? 0.0,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              initialValue: _prixVente.toString(),
                              decoration: const InputDecoration(labelText: 'Prix de vente *', border: OutlineInputBorder()),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\s-]')),
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Requis';
                                }
                                final num = _parseDoubleLocale(value);
                                if (num == null) {
                                  return 'Doit être un nombre valide';
                                }
                                if (num < 0) {
                                  return 'Ne peut pas être négatif';
                                }
                                return null;
                              },
                              onSaved: (value) => _prixVente = _parseDoubleLocale(value) ?? 0.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: _tva.toString(),
                        decoration: const InputDecoration(labelText: 'TVA (%)', border: OutlineInputBorder()),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\s-]')),
                        ],
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final num = _parseDoubleLocale(value);
                            if (num == null) {
                              return 'Doit être un nombre valide';
                            }
                            if (num < 0) {
                              return 'Ne peut pas être négatif';
                            }
                          }
                          return null;
                        },
                        onSaved: (value) => _tva = _parseDoubleLocale(value) ?? 0.0,
                        onFieldSubmitted: (_) => isEditing ? _updateProduct() : _addProduct(),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: _fournisseurPrincipal,
                        decoration: const InputDecoration(labelText: 'Fournisseur principal', border: OutlineInputBorder()),
                        onSaved: (value) => _fournisseurPrincipal = value,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: _fournisseursSecondaires.join(','),
                        decoration: const InputDecoration(labelText: 'Fournisseurs secondaires (séparés par des virgules)', border: OutlineInputBorder()),
                        onSaved: (value) => _fournisseursSecondaires = (value?.split(',') ?? []).map((e) => e.trim()).toList(),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Statut *', border: OutlineInputBorder()),
                        items: widget.statuts.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        value: _statut,
                        onChanged: (value) => setState(() => _statut = value!),
                        validator: (value) => value == null ? 'Requis' : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: isEditing ? _updateProduct : _addProduct,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color(0xFF0E5A8A),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    ),
                    child: Text(isEditing ? 'Modifier' : 'Enregistrer'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      ),
    ));
  }
}

class SubmitFormIntent extends Intent {
  const SubmitFormIntent();
}
