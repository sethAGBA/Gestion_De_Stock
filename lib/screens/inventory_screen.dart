import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:stock_management/providers/auth_provider.dart';
import '../models/models.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({Key? key}) : super(key: key);

  @override
  _InventoryScreenState createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  late Database _database;
  late Future<List<Produit>> _produitsFuture;

  @override
  void initState() {
    super.initState();
    _produitsFuture = Future.value([]);
    _initDatabase().then((_) {
      setState(() {
        _produitsFuture = _getProducts();
      });
    }).catchError((e) {
      print('Erreur lors de l\'initialisation : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur d\'initialisation : $e')),
      );
    });
  }

  @override
  void dispose() {
    _database.close();
    super.dispose();
  }

  Future<void> _initDatabase() async {
    print('Initialisation de la base de données pour InventoryScreen...');
    _database = await openDatabase(
      path.join(await getDatabasesPath(), 'dashboard.db'),
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
        print('Clés étrangères activées');
      },
    );
    print('Base de données initialisée avec succès');
  }

  Future<List<Produit>> _getProducts() async {
    print('Récupération des produits...');
    try {
      final List<Map<String, dynamic>> maps = await _database.query('produits');
      print('Produits récupérés : ${maps.length}');
      return List.generate(maps.length, (i) => Produit.fromMap(maps[i]));
    } catch (e) {
      print('Erreur lors de la récupération des produits : $e');
      return [];
    }
  }

  Future<void> _logAdjustment(int produitId, String produitNom, int quantiteStockChange, int quantiteAvarieeChange, String utilisateur) async {
    try {
      final log = DamagedAction(
        id: 0,
        produitId: produitId,
        produitNom: produitNom,
        quantite: quantiteStockChange != 0 ? quantiteStockChange : quantiteAvarieeChange,
        action: 'ajustement',
        utilisateur: utilisateur,
        date: DateTime.now().millisecondsSinceEpoch,
      );
      await _database.insert('historique_avaries', log.toMap());
      print('Ajustement enregistré dans historique_avaries pour produit $produitId');
    } catch (e) {
      print('Erreur lors de l\'enregistrement de l\'ajustement : $e');
    }
  }

  Future<void> _adjustStock(Produit produit) async {
    final formKey = GlobalKey<FormState>();
    int newQuantiteStock = produit.quantiteStock;
    int newQuantiteAvariee = produit.quantiteAvariee;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ajuster le stock : ${produit.nom}'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Stock actuel : ${produit.quantiteStock}${produit.unite == 'kg' ? ' kg' : ''}'),
              Text('Quantité avariée : ${produit.quantiteAvariee}${produit.unite == 'kg' ? ' kg' : ''}'),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: produit.quantiteStock.toString(),
                decoration: const InputDecoration(
                  labelText: 'Nouvelle quantité en stock',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer une quantité';
                  }
                  final num = int.tryParse(value);
                  if (num == null) {
                    return 'Doit être un nombre';
                  }
                  if (num < 0) {
                    return 'La quantité ne peut pas être négative';
                  }
                  return null;
                },
                onSaved: (value) {
                  newQuantiteStock = int.parse(value!);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: produit.quantiteAvariee.toString(),
                decoration: const InputDecoration(
                  labelText: 'Nouvelle quantité avariée',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer une quantité';
                  }
                  final num = int.tryParse(value);
                  if (num == null) {
                    return 'Doit être un nombre';
                  }
                  if (num < 0) {
                    return 'La quantité ne peut pas être négative';
                  }
                  return null;
                },
                onSaved: (value) {
                  newQuantiteAvariee = int.parse(value!);
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
          TextButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                try {
                  await _database.update(
                    'produits',
                    {
                      'quantiteStock': newQuantiteStock,
                      'quantiteAvariee': newQuantiteAvariee,
                    },
                    where: 'id = ?',
                    whereArgs: [produit.id],
                  );
                  final quantiteStockChange = newQuantiteStock - produit.quantiteStock;
                  final quantiteAvarieeChange = newQuantiteAvariee - produit.quantiteAvariee;
                  if (quantiteStockChange != 0 || quantiteAvarieeChange != 0) {
                    await _logAdjustment(
                      produit.id,
                      produit.nom,
                      quantiteStockChange,
                      quantiteAvarieeChange,
                      Provider.of<AuthProvider>(context, listen: false).currentUser?.name ?? 'Inconnu',
                    );
                  }
                  Navigator.pop(context);
                  setState(() {
                    _produitsFuture = _getProducts();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Stock ajusté avec succès')),
                  );
                } catch (e) {
                  print('Erreur lors de l\'ajustement du stock : $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur lors de l\'ajustement : $e')),
                  );
                }
              }
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Inventaire',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : const Color(0xFF0A3049),
                  ),
                ),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: null, // Placeholder
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.grey.shade400,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Inventaire global/partiel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: null, // Placeholder
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.grey.shade400,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Imprimer fiche'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: null, // Placeholder
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.grey.shade400,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Calculer écarts'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const SizedBox(width: 120, child: Text('Nom', style: TextStyle(fontWeight: FontWeight.bold))),
                    const SizedBox(width: 120, child: Text('Catégorie', style: TextStyle(fontWeight: FontWeight.bold))),
                    const SizedBox(width: 120, child: Text('Stock', style: TextStyle(fontWeight: FontWeight.bold))),
                    const SizedBox(width: 120, child: Text('Avarié', style: TextStyle(fontWeight: FontWeight.bold))),
                    const SizedBox(width: 120, child: Text('Fournisseur', style: TextStyle(fontWeight: FontWeight.bold))),
                    const SizedBox(width: 80, child: Text('Statut', style: TextStyle(fontWeight: FontWeight.bold))),
                    const SizedBox(width: 80, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Produit>>(
                future: _produitsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    print('Erreur dans FutureBuilder : ${snapshot.error}');
                    return Center(child: Text('Erreur : ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 48,
                            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun produit disponible',
                            style: TextStyle(
                              fontSize: 16,
                              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  final produits = snapshot.data!;
                  print('Affichage des produits : ${produits.map((p) => p.nom).toList()}');
                  return ListView.builder(
                    itemCount: produits.length,
                    itemBuilder: (context, index) {
                      final produit = produits[index];
                      final isLowStock = produit.quantiteStock <= produit.seuilAlerte;
                      final hasDamaged = produit.quantiteAvariee > 0;
                      return Container(
                        decoration: BoxDecoration(
                          color: hasDamaged ? Colors.red.withOpacity(0.05) : null,
                          border: Border(bottom: BorderSide(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 120,
                                  child: Text(
                                    produit.nom,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(
                                  width: 120,
                                  child: Text(
                                    produit.categorie,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(
                                  width: 120,
                                  child: Text(
                                    '${produit.quantiteStock}${produit.unite == 'kg' ? ' kg' : ''}',
                                    style: TextStyle(
                                      color: isLowStock ? Colors.red : null,
                                      fontWeight: isLowStock ? FontWeight.bold : null,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(
                                  width: 120,
                                  child: Text(
                                    '${produit.quantiteAvariee}${produit.unite == 'kg' ? ' kg' : ''}',
                                    style: TextStyle(
                                      color: hasDamaged ? Colors.red : null,
                                      fontWeight: hasDamaged ? FontWeight.bold : null,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(
                                  width: 120,
                                  child: Text(
                                    produit.fournisseurPrincipal ?? 'N/A',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(
                                  width: 80,
                                  child: Text(
                                    produit.statut,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(
                                  width: 80,
                                  child: IconButton(
                                    icon: const Icon(Icons.edit, color: Color(0xFF0E5A8A)),
                                    onPressed: () => _adjustStock(produit),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}