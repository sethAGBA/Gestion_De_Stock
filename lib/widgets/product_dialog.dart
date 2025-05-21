import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
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
  int _id = 0;
  String _nom = '';
  String? _description;
  String _categorie = '';
  String? _marque;
  String? _imageUrl;
  String? _sku;
  String? _codeBarres;
  String _unite = '';
  int _quantiteStock = 0;
  int _quantiteAvariee = 0;
  int _quantiteInitiale = 0; // New field
  int _stockMin = 0;
  int _stockMax = 0;
  int _seuilAlerte = 0;
  List<Variante> _variantes = [];
  double _prixAchat = 0.0;
  double _prixVente = 0.0;
  double _tva = 0.0;
  String? _fournisseurPrincipal;
  List<String> _fournisseursSecondaires = [];
  DateTime? _derniereEntree;
  DateTime? _derniereSortie;
  String _statut = 'disponible';
  final _newUniteController = TextEditingController();
  final _newCategorieController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _categorie = widget.categories.isNotEmpty ? widget.categories.first : 'Électronique';
    _unite = widget.unites.isNotEmpty ? widget.unites.first : 'Pièce';
    if (widget.produit != null) {
      _id = widget.produit!.id;
      _nom = widget.produit!.nom;
      _description = widget.produit!.description;
      _categorie = widget.categories.contains(widget.produit!.categorie) ? widget.produit!.categorie : widget.categories.first;
      _marque = widget.produit!.marque;
      _imageUrl = widget.produit!.imageUrl;
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
      Navigator.pop(context);
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
      await widget.database.insert(
        'unites',
        {'nom': newUnite},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      setState(() {
        if (!widget.unites.contains(newUnite)) {
          widget.unites.add(newUnite);
        }
        _unite = newUnite;
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
      await widget.database.insert(
        'categories',
        {'nom': newCategorie},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      setState(() {
        if (!widget.categories.contains(newCategorie)) {
          widget.categories.add(newCategorie);
        }
        _categorie = newCategorie;
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

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.produit != null;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.7,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? 'Modifier un produit' : 'Ajouter un produit',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                      TextFormField(
                        initialValue: _imageUrl,
                        decoration: const InputDecoration(labelText: 'URL de l\'image', border: OutlineInputBorder()),
                        onSaved: (value) => _imageUrl = value,
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
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Requis';
                                }
                                final num = int.tryParse(value);
                                if (num == null) {
                                  return 'Doit être un nombre';
                                }
                                if (num < 0) {
                                  return 'Ne peut pas être négatif';
                                }
                                return null;
                              },
                              onSaved: (value) => _quantiteInitiale = int.tryParse(value ?? '0') ?? 0,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              initialValue: _quantiteStock.toString(),
                              decoration: const InputDecoration(labelText: 'Quantité en stock *', border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Requis';
                                }
                                final num = int.tryParse(value);
                                if (num == null) {
                                  return 'Doit être un nombre';
                                }
                                if (num < 0) {
                                  return 'Ne peut pas être négatif';
                                }
                                return null;
                              },
                              onSaved: (value) => _quantiteStock = int.tryParse(value ?? '0') ?? 0,
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
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  final num = int.tryParse(value);
                                  if (num == null) {
                                    return 'Doit être un nombre';
                                  }
                                  if (num < 0) {
                                    return 'Ne peut pas être négatif';
                                  }
                                }
                                return null;
                              },
                              onSaved: (value) => _quantiteAvariee = int.tryParse(value ?? '0') ?? 0,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              initialValue: _stockMin.toString(),
                              decoration: const InputDecoration(labelText: 'Stock minimum', border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  final num = int.tryParse(value);
                                  if (num == null) {
                                    return 'Doit être un nombre';
                                  }
                                  if (num < 0) {
                                    return 'Ne peut pas être négatif';
                                  }
                                }
                                return null;
                              },
                              onSaved: (value) => _stockMin = int.tryParse(value ?? '0') ?? 0,
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
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  final num = int.tryParse(value);
                                  if (num == null) {
                                    return 'Doit être un nombre';
                                  }
                                  if (num < 0) {
                                    return 'Ne peut pas être négatif';
                                  }
                                }
                                return null;
                              },
                              onSaved: (value) => _stockMax = int.tryParse(value ?? '0') ?? 0,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              initialValue: _seuilAlerte.toString(),
                              decoration: const InputDecoration(labelText: 'Seuil d\'alerte', border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  final num = int.tryParse(value);
                                  if (num == null) {
                                    return 'Doit être un nombre';
                                  }
                                  if (num < 0) {
                                    return 'Ne peut pas être négatif';
                                  }
                                }
                                return null;
                              },
                              onSaved: (value) => _seuilAlerte = int.tryParse(value ?? '0') ?? 0,
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
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Requis';
                                }
                                final num = double.tryParse(value);
                                if (num == null) {
                                  return 'Doit être un nombre valide';
                                }
                                if (num < 0) {
                                  return 'Ne peut pas être négatif';
                                }
                                return null;
                              },
                              onSaved: (value) => _prixAchat = double.tryParse(value ?? '0.0') ?? 0.0,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              initialValue: _prixVente.toString(),
                              decoration: const InputDecoration(labelText: 'Prix de vente *', border: OutlineInputBorder()),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Requis';
                                }
                                final num = double.tryParse(value);
                                if (num == null) {
                                  return 'Doit être un nombre valide';
                                }
                                if (num < 0) {
                                  return 'Ne peut pas être négatif';
                                }
                                return null;
                              },
                              onSaved: (value) => _prixVente = double.tryParse(value ?? '0.0') ?? 0.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: _tva.toString(),
                        decoration: const InputDecoration(labelText: 'TVA (%)', border: OutlineInputBorder()),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final num = double.tryParse(value);
                            if (num == null) {
                              return 'Doit être un nombre valide';
                            }
                            if (num < 0) {
                              return 'Ne peut pas être négatif';
                            }
                          }
                          return null;
                        },
                        onSaved: (value) => _tva = double.tryParse(value ?? '0.0') ?? 0.0,
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
    );
  }
}