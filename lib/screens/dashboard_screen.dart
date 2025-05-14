import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import '../widgets/products_table_widget.dart';
import '../widgets/sidebar_widget.dart';
import '../widgets/appbar_widget.dart';
import '../widgets/stats_cards_widget.dart';
import '../screens/products_screen.dart';
import '../screens/entries_screen.dart';
import '../screens/exits_screen.dart';
import '../screens/inventory_screen.dart';
import '../screens/suppliers_screen.dart';
import '../screens/users_screen.dart';
import '../screens/sales_screen.dart';
import '../screens/alerts_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/damaged_history_screen.dart';
import '../models/models.dart';
import '../widgets/stock_movements_chart_widget.dart';
import '../widgets/suppliers_table_widget.dart';
import '../widgets/users_table_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Database _database;
  late Future<List<Produit>> _produitsFuture;
  late Future<List<Supplier>> _suppliersFuture;
  late Future<List<User>> _usersFuture;
  final List<String> months = ['Mai', 'Juin', 'Juillet', 'Août', 'Octobre'];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _produitsFuture = Future.value([]);
    _suppliersFuture = Future.value([]);
    _usersFuture = Future.value([]);
    _initDatabase().then((_) {
      setState(() {
        _produitsFuture = _getProduits();
        _suppliersFuture = _getSuppliers();
        _usersFuture = _getUsers();
      });
    }).catchError((e) {
      print('Erreur lors de l\'initialisation de la base de données : $e');
    });
  }

  @override
  void dispose() {
    _database.close();
    super.dispose();
  }

  Future<void> _initDatabase() async {
    try {
      print('Initialisation de la base de données...');
      _database = await openDatabase(
        path.join(await getDatabasesPath(), 'dashboard.db'),
        version: 5,
        onCreate: (db, version) async {
          print('Création des tables...');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS produits (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              nom TEXT NOT NULL,
              description TEXT,
              categorie TEXT NOT NULL,
              marque TEXT,
              imageUrl TEXT,
              sku TEXT,
              codeBarres TEXT,
              unite TEXT NOT NULL,
              quantiteStock INTEGER NOT NULL DEFAULT 0,
              quantiteAvariee INTEGER NOT NULL DEFAULT 0,
              stockMin INTEGER NOT NULL DEFAULT 0,
              stockMax INTEGER NOT NULL DEFAULT 0,
              seuilAlerte INTEGER NOT NULL DEFAULT 0,
              variantes TEXT,
              prixAchat REAL NOT NULL DEFAULT 0.0,
              prixVente REAL NOT NULL DEFAULT 0.0,
              tva REAL NOT NULL DEFAULT 0.0,
              fournisseurPrincipal TEXT,
              fournisseursSecondaires TEXT,
              derniereEntree INTEGER,
              derniereSortie INTEGER,
              statut TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS suppliers (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              productName TEXT NOT NULL,
              category TEXT NOT NULL,
              price REAL NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS users (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              role TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS historique_avaries (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              produitId INTEGER NOT NULL,
              produitNom TEXT NOT NULL,
              quantite INTEGER NOT NULL,
              action TEXT NOT NULL,
              utilisateur TEXT NOT NULL,
              date INTEGER NOT NULL,
              FOREIGN KEY (produitId) REFERENCES produits(id)
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS clients (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              nom TEXT NOT NULL,
              email TEXT,
              telephone TEXT,
              adresse TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS bons_commande (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              clientId INTEGER NOT NULL,
              date INTEGER NOT NULL,
              statut TEXT NOT NULL,
              FOREIGN KEY (clientId) REFERENCES clients(id)
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS bon_commande_items (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              bonCommandeId INTEGER NOT NULL,
              produitId INTEGER NOT NULL,
              quantite INTEGER NOT NULL,
              prixUnitaire REAL NOT NULL,
              FOREIGN KEY (bonCommandeId) REFERENCES bons_commande(id),
              FOREIGN KEY (produitId) REFERENCES produits(id)
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS factures (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              numero TEXT NOT NULL,
              bonCommandeId INTEGER NOT NULL,
              clientId INTEGER NOT NULL,
              date INTEGER NOT NULL,
              total REAL NOT NULL,
              statutPaiement TEXT NOT NULL,
              FOREIGN KEY (bonCommandeId) REFERENCES bons_commande(id),
              FOREIGN KEY (clientId) REFERENCES clients(id)
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS paiements (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              factureId INTEGER NOT NULL,
              montant REAL NOT NULL,
              date INTEGER NOT NULL,
              methode TEXT NOT NULL,
              FOREIGN KEY (factureId) REFERENCES factures(id)
            )
          ''');
          print('Insertion de données initiales...');
          await db.insert('produits', Produit(
            id: 0,
            nom: 'Article A',
            description: '',
            categorie: 'Électronique',
            marque: '',
            imageUrl: '',
            sku: '',
            codeBarres: '',
            unite: 'pièce',
            quantiteStock: 123,
            quantiteAvariee: 0,
            stockMin: 5,
            stockMax: 50,
            seuilAlerte: 5,
            variantes: [],
            prixAchat: 0.0,
            prixVente: 100.0,
            tva: 20.0,
            fournisseurPrincipal: 'Supplier X',
            fournisseursSecondaires: [],
            derniereEntree: null,
            derniereSortie: null,
            statut: 'disponible',
          ).toMap());
          await db.insert('produits', Produit(
            id: 0,
            nom: 'Article B',
            description: '',
            categorie: 'Électronique',
            marque: '',
            imageUrl: '',
            sku: '',
            codeBarres: '',
            unite: 'pièce',
            quantiteStock: 10,
            quantiteAvariee: 0,
            stockMin: 5,
            stockMax: 50,
            seuilAlerte: 5,
            variantes: [],
            prixAchat: 0.0,
            prixVente: 1230.0,
            tva: 20.0,
            fournisseurPrincipal: 'Supplier X',
            fournisseursSecondaires: [],
            derniereEntree: null,
            derniereSortie: null,
            statut: 'disponible',
          ).toMap());
          await db.insert('suppliers', Supplier(
            id: 0,
            name: 'Supplier X',
            productName: 'Article A',
            category: 'Électronique',
            price: 50.00,
          ).toMap());
          await db.insert('users', User(
            id: 0,
            name: 'Admin',
            role: 'Administrateur',
          ).toMap());
          await db.insert('clients', Client(
            id: 0,
            nom: 'Jean Dupont',
            email: 'jean.dupont@example.com',
            telephone: '123456789',
            adresse: '123 Rue Exemple, Lomé',
          ).toMap());
          print('Base de données initialisée avec succès.');
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          print('Mise à jour de la base de données de $oldVersion à $newVersion...');
          if (oldVersion < 2) {
            await db.execute('ALTER TABLE produits ADD COLUMN quantiteAvariee INTEGER NOT NULL DEFAULT 0');
          }
          if (oldVersion < 3) {
            await db.execute('''
              CREATE TABLE IF NOT EXISTS historique_avaries (
                id TEXT PRIMARY KEY,
                produitId TEXT NOT NULL,
                quantite INTEGER NOT NULL,
                action TEXT NOT NULL,
                utilisateur TEXT NOT NULL,
                date INTEGER NOT NULL,
                FOREIGN KEY (produitId) REFERENCES produits(id)
              )
            ''');
          }
          if (oldVersion < 4) {
            print('Migration vers version 4 : conversion des ID en INTEGER');
            // Migration des produits
            await db.execute('''
              CREATE TABLE produits_new (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                nom TEXT NOT NULL,
                description TEXT,
                categorie TEXT NOT NULL,
                marque TEXT,
                imageUrl TEXT,
                sku TEXT,
                codeBarres TEXT,
                unite TEXT NOT NULL,
                quantiteStock INTEGER NOT NULL DEFAULT 0,
                quantiteAvariee INTEGER NOT NULL DEFAULT 0,
                stockMin INTEGER NOT NULL DEFAULT 0,
                stockMax INTEGER NOT NULL DEFAULT 0,
                seuilAlerte INTEGER NOT NULL DEFAULT 0,
                variantes TEXT,
                prixAchat REAL NOT NULL DEFAULT 0.0,
                prixVente REAL NOT NULL DEFAULT 0.0,
                tva REAL NOT NULL DEFAULT 0.0,
                fournisseurPrincipal TEXT,
                fournisseursSecondaires TEXT,
                derniereEntree INTEGER,
                derniereSortie INTEGER,
                statut TEXT NOT NULL
              )
            ''');
            await db.execute('''
              INSERT INTO produits_new (
                nom, description, categorie, marque, imageUrl, sku, codeBarres, unite,
                quantiteStock, quantiteAvariee, stockMin, stockMax, seuilAlerte, variantes,
                prixAchat, prixVente, tva, fournisseurPrincipal, fournisseursSecondaires,
                derniereEntree, derniereSortie, statut
              )
              SELECT
                nom, description, categorie, marque, imageUrl, sku, codeBarres, unite,
                quantiteStock, quantiteAvariee, stockMin, stockMax, seuilAlerte, variantes,
                prixAchat, prixVente, tva, fournisseurPrincipal, fournisseursSecondaires,
                derniereEntree, derniereSortie, statut
              FROM produits
            ''');
            await db.execute('DROP TABLE produits');
            await db.execute('ALTER TABLE produits_new RENAME TO produits');

            // Migration des fournisseurs
            await db.execute('''
              CREATE TABLE suppliers_new (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                productName TEXT NOT NULL,
                category TEXT NOT NULL,
                price REAL NOT NULL
              )
            ''');
            await db.execute('''
              INSERT INTO suppliers_new (name, productName, category, price)
              SELECT name, productName, category, price
              FROM suppliers
            ''');
            await db.execute('DROP TABLE suppliers');
            await db.execute('ALTER TABLE suppliers_new RENAME TO suppliers');

            // Migration des utilisateurs
            await db.execute('''
              CREATE TABLE users_new (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                role TEXT NOT NULL
              )
            ''');
            await db.execute('''
              INSERT INTO users_new (name, role)
              SELECT name, role
              FROM users
            ''');
            await db.execute('DROP TABLE users');
            await db.execute('ALTER TABLE users_new RENAME TO users');

            // Migration de historique_avaries
            await db.execute('''
              CREATE TABLE historique_avaries_new (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                produitId INTEGER NOT NULL,
                produitNom TEXT NOT NULL,
                quantite INTEGER NOT NULL,
                action TEXT NOT NULL,
                utilisateur TEXT NOT NULL,
                date INTEGER NOT NULL,
                FOREIGN KEY (produitId) REFERENCES produits(id)
              )
            ''');
            await db.execute('''
              INSERT INTO historique_avaries_new (
                produitId, produitNom, quantite, action, utilisateur, date
              )
              SELECT
                CAST(produitId AS INTEGER), 'Inconnu', quantite, action, utilisateur, date
              FROM historique_avaries
            ''');
            await db.execute('DROP TABLE historique_avaries');
            await db.execute('ALTER TABLE historique_avaries_new RENAME TO historique_avaries');
          }
          if (oldVersion < 5) {
            print('Migration vers version 5 : ajout des tables pour facturation');
            await db.execute('''
              CREATE TABLE IF NOT EXISTS clients (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                nom TEXT NOT NULL,
                email TEXT,
                telephone TEXT,
                adresse TEXT
              )
            ''');
            await db.execute('''
              CREATE TABLE IF NOT EXISTS bons_commande (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                clientId INTEGER NOT NULL,
                date INTEGER NOT NULL,
                statut TEXT NOT NULL,
                FOREIGN KEY (clientId) REFERENCES clients(id)
              )
            ''');
            await db.execute('''
              CREATE TABLE IF NOT EXISTS bon_commande_items (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                bonCommandeId INTEGER NOT NULL,
                produitId INTEGER NOT NULL,
                quantite INTEGER NOT NULL,
                prixUnitaire REAL NOT NULL,
                FOREIGN KEY (bonCommandeId) REFERENCES bons_commande(id),
                FOREIGN KEY (produitId) REFERENCES produits(id)
              )
            ''');
            await db.execute('''
              CREATE TABLE IF NOT EXISTS factures (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                numero TEXT NOT NULL,
                bonCommandeId INTEGER NOT NULL,
                clientId INTEGER NOT NULL,
                date INTEGER NOT NULL,
                total REAL NOT NULL,
                statutPaiement TEXT NOT NULL,
                FOREIGN KEY (bonCommandeId) REFERENCES bons_commande(id),
                FOREIGN KEY (clientId) REFERENCES clients(id)
              )
            ''');
            await db.execute('''
              CREATE TABLE IF NOT EXISTS paiements (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                factureId INTEGER NOT NULL,
                montant REAL NOT NULL,
                date INTEGER NOT NULL,
                methode TEXT NOT NULL,
                FOREIGN KEY (factureId) REFERENCES factures(id)
              )
            ''');
            await db.insert('clients', Client(
              id: 0,
              nom: 'Jean Dupont',
              email: 'jean.dupont@example.com',
              telephone: '123456789',
              adresse: '123 Rue Exemple, Lomé',
            ).toMap());
          }
          print('Mise à jour terminée.');
        },
      );
    } catch (e) {
      print('Erreur dans _initDatabase : $e');
    }
  }

  Future<List<Produit>> _getProduits() async {
    try {
      print('Récupération des produits...');
      final List<Map<String, dynamic>> maps = await _database.query('produits');
      print('Produits récupérés : ${maps.length}');
      return List.generate(maps.length, (i) => Produit.fromMap(maps[i]));
    } catch (e) {
      print('Erreur lors de la récupération des produits : $e');
      return [];
    }
  }

  Future<List<Supplier>> _getSuppliers() async {
    try {
      print('Récupération des fournisseurs...');
      final List<Map<String, dynamic>> maps = await _database.query('suppliers');
      print('Fournisseurs récupérés : ${maps.length}');
      return List.generate(maps.length, (i) => Supplier.fromMap(maps[i]));
    } catch (e) {
      print('Erreur lors de la récupération des fournisseurs : $e');
      return [];
    }
  }

  Future<List<User>> _getUsers() async {
    try {
      print('Récupération des utilisateurs...');
      final List<Map<String, dynamic>> maps = await _database.query('users');
      print('Utilisateurs récupérés : ${maps.length}');
      return List.generate(maps.length, (i) => User.fromMap(maps[i]));
    } catch (e) {
      print('Erreur lors de la récupération des utilisateurs : $e');
      return [];
    }
  }

  List<Widget> get _screens {
    return [
      FutureBuilder<List<Produit>>(
        future: _produitsFuture,
        builder: (context, produitSnapshot) {
          if (produitSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (produitSnapshot.hasError) {
            return Center(child: Text('Erreur : ${produitSnapshot.error}'));
          }
          return FutureBuilder<List<Supplier>>(
            future: _suppliersFuture,
            builder: (context, supplierSnapshot) {
              if (supplierSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (supplierSnapshot.hasError) {
                return Center(child: Text('Erreur : ${supplierSnapshot.error}'));
              }
              return FutureBuilder<List<User>>(
                future: _usersFuture,
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (userSnapshot.hasError) {
                    return Center(child: Text('Erreur : ${userSnapshot.error}'));
                  }
                  if (!produitSnapshot.hasData || !supplierSnapshot.hasData || !userSnapshot.hasData) {
                    return Center(child: Text('Aucune donnée disponible'));
                  }
                  return DashboardContent(
                    produits: produitSnapshot.data!,
                    suppliers: supplierSnapshot.data!,
                    months: months,
                    users: userSnapshot.data!,
                  );
                },
              );
            },
          );
        },
      ),
      ProductsScreen(),
      EntriesScreen(),
      ExitsScreen(),
      InventoryScreen(),
      SuppliersScreen(),
      UsersScreen(),
      SalesScreen(),
      AlertsScreen(),
      SettingsScreen(),
      DamagedHistoryScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (_selectedIndex == 0) {
        _produitsFuture = _getProduits();
        _suppliersFuture = _getSuppliers();
        _usersFuture = _getUsers();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 1200;
    final isVerySmallScreen = screenWidth < 800;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 800),
      child: Scaffold(
        body: Row(
          children: [
            if (!isVerySmallScreen) SidebarWidget(onItemTapped: _onItemTapped),
            Expanded(
              child: Container(
                color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppBarWidget(
                      isSmallScreen: isVerySmallScreen,
                      onMenuPressed: isVerySmallScreen
                          ? () => Scaffold.of(context).openDrawer()
                          : null,
                    ),
                    Expanded(
                      child: IndexedStack(
                        index: _selectedIndex,
                        children: _screens,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        drawer: isVerySmallScreen ? Drawer(child: SidebarWidget(onItemTapped: _onItemTapped)) : null,
      ),
    );
  }
}

class DashboardContent extends StatelessWidget {
  final List<Produit> produits;
  final List<Supplier> suppliers;
  final List<String> months;
  final List<User> users;

  const DashboardContent({
    Key? key,
    required this.produits,
    required this.suppliers,
    required this.months,
    required this.users,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 1200;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth < 800 ? 8.0 : 16.0,
        vertical: 16.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tableau de bord',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 24.0),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade800 : Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                if (!isDarkMode)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10.0,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: StatsCardsWidget(
              totalProducts: produits.length,
              outOfStock: produits.where((p) => p.quantiteStock <= p.stockMin).length,
              stockValue: produits.isNotEmpty
                  ? produits.map((p) => (p.prixVente) * p.quantiteStock).reduce((a, b) => a + b)
                  : 0.0,
              productsSold: 320,
              screenWidth: screenWidth,
            ),
          ),
          const SizedBox(height: 24.0),
          Container(
            width: screenWidth * 0.9, // Largeur augmentée comme demandé le 14 mai 2025
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade800 : Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                if (!isDarkMode)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10.0,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: produits.isEmpty
                ? Center(
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
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ProductsTableWidget(produits: produits),
          ),
          const SizedBox(height: 24.0),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade800 : Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                if (!isDarkMode)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10.0,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: StockMovementsChartWidget(months: months),
          ),
          const SizedBox(height: 24.0),
          isSmallScreen
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey.shade800 : Colors.white,
                        borderRadius: BorderRadius.circular(12.0),
                        boxShadow: [
                          if (!isDarkMode)
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10.0,
                              offset: const Offset(0, 4),
                            ),
                        ],
                      ),
                      child: SuppliersTableWidget(suppliers: suppliers),
                    ),
                    const SizedBox(height: 24.0),
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey.shade800 : Colors.white,
                        borderRadius: BorderRadius.circular(12.0),
                        boxShadow: [
                          if (!isDarkMode)
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10.0,
                              offset: const Offset(0, 4),
                            ),
                        ],
                      ),
                      child: UsersTableWidget(users: users),
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey.shade800 : Colors.white,
                          borderRadius: BorderRadius.circular(12.0),
                          boxShadow: [
                            if (!isDarkMode)
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10.0,
                                offset: const Offset(0, 4),
                              ),
                          ],
                        ),
                        child: SuppliersTableWidget(suppliers: suppliers),
                      ),
                    ),
                    const SizedBox(width: 24.0),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey.shade800 : Colors.white,
                          borderRadius: BorderRadius.circular(12.0),
                          boxShadow: [
                            if (!isDarkMode)
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10.0,
                                offset: const Offset(0, 4),
                              ),
                          ],
                        ),
                        child: UsersTableWidget(users: users),
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}