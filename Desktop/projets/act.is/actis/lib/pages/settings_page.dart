// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:provider/provider.dart';
// import '../providers/theme_provider.dart';

// class SettingsPage extends StatelessWidget {
//   const SettingsPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final themeProvider = Provider.of<ThemeProvider>(context);
//     final isDarkMode = themeProvider.themeMode == ThemeMode.dark ||
//         (themeProvider.themeMode == ThemeMode.system &&
//             MediaQuery.of(context).platformBrightness == Brightness.dark);

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
//         child: ListView(
//           children: [
//             const ListTile(
//               leading: Icon(Icons.person, color: Color(0xFF00DDEB)),
//               title: Text('Profil'),
//               trailing: Icon(Icons.arrow_forward_ios),
//             ).animate().fadeIn(delay: 100.ms),
//             const ListTile(
//               leading: Icon(Icons.notifications, color: Color(0xFF00DDEB)),
//               title: Text('Notifications'),
//               trailing: Icon(Icons.arrow_forward_ios),
//             ).animate().fadeIn(delay: 200.ms),
//             const ListTile(
//               leading: Icon(Icons.security, color: Color(0xFF00DDEB)),
//               title: Text('Sécurité'),
//               trailing: Icon(Icons.arrow_forward_ios),
//             ).animate().fadeIn(delay: 300.ms),
//             const ListTile(
//               leading: Icon(Icons.backup, color: Color(0xFF00DDEB)),
//               title: Text('Sauvegarde'),
//               trailing: Icon(Icons.arrow_forward_ios),
//             ).animate().fadeIn(delay: 400.ms),
//             ListTile(
//               leading: const Icon(Icons.brightness_6, color: Color(0xFF00DDEB)),
//               title: const Text('Thème'),
//               trailing: Switch(
//                 value: isDarkMode,
//                 onChanged: (value) {
//                   themeProvider.toggleTheme(value);
//                 },
//                 activeColor: const Color(0xFF00DDEB),
//               ),
//             ).animate().fadeIn(delay: 450.ms),
//             const Divider(),
//             ListTile(
//               leading: const Icon(Icons.info, color: Color(0xFF00DDEB)),
//               title: const Text('À propos d\'Act.is'),
//               trailing: const Icon(Icons.arrow_forward_ios),
//               onTap: () {
//                 showDialog(
//                   context: context,
//                   builder: (context) => AlertDialog(
//                     backgroundColor: Theme.of(context).colorScheme.background.withOpacity(0.9),
//                     title: const Text('Act.is'),
//                     content: const Text('Application de gestion futuriste pour tailleurs\nVersion 1.0.0'),
//                     actions: [
//                       TextButton(
//                         onPressed: () => Navigator.pop(context),
//                         child: const Text('OK', style: TextStyle(color: Color(0xFF00DDEB))),
//                       ),
//                     ],
//                   ).animate().fadeIn(duration: 300.ms),
//                 );
//               },
//             ).animate().fadeIn(delay: 500.ms),
//           ],
//         ),
//       ),
//     );
//   }
// }




// import 'package:actis/helpers/database_helper.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:provider/provider.dart';
// import '../providers/theme_provider.dart';
// import 'package:image_picker/image_picker.dart';
// import 'dart:io';

// class SettingsPage extends StatefulWidget {
//   const SettingsPage({super.key});

//   @override
//   State<SettingsPage> createState() => _SettingsPageState();
// }

// class _SettingsPageState extends State<SettingsPage> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _businessNameController = TextEditingController();
//   final TextEditingController _businessAddressController = TextEditingController();
//   final TextEditingController _businessPhoneController = TextEditingController();
//   final TextEditingController _businessEmailController = TextEditingController();
//   String? _businessLogoPath;
//   Map<String, dynamic>? _settings;

//   @override
//   void initState() {
//     super.initState();
//     _loadSettings();
//   }

//   Future<void> _loadSettings() async {
//     final settings = await DatabaseHelper().getSettings();
//     setState(() {
//       _settings = settings;
//       _businessNameController.text = settings?['businessName'] ?? 'Actis Couture';
//       _businessAddressController.text = settings?['businessAddress'] ?? '123 Rue de la Mode, Ville';
//       _businessPhoneController.text = settings?['businessPhone'] ?? '+1234567890';
//       _businessEmailController.text = settings?['businessEmail'] ?? 'contact@actiscouture.com';
//       _businessLogoPath = settings?['businessLogoPath'];
//     });
//   }

//   Future<void> _pickLogo() async {
//     final picker = ImagePicker();
//     final pickedFile = await picker.pickImage(source: ImageSource.gallery);
//     if (pickedFile != null) {
//       setState(() {
//         _businessLogoPath = pickedFile.path;
//       });
//     }
//   }

//   Future<void> _saveSettings() async {
//     if (_formKey.currentState!.validate()) {
//       final settings = {
//         'id': _settings?['id'] ?? 1,
//         'businessName': _businessNameController.text,
//         'businessAddress': _businessAddressController.text,
//         'businessPhone': _businessPhoneController.text,
//         'businessEmail': _businessEmailController.text,
//         'businessLogoPath': _businessLogoPath ?? '',
//       };
//       await DatabaseHelper().updateSettings(settings);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             'Paramètres enregistrés',
//             style: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
//           ),
//         ),
//       );
//       await _loadSettings();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final themeProvider = Provider.of<ThemeProvider>(context);
//     final isDarkMode = themeProvider.themeMode == ThemeMode.dark ||
//         (themeProvider.themeMode == ThemeMode.system &&
//             MediaQuery.of(context).platformBrightness == Brightness.dark);

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           'Paramètres',
//           style: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
//         ),
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
//         child: ListView(
//           padding: const EdgeInsets.all(16.0),
//           children: [
//             ListTile(
//               leading: const Icon(Icons.person, color: Color(0xFF00DDEB)),
//               title: const Text('Profil'),
//               trailing: const Icon(Icons.arrow_forward_ios),
//               onTap: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => const ProfileSettingsPage(),
//                   ),
//                 );
//               },
//             ).animate().fadeIn(delay: 100.ms),
//             ListTile(
//               leading: const Icon(Icons.notifications, color: Color(0xFF00DDEB)),
//               title: const Text('Notifications'),
//               trailing: const Icon(Icons.arrow_forward_ios),
//             ).animate().fadeIn(delay: 200.ms),
//             ListTile(
//               leading: const Icon(Icons.security, color: Color(0xFF00DDEB)),
//               title: const Text('Sécurité'),
//               trailing: const Icon(Icons.arrow_forward_ios),
//             ).animate().fadeIn(delay: 300.ms),
//             ListTile(
//               leading: const Icon(Icons.backup, color: Color(0xFF00DDEB)),
//               title: const Text('Sauvegarde'),
//               trailing: const Icon(Icons.arrow_forward_ios),
//             ).animate().fadeIn(delay: 400.ms),
//             ListTile(
//               leading: const Icon(Icons.brightness_6, color: Color(0xFF00DDEB)),
//               title: const Text('Thème'),
//               trailing: Switch(
//                 value: isDarkMode,
//                 onChanged: (value) {
//                   themeProvider.toggleTheme(value);
//                 },
//                 activeColor: const Color(0xFF00DDEB),
//               ),
//             ).animate().fadeIn(delay: 450.ms),
//             const Divider(),
//             ListTile(
//               leading: const Icon(Icons.info, color: Color(0xFF00DDEB)),
//               title: const Text('À propos d\'Act.is'),
//               trailing: const Icon(Icons.arrow_forward_ios),
//               onTap: () {
//                 showDialog(
//                   context: context,
//                   builder: (context) => AlertDialog(
//                     backgroundColor: Theme.of(context).colorScheme.background.withOpacity(0.9),
//                     title: const Text('Act.is'),
//                     content: const Text('Application de gestion futuriste pour tailleurs\nVersion 1.0.0'),
//                     actions: [
//                       TextButton(
//                         onPressed: () => Navigator.pop(context),
//                         child: const Text('OK', style: TextStyle(color: Color(0xFF00DDEB))),
//                       ),
//                     ],
//                   ).animate().fadeIn(duration: 300.ms),
//                 );
//               },
//             ).animate().fadeIn(delay: 500.ms),
//             const Divider(),
//             Padding(
//               padding: const EdgeInsets.symmetric(vertical: 16.0),
//               child: Form(
//                 key: _formKey,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Informations de facturation',
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         fontFamily: GoogleFonts.poppins().fontFamily,
//                       ),
//                     ).animate().fadeIn(delay: 600.ms),
//                     const SizedBox(height: 16),
//                     TextFormField(
//                       controller: _businessNameController,
//                       decoration: InputDecoration(
//                         labelText: 'Nom de l\'entreprise',
//                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                         labelStyle: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
//                       ),
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Veuillez entrer un nom';
//                         }
//                         return null;
//                       },
//                     ),
//                     const SizedBox(height: 16),
//                     TextFormField(
//                       controller: _businessAddressController,
//                       decoration: InputDecoration(
//                         labelText: 'Adresse de l\'entreprise',
//                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                         labelStyle: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
//                       ),
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Veuillez entrer une adresse';
//                         }
//                         return null;
//                       },
//                     ),
//                     const SizedBox(height: 16),
//                     TextFormField(
//                       controller: _businessPhoneController,
//                       decoration: InputDecoration(
//                         labelText: 'Téléphone de l\'entreprise',
//                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                         labelStyle: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
//                       ),
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Veuillez entrer un numéro de téléphone';
//                         }
//                         return null;
//                       },
//                     ),
//                     const SizedBox(height: 16),
//                     TextFormField(
//                       controller: _businessEmailController,
//                       decoration: InputDecoration(
//                         labelText: 'E-mail de l\'entreprise',
//                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                         labelStyle: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
//                       ),
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Veuillez entrer un e-mail';
//                         }
//                         if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
//                           return 'Veuillez entrer un e-mail valide';
//                         }
//                         return null;
//                       },
//                     ),
//                     const SizedBox(height: 16),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Expanded(
//                           flex: 2,
//                           child: Text(
//                             _businessLogoPath?.isNotEmpty == true
//                                 ? 'Logo sélectionné: ${_businessLogoPath!.split('/').last}'
//                                 : 'Aucun logo sélectionné',
//                             style: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ),
//                         const SizedBox(width: 16),
//                         Expanded(
//                           flex: 1,
//                           child: ElevatedButton(
//                             onPressed: _pickLogo,
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Theme.of(context).colorScheme.primary,
//                               foregroundColor: Colors.white,
//                               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                               minimumSize: const Size(0, 48),
//                             ),
//                             child: Text(
//                               'Choisir un logo',
//                               style: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 24),
//                     SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton(
//                         onPressed: _saveSettings,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Theme.of(context).colorScheme.primary,
//                           foregroundColor: Colors.white,
//                           padding: const EdgeInsets.symmetric(vertical: 16),
//                           minimumSize: const Size(double.infinity, 56),
//                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                         ),
//                         child: Text(
//                           'Enregistrer les paramètres',
//                           style: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily, fontSize: 16),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _businessNameController.dispose();
//     _businessAddressController.dispose();
//     _businessPhoneController.dispose();
//     _businessEmailController.dispose();
//     super.dispose();
//   }
// }

// class ProfileSettingsPage extends StatelessWidget {
//   const ProfileSettingsPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           'Profil',
//           style: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
//         ),
//       ),
//       body: const Center(
//         child: Text('Page de profil (à implémenter)'),
//       ),
//     );
//   }
// }




// import 'package:actis/helpers/database_helper.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:provider/provider.dart';
// import '../providers/theme_provider.dart';
// import 'package:image_picker/image_picker.dart';
// import 'dart:io';

// class SettingsPage extends StatefulWidget {
//   const SettingsPage({super.key});

//   @override
//   State<SettingsPage> createState() => _SettingsPageState();
// }

// class _SettingsPageState extends State<SettingsPage> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _businessNameController = TextEditingController();
//   final TextEditingController _businessAddressController = TextEditingController();
//   final TextEditingController _businessPhoneController = TextEditingController();
//   final TextEditingController _businessEmailController = TextEditingController();
//   String? _businessLogoPath;
//   Map<String, dynamic>? _settings;

//   @override
//   void initState() {
//     super.initState();
//     _loadSettings();
//   }

//   Future<void> _loadSettings() async {
//     final settings = await DatabaseHelper().getSettings();
//     setState(() {
//       _settings = settings;
//       _businessNameController.text = settings?['businessName'] ?? 'Actis Couture';
//       _businessAddressController.text = settings?['businessAddress'] ?? '123 Rue de la Mode, Ville';
//       _businessPhoneController.text = settings?['businessPhone'] ?? '+1234567890';
//       _businessEmailController.text = settings?['businessEmail'] ?? 'contact@actiscouture.com';
//       _businessLogoPath = settings?['businessLogoPath'];
//     });
//   }

//   Future<void> _pickLogo() async {
//     final picker = ImagePicker();
//     final pickedFile = await picker.pickImage(source: ImageSource.gallery);
//     if (pickedFile != null) {
//       setState(() {
//         _businessLogoPath = pickedFile.path;
//       });
//     }
//   }

//   Future<void> _saveSettings() async {
//     if (_formKey.currentState!.validate()) {
//       final settings = {
//         'id': _settings?['id'] ?? 1,
//         'businessName': _businessNameController.text,
//         'businessAddress': _businessAddressController.text,
//         'businessPhone': _businessPhoneController.text,
//         'businessEmail': _businessEmailController.text,
//         'businessLogoPath': _businessLogoPath ?? '',
//       };
//       await DatabaseHelper().updateSettings(settings);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             'Paramètres enregistrés',
//             style: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
//           ),
//         ),
//       );
//       await _loadSettings();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final themeProvider = Provider.of<ThemeProvider>(context);
//     final isDarkMode = themeProvider.themeMode == ThemeMode.dark ||
//         (themeProvider.themeMode == ThemeMode.system &&
//             MediaQuery.of(context).platformBrightness == Brightness.dark);

//     final primaryColor = Theme.of(context).colorScheme.primary;

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           'Paramètres',
//           style: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
//         ),
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
//         child: ListView(
//           padding: const EdgeInsets.all(16.0),
//           children: [
//             ListTile(
//               leading: Icon(Icons.person_outline, color: primaryColor),
//               title: const Text('Profil'),
//               trailing: Icon(Icons.arrow_forward_ios, color: primaryColor.withOpacity(0.6)),
//               onTap: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => const ProfileSettingsPage(),
//                   ),
//                 );
//               },
//             ).animate().fadeIn(delay: 100.ms),
//             ListTile(
//               leading: Icon(Icons.notifications_outlined, color: primaryColor),
//               title: const Text('Notifications'),
//               trailing: Icon(Icons.arrow_forward_ios, color: primaryColor.withOpacity(0.6)),
//             ).animate().fadeIn(delay: 200.ms),
//             ListTile(
//               leading: Icon(Icons.security_outlined, color: primaryColor),
//               title: const Text('Sécurité'),
//               trailing: Icon(Icons.arrow_forward_ios, color: primaryColor.withOpacity(0.6)),
//             ).animate().fadeIn(delay: 300.ms),
//             ListTile(
//               leading: Icon(Icons.backup_outlined, color: primaryColor),
//               title: const Text('Sauvegarde'),
//               trailing: Icon(Icons.arrow_forward_ios, color: primaryColor.withOpacity(0.6)),
//             ).animate().fadeIn(delay: 400.ms),
//             ListTile(
//               leading: Icon(Icons.brightness_6_outlined, color: primaryColor),
//               title: const Text('Thème'),
//               trailing: Switch(
//                 value: isDarkMode,
//                 onChanged: (value) {
//                   themeProvider.toggleTheme(value);
//                 },
//                 activeColor: primaryColor,
//               ),
//             ).animate().fadeIn(delay: 450.ms),
//             const Divider(),
//             ListTile(
//               leading: Icon(Icons.info_outline, color: primaryColor),
//               title: const Text('À propos d\'Act.is'),
//               trailing: Icon(Icons.arrow_forward_ios, color: primaryColor.withOpacity(0.6)),
//               onTap: () {
//                 showDialog(
//                   context: context,
//                   builder: (context) => AlertDialog(
//                     backgroundColor: Theme.of(context).colorScheme.background.withOpacity(0.9),
//                     title: const Text('Act.is'),
//                     content: const Text('Application de gestion de clients pour tailleurs \ndéveloppée par le cabinet ACTe\nVersion 1.0.0'),
//                     actions: [
//                       TextButton(
//                         onPressed: () => Navigator.pop(context),
//                         child: Text('OK', style: TextStyle(color: primaryColor)),
//                       ),
//                     ],
//                   ).animate().fadeIn(duration: 300.ms),
//                 );
//               },
//             ).animate().fadeIn(delay: 500.ms),
//             const Divider(),
//             Padding(
//               padding: const EdgeInsets.symmetric(vertical: 16.0),
//               child: Form(
//                 key: _formKey,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Icon(Icons.business_outlined, color: primaryColor, size: 24),
//                         const SizedBox(width: 12),
//                         Text(
//                           'Informations de facturation',
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                             fontFamily: GoogleFonts.poppins().fontFamily,
//                           ),
//                         ),
//                       ],
//                     ).animate().fadeIn(delay: 600.ms),
//                     const SizedBox(height: 16),
//                     TextFormField(
//                       controller: _businessNameController,
//                       decoration: InputDecoration(
//                         labelText: 'Nom de l\'entreprise',
//                         prefixIcon: Icon(Icons.business, color: primaryColor.withOpacity(0.7)),
//                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                         focusedBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: BorderSide(color: primaryColor, width: 2),
//                         ),
//                         labelStyle: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
//                       ),
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Veuillez entrer un nom';
//                         }
//                         return null;
//                       },
//                     ),
//                     const SizedBox(height: 16),
//                     TextFormField(
//                       controller: _businessAddressController,
//                       decoration: InputDecoration(
//                         labelText: 'Adresse de l\'entreprise',
//                         prefixIcon: Icon(Icons.location_on, color: primaryColor.withOpacity(0.7)),
//                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                         focusedBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: BorderSide(color: primaryColor, width: 2),
//                         ),
//                         labelStyle: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
//                       ),
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Veuillez entrer une adresse';
//                         }
//                         return null;
//                       },
//                     ),
//                     const SizedBox(height: 16),
//                     TextFormField(
//                       controller: _businessPhoneController,
//                       decoration: InputDecoration(
//                         labelText: 'Téléphone de l\'entreprise',
//                         prefixIcon: Icon(Icons.phone, color: primaryColor.withOpacity(0.7)),
//                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                         focusedBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: BorderSide(color: primaryColor, width: 2),
//                         ),
//                         labelStyle: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
//                       ),
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Veuillez entrer un numéro de téléphone';
//                         }
//                         return null;
//                       },
//                     ),
//                     const SizedBox(height: 16),
//                     TextFormField(
//                       controller: _businessEmailController,
//                       decoration: InputDecoration(
//                         labelText: 'E-mail de l\'entreprise',
//                         prefixIcon: Icon(Icons.email, color: primaryColor.withOpacity(0.7)),
//                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                         focusedBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: BorderSide(color: primaryColor, width: 2),
//                         ),
//                         labelStyle: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
//                       ),
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Veuillez entrer un e-mail';
//                         }
//                         if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
//                           return 'Veuillez entrer un e-mail valide';
//                         }
//                         return null;
//                       },
//                     ),
//                     const SizedBox(height: 16),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Expanded(
//                           flex: 2,
//                           child: Row(
//                             children: [
//                               Icon(Icons.image_outlined, color: primaryColor.withOpacity(0.7), size: 20),
//                               const SizedBox(width: 8),
//                               Expanded(
//                                 child: Text(
//                                   _businessLogoPath?.isNotEmpty == true
//                                       ? 'Logo: ${_businessLogoPath!.split('/').last}'
//                                       : 'Aucun logo sélectionné',
//                                   style: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                         const SizedBox(width: 16),
//                         Expanded(
//                           flex: 1,
//                           child: ElevatedButton.icon(
//                             onPressed: _pickLogo,
//                             icon: Icon(Icons.upload_file, size: 18),
//                             label: Text(
//                               'Choisir',
//                               style: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
//                             ),
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: primaryColor,
//                               foregroundColor: Colors.white,
//                               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
//                               minimumSize: const Size(0, 48),
//                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 24),
//                     SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton.icon(
//                         onPressed: _saveSettings,
//                         icon: Icon(Icons.save, size: 20),
//                         label: Text(
//                           'Enregistrer les paramètres',
//                           style: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily, fontSize: 16),
//                         ),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: primaryColor,
//                           foregroundColor: Colors.white,
//                           padding: const EdgeInsets.symmetric(vertical: 16),
//                           minimumSize: const Size(double.infinity, 56),
//                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _businessNameController.dispose();
//     _businessAddressController.dispose();
//     _businessPhoneController.dispose();
//     _businessEmailController.dispose();
//     super.dispose();
//   }
// }

// class ProfileSettingsPage extends StatelessWidget {
//   const ProfileSettingsPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           'Profil',
//           style: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
//         ),
//       ),
//       body: const Center(
//         child: Text('Page de profil (à implémenter)'),
//       ),
//     );
//   }
// }




import 'package:actis/helpers/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _businessAddressController = TextEditingController();
  final TextEditingController _businessPhoneController = TextEditingController();
  final TextEditingController _businessEmailController = TextEditingController();
  String? _businessLogoPath;
  Map<String, dynamic>? _settings;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await DatabaseHelper().getSettings();
    setState(() {
      _settings = settings;
      _businessNameController.text = settings?['businessName'] ?? 'Actis Couture';
      _businessAddressController.text = settings?['businessAddress'] ?? '123 Rue de la Mode, Ville';
      _businessPhoneController.text = settings?['businessPhone'] ?? '+1234567890';
      _businessEmailController.text = settings?['businessEmail'] ?? 'contact@actiscouture.com';
      _businessLogoPath = settings?['businessLogoPath'];
    });
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _businessLogoPath = pickedFile.path;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      final settings = {
        'id': _settings?['id'] ?? 1,
        'businessName': _businessNameController.text,
        'businessAddress': _businessAddressController.text,
        'businessPhone': _businessPhoneController.text,
        'businessEmail': _businessEmailController.text,
        'businessLogoPath': _businessLogoPath ?? '',
      };
      await DatabaseHelper().updateSettings(settings);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Paramètres enregistrés',
            style: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
          ),
        ),
      );
      await _loadSettings();
    }
  }

  Future<void> _launchUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        _showErrorDialog('Impossible d\'ouvrir le lien', 'Aucune application compatible trouvée.');
      }
    } catch (e) {
      _showErrorDialog('Erreur', 'Une erreur s\'est produite lors de l\'ouverture du lien.');
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.background.withOpacity(0.9),
        title: Text(
          title,
          style: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
        ),
        content: Text(
          message,
          style: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontFamily: GoogleFonts.poppins().fontFamily,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark ||
        (themeProvider.themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Paramètres',
          style: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
        ),
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
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            ListTile(
              leading: Icon(Icons.person_outline, color: primaryColor),
              title: const Text('Profil'),
              trailing: Icon(Icons.arrow_forward_ios, color: primaryColor.withOpacity(0.6)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileSettingsPage(),
                  ),
                );
              },
            ).animate().fadeIn(delay: 100.ms),
            ListTile(
              leading: Icon(Icons.notifications_outlined, color: primaryColor),
              title: const Text('Notifications'),
              trailing: Icon(Icons.arrow_forward_ios, color: primaryColor.withOpacity(0.6)),
            ).animate().fadeIn(delay: 200.ms),
            ListTile(
              leading: Icon(Icons.security_outlined, color: primaryColor),
              title: const Text('Sécurité'),
              trailing: Icon(Icons.arrow_forward_ios, color: primaryColor.withOpacity(0.6)),
            ).animate().fadeIn(delay: 300.ms),
            ListTile(
              leading: Icon(Icons.backup_outlined, color: primaryColor),
              title: const Text('Sauvegarde'),
              trailing: Icon(Icons.arrow_forward_ios, color: primaryColor.withOpacity(0.6)),
            ).animate().fadeIn(delay: 400.ms),
            ListTile(
              leading: Icon(Icons.brightness_6_outlined, color: primaryColor),
              title: const Text('Thème'),
              trailing: Switch(
                value: isDarkMode,
                onChanged: (value) {
                  themeProvider.toggleTheme(value);
                },
                activeColor: primaryColor,
              ),
            ).animate().fadeIn(delay: 450.ms),
            const Divider(),
            ListTile(
              leading: Icon(Icons.info_outline, color: primaryColor),
              title: const Text('À propos d\'Act.is'),
              trailing: Icon(Icons.arrow_forward_ios, color: primaryColor.withOpacity(0.6)),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: Theme.of(context).colorScheme.background.withOpacity(0.9),
                    title: const Text('Act.is'),
                    content: const Text('Application de gestion de clients pour tailleurs \ndéveloppée par le cabinet ACTe\nVersion 1.0.0'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('OK', style: TextStyle(color: primaryColor)),
                      ),
                    ],
                  ).animate().fadeIn(duration: 300.ms),
                );
              },
            ).animate().fadeIn(delay: 500.ms),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.business_outlined, color: primaryColor, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          'Informations de facturation',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: GoogleFonts.poppins().fontFamily,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 600.ms),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _businessNameController,
                      decoration: InputDecoration(
                        labelText: 'Nom de l\'entreprise',
                        prefixIcon: Icon(Icons.business, color: primaryColor.withOpacity(0.7)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                        labelStyle: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un nom';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _businessAddressController,
                      decoration: InputDecoration(
                        labelText: 'Adresse de l\'entreprise',
                        prefixIcon: Icon(Icons.location_on, color: primaryColor.withOpacity(0.7)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                        labelStyle: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer une adresse';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _businessPhoneController,
                      decoration: InputDecoration(
                        labelText: 'Téléphone de l\'entreprise',
                        prefixIcon: Icon(Icons.phone, color: primaryColor.withOpacity(0.7)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                        labelStyle: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un numéro de téléphone';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _businessEmailController,
                      decoration: InputDecoration(
                        labelText: 'E-mail de l\'entreprise',
                        prefixIcon: Icon(Icons.email, color: primaryColor.withOpacity(0.7)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                        labelStyle: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un e-mail';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Veuillez entrer un e-mail valide';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Row(
                            children: [
                              Icon(Icons.image_outlined, color: primaryColor.withOpacity(0.7), size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _businessLogoPath?.isNotEmpty == true
                                      ? 'Logo: ${_businessLogoPath!.split('/').last}'
                                      : 'Aucun logo sélectionné',
                                  style: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: ElevatedButton.icon(
                            onPressed: _pickLogo,
                            icon: Icon(Icons.upload_file, size: 18),
                            label: Text(
                              'Choisir',
                              style: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              minimumSize: const Size(0, 48),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saveSettings,
                        icon: Icon(Icons.save, size: 20),
                        label: Text(
                          'Enregistrer les paramètres',
                          style: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily, fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ).animate().fadeIn(delay: 700.ms),
                  ],
                ),
              ),
            ),
            
            // Section Copyright et Conditions d'utilisation
            const Divider(height: 32),
            Column(
              children: [
                // Copyright
                ListTile(
                  leading: Icon(Icons.copyright_outlined, color: primaryColor),
                  title: Text(
                    'Copyright',
                    style: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
                  ),
                  subtitle: Text(
                    '© 2024 Cabinet ACTe - Tous droits réservés',
                    style: TextStyle(
                      fontFamily: GoogleFonts.poppins().fontFamily,
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                  trailing: Icon(Icons.link, color: primaryColor.withOpacity(0.6)),
                  onTap: () => _launchUrl('https://www.cabinetacte.com'),
                ).animate().fadeIn(delay: 750.ms),
                
                // Conditions d'utilisation
                ListTile(
                  leading: Icon(Icons.description_outlined, color: primaryColor),
                  title: Text(
                    'Conditions d\'utilisation',
                    style: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
                  ),
                  subtitle: Text(
                    'Consultez nos conditions d\'utilisation',
                    style: TextStyle(
                      fontFamily: GoogleFonts.poppins().fontFamily,
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                  trailing: Icon(Icons.link, color: primaryColor.withOpacity(0.6)),
                  onTap: () => _launchUrl('https://www.cabinetacte.com'),
                ).animate().fadeIn(delay: 800.ms),
                
                // Politique de confidentialité
                ListTile(
                  leading: Icon(Icons.privacy_tip_outlined, color: primaryColor),
                  title: Text(
                    'Politique de confidentialité',
                    style: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
                  ),
                  subtitle: Text(
                    'Protection de vos données personnelles',
                    style: TextStyle(
                      fontFamily: GoogleFonts.poppins().fontFamily,
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                  trailing: Icon(Icons.link, color: primaryColor.withOpacity(0.6)),
                  onTap: () => _launchUrl('https://www.cabinetacte.com'),
                ).animate().fadeIn(delay: 850.ms),
                
                // Support technique
                ListTile(
                  leading: Icon(Icons.help_outline, color: primaryColor),
                  title: Text(
                    'Support technique',
                    style: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
                  ),
                  subtitle: Text(
                    'Besoin d\'aide ? Contactez-nous',
                    style: TextStyle(
                      fontFamily: GoogleFonts.poppins().fontFamily,
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                  trailing: Icon(Icons.link, color: primaryColor.withOpacity(0.6)),
                  onTap: () => _launchUrl('https://www.cabinetacte.com'),
                ).animate().fadeIn(delay: 900.ms),
                
                // Mentions légales
                ListTile(
                  leading: Icon(Icons.gavel_outlined, color: primaryColor),
                  title: Text(
                    'Mentions légales',
                    style: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
                  ),
                  subtitle: Text(
                    'Informations légales de l\'application',
                    style: TextStyle(
                      fontFamily: GoogleFonts.poppins().fontFamily,
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                  trailing: Icon(Icons.link, color: primaryColor.withOpacity(0.6)),
                  onTap: () => _launchUrl('https://www.cabinetacte.com'),
                ).animate().fadeIn(delay: 950.ms),
              ],
            ),
            
            // Footer avec informations du cabinet
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: primaryColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Développé par',
                    style: TextStyle(
                      fontFamily: GoogleFonts.poppins().fontFamily,
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cabinet ACTe',
                    style: TextStyle(
                      fontFamily: GoogleFonts.poppins().fontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Solutions digitales innovantes',
                    style: TextStyle(
                      fontFamily: GoogleFonts.poppins().fontFamily,
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => _launchUrl('https://www.cabinetacte.com'),
                    child: Text(
                      'www.cabinetacte.com',
                      style: TextStyle(
                        fontFamily: GoogleFonts.poppins().fontFamily,
                        color: primaryColor,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 1000.ms),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessAddressController.dispose();
    _businessPhoneController.dispose();
    _businessEmailController.dispose();
    super.dispose();
  }
}

class ProfileSettingsPage extends StatelessWidget {
  const ProfileSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profil',
          style: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
        ),
      ),
      body: const Center(
        child: Text('Page de profil (à implémenter)'),
      ),
    );
  }
}