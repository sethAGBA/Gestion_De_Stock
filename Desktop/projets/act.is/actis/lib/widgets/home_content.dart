// // import 'package:flutter/material.dart';
// // import 'package:flutter_animate/flutter_animate.dart';
// // import 'menu_card.dart';

// // class HomeContent extends StatelessWidget {
// //   const HomeContent({super.key});

// //   @override
// //   Widget build(BuildContext context) {
// //     return SingleChildScrollView(
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           const SizedBox(height: 20),
// //           const MenuCard(
// //             icon: Icons.local_shipping,
// //             title: 'Commandes à Livrer',
// //             subtitle: 'Commandes en attente de livraison',
// //           ).animate().slideY(begin: 0.2, end: 0.0, delay: 200.ms),
// //           const MenuCard(
// //             icon: Icons.cake,
// //             title: 'Anniversaires à Venir',
// //             subtitle: 'Anniversaires des clients',
// //           ).animate().slideY(begin: 0.2, end: 0.0, delay: 300.ms),
// //           const SizedBox(height: 20),
// //         ],
// //       ),
// //     );
// //   }
// // }




// // import 'package:actis/pages/clients_page.dart';
// // import 'package:actis/pages/orders_page.dart';
// // import 'package:flutter/material.dart';
// // import 'package:flutter_animate/flutter_animate.dart';
// // import 'package:google_fonts/google_fonts.dart';
// // import 'package:actis/helpers/database_helper.dart';
// // import 'menu_card.dart';
// // import 'package:intl/intl.dart';

// // class HomeContent extends StatefulWidget {
// //   const HomeContent({super.key});

// //   @override
// //   State<HomeContent> createState() => _HomeContentState();
// // }

// // class _HomeContentState extends State<HomeContent> {
// //   List<Map<String, dynamic>> _upcomingOrders = [];
// //   List<Map<String, dynamic>> _upcomingBirthdays = [];

// //   @override
// //   void initState() {
// //     super.initState();
// //     _loadUpcomingData();
// //   }

// //   Future<void> _loadUpcomingData() async {
// //     await _loadUpcomingOrders();
// //     await _loadUpcomingBirthdays();
// //   }

// //   Future<void> _loadUpcomingOrders() async {
// //     final now = DateTime.now();
// //     final endDate = now.add(const Duration(days: 7)).toIso8601String().split('T')[0];
// //     final db = await DatabaseHelper().database;
// //     final orders = await db.rawQuery('''
// //       SELECT orders.*, clients.name AS clientName
// //       FROM orders
// //       LEFT JOIN clients ON orders.clientId = clients.id
// //       WHERE orders.deliveryDate >= ? AND orders.deliveryDate <= ? AND orders.status = 'pending'
// //       ORDER BY orders.deliveryDate ASC
// //       LIMIT 5
// //     ''', [now.toIso8601String().split('T')[0], endDate]);

// //     setState(() {
// //       _upcomingOrders = orders;
// //     });
// //   }

// //   Future<void> _loadUpcomingBirthdays() async {
// //     final now = DateTime.now();
// //     final clients = await DatabaseHelper().getClients();
// //     final upcomingBirthdays = <Map<String, dynamic>>[];

// //     for (var client in clients) {
// //       final birthdateStr = client['birthdate']?.toString();
// //       if (birthdateStr == null || birthdateStr.isEmpty) continue;

// //       try {
// //         final birthdate = DateTime.parse(birthdateStr);
// //         final currentYearBirthdate = DateTime(now.year, birthdate.month, birthdate.day);
// //         final nextYearBirthdate = DateTime(now.year + 1, birthdate.month, birthdate.day);

// //         final diffCurrent = currentYearBirthdate.difference(now).inDays;
// //         final diffNext = nextYearBirthdate.difference(now).inDays;

// //         // Anniversaires dans les 30 prochains jours
// //         if ((diffCurrent >= 0 && diffCurrent <= 30) || (diffNext >= 0 && diffNext <= 30)) {
// //           upcomingBirthdays.add({
// //             'id': client['id'],
// //             'name': client['name'],
// //             'birthdate': birthdateStr,
// //             'daysUntil': diffCurrent >= 0 && diffCurrent <= 30 ? diffCurrent : diffNext,
// //           });
// //         }
// //       } catch (e) {
// //         // Ignorer les dates mal formatées
// //         continue;
// //       }
// //     }

// //     // Trier par jours restants
// //     upcomingBirthdays.sort((a, b) => a['daysUntil'].compareTo(b['daysUntil']));
// //     setState(() {
// //       _upcomingBirthdays = upcomingBirthdays.take(5).toList();
// //     });
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return SingleChildScrollView(
// //       child: Padding(
// //         padding: const EdgeInsets.symmetric(horizontal: 16.0),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             const SizedBox(height: 20),
// //             _buildUpcomingOrdersSection(context)
// //                 .animate()
// //                 .slideY(begin: 0.2, end: 0.0, delay: 200.ms),
// //             const SizedBox(height: 20),
// //             _buildUpcomingBirthdaysSection(context)
// //                 .animate()
// //                 .slideY(begin: 0.2, end: 0.0, delay: 300.ms),
// //             const SizedBox(height: 20),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _buildUpcomingOrdersSection(BuildContext context) {
// //     return Column(
// //       crossAxisAlignment: CrossAxisAlignment.start,
// //       children: [
// //         MenuCard(
// //           icon: Icons.local_shipping,
// //           title: 'Commandes à Livrer',
// //           subtitle: 'Commandes en attente de livraison',
// //           onTap: () {
// //             Navigator.push(
// //               context,
// //               MaterialPageRoute(builder: (context) => const OrdersPage()),
// //             );
// //           },
// //         ),
// //         if (_upcomingOrders.isEmpty)
// //           Padding(
// //             padding: const EdgeInsets.symmetric(vertical: 16.0),
// //             child: Text(
// //               'Aucune commande à livrer dans les 7 prochains jours',
// //               style: TextStyle(
// //                 fontSize: 14,
// //                 color: Theme.of(context).colorScheme.secondary,
// //                 fontFamily: GoogleFonts.poppins().fontFamily,
// //               ),
// //             ),
// //           )
// //         else
// //           ListView.builder(
// //             shrinkWrap: true,
// //             physics: const NeverScrollableScrollPhysics(),
// //             itemCount: _upcomingOrders.length,
// //             itemBuilder: (context, index) {
// //               final order = _upcomingOrders[index];
// //               final deliveryDate = DateTime.parse(order['deliveryDate']);
// //               final formattedDate = DateFormat('dd MMM yyyy').format(deliveryDate);
// //               return Card(
// //                 elevation: 2,
// //                 margin: const EdgeInsets.symmetric(vertical: 8.0),
// //                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
// //                 child: ListTile(
// //                   contentPadding: const EdgeInsets.all(16.0),
// //                   title: Text(
// //                     order['clientName'] ?? 'Client inconnu',
// //                     style: TextStyle(
// //                       fontSize: 16,
// //                       fontWeight: FontWeight.bold,
// //                       fontFamily: GoogleFonts.poppins().fontFamily,
// //                     ),
// //                   ),
// //                   subtitle: Text(
// //                     '${order['service']}\nÀ livrer le $formattedDate',
// //                     style: TextStyle(
// //                       fontSize: 14,
// //                       color: Theme.of(context).colorScheme.secondary,
// //                       fontFamily: GoogleFonts.poppins().fontFamily,
// //                     ),
// //                   ),
// //                   trailing: Icon(
// //                     Icons.arrow_forward_ios,
// //                     size: 16,
// //                     color: Theme.of(context).colorScheme.primary,
// //                   ),
// //                   onTap: () {
// //                     Navigator.push(
// //                       context,
// //                       MaterialPageRoute(
// //                         builder: (context) => OrdersPage(
// //                           clientId: order['clientId'],
// //                           clientName: order['clientName'],
// //                         ),
// //                       ),
// //                     );
// //                   },
// //                 ),
// //               ).animate().fadeIn(delay: (100 * index).ms);
// //             },
// //           ),
// //         if (_upcomingOrders.length >= 5)
// //           TextButton(
// //             onPressed: () {
// //               Navigator.push(
// //                 context,
// //                 MaterialPageRoute(builder: (context) => const OrdersPage()),
// //               );
// //             },
// //             child: Text(
// //               'Voir toutes les commandes',
// //               style: TextStyle(
// //                 fontSize: 14,
// //                 color: Theme.of(context).colorScheme.primary,
// //                 fontFamily: GoogleFonts.poppins().fontFamily,
// //               ),
// //             ),
// //           ),
// //       ],
// //     );
// //   }

// //   Widget _buildUpcomingBirthdaysSection(BuildContext context) {
// //     return Column(
// //       crossAxisAlignment: CrossAxisAlignment.start,
// //       children: [
// //         MenuCard(
// //           icon: Icons.cake,
// //           title: 'Anniversaires à Venir',
// //           subtitle: 'Anniversaires des clients',
// //           onTap: () {
// //             Navigator.push(
// //               context,
// //               MaterialPageRoute(builder: (context) => const ClientsPage()),
// //             );
// //           },
// //         ),
// //         if (_upcomingBirthdays.isEmpty)
// //           Padding(
// //             padding: const EdgeInsets.symmetric(vertical: 16.0),
// //             child: Text(
// //               'Aucun anniversaire dans les 30 prochains jours',
// //               style: TextStyle(
// //                 fontSize: 14,
// //                 color: Theme.of(context).colorScheme.secondary,
// //                 fontFamily: GoogleFonts.poppins().fontFamily,
// //               ),
// //             ),
// //           )
// //         else
// //           ListView.builder(
// //             shrinkWrap: true,
// //             physics: const NeverScrollableScrollPhysics(),
// //             itemCount: _upcomingBirthdays.length,
// //             itemBuilder: (context, index) {
// //               final birthday = _upcomingBirthdays[index];
// //               final birthdate = DateTime.parse(birthday['birthdate']);
// //               final formattedDate = DateFormat('dd MMM').format(birthdate);
// //               final daysUntil = birthday['daysUntil'];
// //               final daysText = daysUntil == 0
// //                   ? "Aujourd'hui"
// //                   : daysUntil == 1
// //                       ? 'Demain'
// //                       : 'Dans $daysUntil jours';
// //               return Card(
// //                 elevation: 2,
// //                 margin: const EdgeInsets.symmetric(vertical: 8.0),
// //                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
// //                 child: ListTile(
// //                   contentPadding: const EdgeInsets.all(16.0),
// //                   title: Text(
// //                     birthday['name'] ?? 'Client inconnu',
// //                     style: TextStyle(
// //                       fontSize: 16,
// //                       fontWeight: FontWeight.bold,
// //                       fontFamily: GoogleFonts.poppins().fontFamily,
// //                     ),
// //                   ),
// //                   subtitle: Text(
// //                     '$formattedDate ($daysText)',
// //                     style: TextStyle(
// //                       fontSize: 14,
// //                       color: Theme.of(context).colorScheme.secondary,
// //                       fontFamily: GoogleFonts.poppins().fontFamily,
// //                     ),
// //                   ),
// //                   trailing: Icon(
// //                     Icons.arrow_forward_ios,
// //                     size: 16,
// //                     color: Theme.of(context).colorScheme.primary,
// //                   ),
// //                   onTap: () async {
// //                     final client = await DatabaseHelper().getClient(birthday['id']);
// //                     if (client != null && mounted) {
// //                       Navigator.pushNamed(
// //                         context,
// //                         '/edit_client',
// //                         arguments: Client.fromMap(client..['orders'] = []),
// //                       );
// //                     }
// //                   },
// //                 ),
// //               ).animate().fadeIn(delay: (100 * index).ms);
// //             },
// //           ),
// //         if (_upcomingBirthdays.length >= 5)
// //           TextButton(
// //             onPressed: () {
// //               Navigator.push(
// //                 context,
// //                 MaterialPageRoute(builder: (context) => const ClientsPage()),
// //               );
// //             },
// //             child: Text(
// //               'Voir tous les clients',
// //               style: TextStyle(
// //                 fontSize: 14,
// //                 color: Theme.of(context).colorScheme.primary,
// //                 fontFamily: GoogleFonts.poppins().fontFamily,
// //               ),
// //             ),
// //           ),
// //       ],
// //     );
// //   }
// // }





// import 'package:actis/pages/clients_page.dart';
// import 'package:actis/pages/orders_page.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:actis/helpers/database_helper.dart';
// import 'menu_card.dart';
// import 'package:intl/intl.dart';
// import 'package:intl/date_symbol_data_local.dart';
// import 'package:flutter/services.dart'; // Pour copier dans le presse-papiers

// class HomeContent extends StatefulWidget {
//   const HomeContent({super.key});

//   @override
//   State<HomeContent> createState() => _HomeContentState();
// }

// class _HomeContentState extends State<HomeContent> {
//   List<Map<String, dynamic>> _upcomingOrders = [];
//   List<Map<String, dynamic>> _upcomingBirthdays = [];

//   @override
//   void initState() {
//     super.initState();
//     initializeDateFormatting('fr_FR', null).then((_) {
//       _loadUpcomingData();
//     });
//   }

//   Future<void> _loadUpcomingData() async {
//     await _loadUpcomingOrders();
//     await _loadUpcomingBirthdays();
//   }

//   Future<void> _loadUpcomingOrders() async {
//     final now = DateTime.now();
//     final endDate = now.add(const Duration(days: 7)).toIso8601String().split('T')[0];
//     final db = await DatabaseHelper().database;
//     final orders = await db.rawQuery('''
//       SELECT orders.*, clients.name AS clientName
//       FROM orders
//       LEFT JOIN clients ON orders.clientId = clients.id
//       WHERE orders.deliveryDate >= ? AND orders.deliveryDate <= ? AND orders.status = 'pending'
//       ORDER BY orders.deliveryDate ASC
//       LIMIT 5
//     ''', [now.toIso8601String().split('T')[0], endDate]);

//     setState(() {
//       _upcomingOrders = orders;
//     });
//   }

//   Future<void> _loadUpcomingBirthdays() async {
//     final now = DateTime.now();
//     final clients = await DatabaseHelper().getClients();
//     final upcomingBirthdays = <Map<String, dynamic>>[];
//     print('Clients loaded: ${clients.length}');
//     for (var client in clients) {
//       final birthdateStr = client['birthdate']?.toString();
//       print('Client: ${client['name']}, Birthdate: $birthdateStr');
//       if (birthdateStr == null || birthdateStr.isEmpty) continue;
//       DateTime? birthdate;
//       try {
//         birthdate = DateTime.parse(birthdateStr);
//         print('Parsed birthdate: $birthdate');
//       } catch (e) {
//         try {
//           final parts = birthdateStr.split('/');
//           if (parts.length == 3) {
//             birthdate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
//             print('Parsed alternative birthdate: $birthdate');
//           }
//         } catch (e2) {
//           print('Error parsing birthdate for ${client['name']}: $birthdateStr, Error: $e2');
//           continue;
//         }
//       }
//       if (birthdate == null) continue;
//       final currentYearBirthdate = DateTime(now.year, birthdate.month, birthdate.day);
//       final nextYearBirthdate = DateTime(now.year + 1, birthdate.month, birthdate.day);
//       final diffCurrent = currentYearBirthdate.difference(now).inDays;
//       final diffNext = nextYearBirthdate.difference(now).inDays;
//       print('DiffCurrent: $diffCurrent, DiffNext: $diffNext');
//       if ((diffCurrent >= 0 && diffCurrent <= 30) || (diffNext >= 0 && diffNext <= 30)) {
//         upcomingBirthdays.add({
//           'id': client['id'],
//           'name': client['name'],
//           'birthdate': birthdateStr,
//           'daysUntil': diffCurrent >= 0 && diffCurrent <= 30 ? diffCurrent : diffNext,
//         });
//         print('Added birthday for ${client['name']}');
//       }
//     }
//     upcomingBirthdays.sort((a, b) => a['daysUntil'].compareTo(b['daysUntil']));
//     print('Upcoming birthdays: $upcomingBirthdays');
//     setState(() {
//       _upcomingBirthdays = upcomingBirthdays.take(5).toList();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const SizedBox(height: 20),
//             _buildUpcomingOrdersSection(context)
//                 .animate()
//                 .slideY(begin: 0.2, end: 0.0, delay: 200.ms),
//             const SizedBox(height: 20),
//             _buildUpcomingBirthdaysSection(context)
//                 .animate()
//                 .slideY(begin: 0.2, end: 0.0, delay: 300.ms),
//             const SizedBox(height: 20),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildUpcomingOrdersSection(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         MenuCard(
//           icon: Icons.local_shipping,
//           title: 'Commandes à Livrer',
//           subtitle: 'Commandes en attente de livraison',
//           onTap: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(builder: (context) => const OrdersPage()),
//             );
//           },
//         ),
//         if (_upcomingOrders.isEmpty)
//           Padding(
//             padding: const EdgeInsets.symmetric(vertical: 16.0),
//             child: Text(
//               'Aucune commande à livrer dans les 7 prochains jours',
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Theme.of(context).colorScheme.secondary,
//                 fontFamily: GoogleFonts.poppins().fontFamily,
//               ),
//             ),
//           )
//         else
//           ListView.builder(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             itemCount: _upcomingOrders.length,
//             itemBuilder: (context, index) {
//               final order = _upcomingOrders[index];
//               final deliveryDate = DateTime.parse(order['deliveryDate']);
//               final formattedDate = DateFormat('dd MMM yyyy').format(deliveryDate);
//               return Card(
//                 elevation: 2,
//                 margin: const EdgeInsets.symmetric(vertical: 8.0),
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                 child: ListTile(
//                   contentPadding: const EdgeInsets.all(20.0),
//                   title: Text(
//                     order['clientName'] ?? 'Client inconnu',
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       fontFamily: GoogleFonts.poppins().fontFamily,
//                     ),
//                   ),
//                   subtitle: Text(
//                     '${order['service']}\nÀ livrer le $formattedDate',
//                     style: TextStyle(
//                       fontSize: 16,
//                       color: Theme.of(context).colorScheme.secondary,
//                       fontFamily: GoogleFonts.poppins().fontFamily,
//                     ),
//                   ),
//                   trailing: Icon(
//                     Icons.arrow_forward_ios,
//                     size: 16,
//                     color: Theme.of(context).colorScheme.primary,
//                   ),
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => OrdersPage(
//                           clientId: order['clientId'],
//                           clientName: order['clientName'],
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ).animate().fadeIn(delay: (100 * index).ms);
//             },
//           ),
//         if (_upcomingOrders.length >= 5)
//           TextButton(
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => const OrdersPage()),
//               );
//             },
//             child: Text(
//               'Voir toutes les commandes',
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Theme.of(context).colorScheme.primary,
//                 fontFamily: GoogleFonts.poppins().fontFamily,
//               ),
//             ),
//           ),
//       ],
//     );
//   }

//   Widget _buildUpcomingBirthdaysSection(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         MenuCard(
//           icon: Icons.cake,
//           title: 'Anniversaires à Venir',
//           subtitle: 'Anniversaires des clients',
//           onTap: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(builder: (context) => const ClientsPage()),
//             );
//           },
       



//         ),

//              const SizedBox(height: 20),

//         if (_upcomingBirthdays.isEmpty)
//           Padding(
//             padding: const EdgeInsets.symmetric(vertical: 16.0),
//             child: Text(
//               'Aucun anniversaire dans les 30 prochains jours',
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Theme.of(context).colorScheme.secondary,
//                 fontFamily: GoogleFonts.poppins().fontFamily,
//               ),
//             ),
//           )
//         else
//           ListView.builder(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             itemCount: _upcomingBirthdays.length,
//             itemBuilder: (context, index) {
//               final birthday = _upcomingBirthdays[index];
//               DateTime birthdate;
//               try {
//                 birthdate = DateTime.parse(birthday['birthdate']);
//               } catch (e) {
//                 final parts = birthday['birthdate'].split('/');
//                 if (parts.length == 3) {
//                   birthdate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
//                 } else {
//                   return SizedBox.shrink();
//                 }
//               }
//               final formattedDate = DateFormat('dd MMMM', 'fr_FR').format(birthdate);
//               final daysUntil = birthday['daysUntil'];
//               final daysText = daysUntil == 0
//                   ? "aujourd'hui"
//                   : daysUntil == 1
//                       ? 'demain'
//                       : 'dans $daysUntil jours';
//               final message = "${birthday['name']} fête son anniversaire le $formattedDate $daysText, envie de lui faire une surprise ?";
//               return Card(
//                 elevation: 2,
//                 margin: const EdgeInsets.symmetric(vertical: 8.0),
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                 child: ListTile(
//                   contentPadding: const EdgeInsets.all(20.0),
//                   title: Text(
//                     birthday['name'] ?? 'Client inconnu',
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       fontFamily: GoogleFonts.poppins().fontFamily,
//                     ),
//                   ),
//                   subtitle: Text(
//                     message,
//                     style: TextStyle(
//                       fontSize: 16,
//                       color: Theme.of(context).colorScheme.secondary,
//                       fontFamily: GoogleFonts.poppins().fontFamily,
//                     ),
//                   ),
//                   trailing: Icon(
//                     Icons.arrow_forward_ios,
//                     size: 16,
//                     color: Theme.of(context).colorScheme.primary,
//                   ),
//                   onTap: () async {
//                     final client = await DatabaseHelper().getClient(birthday['id']);
//                     if (client != null && mounted) {
//                       final orders = await DatabaseHelper().getOrdersForClient(birthday['id']);
//                       String giftSuggestion = 'Offrez lui un cadeau .';
//                       if (orders.isNotEmpty) {
//                         final lastService = orders.last['service'];
//                         giftSuggestion = 'Offrez une $lastService personnalisée à ${birthday['name']}.';
//                       }
//                       final smsMessage = 'Joyeux anniversaire, ${birthday['name']} ! Profitez de 10% de réduction sur votre prochaine commande chez nous !';
//                       showDialog(
//                         context: context,
//                         builder: (context) => AlertDialog(
//                           title: Text('Anniversaire de ${birthday['name']}'),
//                           content: Column(
//                             mainAxisSize: MainAxisSize.min,
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text('Message SMS suggéré :'),
//                               SizedBox(height: 8),
//                               Text(smsMessage, style: TextStyle(fontSize: 14)),
//                               SizedBox(height: 16),
//                               Text('Suggestion de cadeau :'),
//                               SizedBox(height: 8),
//                               Text(giftSuggestion, style: TextStyle(fontSize: 14)),
//                             ],
//                           ),
//                           actions: [
//                             TextButton(
//                               onPressed: () {
//                                 Clipboard.setData(ClipboardData(text: smsMessage));
//                                 ScaffoldMessenger.of(context).showSnackBar(
//                                   SnackBar(content: Text('Message copié dans le presse-papiers')),
//                                 );
//                               },
//                               child: Text('Copier le message'),
//                             ),
//                             TextButton(
//                               onPressed: () => Navigator.pop(context),
//                               child: Text('Fermer'),
//                             ),
//                           ],
//                         ),
//                       );
//                     }
//                   },
//                 ),
//               ).animate().fadeIn(delay: (100 * index).ms);
//             },
//           ),
//         if (_upcomingBirthdays.length >= 5)
//           TextButton(
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => const ClientsPage()),
//               );
//             },
//             child: Text(
//               'Voir tous les clients',
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Theme.of(context).colorScheme.primary,
//                 fontFamily: GoogleFonts.poppins().fontFamily,
//               ),
//             ),
//           ),
//       ],
//     );
//   }
// }



// import 'package:actis/notifications/notification_service.dart';
// import 'package:actis/pages/clients_page.dart';
// import 'package:actis/pages/orders_page.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:actis/helpers/database_helper.dart';
// import 'package:intl/date_symbol_data_local.dart';
// import 'menu_card.dart';
// import 'package:intl/intl.dart';
// import 'package:flutter/services.dart';

// class HomeContent extends StatefulWidget {
//   const HomeContent({super.key});

//   @override
//   State<HomeContent> createState() => _HomeContentState();
// }

// class _HomeContentState extends State<HomeContent> {
//   List<Map<String, dynamic>> _upcomingOrders = [];
//   List<Map<String, dynamic>> _upcomingBirthdays = [];

//   @override
//   void initState() {
//     super.initState();
//     initializeDateFormatting('fr_FR', null).then((_) {
//       _loadUpcomingData();
//       // Initialiser et planifier les notifications
//       NotificationService.initialize().then((_) {
//         NotificationService.scheduleDailyNotifications();
//       });
//     });
//   }

//   Future<void> _loadUpcomingData() async {
//     await _loadUpcomingOrders();
//     await _loadUpcomingBirthdays();
//   }

//   Future<void> _loadUpcomingOrders() async {
//     final now = DateTime.now();
//     final endDate = now.add(const Duration(days: 7)).toIso8601String().split('T')[0];
//     final db = await DatabaseHelper().database;
//     final orders = await db.rawQuery('''
//       SELECT orders.*, clients.name AS clientName
//       FROM orders
//       LEFT JOIN clients ON orders.clientId = clients.id
//       WHERE orders.deliveryDate >= ? AND orders.deliveryDate <= ? AND orders.status = 'pending'
//       ORDER BY orders.deliveryDate ASC
//       LIMIT 5
//     ''', [now.toIso8601String().split('T')[0], endDate]);

//     setState(() {
//       _upcomingOrders = orders;
//     });
//   }

//   Future<void> _loadUpcomingBirthdays() async {
//     final now = DateTime.now();
//     final clients = await DatabaseHelper().getClients();
//     final upcomingBirthdays = <Map<String, dynamic>>[];
//     print('Clients loaded: ${clients.length}');
//     for (var client in clients) {
//       final birthdateStr = client['birthdate']?.toString();
//       print('Client: ${client['name']}, Birthdate: $birthdateStr');
//       if (birthdateStr == null || birthdateStr.isEmpty) continue;
//       DateTime? birthdate;
//       try {
//         birthdate = DateTime.parse(birthdateStr);
//         print('Parsed birthdate: $birthdate');
//       } catch (e) {
//         try {
//           final parts = birthdateStr.split('/');
//           if (parts.length == 3) {
//             birthdate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
//             print('Parsed alternative birthdate: $birthdate');
//           }
//         } catch (e2) {
//           print('Error parsing birthdate for ${client['name']}: $birthdateStr, Error: $e2');
//           continue;
//         }
//       }
//       if (birthdate == null) continue;
//       final currentYearBirthdate = DateTime(now.year, birthdate.month, birthdate.day);
//       final nextYearBirthdate = DateTime(now.year + 1, birthdate.month, birthdate.day);
//       final diffCurrent = currentYearBirthdate.difference(now).inDays;
//       final diffNext = nextYearBirthdate.difference(now).inDays;
//       print('DiffCurrent: $diffCurrent, DiffNext: $diffNext');
//       if ((diffCurrent >= 0 && diffCurrent <= 30) || (diffNext >= 0 && diffNext <= 30)) {
//         upcomingBirthdays.add({
//           'id': client['id'],
//           'name': client['name'],
//           'birthdate': birthdateStr,
//           'daysUntil': diffCurrent >= 0 && diffCurrent <= 30 ? diffCurrent : diffNext,
//         });
//         print('Added birthday for ${client['name']}');
//       }
//     }
//     upcomingBirthdays.sort((a, b) => a['daysUntil'].compareTo(b['daysUntil']));
//     print('Upcoming birthdays: $upcomingBirthdays');
//     setState(() {
//       _upcomingBirthdays = upcomingBirthdays.take(5).toList();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const SizedBox(height: 20),
//             _buildUpcomingOrdersSection(context)
//                 .animate()
//                 .slideY(begin: 0.2, end: 0.0, delay: 200.ms),
//             const SizedBox(height: 20),
//             _buildUpcomingBirthdaysSection(context)
//                 .animate()
//                 .slideY(begin: 0.2, end: 0.0, delay: 300.ms),
//             const SizedBox(height: 20),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildUpcomingOrdersSection(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         MenuCard(
//           icon: Icons.local_shipping,
//           title: 'Commandes à Livrer',
//           subtitle: 'Commandes en attente de livraison',
//           onTap: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(builder: (context) => const OrdersPage()),
//             );
//           },
//         ),
//         if (_upcomingOrders.isEmpty)
//           Padding(
//             padding: const EdgeInsets.symmetric(vertical: 16.0),
//             child: Text(
//               'Aucune commande à livrer dans les 7 prochains jours',
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Theme.of(context).colorScheme.secondary,
//                 fontFamily: GoogleFonts.poppins().fontFamily,
//               ),
//             ),
//           )
//         else
//           ListView.builder(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             itemCount: _upcomingOrders.length,
//             itemBuilder: (context, index) {
//               final order = _upcomingOrders[index];
//               final deliveryDate = DateTime.parse(order['deliveryDate']);
//               final formattedDate = DateFormat('dd MMM yyyy').format(deliveryDate);
//               return Card(
//                 elevation: 2,
//                 margin: const EdgeInsets.symmetric(vertical: 8.0),
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                 child: ListTile(
//                   contentPadding: const EdgeInsets.all(20.0),
//                   title: Text(
//                     order['clientName'] ?? 'Client inconnu',
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       fontFamily: GoogleFonts.poppins().fontFamily,
//                     ),
//                   ),
//                   subtitle: Text(
//                     '${order['service']}\nÀ livrer le $formattedDate',
//                     style: TextStyle(
//                       fontSize: 16,
//                       color: Theme.of(context).colorScheme.secondary,
//                       fontFamily: GoogleFonts.poppins().fontFamily,
//                     ),
//                   ),
//                   trailing: Icon(
//                     Icons.arrow_forward_ios,
//                     size: 16,
//                     color: Theme.of(context).colorScheme.primary,
//                   ),
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => OrdersPage(
//                           clientId: order['clientId'],
//                           clientName: order['clientName'],
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ).animate().fadeIn(delay: (100 * index).ms);
//             },
//           ),
//         if (_upcomingOrders.length >= 5)
//           TextButton(
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => const OrdersPage()),
//               );
//             },
//             child: Text(
//               'Voir toutes les commandes',
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Theme.of(context).colorScheme.primary,
//                 fontFamily: GoogleFonts.poppins().fontFamily,
//               ),
//             ),
//           ),
//       ],
//     );
//   }

//   Widget _buildUpcomingBirthdaysSection(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         MenuCard(
//           icon: Icons.cake,
//           title: 'Anniversaires à Venir',
//           subtitle: 'Anniversaires des clients',
//           onTap: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(builder: (context) => const ClientsPage()),
//             );
//           },
//         ),
//         const SizedBox(height: 20),
//         if (_upcomingBirthdays.isEmpty)
//           Padding(
//             padding: const EdgeInsets.symmetric(vertical: 16.0),
//             child: Text(
//               'Aucun anniversaire dans les 30 prochains jours',
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Theme.of(context).colorScheme.secondary,
//                 fontFamily: GoogleFonts.poppins().fontFamily,
//               ),
//             ),
//           )
//         else
//           ListView.builder(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             itemCount: _upcomingBirthdays.length,
//             itemBuilder: (context, index) {
//               final birthday = _upcomingBirthdays[index];
//               DateTime birthdate;
//               try {
//                 birthdate = DateTime.parse(birthday['birthdate']);
//               } catch (e) {
//                 final parts = birthday['birthdate'].split('/');
//                 if (parts.length == 3) {
//                   birthdate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
//                 } else {
//                   return SizedBox.shrink();
//                 }
//               }
//               final formattedDate = DateFormat('dd MMMM', 'fr_FR').format(birthdate);
//               final daysUntil = birthday['daysUntil'];
//               final daysText = daysUntil == 0
//                   ? "aujourd'hui"
//                   : daysUntil == 1
//                       ? 'demain'
//                       : 'dans $daysUntil jours';
//               final message = "${birthday['name']} fête son anniversaire le $formattedDate $daysText, envie de lui faire une surprise ?";
//               return Card(
//                 elevation: 2,
//                 margin: const EdgeInsets.symmetric(vertical: 8.0),
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                 child: ListTile(
//                   contentPadding: const EdgeInsets.all(20.0),
//                   title: Text(
//                     birthday['name'] ?? 'Client inconnu',
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       fontFamily: GoogleFonts.poppins().fontFamily,
//                     ),
//                   ),
//                   subtitle: Text(
//                     message,
//                     style: TextStyle(
//                       fontSize: 16,
//                       color: Theme.of(context).colorScheme.secondary,
//                       fontFamily: GoogleFonts.poppins().fontFamily,
//                     ),
//                   ),
//                   trailing: Icon(
//                     Icons.arrow_forward_ios,
//                     size: 16,
//                     color: Theme.of(context).colorScheme.primary,
//                   ),
//                   onTap: () async {
//                     final client = await DatabaseHelper().getClient(birthday['id']);
//                     if (client != null && mounted) {
//                       final orders = await DatabaseHelper().getOrdersForClient(birthday['id']);
//                       String giftSuggestion = 'Offrez un bon cadeau de 50€.';
//                       if (orders.isNotEmpty) {
//                         final lastService = orders.last['service'];
//                         giftSuggestion = 'Offrez une $lastService personnalisée à ${birthday['name']}.';
//                       }
//                       final smsMessage = 'Joyeux anniversaire, ${birthday['name']} ! Profitez de 10% de réduction sur votre prochaine commande chez nous !';
//                       showDialog(
//                         context: context,
//                         builder: (context) => AlertDialog(
//                           title: Text('Anniversaire de ${birthday['name']}'),
//                           content: Column(
//                             mainAxisSize: MainAxisSize.min,
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text('Message SMS suggéré :'),
//                               const SizedBox(height: 8),
//                               Text(smsMessage, style: const TextStyle(fontSize: 14)),
//                               const SizedBox(height: 16),
//                               Text('Suggestion de cadeau :'),
//                               const SizedBox(height: 8),
//                               Text(giftSuggestion, style: const TextStyle(fontSize: 14)),
//                             ],
//                           ),
//                           actions: [
//                             TextButton(
//                               onPressed: () {
//                                 Clipboard.setData(ClipboardData(text: smsMessage));
//                                 ScaffoldMessenger.of(context).showSnackBar(
//                                   const SnackBar(content: Text('Message copié dans le presse-papiers')),
//                                 );
//                               },
//                               child: const Text('Copier le message'),
//                             ),
//                             TextButton(
//                               onPressed: () => Navigator.pop(context),
//                               child: const Text('Fermer'),
//                             ),
//                           ],
//                         ),
//                       );
//                     }
//                   },
//                 ),
//               ).animate().fadeIn(delay: (100 * index).ms);
//             },
//           ),
//         if (_upcomingBirthdays.length >= 5)
//           TextButton(
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => const ClientsPage()),
//               );
//             },
//             child: Text(
//               'Voir tous les clients',
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Theme.of(context).colorScheme.primary,
//                 fontFamily: GoogleFonts.poppins().fontFamily,
//               ),
//             ),
//           ),
//       ],
//     );
//   }
// }





import 'package:actis/pages/clients_page.dart';
import 'package:actis/pages/orders_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:actis/helpers/database_helper.dart';
import 'menu_card.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/services.dart';
import 'package:actis/notifications/notification_service.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  List<Map<String, dynamic>> _upcomingOrders = [];
  List<Map<String, dynamic>> _upcomingBirthdays = [];

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('fr_FR', null).then((_) {
      _loadUpcomingData();
      NotificationService().scheduleDailyNotifications();
    });
  }

  Future<void> _loadUpcomingData() async {
    await _loadUpcomingOrders();
    await _loadUpcomingBirthdays();
  }

  Future<void> _loadUpcomingOrders() async {
    final now = DateTime.now();
    final endDate = now.add(const Duration(days: 7)).toIso8601String().split('T')[0];
    final db = await DatabaseHelper().database;
    final orders = await db.rawQuery('''
      SELECT orders.*, clients.name AS clientName
      FROM orders
      LEFT JOIN clients ON orders.clientId = clients.id
      WHERE orders.deliveryDate >= ? AND orders.deliveryDate <= ? AND orders.status = 'pending'
      ORDER BY orders.deliveryDate ASC
      LIMIT 5
    ''', [now.toIso8601String().split('T')[0], endDate]);

    setState(() {
      _upcomingOrders = orders;
    });
  }

  Future<void> _loadUpcomingBirthdays() async {
    final now = DateTime.now();
    final clients = await DatabaseHelper().getClients();
    final upcomingBirthdays = <Map<String, dynamic>>[];
    print('Clients loaded: ${clients.length}');
    for (var client in clients) {
      final birthdateStr = client['birthdate']?.toString();
      print('Client: ${client['name']}, Birthdate: $birthdateStr');
      if (birthdateStr == null || birthdateStr.isEmpty) continue;
      DateTime? birthdate;
      try {
        birthdate = DateTime.parse(birthdateStr);
        print('Parsed birthdate: $birthdate');
      } catch (e) {
        try {
          final parts = birthdateStr.split('/');
          if (parts.length == 3) {
            birthdate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
            print('Parsed alternative birthdate: $birthdate');
          }
        } catch (e2) {
          print('Error parsing birthdate for ${client['name']}: $birthdateStr, Error: $e2');
          continue;
        }
      }
      if (birthdate == null) continue;
      final currentYearBirthdate = DateTime(now.year, birthdate.month, birthdate.day);
      final nextYearBirthdate = DateTime(now.year + 1, birthdate.month, birthdate.day);
      final diffCurrent = currentYearBirthdate.difference(now).inDays;
      final diffNext = nextYearBirthdate.difference(now).inDays;
      print('DiffCurrent: $diffCurrent, DiffNext: $diffNext');
      if ((diffCurrent >= 0 && diffCurrent <= 30) || (diffNext >= 0 && diffNext <= 30)) {
        upcomingBirthdays.add({
          'id': client['id'],
          'name': client['name'],
          'birthdate': birthdateStr,
          'daysUntil': diffCurrent >= 0 && diffCurrent <= 30 ? diffCurrent : diffNext,
        });
        print('Added birthday for ${client['name']}');
      }
    }
    upcomingBirthdays.sort((a, b) => a['daysUntil'].compareTo(b['daysUntil']));
    print('Upcoming birthdays: $upcomingBirthdays');
    setState(() {
      _upcomingBirthdays = upcomingBirthdays.take(5).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildUpcomingOrdersSection(context)
                .animate()
                .slideY(begin: 0.2, end: 0.0, delay: 200.ms),
            const SizedBox(height: 20),
            _buildUpcomingBirthdaysSection(context)
                .animate()
                .slideY(begin: 0.2, end: 0.0, delay: 300.ms),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingOrdersSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MenuCard(
          icon: Icons.local_shipping,
          title: 'Commandes à Livrer',
          subtitle: 'Commandes en attente de livraison',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const OrdersPage()),
            );
          },
        ),
        if (_upcomingOrders.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Text(
              'Aucune commande à livrer dans les 7 prochains jours',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.secondary,
                fontFamily: GoogleFonts.poppins().fontFamily,
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _upcomingOrders.length,
            itemBuilder: (context, index) {
              final order = _upcomingOrders[index];
              final deliveryDate = DateTime.parse(order['deliveryDate'].toString());
              final formattedDate = DateFormat('dd MMM yyyy').format(deliveryDate);
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(20.0),
                  title: Text(
                    order['clientName'] ?? 'Client inconnu',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Gilroy',
                    ),
                  ),
                  subtitle: Text(
                    '${order['service']}\nÀ livrer le $formattedDate',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.secondary,
                      fontFamily: GoogleFonts.poppins().fontFamily,
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: const Color(0xFF66CC66),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrdersPage(
                          clientId: order['clientId'],
                          clientName: order['clientName'],
                        ),
                      ),
                    );
                  },
                ),
              ).animate().fadeIn(delay: (100 * index).ms);
            },
          ),
        if (_upcomingOrders.length >= 5)
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const OrdersPage()),
              );
            },
            child: Text(
              'Voir toutes les commandes',
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF66CC66),
                fontFamily: GoogleFonts.poppins().fontFamily,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUpcomingBirthdaysSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MenuCard(
          icon: Icons.cake,
          title: 'Anniversaires à Venir',
          subtitle: 'Anniversaires des clients',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ClientsPage()),
            );
          },
        ),
        const SizedBox(height: 20),
        if (_upcomingBirthdays.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Text(
              'Aucun anniversaire dans les 30 prochains jours',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.secondary,
                fontFamily: GoogleFonts.poppins().fontFamily,
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _upcomingBirthdays.length,
            itemBuilder: (context, index) {
              final birthday = _upcomingBirthdays[index];
              DateTime birthdate;
              try {
                birthdate = DateTime.parse(birthday['birthdate'].toString());
              } catch (e) {
                final parts = birthday['birthdate'].split('/');
                if (parts.length == 3) {
                  birthdate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
                } else {
                  return const SizedBox.shrink();
                }
              }
              final formattedDate = DateFormat('dd MMMM', 'fr_FR').format(birthdate);
              final daysUntil = birthday['daysUntil'];
              final daysText = daysUntil == 0
                  ? "aujourd'hui"
                  : daysUntil == 1
                      ? 'demain'
                      : 'dans $daysUntil jours';
              final message = "${birthday['name']} fête son anniversaire le $formattedDate $daysText, envie de lui faire une surprise ?";
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(20.0),
                  title: Text(
                    birthday['name'] ?? 'Client inconnu',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Gilroy',
                    ),
                  ),
                  subtitle: Text(
                    message,
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.secondary,
                      fontFamily: GoogleFonts.poppins().fontFamily,
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: const Color(0xFF66CC66),
                  ),
                  onTap: () async {
                    final client = await DatabaseHelper().getClient(birthday['id']);
                    if (client != null && mounted) {
                      final orders = await DatabaseHelper().getOrdersForClient(birthday['id']);
                      String giftSuggestion = 'Offrez un bon cadeau de 5 000.';
                      if (orders.isNotEmpty) {
                        final lastService = orders.last['service'];
                        giftSuggestion = 'Offrez une $lastService personnalisée à ${birthday['name']}.';
                      }
                      final smsMessage = 'Joyeux anniversaire, ${birthday['name']} ! Profitez de 10% de réduction sur votre prochaine commande chez nous !';
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(
                            'Anniversaire de ${birthday['name']}',
                            style: const TextStyle(
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Message SMS suggéré :',
                                style: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                smsMessage,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: GoogleFonts.poppins().fontFamily,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Suggestion de cadeau :',
                                style: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                giftSuggestion,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: GoogleFonts.poppins().fontFamily,
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: smsMessage));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Message copié dans le presse-papiers')),
                                );
                              },
                              child: Text(
                                'Copier le message',
                                style: TextStyle(
                                  color: const Color(0xFF66CC66),
                                  fontFamily: GoogleFonts.poppins().fontFamily,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                'Fermer',
                                style: TextStyle(
                                  color: const Color(0xFF66CC66),
                                  fontFamily: GoogleFonts.poppins().fontFamily,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
              ).animate().fadeIn(delay: (100 * index).ms);
            },
          ),
        if (_upcomingBirthdays.length >= 5)
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ClientsPage()),
              );
            },
            child: Text(
              'Voir tous les clients',
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF66CC66),
                fontFamily: GoogleFonts.poppins().fontFamily,
              ),
            ),
          ),
      ],
    );
  }
}