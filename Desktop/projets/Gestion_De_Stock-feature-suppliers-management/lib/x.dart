import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const StockManagementApp());
}

class StockManagementApp extends StatelessWidget {
  const StockManagementApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gestion de Stock',
      theme: ThemeData(
        primaryColor: const Color(0xFF1C3144),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1C3144),
          primary: const Color(0xFF1C3144),
        ),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final List<Product> products = [
    Product(name: 'Article A', category: 'Électronique', stock: 20, price: 50.00, supplier: 'Suppiler X'),
    Product(name: 'Article B', category: 'Outils', stock: 15, price: 150.00, supplier: 'Soluveier X'),
    Product(name: 'Article C', category: 'Outils', stock: 30, price: 25.00, supplier: 'Supureier Y'),
  ];

  final List<Supplier> suppliers = [
    Supplier(name: 'Suppiler X', productName: 'Article A', category: 'Electronique', price: 50.00),
    Supplier(name: 'Soluveier X', productName: 'Article B', category: 'Français', price: 150.00),
    Supplier(name: 'Supureier Y', productName: '', category: '', price: 0),
  ];

  final List<String> months = ['Mai', 'Jun', 'Mai', 'Jun', 'Jul', 'Aug', 'Oct'];
  final List<User> users = [
    User(name: 'Admin', role: 'Admin'),
    User(name: 'Magasinier', role: 'Magasinier'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          SidebarWidget(),
          
          // Main Content
          Expanded(
            child: Container(
              color: Colors.grey[100],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Bar
                  AppBarWidget(),
                  
                  // Dashboard Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tableau de bord',
                            style: TextStyle(
                              fontSize: 28.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20.0),
                          
                          // Stats Cards
                          StatsCardsWidget(
                            totalProducts: 150,
                            outOfStock: 8,
                            stockValue: 75350,
                            productsSold: 320,
                          ),
                          const SizedBox(height: 20.0),
                          
                          // Products and Chart Section
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Products Table
                              Expanded(
                                flex: 3,
                                child: ProductsTableWidget(products: products),
                              ),
                              const SizedBox(width: 20.0),
                              
                              // Stock Movements Chart
                              Expanded(
                                flex: 2,
                                child: StockMovementsChartWidget(months: months),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20.0),
                          
                          // Suppliers and Users Section
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Suppliers Table
                              Expanded(
                                child: SuppliersTableWidget(suppliers: suppliers),
                              ),
                              const SizedBox(width: 20.0),
                              
                              // Users Table
                              Expanded(
                                child: UsersTableWidget(users: users),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Sidebar Widget
class SidebarWidget extends StatelessWidget {
  const SidebarWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260.0,
      color: const Color(0xFF1C3144),
      child: Column(
        children: [
          // Logo and Title
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 32.0),
            child: Row(
              children: [
                const Icon(Icons.inventory_outlined, color: Colors.white, size: 28.0),
                const SizedBox(width: 12.0),
                const Text(
                  'GESTION DE STOCK',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Menu Items
          _buildMenuItem(Icons.dashboard, 'Tableau de bord', isSelected: true),
          _buildMenuItem(Icons.list_alt_outlined, 'Produits'),
          _buildMenuItem(Icons.input, 'Entrées'),
          _buildMenuItem(Icons.output, 'Sorties'),
          _buildMenuItem(Icons.folder_open_outlined, 'Inventaire'),
          _buildMenuItem(Icons.business, 'Fournisseurs'),
          _buildMenuItem(Icons.people, 'Utilisateurs'),
          _buildMenuItem(Icons.account_balance_outlined, 'Gestion des ventes et des clients'),
          _buildMenuItem(Icons.notifications, 'Alertes'),
          
          const Spacer(),
          
          // Settings at the bottom
          _buildMenuItem(Icons.settings, 'Paramètres'),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {bool isSelected = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
        selected: isSelected,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        onTap: () {},
      ),
    );
  }
}

// App Bar Widget
class AppBarWidget extends StatelessWidget {
  const AppBarWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.red, size: 18.0),
                const SizedBox(width: 8.0),
                Text(
                  'Alerte: Produits en rupture de stock',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          ),
          const SizedBox(width: 16.0),
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

// Stats Cards Widget
class StatsCardsWidget extends StatelessWidget {
  final int totalProducts;
  final int outOfStock;
  final double stockValue;
  final int productsSold;

  const StatsCardsWidget({
    Key? key,
    required this.totalProducts,
    required this.outOfStock,
    required this.stockValue,
    required this.productsSold,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildStatCard(
          icon: Icons.inventory_2,
          iconColor: Colors.blue,
          title: '# de produits',
          value: totalProducts.toString(),
        ),
        const SizedBox(width: 16.0),
        _buildStatCard(
          icon: Icons.warning,
          iconColor: Colors.red,
          title: 'Produits en rupture',
          value: outOfStock.toString(),
        ),
        const SizedBox(width: 16.0),
        _buildStatCard(
          icon: Icons.euro,
          iconColor: Colors.green,
          title: 'Valeur du stock',
          value: 'FCFA ${stockValue.toStringAsFixed(0)}',
        ),
        const SizedBox(width: 16.0),
        _buildStatCard(
          icon: Icons.trending_up,
          iconColor: Colors.purple,
          title: 'Produits vendus',
          value: productsSold.toString(),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 16.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14.0,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Products Table Widget
class ProductsTableWidget extends StatelessWidget {
  final List<Product> products;

  const ProductsTableWidget({
    Key? key,
    required this.products,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Gestion des produits',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: const Text('Ajouter un produit...'),
                ),
                const SizedBox(width: 8.0),
                IconButton(
                  icon: const Icon(Icons.more_horiz),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          const Divider(height: 0),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1),
              4: FlexColumnWidth(2),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                ),
                children: [
                  _buildTableHeader('Nom'),
                  _buildTableHeader('Categorie'),
                  _buildTableHeader('Stock'),
                  _buildTableHeader('Prix'),
                  _buildTableHeader('Fournisseur'),
                ],
              ),
              ...products.map((product) => TableRow(
                    children: [
                      _buildTableCell(product.name),
                      _buildTableCell(product.category),
                      _buildTableCell(product.stock.toString()),
                      _buildTableCell('FCFA ${product.price.toStringAsFixed(2)}'),
                      _buildTableCell(
                        '',
                        trailing: TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                          ),
                          child: Text(
                            product.stock > 20 ? 'Supprimer' : 'Modifier',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 12.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTableCell(String text, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(text),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}

// Stock Movements Chart Widget
class StockMovementsChartWidget extends StatelessWidget {
  final List<String> months;

  const StockMovementsChartWidget({
    Key? key,
    required this.months,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Mouvements de stock',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () {},
                icon: const Text('Voir plus'),
                label: const Icon(Icons.arrow_forward, size: 16.0),
              ),
            ],
          ),
          const SizedBox(height: 20.0),
          Container(
            height: 200.0,
            child: ChartWidget(months: months),
          ),
        ],
      ),
    );
  }
}

// Chart Widget
class ChartWidget extends StatelessWidget {
  final List<String> months;

  const ChartWidget({
    Key? key,
    required this.months,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Generate random values for the chart
    final random = Random();
    final values = List.generate(
      months.length,
      (_) => 40 + random.nextInt(60),
    );

    final maxValue = values.reduce((a, b) => a > b ? a : b).toDouble();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        months.length,
        (index) {
          final height = (values[index] / maxValue) * 160;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32.0,
                height: height,
                decoration: BoxDecoration(
                  color: Colors.blue.shade300,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(4.0)),
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                months[index],
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12.0,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Suppliers Table Widget
class SuppliersTableWidget extends StatelessWidget {
  final List<Supplier> suppliers;

  const SuppliersTableWidget({
    Key? key,
    required this.suppliers,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Fournisseurs',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Text('Voir plus'),
                  label: const Icon(Icons.arrow_forward, size: 16.0),
                ),
              ],
            ),
          ),
          // Supplier List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            itemBuilder: (context, index) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Text(
                          index == 0 ? 'Supplier X' : (index == 1 ? 'Soluveier X' : 'Supureier Y'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (index < 2)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(index == 0 ? 'Article A' : 'Article B'),
                          ),
                          Expanded(
                            child: Text(index == 0 ? 'Électronique' : 'Français'),
                          ),
                          Expanded(
                            child: Text('FCFA ${index == 0 ? '50.00' : '150.00'}'),
                          ),
                          TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                            ),
                            child: Text(
                              index == 0 ? 'Modifier' : 'Supprimer',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 12.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (index < 2) const SizedBox(height: 16.0),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// Users Table Widget
class UsersTableWidget extends StatelessWidget {
  final List<User> users;

  const UsersTableWidget({
    Key? key,
    required this.users,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Utilisateurs',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Text('Voir plus'),
                  label: const Icon(Icons.arrow_forward, size: 16.0),
                ),
              ],
            ),
          ),
          // Users List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.grey[300],
                      child: Icon(
                        Icons.person,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          user.role,
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Data classes
class Product {
  final String name;
  final String category;
  final int stock;
  final double price;
  final String supplier;

  Product({
    required this.name,
    required this.category,
    required this.stock,
    required this.price,
    required this.supplier,
  });
}

class Supplier {
  final String name;
  final String productName;
  final String category;
  final double price;

  Supplier({
    required this.name,
    required this.productName,
    required this.category,
    required this.price,
  });
}

class User {
  final String name;
  final String role;

  User({
    required this.name,
    required this.role,
  });
}