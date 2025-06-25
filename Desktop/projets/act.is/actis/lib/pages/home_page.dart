// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:google_fonts/google_fonts.dart';
// import '../widgets/home_content.dart';
// import 'clients_page.dart';
// import 'orders_page.dart';
// import 'settings_page.dart';

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});

//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   int _selectedIndex = 0;

//   final List<Widget> _pages = [
//     const HomeContent(),
//     const ClientsPage(),
//     const OrdersPage(),
//     const SettingsPage(),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       extendBodyBehindAppBar: true,
//       appBar: AppBar(
//         title: Text(
//           'Act.is',
//           style: TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//             fontFamily: GoogleFonts.poppins().fontFamily,
//           ),
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.settings).animate().fadeIn(duration: 500.ms),
//             onPressed: () {
//               setState(() {
//                 _selectedIndex = 3;
//               });
//             },
//           ),
//         ],
//       ),
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
//         child: SafeArea(
//           child: _pages[_selectedIndex]
//               .animate()
//               .fadeIn(duration: 300.ms)
//               .slideX(begin: 0.2, end: 0.0),
//         ),
//       ),
//       bottomNavigationBar: Container(
//         margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(16),
//           color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.1),
//               blurRadius: 10,
//               spreadRadius: 1,
//             ),
//           ],
//         ),
//         child: BottomNavigationBar(
//           currentIndex: _selectedIndex,
//           onTap: (index) {
//             setState(() {
//               _selectedIndex = index;
//             });
//           },
//           items: const [
//             BottomNavigationBarItem(
//               icon: Icon(Icons.home),
//               label: 'Accueil',
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.people),
//               label: 'Clients',
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.local_shipping),
//               label: 'Commandes',
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.settings),
//               label: 'Paramètres',
//             ),
//           ],
//         ).animate().fadeIn(duration: 500.ms),
//       ),
//     );
//   }
// }



// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:google_fonts/google_fonts.dart';
// import '../widgets/home_content.dart';
// import 'clients_page.dart';
// import 'orders_page.dart';
// import 'settings_page.dart';

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});

//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   int _selectedIndex = 0;

//   final List<Widget> _pages = [
//     const HomeContent(),
//     const ClientsPage(),
//     const OrdersPage(),
//     const SettingsPage(),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       extendBodyBehindAppBar: true,
//       appBar: AppBar(
//         title: Text(
//           'Act.is',
//           style: TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//             fontFamily: GoogleFonts.poppins().fontFamily,
//           ),
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.settings).animate().fadeIn(duration: 500.ms),
//             onPressed: () {
//               setState(() {
//                 _selectedIndex = 3;
//               });
//             },
//           ),
//         ],
//       ),
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
//         child: SafeArea(
//           child: _pages[_selectedIndex]
//               .animate()
//               .fadeIn(duration: 300.ms)
//               .slideX(begin: 0.2, end: 0.0),
//         ),
//       ),
//       bottomNavigationBar: Container(
//         margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(16),
//           color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.1),
//               blurRadius: 10,
//               spreadRadius: 1,
//             ),
//           ],
//         ),
//         child: BottomNavigationBar(
//           currentIndex: _selectedIndex,
//           onTap: (index) {
//             setState(() {
//               _selectedIndex = index;
//             });
//           },
//           items: const [
//             BottomNavigationBarItem(
//               icon: Icon(Icons.home),
//               label: 'Accueil',
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.people),
//               label: 'Clients',
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.local_shipping),
//               label: 'Commandes',
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.settings),
//               label: 'Paramètres',
//             ),
//           ],
//           selectedLabelStyle: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
//           unselectedLabelStyle: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
//         ).animate().fadeIn(duration: 500.ms),
//       ),
//     );
//   }
// }


//  bottomNavigationBar: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [
//               Theme.of(context).colorScheme.background,
//               Theme.of(context).colorScheme.background.withOpacity(0.8),
//             ],
//           ),
//           border: Border(
//             top: BorderSide(
//               color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
//               width: 1,
//             ),
//           ),
//         ),
//         child: BottomNavigationBar(
//           backgroundColor: Colors.transparent,
//           elevation: 0,
//           type: BottomNavigationBarType.fixed,
//           selectedItemColor: Theme.of(context).colorScheme.primary,
//           unselectedItemColor: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
//           currentIndex: 1,
//           onTap: (index) {
//             HapticFeedback.lightImpact();
//             // Ajouter la navigation vers d'autres pages ici
//           },
//           items: const [
//             BottomNavigationBarItem(
//               icon: Icon(Icons.home_outlined),
//               activeIcon: Icon(Icons.home),
//               label: 'Accueil',
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.local_shipping),
//               activeIcon: Icon(Icons.local_shipping),
//               label: 'Commandes',
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.people_outline),
//               activeIcon: Icon(Icons.people),
//               label: 'Clients',
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.settings_outlined),
//               activeIcon: Icon(Icons.settings),
//               label: 'Paramètres',
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/home_content.dart';
import 'clients_page.dart';
import 'orders_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeContent(),
    const OrdersPage(),
    const ClientsPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Act.is',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: GoogleFonts.poppins().fontFamily,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings).animate().fadeIn(duration: 500.ms),
            onPressed: () {
              setState(() {
                _selectedIndex = 3;
              });
            },
          ),
        ],
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
        child: SafeArea(
          child: _pages[_selectedIndex]
              .animate()
              .fadeIn(duration: 300.ms)
              .slideX(begin: 0.2, end: 0.0),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.background,
              Theme.of(context).colorScheme.background.withOpacity(0.8),
            ],
          ),
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
          currentIndex: _selectedIndex,
          onTap: (index) {
            HapticFeedback.lightImpact();
            setState(() {
              _selectedIndex = index;
            });
          },
          selectedLabelStyle: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
          unselectedLabelStyle: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Accueil',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_shipping_outlined),
              activeIcon: Icon(Icons.local_shipping),
              label: 'Commandes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Clients',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Paramètres',
            ),
          ],
        ).animate().fadeIn(duration: 500.ms),
      ),
    );
  }
}