// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import '../pages/clients_page.dart';

// class MenuCard extends StatelessWidget {
//   final IconData icon;
//   final String title;
//   final String subtitle;

//   const MenuCard({
//     super.key,
//     required this.icon,
//     required this.title,
//     required this.subtitle,
//   });

//   @override
//   Widget build( context) {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       child: Card(
//         child: InkWell(
//           borderRadius: BorderRadius.circular(16),
//           onTap: () {
//             switch (title) {
//               case 'Liste des Clients':
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => const ClientsPage()),
//                 );
//                 break;
//               case 'Commandes à Livrer':
//               case 'Anniversaires à Venir':
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(content: Text('$title sélectionné')),
//                 );
//                 break;
//               default:
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(content: Text('$title sélectionné')),
//                 );
//             }
//           },
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Row(
//               children: [
//                 Container(
//                   width: 48,
//                   height: 48,
//                   decoration: BoxDecoration(
//                     gradient: const LinearGradient(
//                       colors: [Color(0xFF00DDEB), Color(0xFF8B00FF)],
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                     ),
//                     borderRadius: const BorderRadius.all(Radius.circular(12)),
//                   ),
//                   child: Icon(
//                     icon,
//                     color: Colors.white,
//                     size: 24,
//                   ).animate().scale(duration: 300.ms),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         title,
//                         style: const TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         subtitle,
//                         style: const TextStyle(
//                           fontSize: 14,
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
// }




import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
    final double height;

  const MenuCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.height = 100.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap ??
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '$title sélectionné',
                      style: TextStyle(fontFamily: GoogleFonts.orbitron().fontFamily),
                    ),
                  ),
                );
              },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF00DDEB), Color(0xFF8B00FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ).animate().scale(duration: 300.ms),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: GoogleFonts.orbitron().fontFamily,
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.secondary,
                          fontFamily: GoogleFonts.orbitron().fontFamily,
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
}