import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';

class DamagedHistoryScreen extends StatefulWidget {
  const DamagedHistoryScreen({Key? key}) : super(key: key);

  @override
  _DamagedHistoryScreenState createState() => _DamagedHistoryScreenState();
}

class _DamagedHistoryScreenState extends State<DamagedHistoryScreen> {
  late Database _database;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  String? _selectedAction; // Filtre d'action existant
  String _searchQuery = ''; // Pour la barre de recherche
  String _selectedPeriod = 'tout'; // Filtre par période
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initDatabase();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _database.close();
    super.dispose();
  }

  Future<void> _initDatabase() async {
    try {
      _database = await openDatabase(
        path.join(await getDatabasesPath(), 'dashboard.db'),
      );
    } catch (e) {
      print('Erreur lors de l\'initialisation de la base de données : $e');
    }
  }

  Future<List<Map<String, dynamic>>> _getHistory() async {
    try {
      String query = '''
        SELECT 
          h.*,
          p.nom as nomProduit,
          p.categorie,
          p.unite,
          p.fournisseurPrincipal
        FROM historique_avaries h
        LEFT JOIN produits p ON h.produitId = p.id
      ''';
      List<String> whereClauses = [];
      List<dynamic> whereArgs = [];

      // Filtre par action
      if (_selectedAction != null) {
        whereClauses.add('h.action = ?');
        whereArgs.add(_selectedAction);
      }

      // Filtre par recherche (nom du produit)
      if (_searchQuery.isNotEmpty) {
        whereClauses.add('p.nom LIKE ?');
        whereArgs.add('%$_searchQuery%');
      }

      // Filtre par période
      if (_selectedPeriod != 'tout') {
        final now = DateTime.now().millisecondsSinceEpoch;
        int timeThreshold;
        switch (_selectedPeriod) {
          case 'semaine':
            timeThreshold = now - (7 * 24 * 60 * 60 * 1000); // 7 jours
            break;
          case 'mois':
            timeThreshold = now - (30 * 24 * 60 * 60 * 1000); // 30 jours
            break;
          case 'année':
            timeThreshold = now - (365 * 24 * 60 * 60 * 1000); // 365 jours
            break;
          default:
            timeThreshold = 0;
        }
        whereClauses.add('h.date >= ?');
        whereArgs.add(timeThreshold);
      }

      if (whereClauses.isNotEmpty) {
        query += ' WHERE ${whereClauses.join(' AND ')}';
      }

      query += ' ORDER BY h.date DESC';
      return await _database.rawQuery(query, whereArgs);
    } catch (e) {
      print('Erreur lors de la récupération de l\'historique : $e');
      return [];
    }
  }

  Color _getActionColor(String action) {
    switch (action.toLowerCase()) {
      case 'retour':
        return Colors.blue;
      case 'detruit':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade800 : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.history,
                  color: theme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Historique des avaries',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                DropdownButton<String>(
                  value: _selectedAction,
                  hint: const Text('Filtrer par action'),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Toutes les actions'),
                    ),
                    const DropdownMenuItem<String>(
                      value: 'declare',
                      child: Text('Déclaré'),
                    ),
                    const DropdownMenuItem<String>(
                      value: 'retour',
                      child: Text('Retour'),
                    ),
                    const DropdownMenuItem<String>(
                      value: 'detruit',
                      child: Text('Détruit'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedAction = value;
                    });
                  },
                  underline: const SizedBox(),
                  icon: Icon(Icons.filter_list, color: Colors.grey.shade600),
                  dropdownColor: isDarkMode ? Colors.grey.shade700 : Colors.white,
                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher par nom de produit...',
                      prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade100,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _selectedPeriod,
                  hint: const Text('Filtrer par période'),
                  items: [
                    const DropdownMenuItem<String>(
                      value: 'tout',
                      child: Text('Tout'),
                    ),
                    const DropdownMenuItem<String>(
                      value: 'semaine',
                      child: Text('Semaine'),
                    ),
                    const DropdownMenuItem<String>(
                      value: 'mois',
                      child: Text('Mois'),
                    ),
                    const DropdownMenuItem<String>(
                      value: 'année',
                      child: Text('Année'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedPeriod = value!;
                    });
                  },
                  underline: const SizedBox(),
                  icon: Icon(Icons.calendar_today, color: Colors.grey.shade600),
                  dropdownColor: isDarkMode ? Colors.grey.shade700 : Colors.white,
                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _getHistory(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Erreur : ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  );
                }

                final history = snapshot.data ?? [];
                
                if (history.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inventory_2,
                          size: 48,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun historique d\'avaries disponible',
                          style: TextStyle(
                            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final entry = history[index];
                    final date = DateTime.fromMillisecondsSinceEpoch(entry['date']);
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.inventory_2,
                                  color: theme.primaryColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    entry['nomProduit'] ?? 'Produit inconnu',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getActionColor(entry['action'])
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    entry['action'].toString().toUpperCase(),
                                    style: TextStyle(
                                      color: _getActionColor(entry['action']),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  'Quantité : ${entry['quantite']} ${entry['unite'] ?? ''}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const Spacer(),
                                Text(
                                  'Catégorie : ${entry['categorie'] ?? 'Non définie'}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  'Fournisseur : ${entry['fournisseurPrincipal'] ?? 'Non défini'}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: 16,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  entry['utilisateur'],
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _dateFormat.format(date),
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
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
    );
  }
}