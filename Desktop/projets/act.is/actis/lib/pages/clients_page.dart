// import 'package:actis/helpers/database_helper.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'add_client_page.dart';
// import 'edit_client_page.dart';
// import 'orders_page.dart';
// import 'dart:io';

// class Client {
//   final int id;
//   final String name;
//   final String phone;
//   final String email;
//   final String address;
//   final String photo;
//   final String deliveryDate;
//   final String createdAt;
//   final String status;
//   final List<String> services;
//   final double totalSpent;
//   final int totalOrders;
//   final Map<String, dynamic> measurements;
//   final String notes;
//   final String clientType;
//   final String gender;
//   final String profession;
//   final String birthdate;

//   Client({
//     required this.id,
//     required this.name,
//     required this.phone,
//     required this.email,
//     required this.address,
//     required this.photo,
//     required this.deliveryDate,
//     required this.createdAt,
//     required this.status,
//     required this.services,
//     required this.totalSpent,
//     required this.totalOrders,
//     required this.measurements,
//     required this.notes,
//     required this.clientType,
//     required this.gender,
//     required this.profession,
//     required this.birthdate,
//   });

//   factory Client.fromMap(Map<String, dynamic> map) {
//     final orders = map['orders'] as List<Map<String, dynamic>>? ?? [];
//     final services = (map['services'] as String? ?? '').split(',').where((s) => s.isNotEmpty).toList();
//     final measurements = {
//       'height': map['height'] ?? '',
//       'weight': map['weight'] ?? '',
//       'neck': map['neck'] ?? '',
//       'chest': map['chest'] ?? '',
//       'waist': map['waist'] ?? '',
//       'hips': map['hips'] ?? '',
//       'shoulder': map['shoulder'] ?? '',
//       'armLength': map['armLength'] ?? '',
//       'bustLength': map['bustLength'] ?? '',
//       'totalLength': map['totalLength'] ?? '',
//       'armCircumference': map['armCircumference'] ?? '',
//       'wrist': map['wrist'] ?? '',
//       'inseam': map['inseam'] ?? '',
//       'pantLength': map['pantLength'] ?? '',
//       'thigh': map['thigh'] ?? '',
//       'knee': map['knee'] ?? '',
//       'ankle': map['ankle'] ?? '',
//       'buttocks': map['buttocks'] ?? '',
//       'underBust': map['underBust'] ?? '',
//       'bustDistance': map['bustDistance'] ?? '',
//       'bustHeight': map['bustHeight'] ?? '',
//       'skirtLength': map['skirtLength'] ?? '',
//       'dressLength': map['dressLength'] ?? '',
//       'calf': map['calf'] ?? '',
//       'heelHeight': map['heelHeight'] ?? '',
//       'backBustLength': map['backBustLength'] ?? '',
//       'headCircumference': map['headCircumference'] ?? '',
//     };
//     return Client(
//       id: int.parse(map['id']?.toString() ?? '0'),
//       name: map['name'] ?? '',
//       phone: map['phone'] ?? '',
//       email: map['email'] ?? '',
//       address: map['address'] ?? '',
//       photo: map['photo'] ?? '',
//       deliveryDate: map['deliveryDate'] ?? '',
//       createdAt: map['createdAt'] ?? DateTime.now().toIso8601String(),
//       status: map['status'] ?? 'active',
//       services: services.isEmpty ? ['Retouches'] : services,
//       totalSpent: orders.fold(0.0, (sum, order) => sum + (order['amount'] as double? ?? 0.0)),
//       totalOrders: orders.length,
//       measurements: measurements,
//       notes: map['notes'] ?? '',
//       clientType: map['clientType'] ?? 'Adulte',
//       gender: map['gender'] ?? 'Homme',
//       profession: map['profession'] ?? '',
//       birthdate: map['birthdate'] ?? '',
//     );
//   }
// }

// String formatAmount(double amount) {
//   if (amount >= 1000000) {
//     return '${(amount / 1000000).toStringAsFixed(1)}M FCFA';
//   } else if (amount >= 1000) {
//     return '${(amount / 1000).toStringAsFixed(1)}K FCFA';
//   }
//   return '${amount.toStringAsFixed(0)} FCFA';
// }

// class ClientsPage extends StatefulWidget {
//   const ClientsPage({super.key});

//   @override
//   State<ClientsPage> createState() => _ClientsPageState();
// }

// class _ClientsPageState extends State<ClientsPage> with TickerProviderStateMixin {
//   final TextEditingController _searchController = TextEditingController();
//   String _selectedFilter = 'Tous';
//   final List<String> _filters = ['Tous', 'Actifs', 'Inactifs', 'En attente'];
//   List<Client> _clients = [];

//   final Map<String, String> _measurementTranslations = {
//     'height': 'Hauteur',
//     'weight': 'Poids',
//     'neck': 'Cou',
//     'chest': 'Poitrine',
//     'waist': 'Taille',
//     'hips': 'Hanches',
//     'shoulder': 'Épaule',
//     'armLength': 'Longueur de bras',
//     'bustLength': 'Longueur de buste',
//     'totalLength': 'Longueur totale',
//     'armCircumference': 'Circonférence de bras',
//     'wrist': 'Poignet',
//     'inseam': 'Entrejambe',
//     'pantLength': 'Longueur de pantalon',
//     'thigh': 'Cuisse',
//     'knee': 'Genou',
//     'ankle': 'Cheville',
//     'buttocks': 'Fesses',
//     'underBust': 'Sous-poitrine',
//     'bustDistance': 'Distance de buste',
//     'bustHeight': 'Hauteur de buste',
//     'skirtLength': 'Longueur de jupe',
//     'dressLength': 'Longueur de robe',
//     'calf': 'Mollet',
//     'heelHeight': 'Hauteur de talon',
//     'backBustLength': 'Longueur arrière buste',
//     'headCircumference': 'Circonférence de tête',
//   };

//   @override
//   void initState() {
//     super.initState();
//     _loadClients();
//     _searchController.addListener(() => setState(() {}));
//   }

//   Future<void> _loadClients() async {
//     final clientMaps = await DatabaseHelper().getClients();
//     final clients = <Client>[];
//     for (var map in clientMaps) {
//       final orders = await DatabaseHelper().getOrdersForClient(int.parse(map['id']?.toString() ?? '0'));
//       final mutableMap = Map<String, dynamic>.from(map);
//       mutableMap['orders'] = orders;
//       clients.add(Client.fromMap(mutableMap));
//     }
//     setState(() {
//       _clients = clients;
//     });
//   }

//   List<Client> get _filteredClients {
//     List<Client> filtered = _clients;
//     if (_selectedFilter != 'Tous') {
//       String status = _selectedFilter == 'Actifs'
//           ? 'active'
//           : _selectedFilter == 'Inactifs'
//               ? 'inactive'
//               : 'pending';
//       filtered = filtered.where((client) => client.status == status).toList();
//     }
//     if (_searchController.text.isNotEmpty) {
//       filtered = filtered.where((client) =>
//           client.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
//           client.email.toLowerCase().contains(_searchController.text.toLowerCase()) ||
//           client.phone.contains(_searchController.text)).toList();
//     }
//     return filtered;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [
//               Theme.of(context).colorScheme.background,
//               Theme.of(context).colorScheme.background.withOpacity(0.8),
//             ],
//           ),
//         ),
//         child: CustomScrollView(
//           slivers: [
//             SliverToBoxAdapter(
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   children: [
//                     _buildSearchBar(),
//                     const SizedBox(height: 16),
//                     _buildFilters(),
//                     const SizedBox(height: 20),
//                     _buildStatsCards(),
//                     const SizedBox(height: 24),
//                   ],
//                 ),
//               ),
//             ),
//             if (_clients.isEmpty)
//               SliverFillRemaining(
//                 child: Center(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       const Icon(
//                         Icons.people,
//                         size: 64,
//                         color: Color(0xFF00DDEB),
//                       ).animate().scale(duration: 500.ms),
//                       const SizedBox(height: 16),
//                       Text(
//                         'Liste des Clients',
//                         style: TextStyle(
//                           fontSize: 24,
//                           fontWeight: FontWeight.bold,
//                           fontFamily: GoogleFonts.poppins().fontFamily,
//                           color: Theme.of(context).colorScheme.onBackground,
//                         ),
//                       ).animate().fadeIn(delay: 200.ms),
//                       const SizedBox(height: 8),
//                       Text(
//                         'Aucun client ajouté pour le moment',
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontFamily: GoogleFonts.poppins().fontFamily,
//                           color: Theme.of(context).colorScheme.secondary,
//                         ),
//                       ).animate().fadeIn(delay: 300.ms),
//                     ],
//                   ),
//                 ),
//               )
//             else if (_filteredClients.isEmpty && _searchController.text.isNotEmpty)
//               SliverFillRemaining(
//                 child: Center(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       const Icon(
//                         Icons.search_off,
//                         size: 64,
//                         color: Color(0xFF00DDEB),
//                       ).animate().scale(duration: 500.ms),
//                       const SizedBox(height: 16),
//                       Text(
//                         'Aucun client trouvé',
//                         style: TextStyle(
//                           fontSize: 24,
//                           fontWeight: FontWeight.bold,
//                           fontFamily: GoogleFonts.poppins().fontFamily,
//                           color: Theme.of(context).colorScheme.onBackground,
//                         ),
//                       ).animate().fadeIn(delay: 200.ms),
//                       const SizedBox(height: 8),
//                       Text(
//                         'Essayez un autre terme de recherche',
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontFamily: GoogleFonts.poppins().fontFamily,
//                           color: Theme.of(context).colorScheme.secondary,
//                         ),
//                       ).animate().fadeIn(delay: 300.ms),
//                     ],
//                   ),
//                 ),
//               )
//             else
//               SliverList(
//                 delegate: SliverChildBuilderDelegate(
//                   (context, index) {
//                     final client = _filteredClients[index];
//                     return _buildClientCard(client, index);
//                   },
//                   childCount: _filteredClients.length,
//                 ),
//               ),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () async {
//           final result = await Navigator.pushNamed(context, '/add_client');
//           if (result != null) {
//             await _loadClients();
//           }
//         },
//         backgroundColor: Theme.of(context).colorScheme.primary,
//         child: const Icon(Icons.add).animate().rotate(duration: 500.ms),
//       ),
//     );
//   }

//   Widget _buildSearchBar() {
//     return Container(
//       decoration: BoxDecoration(
//         color: Theme.of(context).inputDecorationTheme.fillColor,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: TextField(
//         controller: _searchController,
//         decoration: InputDecoration(
//           hintText: 'Rechercher un client...',
//           hintStyle: TextStyle(
//             color: Theme.of(context).colorScheme.secondary,
//             fontFamily: GoogleFonts.poppins().fontFamily,
//           ),
//           prefixIcon: Icon(
//             Icons.search_rounded,
//             color: Theme.of(context).colorScheme.secondary,
//             size: 24,
//           ),
//           border: InputBorder.none,
//           contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//         ),
//         style: TextStyle(
//           color: Theme.of(context).colorScheme.onBackground,
//           fontSize: 16,
//           fontFamily: GoogleFonts.poppins().fontFamily,
//         ),
//       ),
//     ).animate().slideX(delay: 200.ms, duration: 600.ms);
//   }

//   Widget _buildFilters() {
//     return SizedBox(
//       height: 40,
//       child: ListView.builder(
//         scrollDirection: Axis.horizontal,
//         itemCount: _filters.length,
//         itemBuilder: (context, index) {
//           final filter = _filters[index];
//           final isSelected = _selectedFilter == filter;
//           return Padding(
//             padding: const EdgeInsets.only(right: 12),
//             child: FilterChip(
//               label: Text(
//                 filter,
//                 style: TextStyle(
//                   color: isSelected ? Colors.white : Theme.of(context).colorScheme.onBackground,
//                   fontWeight: FontWeight.w600,
//                   fontFamily: GoogleFonts.poppins().fontFamily,
//                 ),
//               ),
//               selected: isSelected,
//               onSelected: (selected) {
//                 if (selected) {
//                   setState(() {
//                     _selectedFilter = filter;
//                   });
//                 }
//               },
//               backgroundColor: Theme.of(context).inputDecorationTheme.fillColor,
//               selectedColor: Theme.of(context).colorScheme.primary,
//               elevation: isSelected ? 4 : 0,
//               shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
//             ).animate().scale(delay: (100 * index).ms),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildStatsCards() {
//     final totalClients = _clients.length;
//     final activeClients = _clients.where((c) => c.status == 'active').length;
//     final totalRevenue = _clients.fold<double>(0, (sum, client) => sum + client.totalSpent);

//     return Row(
//       children: [
//         Expanded(
//           child: _buildStatCard(
//             'Total Clients',
//             totalClients.toString(),
//             Icons.people_rounded,
//             const Color(0xFF10B981),
//           ).animate().slideY(delay: 300.ms),
//         ),
//         const SizedBox(width: 16),
//         Expanded(
//           child: _buildStatCard(
//             'Clients Actifs',
//             activeClients.toString(),
//             Icons.trending_up_rounded,
//             Theme.of(context).colorScheme.primary,
//           ).animate().slideY(delay: 400.ms),
//         ),
//         const SizedBox(width: 16),
//         Expanded(
//           child: _buildStatCard(
//             'Chiffre d\'Affaires',
//             formatAmount(totalRevenue),
//             Icons.money_rounded,
//             const Color(0xFFF59E0B),
//           ).animate().slideY(delay: 500.ms),
//         ),
//       ],
//     );
//   }

//   Widget _buildStatCard(String title, String value, IconData icon, Color color) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Theme.of(context).cardColor,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: color.withOpacity(0.1),
//             blurRadius: 20,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(icon, color: color, size: 24),
//           const SizedBox(height: 8),
//           Text(
//             value,
//             style: TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//               color: Theme.of(context).colorScheme.onBackground,
//               fontFamily: GoogleFonts.poppins().fontFamily,
//             ),
//           ),
//           Text(
//             title,
//             style: TextStyle(
//               fontSize: 12,
//               color: Theme.of(context).colorScheme.secondary,
//               fontWeight: FontWeight.w500,
//               fontFamily: GoogleFonts.poppins().fontFamily,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildClientCard(Client client, int index) {
//     Color statusColor = client.status == 'active'
//         ? const Color(0xFF10B981)
//         : client.status == 'inactive'
//             ? const Color(0xFFEF4444)
//             : const Color(0xFFF59E0B);

//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
//       child: Card(
//         elevation: 2,
//         shadowColor: Colors.black.withOpacity(0.1),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         child: InkWell(
//           borderRadius: BorderRadius.circular(16),
//           onTap: () => _showClientDetails(client),
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Row(
//               children: [
//                 Container(
//                   width: 60,
//                   height: 60,
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(16),
//                     gradient: LinearGradient(
//                       colors: [statusColor.withOpacity(0.1), statusColor.withOpacity(0.05)],
//                     ),
//                   ),
//                   child: ClipRRect(
//                     borderRadius: BorderRadius.circular(16),
//                     child: client.photo.isNotEmpty && File(client.photo).existsSync()
//                         ? Image.file(
//                             File(client.photo),
//                             fit: BoxFit.cover,
//                             errorBuilder: (context, error, stackTrace) => _buildFallbackAvatar(statusColor),
//                           )
//                         : _buildFallbackAvatar(statusColor),
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           Expanded(
//                             child: Text(
//                               client.name,
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.bold,
//                                 color: Theme.of(context).colorScheme.onBackground,
//                                 fontFamily: GoogleFonts.poppins().fontFamily,
//                               ),
//                             ),
//                           ),
//                           Container(
//                             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                             decoration: BoxDecoration(
//                               color: statusColor.withOpacity(0.1),
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             child: Text(
//                               client.status == 'active'
//                                   ? 'Actif'
//                                   : client.status == 'inactive'
//                                       ? 'Inactif'
//                                       : 'En attente',
//                               style: TextStyle(
//                                 color: statusColor,
//                                 fontSize: 12,
//                                 fontWeight: FontWeight.w600,
//                                 fontFamily: GoogleFonts.poppins().fontFamily,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         client.address,
//                         style: TextStyle(
//                           fontSize: 14,
//                           color: Theme.of(context).colorScheme.secondary,
//                           fontFamily: GoogleFonts.poppins().fontFamily,
//                         ),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       const SizedBox(height: 8),
//                       Row(
//                         children: [
//                           Icon(
//                             Icons.phone_rounded,
//                             size: 16,
//                             color: Theme.of(context).colorScheme.secondary.withOpacity(0.7),
//                           ),
//                           const SizedBox(width: 4),
//                           Text(
//                             client.phone,
//                             style: TextStyle(
//                               fontSize: 13,
//                               color: Theme.of(context).colorScheme.secondary,
//                               fontFamily: GoogleFonts.poppins().fontFamily,
//                             ),
//                           ),
//                           const Spacer(),
//                           Text(
//                             formatAmount(client.totalSpent),
//                             style: TextStyle(
//                               fontSize: 14,
//                               fontWeight: FontWeight.bold,
//                               color: const Color(0xFF10B981),
//                               fontFamily: GoogleFonts.poppins().fontFamily,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//                 IconButton(
//                   icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
//                   onPressed: () async {
//                     final result = await Navigator.pushNamed(context, '/edit_client', arguments: client);
//                     if (result != null) {
//                       await _loadClients();
//                     }
//                   },
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ).animate().slideX(delay: (100 * index).ms, duration: 600.ms),
//     );
//   }

//   Widget _buildFallbackAvatar(Color statusColor) {
//     return Container(
//       color: statusColor.withOpacity(0.1),
//       child: Icon(
//         Icons.person_rounded,
//         color: statusColor,
//         size: 30,
//       ),
//     );
//   }

//   void _showClientDetails(Client client) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) => DraggableScrollableSheet(
//         initialChildSize: 0.7,
//         maxChildSize: 0.95,
//         minChildSize: 0.5,
//         builder: (context, scrollController) => Container(
//           decoration: BoxDecoration(
//             color: Theme.of(context).colorScheme.background,
//             borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
//           ),
//           child: Padding(
//             padding: const EdgeInsets.all(24),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Center(
//                   child: Container(
//                     width: 40,
//                     height: 4,
//                     decoration: BoxDecoration(
//                       color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
//                       borderRadius: BorderRadius.circular(2),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 24),
//                 Row(
//                   children: [
//                     CircleAvatar(
//                       radius: 30,
//                       backgroundImage: client.photo.isNotEmpty && File(client.photo).existsSync()
//                           ? FileImage(File(client.photo))
//                           : null,
//                       child: client.photo.isEmpty || !File(client.photo).existsSync()
//                           ? Icon(Icons.person_rounded, color: Theme.of(context).colorScheme.primary)
//                           : null,
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             client.name,
//                             style: TextStyle(
//                               fontSize: 24,
//                               fontWeight: FontWeight.bold,
//                               color: Theme.of(context).colorScheme.onBackground,
//                               fontFamily: GoogleFonts.poppins().fontFamily,
//                             ),
//                           ),
//                           Text(
//                             client.email,
//                             style: TextStyle(
//                               fontSize: 16,
//                               color: Theme.of(context).colorScheme.secondary,
//                               fontFamily: GoogleFonts.poppins().fontFamily,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     IconButton(
//                       icon: Icon(Icons.delete, color: Colors.red),
//                       onPressed: () async {
//                         final confirm = await showDialog<bool>(
//                           context: context,
//                           builder: (context) => AlertDialog(
//                             title: const Text('Supprimer le client'),
//                             content: Text('Voulez-vous vraiment supprimer ${client.name} ?'),
//                             actions: [
//                               TextButton(
//                                 onPressed: () => Navigator.pop(context, false),
//                                 child: const Text('Annuler'),
//                               ),
//                               TextButton(
//                                 onPressed: () => Navigator.pop(context, true),
//                                 child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
//                               ),
//                             ],
//                           ),
//                         );
//                         if (confirm == true) {
//                           await DatabaseHelper().deleteClient(client.id);
//                           Navigator.pop(context);
//                           await _loadClients();
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             const SnackBar(content: Text('Client supprimé avec succès')),
//                           );
//                         }
//                       },
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 24),
//                 Expanded(
//                   child: ListView(
//                     controller: scrollController,
//                     children: [
//                       _buildDetailRow('Téléphone', client.phone, Icons.phone_rounded),
//                       _buildDetailRow('Adresse', client.address, Icons.location_on_rounded),
//                       _buildDetailRow('Date de livraison', client.deliveryDate, Icons.event_rounded),
//                       _buildDetailRow('Services', client.services.join(', '), Icons.design_services_rounded),
//                       _buildDetailRow('Total dépensé', formatAmount(client.totalSpent), Icons.money_rounded),
//                       _buildDetailRow('Nombre de commandes', client.totalOrders.toString(), Icons.shopping_bag_rounded),
//                       _buildDetailRow('Type de client', client.clientType, Icons.person),
//                       _buildDetailRow('Genre', client.gender, Icons.wc),
//                       _buildDetailRow('Profession', client.profession, Icons.work),
//                       _buildDetailRow('Date de naissance', client.birthdate, Icons.cake),
//                       _buildDetailRow('Notes', client.notes, Icons.note),
//                       const SizedBox(height: 16),
//                       Text(
//                         'Mensurations',
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                           fontFamily: GoogleFonts.poppins().fontFamily,
//                         ),
//                       ),
//                       ...client.measurements.entries
//                           .where((entry) => entry.value.isNotEmpty)
//                           .map((entry) => _buildDetailRow(
//                                 _measurementTranslations[entry.key] ?? entry.key,
//                                 entry.value,
//                                 Icons.straighten,
//                               )),
//                       const SizedBox(height: 16),
//                       ElevatedButton.icon(
//                         onPressed: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) => OrdersPage(clientId: client.id),
//                             ),
//                           );
//                         },
//                         icon: const Icon(Icons.shopping_bag),
//                         label: const Text('Voir les commandes'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Theme.of(context).colorScheme.primary,
//                           foregroundColor: Colors.white,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildDetailRow(String label, String value, IconData icon) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 12),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   label,
//                   style: TextStyle(
//                     fontSize: 14,
//                     color: Theme.of(context).colorScheme.secondary,
//                     fontWeight: FontWeight.w500,
//                     fontFamily: GoogleFonts.poppins().fontFamily,
//                   ),
//                 ),
//                 const SizedBox(height: 2),
//                 Text(
//                   value.isEmpty ? 'Non spécifié' : value,
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                     color: Theme.of(context).colorScheme.onBackground,
//                     fontFamily: GoogleFonts.poppins().fontFamily,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }
// }

// extension StringExtension on String {
//   String capitalize() {
//     if (isEmpty) return this;
//     return "${this[0].toUpperCase()}${substring(1)}";
//   }
// }






import 'package:actis/helpers/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'add_client_page.dart';
import 'edit_client_page.dart';
import 'orders_page.dart';
import 'dart:io';

class Client {
  final int id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String photo;
  final String deliveryDate;
  final String createdAt;
  final String status; // Calculé dynamiquement à partir des commandes
  final List<String> services;
  final double totalSpent;
  final int totalOrders;
  final Map<String, dynamic> measurements;
  final String notes;
  final String clientType;
  final String gender;
  final String profession;
  final String birthdate;

  Client({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.photo,
    required this.deliveryDate,
    required this.createdAt,
    required this.status,
    required this.services,
    required this.totalSpent,
    required this.totalOrders,
    required this.measurements,
    required this.notes,
    required this.clientType,
    required this.gender,
    required this.profession,
    required this.birthdate,
  });

  factory Client.fromMap(Map<String, dynamic> map) {
    final orders = map['orders'] as List<Map<String, dynamic>>? ?? [];
    final services = (map['services'] as String? ?? '').split(',').where((s) => s.isNotEmpty).toList();
    final measurements = {
      'height': map['height'] ?? '',
      'weight': map['weight'] ?? '',
      'neck': map['neck'] ?? '',
      'chest': map['chest'] ?? '',
      'waist': map['waist'] ?? '',
      'hips': map['hips'] ?? '',
      'shoulder': map['shoulder'] ?? '',
      'armLength': map['armLength'] ?? '',
      'bustLength': map['bustLength'] ?? '',
      'totalLength': map['totalLength'] ?? '',
      'armCircumference': map['armCircumference'] ?? '',
      'wrist': map['wrist'] ?? '',
      'inseam': map['inseam'] ?? '',
      'pantLength': map['pantLength'] ?? '',
      'thigh': map['thigh'] ?? '',
      'knee': map['knee'] ?? '',
      'ankle': map['ankle'] ?? '',
      'buttocks': map['buttocks'] ?? '',
      'underBust': map['underBust'] ?? '',
      'bustDistance': map['bustDistance'] ?? '',
      'bustHeight': map['bustHeight'] ?? '',
      'skirtLength': map['skirtLength'] ?? '',
      'dressLength': map['dressLength'] ?? '',
      'calf': map['calf'] ?? '',
      'heelHeight': map['heelHeight'] ?? '',
      'backBustLength': map['backBustLength'] ?? '',
      'headCircumference': map['headCircumference'] ?? '',
    };

    // Calculer le statut en fonction des commandes
    String status;
    if (orders.isEmpty) {
      status = 'no_orders';
    } else if (orders.any((order) => order['status'] == 'pending')) {
      status = 'pending';
    } else if (orders.every((order) => order['status'] == 'completed')) {
      status = 'completed';
    } else if (orders.every((order) => order['status'] == 'cancelled')) {
      status = 'cancelled';
    } else {
      status = 'pending'; // Par défaut si mixte
    }

    return Client(
      id: int.parse(map['id']?.toString() ?? '0'),
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      address: map['address'] ?? '',
      photo: map['photo'] ?? '',
      deliveryDate: map['deliveryDate'] ?? '',
      createdAt: map['createdAt'] ?? DateTime.now().toIso8601String(),
      status: status,
      services: services.isEmpty ? ['Retouches'] : services,
      totalSpent: orders.fold(0.0, (sum, order) => sum + (order['amount'] as double? ?? 0.0)),
      totalOrders: orders.length,
      measurements: measurements,
      notes: map['notes'] ?? '',
      clientType: map['clientType'] ?? 'Adulte',
      gender: map['gender'] ?? 'Homme',
      profession: map['profession'] ?? '',
      birthdate: map['birthdate'] ?? '',
    );
  }
}

String formatAmount(double amount) {
  if (amount >= 1000000) {
    return '${(amount / 1000000).toStringAsFixed(1)}M FCFA';
  } else if (amount >= 1000) {
    return '${(amount / 1000).toStringAsFixed(1)}K FCFA';
  }
  return '${amount.toStringAsFixed(0)} FCFA';
}

class ClientsPage extends StatefulWidget {
  const ClientsPage({super.key});

  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'Tous';
  final List<String> _filters = ['Tous', 'En attente', 'Complété', 'Sans commandes'];
  List<Client> _clients = [];

  final Map<String, String> _measurementTranslations = {
    'height': 'Hauteur',
    'weight': 'Poids',
    'neck': 'Cou',
    'chest': 'Poitrine',
    'waist': 'Taille',
    'hips': 'Hanches',
    'shoulder': 'Épaule',
    'armLength': 'Longueur de bras',
    'bustLength': 'Longueur de buste',
    'totalLength': 'Longueur totale',
    'armCircumference': 'Circonférence de bras',
    'wrist': 'Poignet',
    'inseam': 'Entrejambe',
    'pantLength': 'Longueur de pantalon',
    'thigh': 'Cuisse',
    'knee': 'Genou',
    'ankle': 'Cheville',
    'buttocks': 'Fesses',
    'underBust': 'Sous-poitrine',
    'bustDistance': 'Distance de buste',
    'bustHeight': 'Hauteur de buste',
    'skirtLength': 'Longueur de jupe',
    'dressLength': 'Longueur de robe',
    'calf': 'Mollet',
    'heelHeight': 'Hauteur de talon',
    'backBustLength': 'Longueur arrière buste',
    'headCircumference': 'Circonférence de tête',
  };

  @override
  void initState() {
    super.initState();
    _loadClients();
    _searchController.addListener(() => setState(() {}));
  }

  Future<void> _loadClients() async {
    final clientMaps = await DatabaseHelper().getClients();
    final clients = <Client>[];
    for (var map in clientMaps) {
      final orders = await DatabaseHelper().getOrdersForClient(int.parse(map['id']?.toString() ?? '0'));
      final mutableMap = Map<String, dynamic>.from(map);
      mutableMap['orders'] = orders;
      clients.add(Client.fromMap(mutableMap));
    }
    setState(() {
      _clients = clients;
    });
  }

  List<Client> get _filteredClients {
    List<Client> filtered = _clients;
    if (_selectedFilter != 'Tous') {
      String status = _selectedFilter == 'En attente'
          ? 'pending'
          : _selectedFilter == 'Complété'
              ? 'completed'
              : _selectedFilter == 'Annulé'
                  ? 'cancelled'
                  : 'no_orders';
      filtered = filtered.where((client) => client.status == status).toList();
    }
    if (_searchController.text.isNotEmpty) {
      filtered = filtered.where((client) =>
          client.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          client.email.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          client.phone.contains(_searchController.text)).toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Clients',
          style: TextStyle(
            fontFamily: GoogleFonts.poppins().fontFamily,
            // fontSize: 24,
            // fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
   
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.background,
              Theme.of(context).colorScheme.background.withOpacity(0.8),
            ],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildSearchBar(),
                    const SizedBox(height: 16),
                    _buildFilters(),
                    const SizedBox(height: 20),
                    _buildStatsCards(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            if (_clients.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people,
                        size: 64,
                        color: Theme.of(context).colorScheme.secondary,
                      ).animate().scale(duration: 500.ms),
                      const SizedBox(height: 16),
                      Text(
                        'Liste des Clients',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: GoogleFonts.poppins().fontFamily,
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ).animate().fadeIn(delay: 200.ms),
                      const SizedBox(height: 8),
                      Text(
                        'Aucun client ajouté pour le moment',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: GoogleFonts.poppins().fontFamily,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ).animate().fadeIn(delay: 300.ms),
                    ],
                  ),
                ),
              )
            else if (_filteredClients.isEmpty && _searchController.text.isNotEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.search_off,
                        size: 64,
                        color: Color(0xFF00DDEB),
                      ).animate().scale(duration: 500.ms),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun client trouvé',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: GoogleFonts.poppins().fontFamily,
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ).animate().fadeIn(delay: 200.ms),
                      const SizedBox(height: 8),
                      Text(
                        'Essayez un autre terme de recherche',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: GoogleFonts.poppins().fontFamily,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ).animate().fadeIn(delay: 300.ms),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final client = _filteredClients[index];
                    return _buildClientCard(client, index);
                  },
                  childCount: _filteredClients.length,
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/add_client');
          if (result != null) {
            await _loadClients();
          }
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add).animate().rotate(duration: 500.ms),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).inputDecorationTheme.fillColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher un client...',
          hintStyle: TextStyle(
            // color: Theme.of(context).colorScheme.secondary,
            fontFamily: GoogleFonts.poppins().fontFamily,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            // color: Theme.of(context).colorScheme.secondary,
            size: 24,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        style: TextStyle(
          color: Theme.of(context).colorScheme.onBackground,
          fontSize: 16,
          fontFamily: GoogleFonts.poppins().fontFamily,
        ),
      ),
    ).animate().slideX(delay: 200.ms, duration: 600.ms);
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilterChip(
              label: Text(
                filter,
                style: TextStyle(
                  color: isSelected ? Colors.white : Theme.of(context).colorScheme.onBackground,
                  fontWeight: FontWeight.w600,
                  fontFamily: GoogleFonts.poppins().fontFamily,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                }
              },
              backgroundColor: Theme.of(context).inputDecorationTheme.fillColor,
              selectedColor: Theme.of(context).colorScheme.primary,
              elevation: isSelected ? 4 : 0,
              shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ).animate().scale(delay: (100 * index).ms),
          );
        },
      ),
    );
  }

  Widget _buildStatsCards() {
    final totalClients = _clients.length;
    final pendingClients = _clients.where((c) => c.status == 'pending').length;
    final totalRevenue = _clients.fold<double>(0, (sum, client) => sum + client.totalSpent);

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Clients',
            totalClients.toString(),
            Icons.people_rounded,
            const Color(0xFF10B981),
          ).animate().slideY(delay: 300.ms),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Clients en attente',
            pendingClients.toString(),
            Icons.trending_up_rounded,
            Theme.of(context).colorScheme.primary,
          ).animate().slideY(delay: 400.ms),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Chiffre d\'Affaires',
            formatAmount(totalRevenue),
            Icons.money_rounded,
            const Color(0xFFF59E0B),
          ).animate().slideY(delay: 500.ms),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onBackground,
              fontFamily: GoogleFonts.poppins().fontFamily,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.w500,
              fontFamily: GoogleFonts.poppins().fontFamily,
            ),
          ),
        ],
      ),
    );
  }


// Design 1: Carte avec en-tête coloré et informations organisées
Widget _buildClientCard(Client client, int index) {
  Color statusColor;
  String statusText;
  switch (client.status) {
    case 'pending':
      statusColor = const Color(0xFFF59E0B);
      statusText = 'En attente';
      break;
    case 'completed':
      statusColor = const Color(0xFF10B981);
      statusText = 'Complété';
      break;
    case 'cancelled':
      statusColor = const Color(0xFFEF4444);
      statusText = 'Annulé';
      break;
    case 'no_orders':
      statusColor = Theme.of(context).colorScheme.secondary;
      statusText = 'Sans commandes';
      break;
    default:
      statusColor = Theme.of(context).colorScheme.secondary;
      statusText = 'Inconnu';
  }

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    child: Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showClientDetails(client),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Disposition pour les petits écrans (largeur < 360px)
              if (constraints.maxWidth < 360) {
                return _buildCompactLayout(client, statusColor, statusText);
              }
              // Disposition standard pour les écrans moyens et grands
              else {
                return _buildStandardLayout(client, statusColor, statusText);
              }
            },
          ),
        ),
      ),
    ).animate().slideX(delay: (100 * index).ms, duration: 600.ms),
  );
}


  // Design 2: Carte minimaliste avec séparateurs
// Widget _buildClientCard(Client client, int index) {
//   Color statusColor;
//   String statusText;
//   switch (client.status) {
//     case 'pending':
//       statusColor = const Color(0xFFF59E0B);
//       statusText = 'En attente';
//       break;
//     case 'completed':
//       statusColor = const Color(0xFF10B981);
//       statusText = 'Complété';
//       break;
//     case 'cancelled':
//       statusColor = const Color(0xFFEF4444);
//       statusText = 'Annulé';
//       break;
//     case 'no_orders':
//       statusColor = Theme.of(context).colorScheme.secondary;
//       statusText = 'Sans commandes';
//       break;
//     default:
//       statusColor = Theme.of(context).colorScheme.secondary;
//       statusText = 'Inconnu';
//   }

//   return Padding(
//     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
//     child: Container(
//       decoration: BoxDecoration(
//         color: Theme.of(context).cardColor,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.04),
//             blurRadius: 10,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: InkWell(
//         borderRadius: BorderRadius.circular(16),
//         onTap: () => _showClientDetails(client),
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             children: [
//               // En-tête avec nom et actions
//               Row(
//                 children: [
//                   CircleAvatar(
//                     radius: 24,
//                     backgroundColor: statusColor.withOpacity(0.1),
//                     backgroundImage: client.photo.isNotEmpty && File(client.photo).existsSync()
//                         ? FileImage(File(client.photo))
//                         : null,
//                     child: client.photo.isEmpty || !File(client.photo).existsSync()
//                         ? Icon(Icons.person, color: statusColor, size: 24)
//                         : null,
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           client.name,
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w600,
//                             color: Theme.of(context).colorScheme.onBackground,
//                             fontFamily: GoogleFonts.poppins().fontFamily,
//                           ),
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                         const SizedBox(height: 2),
//                         Row(
//                           children: [
//                             Container(
//                               width: 8,
//                               height: 8,
//                               decoration: BoxDecoration(
//                                 color: statusColor,
//                                 shape: BoxShape.circle,
//                               ),
//                             ),
//                             const SizedBox(width: 6),
//                             Text(
//                               statusText,
//                               style: TextStyle(
//                                 fontSize: 12,
//                                 color: statusColor,
//                                 fontWeight: FontWeight.w500,
//                                 fontFamily: GoogleFonts.poppins().fontFamily,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                   PopupMenuButton<String>(
//                     icon: Icon(Icons.more_vert, color: Theme.of(context).colorScheme.secondary),
//                     onSelected: (value) async {
//                       if (value == 'edit') {
//                         final result = await Navigator.pushNamed(context, '/edit_client', arguments: client);
//                         if (result != null) await _loadClients();
//                       } else if (value == 'orders') {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => OrdersPage(clientId: client.id, clientName: client.name),
//                           ),
//                         );
//                       }
//                     },
//                     itemBuilder: (context) => [
//                       const PopupMenuItem(value: 'edit', child: Text('Modifier')),
//                       const PopupMenuItem(value: 'orders', child: Text('Commandes')),
//                     ],
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//               Divider(color: Theme.of(context).dividerColor.withOpacity(0.2)),
//               const SizedBox(height: 12),
//               // Informations détaillées
//               Row(
//                 children: [
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         _buildInfoRow(Icons.phone_outlined, client.phone),
//                         const SizedBox(height: 8),
//                         _buildInfoRow(Icons.location_on_outlined, client.address),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(width: 16),
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.end,
//                     children: [
//                       Text(
//                         formatAmount(client.totalSpent),
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                           color: const Color(0xFF10B981),
//                           fontFamily: GoogleFonts.poppins().fontFamily,
//                         ),
//                       ),
//                       Text(
//                         '${client.totalOrders} commandes',
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: Theme.of(context).colorScheme.secondary,
//                           fontFamily: GoogleFonts.poppins().fontFamily,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     ).animate().fadeIn(delay: (100 * index).ms, duration: 600.ms),
//   );
// }


// Design 3: Carte compacte avec layout horizontal optimisé
//   Widget _buildClientCard(Client client, int index) {
//   Color statusColor;
//   String statusText;
//   switch (client.status) {
//     case 'pending':
//       statusColor = const Color(0xFFF59E0B);
//       statusText = 'En attente';
//       break;
//     case 'completed':
//       statusColor = const Color(0xFF10B981);
//       statusText = 'Complété';
//       break;
//     case 'cancelled':
//       statusColor = const Color(0xFFEF4444);
//       statusText = 'Annulé';
//       break;
//     case 'no_orders':
//       statusColor = Theme.of(context).colorScheme.secondary;
//       statusText = 'Sans commandes';
//       break;
//     default:
//       statusColor = Theme.of(context).colorScheme.secondary;
//       statusText = 'Inconnu';
//   }

//   return Padding(
//     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//     child: Container(
//       margin: const EdgeInsets.symmetric(vertical: 4),
//       decoration: BoxDecoration(
//         color: Theme.of(context).cardColor,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: statusColor.withOpacity(0.2), width: 1),
//         boxShadow: [
//           BoxShadow(
//             color: statusColor.withOpacity(0.08),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: InkWell(
//         borderRadius: BorderRadius.circular(12),
//         onTap: () => _showClientDetails(client),
//         child: Padding(
//           padding: const EdgeInsets.all(12),
//           child: Row(
//             children: [
//               // Avatar avec indicateur de statut
//               Stack(
//                 children: [
//                   Container(
//                     width: 45,
//                     height: 45,
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(12),
//                       color: statusColor.withOpacity(0.1),
//                     ),
//                     child: ClipRRect(
//                       borderRadius: BorderRadius.circular(12),
//                       child: client.photo.isNotEmpty && File(client.photo).existsSync()
//                           ? Image.file(File(client.photo), fit: BoxFit.cover)
//                           : Icon(Icons.person, color: statusColor, size: 24),
//                     ),
//                   ),
//                   Positioned(
//                     right: -2,
//                     top: -2,
//                     child: Container(
//                       width: 12,
//                       height: 12,
//                       decoration: BoxDecoration(
//                         color: statusColor,
//                         shape: BoxShape.circle,
//                         border: Border.all(color: Theme.of(context).cardColor, width: 1),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(width: 12),
//               // Informations principales
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       client.name,
//                       style: TextStyle(
//                         fontSize: 15,
//                         fontWeight: FontWeight.w600,
//                         color: Theme.of(context).colorScheme.onBackground,
//                         fontFamily: GoogleFonts.poppins().fontFamily,
//                       ),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     const SizedBox(height: 2),
//                     Text(
//                       client.phone,
//                       style: TextStyle(
//                         fontSize: 13,
//                         color: Theme.of(context).colorScheme.secondary,
//                         fontFamily: GoogleFonts.poppins().fontFamily,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               // Statut et montant
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.end,
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                     decoration: BoxDecoration(
//                       color: statusColor.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Text(
//                       statusText,
//                       style: TextStyle(
//                         fontSize: 10,
//                         fontWeight: FontWeight.w600,
//                         color: statusColor,
//                         fontFamily: GoogleFonts.poppins().fontFamily,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     formatAmount(client.totalSpent),
//                     style: TextStyle(
//                       fontSize: 13,
//                       fontWeight: FontWeight.bold,
//                       color: const Color(0xFF10B981),
//                       fontFamily: GoogleFonts.poppins().fontFamily,
//                     ),
//                   ),
//                 ],
//               ),
//               // Bouton d'action
//               const SizedBox(width: 8),
//               IconButton(
//                 onPressed: () async {
//                   final result = await Navigator.pushNamed(context, '/edit_client', arguments: client);
//                   if (result != null) await _loadClients();
//                 },
//                 icon: Icon(Icons.arrow_forward_ios, size: 16, color: Theme.of(context).colorScheme.secondary),
//                 constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
//               ),
//             ],
//           ),
//         ),
//       ),
//     ).animate().slideX(delay: (50 * index).ms, duration: 400.ms),
//   );
// }

// Widgets utilitaires
Widget _buildInfoChip(IconData icon, String text, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.w500,
              fontFamily: GoogleFonts.poppins().fontFamily,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

Widget _buildInfoRow(IconData icon, String text) {
  return Row(
    children: [
      Icon(icon, size: 16, color: Theme.of(context).colorScheme.secondary),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.secondary,
            fontFamily: GoogleFonts.poppins().fontFamily,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}
// Disposition compacte pour les petits écrans
Widget _buildCompactLayout(Client client, Color statusColor, String statusText) {
  return Column(
    children: [
      // Première ligne: Avatar, Nom et Status
      Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [statusColor.withOpacity(0.1), statusColor.withOpacity(0.05)],
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: client.photo.isNotEmpty && File(client.photo).existsSync()
                  ? Image.file(
                      File(client.photo),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildFallbackAvatar(statusColor),
                    )
                  : _buildFallbackAvatar(statusColor),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onBackground,
                    fontFamily: GoogleFonts.poppins().fontFamily,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFamily: GoogleFonts.poppins().fontFamily,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.primary, size: 20),
            onPressed: () async {
              final result = await Navigator.pushNamed(context, '/edit_client', arguments: client);
              if (result != null) {
                await _loadClients();
              }
            },
          ),
        ],
      ),
      const SizedBox(height: 12),
      // Deuxième ligne: Adresse
      if (client.address.isNotEmpty)
        Row(
          children: [
            Icon(
              Icons.location_on_rounded,
              size: 14,
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.7),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                client.address,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.secondary,
                  fontFamily: GoogleFonts.poppins().fontFamily,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      if (client.address.isNotEmpty) const SizedBox(height: 8),
      // Troisième ligne: Téléphone et Montant
      Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(
                  Icons.phone_rounded,
                  size: 14,
                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.7),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    client.phone,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.secondary,
                      fontFamily: GoogleFonts.poppins().fontFamily,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              formatAmount(client.totalSpent),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF10B981),
                fontFamily: GoogleFonts.poppins().fontFamily,
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

// Disposition standard pour les écrans moyens et grands
Widget _buildStandardLayout(Client client, Color statusColor, String statusText) {
  return Row(
    children: [
      Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [statusColor.withOpacity(0.1), statusColor.withOpacity(0.05)],
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: client.photo.isNotEmpty && File(client.photo).existsSync()
              ? Image.file(
                  File(client.photo),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _buildFallbackAvatar(statusColor),
                )
              : _buildFallbackAvatar(statusColor),
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Première ligne: Nom et Status
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    client.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onBackground,
                      fontFamily: GoogleFonts.poppins().fontFamily,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        fontFamily: GoogleFonts.poppins().fontFamily,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Deuxième ligne: Adresse
            if (client.address.isNotEmpty)
              Text(
                client.address,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.secondary,
                  fontFamily: GoogleFonts.poppins().fontFamily,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (client.address.isNotEmpty) const SizedBox(height: 8),
            // Troisième ligne: Téléphone et Montant
            Row(
              children: [
                Icon(
                  Icons.phone_rounded,
                  size: 16,
                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.7),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    client.phone,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.secondary,
                      fontFamily: GoogleFonts.poppins().fontFamily,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    formatAmount(client.totalSpent),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF10B981),
                      fontFamily: GoogleFonts.poppins().fontFamily,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(width: 8),
      IconButton(
        icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/edit_client', arguments: client);
          if (result != null) {
            await _loadClients();
          }
        },
      ),
    ],
  );
}

Widget _buildFallbackAvatar(Color statusColor) {
  return Container(
    color: statusColor.withOpacity(0.1),
    child: Icon(
      Icons.person_rounded,
      color: statusColor,
      size: 30,
    ),
  );
}
 

  void _showClientDetails(Client client) {
    String statusText;
    switch (client.status) {
      case 'pending':
        statusText = 'En attente';
        break;
      case 'completed':
        statusText = 'Complété';
        break;
      case 'cancelled':
        statusText = 'Annulé';
        break;
      case 'no_orders':
        statusText = 'Sans commandes';
        break;
      default:
        statusText = 'Inconnu';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: client.photo.isNotEmpty && File(client.photo).existsSync()
                          ? FileImage(File(client.photo))
                          : null,
                      child: client.photo.isEmpty || !File(client.photo).existsSync()
                          ? Icon(Icons.person_rounded, color: Theme.of(context).colorScheme.primary)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            client.name,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onBackground,
                              fontFamily: GoogleFonts.poppins().fontFamily,
                            ),
                          ),
                          Text(
                            client.email,
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.secondary,
                              fontFamily: GoogleFonts.poppins().fontFamily,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(
                              'Supprimer le client',
                              style: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
                            ),
                            content: Text(
                              'Voulez-vous vraiment supprimer ${client.name} ?',
                              style: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(
                                  'Annuler',
                                  style: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(
                                  'Supprimer',
                                  style: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily, color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await DatabaseHelper().deleteClient(client.id);
                          Navigator.pop(context);
                          await _loadClients();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Client supprimé avec succès',
                                style: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      _buildDetailRow('Téléphone', client.phone, Icons.phone_rounded),
                      _buildDetailRow('Adresse', client.address, Icons.location_on_rounded),
                      _buildDetailRow('Date de livraison', client.deliveryDate, Icons.event_rounded),
                      _buildDetailRow('Services', client.services.join(', '), Icons.design_services_rounded),
                      _buildDetailRow('Total dépensé', formatAmount(client.totalSpent), Icons.money_rounded),
                      _buildDetailRow('Nombre de commandes', client.totalOrders.toString(), Icons.shopping_bag_rounded),
                      _buildDetailRow('Statut', statusText, Icons.info),
                      _buildDetailRow('Type de client', client.clientType, Icons.person),
                      _buildDetailRow('Genre', client.gender, Icons.wc),
                      _buildDetailRow('Profession', client.profession, Icons.work),
                      _buildDetailRow('Date de naissance', client.birthdate, Icons.cake),
                      _buildDetailRow('Notes', client.notes, Icons.note),
                      const SizedBox(height: 16),
                      Text(
                        'Mensurations',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: GoogleFonts.poppins().fontFamily,
                        ),
                      ),
                      ...client.measurements.entries
                          .where((entry) => entry.value.isNotEmpty)
                          .map((entry) => _buildDetailRow(
                                _measurementTranslations[entry.key] ?? entry.key,
                                entry.value,
                                Icons.straighten,
                              )),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrdersPage(clientId: client.id, clientName: client.name),
                            ),
                          );
                        },
                        icon: const Icon(Icons.shopping_bag),
                        label: Text(
                          'Voir les commandes',
                          style: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.w500,
                    fontFamily: GoogleFonts.poppins().fontFamily,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? 'Non spécifié' : value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onBackground,
                    fontFamily: GoogleFonts.poppins().fontFamily,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}