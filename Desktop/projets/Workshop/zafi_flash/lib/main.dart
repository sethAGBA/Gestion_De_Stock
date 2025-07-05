// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';

// void main() {
//   runApp(WeatherApp());
// }

// class WeatherApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Météo App',
//       theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Roboto'),
//       home: WeatherScreen(),
//       debugShowCheckedModeBanner: false,
//     );
//   }
// }

// class WeatherScreen extends StatefulWidget {
//   @override
//   _WeatherScreenState createState() => _WeatherScreenState();
// }

// class _WeatherScreenState extends State<WeatherScreen> {
//   // TODO: Déclarer les variables d'état
//   // Variables nécessaires:
//   // - cityName (String): nom de la ville
//   // - temperature (String): température actuelle
//   // - description (String): description météo
//   // - humidity (String): humidité
//   // - windSpeed (String): vitesse du vent
//   // - pressure (String): pression atmosphérique
//   // - iconCode (String): code de l'icône météo
//   // - isLoading (bool): état de chargement
//   // - cityController (TextEditingController): contrôleur pour le champ de saisie
//   String cityName = 'KARA';
//   String temperature = '--';
//   String description = 'Chargement...';
//   String humidity = '--';
//   String windSpeed = '--';
//   String pressure = '--';
//   String iconCode = '01d';
//   bool isLoading = false;
//   TextEditingController cityController = TextEditingController();
//   // TODO: Remplacer par votre clé API OpenWeatherMap
//   final String apiKey = 'fbeeab593978dd43e3b5dfbec1fa7640';

//   @override
//   void initState() {
//     super.initState();
//     fetchWeatherData();
//     // TODO: Appeler fetchWeatherData() au démarrage
//   }

//   // TODO: Implémenter la fonction pour récupérer les données météo
//   // Cette fonction doit:
//   // 1. Mettre isLoading à true
//   // 2. Construire l'URL de l'API OpenWeatherMap
//   // 3. Faire la requête HTTP
//   // 4. Traiter la réponse JSON
//   // 5. Mettre à jour les variables d'état
//   // 6. Gérer les erreurs
//   Future<void> fetchWeatherData() async {
//     // URL de l'API: https://api.openweathermap.org/data/2.5/weather?q=$cityName&appid=$apiKey&units=metric&lang=fr

//     setState(() {
//       isLoading = true;
//     });
//     try {


//        setState(() {
//         temperature = '22°C';
//         description = 'Ensoleillé';
//         humidity = '65%';
//         windSpeed = '12 km/h';
//         pressure = '1013 hPa';
//         iconCode = '01d';
//         isLoading = false;
//       });
//       // Construction de l'URL de l'API
//       // final url =
//       //     'https://api.openweathermap.org/data/2.5/weather?q=$cityName&appid=$apiKey&units=metric&lang=fr';
//       // // Requête HTTP
//       // final response = await http.get(Uri.parse(url));
//       // if (response.statusCode == 200) {
//       //   final data = json.decode(response.body);
//       //   // Mise à jour des données
//       //   setState(() {
//       //     temperature = '${data['main']['temp'].round()}°C';
//       //     description = data['weather'][0]['description'];
//       //     humidity = '${data['main']['humidity']}%';
//       //     windSpeed = '${data['wind']['speed']} m/s';
//       //     pressure = '${data['main']['pressure']} hPa';
//       //     iconCode = data['weather'][0]['icon'];
//       //     isLoading = false;
//       //   });
//       // } else {
//       //   throw Exception('Erreur API: ${response.statusCode}');
//       // }
//     } catch (e) {
//       setState(() {
//         description = 'Erreur de connexion';
//         isLoading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [Colors.blue.shade400, Colors.blue.shade700],
//           ),
//         ),
//         child: SafeArea(
//           child: Column(
//             children: [
//               // TODO: Ajouter la barre de recherche
//               _buildSearchBar(),

//               // Contenu principal
//               Expanded(
//                 child: isLoading
//                     ? _buildLoadingWidget()
//                     : _buildWeatherContent(),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // TODO: Implémenter le widget barre de recherche
//   // Ce widget doit contenir:
//   // - Un Container avec un décor semi-transparent
//   // - Un TextField pour saisir le nom de la ville
//   // - Une action onSubmitted pour déclencher la recherche

//   // Widget _buildSearchBar() {
//   //   return Container(child: Text('TODO: Barre de recherche'));
//   // }
//   Widget _buildSearchBar() {
//     return Padding(
//       padding: const EdgeInsets.all(20.0),
//       child: Container(
//         decoration: BoxDecoration(
//           color: Colors.white.withOpacity(0.2),
//           borderRadius: BorderRadius.circular(25),
//         ),
//         child: TextField(
//           controller: cityController,
//           style: TextStyle(color: Colors.white),
//           decoration: InputDecoration(
//             hintText: 'Rechercher une ville...',
//             hintStyle: TextStyle(color: Colors.white70),
//             prefixIcon: Icon(Icons.search, color: Colors.white70),
//             border: InputBorder.none,
//             contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
//           ),
//           onSubmitted: (value) {
//             if (value.isNotEmpty) {
//               setState(() {
//                 cityName = value;
//               });
//               fetchWeatherData();
//             }
//           },
//         ),
//       ),
//     );
//   }

//   // TODO: Implémenter le widget de chargement
//   // Afficher un CircularProgressIndicator centré
//   Widget _buildLoadingWidget() {
//     return Center(
//       child: CircularProgressIndicator(
//         valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//       ),
//     );
//   }

//   // TODO: Implémenter le widget contenu météo
//   // Ce widget doit contenir:
//   // - Le nom de la ville
//   // - La date actuelle
//   // - L'affichage principal de la météo
//   // - Les détails météo
//   // - Le bouton d'actualisation

//   Widget _buildWeatherContent() {
//     // return Container(child: Text('TODO: Contenu météo'));

//      return SingleChildScrollView(
//  child: Column(
//  children: [
//  // Nom de la ville
//  Text(
//  cityName,
//  style: TextStyle(
//  fontSize: 32,
//  fontWeight: FontWeight.bold,
//  color: Colors.white,
//  ),
//  ),
//  SizedBox(height: 10),
//  // Date
//  Text(
//  _getCurrentDate(),
//  style: TextStyle(
//  fontSize: 16,
//  color: Colors.white70,
//  ),
//  ),
//  SizedBox(height: 30),
//  // Icône et température
//  _buildMainWeatherDisplay(),
//  SizedBox(height: 30),
//  // Détails météo
//  _buildWeatherDetails(),
//  // Bouton actualiser
//  _buildRefreshButton(),
//  ],
//  ),
//  );
//   }

//   // TODO: Implémenter l'affichage principal de la météo
//   // Ce widget doit afficher:
//   // - L'icône météo (grande taille)
//   // - La température (grand texte)
//   // - La description météo
//   Widget _buildMainWeatherDisplay() {
//    return Container(
//  padding: EdgeInsets.all(20),
//  child: Column(
//  children: [
//  Icon(
//  _getWeatherIcon(iconCode),
//  size: 100,
//  color: Colors.white,
//  ),
//  SizedBox(height: 20),
//  Text(
//  temperature,
//  style: TextStyle(
//  fontSize: 64,
//  fontWeight: FontWeight.w300,
//  color: Colors.white,
//  ),
//  ),
//  Text(
//  description,
//  style: TextStyle(
//  fontSize: 20,
//  color: Colors.white70,
//  fontWeight: FontWeight.w400,
//  ),
//  ),
//  ],
//  ),
//  );
//   }

//   // TODO: Implémenter les détails météo
//   // Ce widget doit afficher dans un container stylé:
//   // - Humidité et Vent (première ligne)
//   // - Pression et Visibilité (deuxième ligne)
//   Widget _buildWeatherDetails() {
//     return Container(
//       padding: EdgeInsets.all(20),
//       child: Column(
//         children: [
//           Icon(_getWeatherIcon(iconCode), size: 100, color: Colors.white),
//           SizedBox(height: 20),
//           Text(
//             temperature,
//             style: TextStyle(
//               fontSize: 64,
//               fontWeight: FontWeight.w300,
//               color: Colors.white,
//             ),
//           ),
//           Text(
//             description,
//             style: TextStyle(
//               fontSize: 20,
//               color: Colors.white70,
//               fontWeight: FontWeight.w400,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // TODO: Implémenter un détail météo individuel
//   // Ce widget doit afficher:
//   // - Une icône
//   // - Un label
//   // - Une valeur
//   Widget _buildWeatherDetail(String label, String value, IconData icon) {
//    return Column(
//     children: [
//       Icon(icon, color: Colors.white70, size: 30),
//       SizedBox(height: 8),
//       Text(
//         label,
//         style: TextStyle(
//           color: Colors.white70,
//           fontSize: 14,
//         ),
//       ),
//       SizedBox(height: 4),
//       Text(
//         value,
//         style: TextStyle(
//           color: Colors.white,
//           fontSize: 18,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//     ],
//   );
  
//   }

//   // TODO: Implémenter le bouton d'actualisation
//   // Un ElevatedButton avec icône et texte
//   Widget _buildRefreshButton() {
//     // return Container(child: Text('TODO: Bouton actualiser'));
//      return Padding(
//     padding: const EdgeInsets.all(20.0),
//     child: ElevatedButton(
//       onPressed: fetchWeatherData,
//       style: ElevatedButton.styleFrom(
//         backgroundColor: Colors.white.withOpacity(0.2),
//         foregroundColor: Colors.white,
//         padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(25),
//         ),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(Icons.refresh),
//           SizedBox(width: 10),
//           Text('Actualiser'),
//         ],
//       ),
//     ),
//   );
//   }

//   // TODO: Implémenter la fonction pour obtenir l'icône météo
//   // Mapper les codes d'icône OpenWeatherMap aux icônes Flutter
//   // Codes principaux:
//   // - 01d/01n: soleil
//   // - 02d/02n: soleil avec nuages
//   // - 03d/03n/04d/04n: nuages
//   // - 09d/09n/10d/10n: pluie
//   // - 11d/11n: orage
//   // - 13d/13n: neige
//   // - 50d/50n: brouillard
//   // IconData _getWeatherIcon(String code) {
//   //   return Icons.wb_sunny; // TODO: Implémenter le switch
//   // }

//   IconData _getWeatherIcon(String code) {
//   switch (code) {
//     case '01d':
//     case '01n':
//       return Icons.wb_sunny;
//     case '02d':
//     case '02n':
//       return CupertinoIcons.sun_min;
//     case '03d':
//     case '03n':
//     case '04d':
//     case '04n':
//       return Icons.cloud;
//     case '09d':
//     case '09n':
//     case '10d':
//     case '10n':
//       return Icons.grain;
//     case '11d':
//     case '11n':
//       return Icons.flash_on;
//     case '13d':
//     case '13n':
//       return Icons.ac_unit;
//     case '50d':
//     case '50n':
//       return Icons.foggy;
//     default:
//       return Icons.wb_sunny;
//   }
// }

//   // TODO: Implémenter la fonction pour obtenir la date actuelle
//   // Retourner la date au format: "Lundi, 15 Janvier"
//   String _getCurrentDate() {
//     // return 'TODO: Date actuelle';

//      DateTime now = DateTime.now();
//   List<String> months = [
//     'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
//     'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
//   ];
//   List<String> days = [
//     'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'
//   ];
  
//   return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
//   }
// }




















import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(WeatherApp());
}

class WeatherApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Météo App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      home: WeatherScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class WeatherScreen extends StatefulWidget {
  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  // TODO: Déclarer les variables d'état
  // Variables nécessaires:
  // - cityName (String): nom de la ville
  // - temperature (String): température actuelle
  // - description (String): description météo
  // - humidity (String): humidité
  // - windSpeed (String): vitesse du vent
  // - pressure (String): pression atmosphérique
  // - iconCode (String): code de l'icône météo
  // - isLoading (bool): état de chargement
  // - cityController (TextEditingController): contrôleur pour le champ de saisie

  // TODO: Remplacer par votre clé API OpenWeatherMap
  final String apiKey = 'VOTRE_CLE_API_ICI';

  @override
  void initState() {
    super.initState();
    // TODO: Appeler fetchWeatherData() au démarrage
  }

  // TODO: Implémenter la fonction pour récupérer les données météo
  // Cette fonction doit:
  // 1. Mettre isLoading à true
  // 2. Construire l'URL de l'API OpenWeatherMap
  // 3. Faire la requête HTTP
  // 4. Traiter la réponse JSON
  // 5. Mettre à jour les variables d'état
  // 6. Gérer les erreurs
  Future<void> fetchWeatherData() async {
    // URL de l'API: https://api.openweathermap.org/data/2.5/weather?q=$cityName&appid=$apiKey&units=metric&lang=fr
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade400,
              Colors.blue.shade700,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // TODO: Ajouter la barre de recherche
              _buildSearchBar(),
              
              // Contenu principal
              Expanded(
                child: isLoading
                    ? _buildLoadingWidget()
                    : _buildWeatherContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // TODO: Implémenter le widget barre de recherche
  // Ce widget doit contenir:
  // - Un Container avec un décor semi-transparent
  // - Un TextField pour saisir le nom de la ville
  // - Une action onSubmitted pour déclencher la recherche
  Widget _buildSearchBar() {
    return Container(
      child: Text('TODO: Barre de recherche'),
    );
  }

  // TODO: Implémenter le widget de chargement
  // Afficher un CircularProgressIndicator centré
  Widget _buildLoadingWidget() {
    return Container(
      child: Text('TODO: Widget de chargement'),
    );
  }

  // TODO: Implémenter le widget contenu météo
  // Ce widget doit contenir:
  // - Le nom de la ville
  // - La date actuelle
  // - L'affichage principal de la météo
  // - Les détails météo
  // - Le bouton d'actualisation
  Widget _buildWeatherContent() {
    return Container(
      child: Text('TODO: Contenu météo'),
    );
  }

  // TODO: Implémenter l'affichage principal de la météo
  // Ce widget doit afficher:
  // - L'icône météo (grande taille)
  // - La température (grand texte)
  // - La description météo
  Widget _buildMainWeatherDisplay() {
    return Container(
      child: Text('TODO: Affichage principal météo'),
    );
  }

  // TODO: Implémenter les détails météo
  // Ce widget doit afficher dans un container stylé:
  // - Humidité et Vent (première ligne)
  // - Pression et Visibilité (deuxième ligne)
  Widget _buildWeatherDetails() {
    return Container(
      child: Text('TODO: Détails météo'),
    );
  }

  // TODO: Implémenter un détail météo individuel
  // Ce widget doit afficher:
  // - Une icône
  // - Un label
  // - Une valeur
  Widget _buildWeatherDetail(String label, String value, IconData icon) {
    return Column(
      children: [
        Text('TODO: Détail météo'),
      ],
    );
  }

  // TODO: Implémenter le bouton d'actualisation
  // Un ElevatedButton avec icône et texte
  Widget _buildRefreshButton() {
    return Container(
      child: Text('TODO: Bouton actualiser'),
    );
  }

  // TODO: Implémenter la fonction pour obtenir l'icône météo
  // Mapper les codes d'icône OpenWeatherMap aux icônes Flutter
  // Codes principaux:
  // - 01d/01n: soleil
  // - 02d/02n: soleil avec nuages
  // - 03d/03n/04d/04n: nuages
  // - 09d/09n/10d/10n: pluie
  // - 11d/11n: orage
  // - 13d/13n: neige
  // - 50d/50n: brouillard
  IconData _getWeatherIcon(String code) {
    return Icons.wb_sunny; // TODO: Implémenter le switch
  }

  // TODO: Implémenter la fonction pour obtenir la date actuelle
  // Retourner la date au format: "Lundi, 15 Janvier"
  String _getCurrentDate() {
    return 'TODO: Date actuelle';
  }
}