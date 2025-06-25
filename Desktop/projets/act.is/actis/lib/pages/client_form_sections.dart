// // import 'package:flutter/material.dart';
// // import 'package:flutter_animate/flutter_animate.dart';
// // import 'client_form_controller.dart';
// // import 'client_form_widgets.dart';

// // Widget buildClientTypeSection(
// //   BuildContext context,
// //   ClientFormController controller,
// //   ValueChanged<String?> onClientTypeChanged,
// //   ValueChanged<String?> onGenderChanged,
// // ) {
// //   return buildGlassCard(
// //     context: context,
// //     child: Column(
// //       crossAxisAlignment: CrossAxisAlignment.start,
// //       children: [
// //         buildSectionTitle('👤 Type de Client', 0, context),
// //         const SizedBox(height: 16),
// //         buildModernDropdown(
// //           value: controller.selectedClientType,
// //           items: controller.clientTypeOptions,
// //           hint: 'Type de client',
// //           onChanged: onClientTypeChanged,
// //           delay: 100,
// //           context: context,
// //         ),
// //         if (controller.selectedClientType == 'Adulte') ...[
// //           const SizedBox(height: 16),
// //           buildModernDropdown(
// //             value: controller.selectedGender,
// //             items: controller.genderOptions,
// //             hint: 'Genre',
// //             onChanged: onGenderChanged,
// //             delay: 200,
// //             context: context,
// //           ),
// //         ],
// //       ],
// //     ),
// //   );
// // }

// // Widget buildPersonalInfoSection(BuildContext context, ClientFormController controller) {
// //   return buildGlassCard(
// //     context: context,
// //     child: Column(
// //       crossAxisAlignment: CrossAxisAlignment.start,
// //       children: [
// //         buildSectionTitle('📋 Informations Personnelles', 300, context),
// //         const SizedBox(height: 20),
// //         buildModernTextField(
// //           controller: controller.controllers['name']!,
// //           hint: 'Nom complet',
// //           icon: Icons.person,
// //           isRequired: true,
// //           validator: (value) {
// //             if (value == null || value.isEmpty) {
// //               return 'Veuillez entrer le nom complet';
// //             }
// //             return null;
// //           },
// //           animationDelay: 400,
// //           context: context,
// //         ),
// //         const SizedBox(height: 16),
// //         buildModernTextField(
// //           controller: controller.controllers['phone']!,
// //           hint: 'Numéro de téléphone',
// //           icon: Icons.phone,
// //           isRequired: true,
// //           keyboardType: TextInputType.phone,
// //           validator: (value) {
// //             if (value == null || value.isEmpty) {
// //               return 'Veuillez entrer le numéro';
// //             }
// //             return null;
// //           },
// //           animationDelay: 500,
// //           context: context,
// //         ),
// //         const SizedBox(height: 16),
// //         buildModernTextField(
// //           controller: controller.controllers['email']!,
// //           hint: 'Adresse email',
// //           icon: Icons.email,
// //           keyboardType: TextInputType.emailAddress,
// //           validator: (value) {
// //             if (value != null && value.isNotEmpty) {
// //               if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
// //                 return 'Email invalide';
// //               }
// //             }
// //             return null;
// //           },
// //           animationDelay: 600,
// //           context: context,
// //         ),
// //         const SizedBox(height: 16),
// //         buildModernTextField(
// //           controller: controller.controllers['address']!,
// //           hint: 'Adresse complète',
// //           icon: Icons.location_on,
// //           maxLines: 2,
// //           animationDelay: 700,
// //           context: context,
// //         ),
// //         const SizedBox(height: 16),
// //         buildModernTextField(
// //           controller: controller.controllers['birthdate']!,
// //           hint: 'Date de naissance (jj/mm/aaaa)',
// //           icon: Icons.calendar_today,
// //           onTap: () async {
// //             DateTime? picked = await showDatePicker(
// //               context: context,
// //               initialDate: DateTime.now(),
// //               firstDate: DateTime(1900),
// //               lastDate: DateTime.now(),
// //               builder: (context, child) {
// //                 return Theme(
// //                   data: Theme.of(context).copyWith(
// //                     colorScheme: Theme.of(context).colorScheme.copyWith(
// //                           primary: const Color(0xFF00DDEB),
// //                           surface: Theme.of(context).colorScheme.background,
// //                         ),
// //                   ),
// //                   child: child!,
// //                 );
// //               },
// //             );
// //             if (picked != null) {
// //               controller.controllers['birthdate']!.text = "${picked.day}/${picked.month}/${picked.year}";
// //             }
// //           },
// //           animationDelay: 800,
// //           context: context,
// //         ),
// //         const SizedBox(height: 16),
// //         buildModernTextField(
// //           controller: controller.controllers['profession']!,
// //           hint: 'Profession',
// //           icon: Icons.work,
// //           animationDelay: 900,
// //           context: context,
// //         ),
// //       ],
// //     ),
// //   );
// // }

// // Widget buildMeasurementsSection(BuildContext context, ClientFormController controller) {
// //   return buildGlassCard(
// //     context: context,
// //     child: Column(
// //       crossAxisAlignment: CrossAxisAlignment.start,
// //       children: [
// //         buildSectionTitle('📏 Mensurations', 1000, context),
// //         const SizedBox(height: 20),
// //         _buildMeasurementGroup(
// //           context,
// //           '📐 Mesures Générales',
// //           [
// //             ['Taille (cm)', controller.controllers['height']!, Icons.height, 'Taille (cm)'],
// //             ['Poids (kg)', controller.controllers['weight']!, Icons.monitor_weight, 'Poids (kg)'],
// //             ['Tour de cou (cm)', controller.controllers['neck']!, Icons.circle, 'Tour de cou (cm)'],
// //           ],
// //           1100,
// //         ),
// //         _buildMeasurementGroup(
// //           context,
// //           '👔 Torse',
// //           [
// //             ['Tour de poitrine (cm)', controller.controllers['chest']!, Icons.favorite, 'Tour de poitrine (cm)'],
// //             ['Tour de taille (cm)', controller.controllers['waist']!, Icons.circle, 'Tour de taille (cm)'],
// //             ['Tour de hanches (cm)', controller.controllers['hips']!, Icons.circle, 'Tour de hanches (cm)'],
// //             if (controller.selectedClientType == 'Adulte' && controller.selectedGender == 'Femme') ...[
// //               ['Tour sous-poitrine (cm)', controller.controllers['underBust']!, Icons.favorite_border, 'Tour sous-poitrine (cm)'],
// //               ['Distance entre seins (cm)', controller.controllers['bustDistance']!, Icons.straighten, 'Distance entre seins (cm)'],
// //               ['Hauteur poitrine (cm)', controller.controllers['bustHeight']!, Icons.height, 'Hauteur poitrine (cm)'],
// //             ],
// //             ['Carrure épaules (cm)', controller.controllers['shoulder']!, Icons.open_in_full, 'Carrure épaules (cm)'],
// //             ['Tour de fesses (cm)', controller.controllers['buttocks']!, Icons.circle, 'Tour de fesses en cm'],
// //           ],
// //           1200,
// //         ),
// //         _buildMeasurementGroup(
// //           context,
// //           '💪 Bras',
// //           [
// //             ['Longueur manche (cm)', controller.controllers['armLength']!, Icons.straighten, 'Longueur manche (cm)'],
// //             ['Tour de bras (cm)', controller.controllers['armCircumference']!, Icons.circle, 'Tour de bras (cm)'],
// //             ['Tour de poignet (cm)', controller.controllers['wrist']!, Icons.circle, 'Tour de poignet (cm)'],
// //           ],
// //           1300,
// //         ),
// //         _buildMeasurementGroup(
// //           context,
// //           '🦵 Jambes',
// //           [
// //             ['Longueur entrejambe (cm)', controller.controllers['inseam']!, Icons.straighten, 'Longueur entrejambe (cm)'],
// //             ['Longueur pantalon (cm)', controller.controllers['pantLength']!, Icons.straighten, 'Longueur pantalon (cm)'],
// //             ['Tour de cuisse (cm)', controller.controllers['thigh']!, Icons.circle, 'Tour de cuisse (cm)'],
// //             ['Tour de genou (cm)', controller.controllers['knee']!, Icons.circle, 'Tour de genou (cm)'],
// //             if (controller.selectedClientType == 'Adulte' && controller.selectedGender == 'Femme')
// //               ['Tour de mollet (cm)', controller.controllers['calf']!, Icons.circle, 'Tour de mollet (cm)'],
// //             ['Tour de cheville (cm)', controller.controllers['ankle']!, Icons.circle, 'Tour de cheville (cm)'],
// //           ],
// //           1400,
// //         ),
// //         _buildMeasurementGroup(
// //           context,
// //           '📏 Longueurs',
// //           [
// //             ['Longueur buste (cm)', controller.controllers['bustLength']!, Icons.straighten, 'Longueur buste (cm)'],
// //             if (controller.selectedClientType == 'Adulte' && controller.selectedGender == 'Femme') ...[
// //               ['Longueur buste dos (cm)', controller.controllers['backBustLength']!, Icons.straighten, 'Longueur buste dos (cm)'],
// //               ['Longueur robe (cm)', controller.controllers['dressLength']!, Icons.straighten, 'Longueur robe (cm)'],
// //               ['Longueur jupe (cm)', controller.controllers['skirtLength']!, Icons.straighten, 'Longueur jupe (cm)'],
// //               ['Hauteur talon (cm)', controller.controllers['heelHeight']!, Icons.height, 'Hauteur talon (cm)'],
// //             ],
// //             ['Longueur totale (cm)', controller.controllers['totalLength']!, Icons.straighten, 'Longueur totale (cm)'],
// //           ],
// //           1500,
// //         ),
// //         if (controller.selectedClientType == 'Enfant')
// //           _buildMeasurementGroup(
// //             context,
// //             '👶 Spécial Enfant',
// //             [
// //               ['Tour de tête (cm)', controller.controllers['headCircumference']!, Icons.circle, 'Tour de tête (cm)'],
// //             ],
// //             1600,
// //           ),
// //       ],
// //     ),
// //   );
// // }

// // Widget _buildMeasurementGroup(
// //   BuildContext context,
// //   String title,
// //   List<List<dynamic>> measurements,
// //   int baseDelay,
// // ) {
// //   return Column(
// //     crossAxisAlignment: CrossAxisAlignment.start,
// //     children: [
// //       const SizedBox(height: 16),
// //       Text(
// //         title,
// //         style: Theme.of(context).textTheme.titleMedium!.copyWith(
// //               color: Theme.of(context).colorScheme.primary.withOpacity(0.9),
// //             ),
// //       ).animate().fadeIn(delay: Duration(milliseconds: baseDelay)),
// //       const SizedBox(height: 12),
// //       ...measurements.asMap().entries.map((entry) {
// //         int index = entry.key;
// //         List<dynamic> measurement = entry.value;
// //         return Padding(
// //           padding: const EdgeInsets.only(bottom: 12),
// //           child: buildModernTextField(
// //             controller: measurement[1],
// //             hint: measurement[3],
// //             icon: measurement[2],
// //             keyboardType: TextInputType.number,
// //             animationDelay: baseDelay + (index * 50),
// //             context: context,
// //           ),
// //         );
// //       }).toList(),
// //     ],
// //   );
// // }

// // Widget buildNotesSection(BuildContext context, ClientFormController controller) {
// //   return buildGlassCard(
// //     context: context,
// //     child: Column(
// //       crossAxisAlignment: CrossAxisAlignment.start,
// //       children: [
// //         buildSectionTitle('📝 Notes', 2000, context),
// //         const SizedBox(height: 16),
// //         buildModernTextField(
// //           controller: controller.controllers['notes']!,
// //           hint: 'Notes supplémentaires',
// //           icon: Icons.note,
// //           maxLines: 4,
// //           animationDelay: 2100,
// //           context: context,
// //         ),
// //       ],
// //     ),
// //   );
// // }






// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'client_form_controller.dart';
// import 'client_form_widgets.dart';
// import 'package:image_picker/image_picker.dart';
// import 'dart:io';

// Widget buildClientTypeSection(
//   BuildContext context,
//   ClientFormController controller,
//   ValueChanged<String?> onClientTypeChanged,
//   ValueChanged<String?> onGenderChanged,
// ) {
//   return buildGlassCard(
//     context: context,
//     child: Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         buildSectionTitle('👤 Type de Client', 0, context),
//         const SizedBox(height: 16),
//         buildModernDropdown(
//           value: controller.selectedClientType,
//           items: controller.clientTypeOptions,
//           hint: 'Type de client',
//           onChanged: onClientTypeChanged,
//           delay: 100,
//           context: context,
//         ),
//         if (controller.selectedClientType == 'Adulte') ...[
//           const SizedBox(height: 16),
//           buildModernDropdown(
//             value: controller.selectedGender,
//             items: controller.genderOptions,
//             hint: 'Genre',
//             onChanged: onGenderChanged,
//             delay: 200,
//             context: context,
//           ),
//         ],
//       ],
//     ),
//   );
// }

// Widget buildPersonalInfoSection(
//   BuildContext context,
//   ClientFormController controller,
//   void Function(VoidCallback) setState,
// ) {
//   return buildGlassCard(
//     context: context,
//     child: Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         buildSectionTitle('📋 Informations Personnelles', 300, context),
//         const SizedBox(height: 20),
//         buildModernTextField(
//           controller: controller.controllers['name']!,
//           hint: 'Nom complet',
//           icon: Icons.person,
//           isRequired: true,
//           validator: (value) {
//             if (value == null || value.isEmpty) {
//               return 'Veuillez entrer le nom complet';
//             }
//             return null;
//           },
//           animationDelay: 400,
//           context: context,
//         ),
//         const SizedBox(height: 16),
//         buildModernTextField(
//           controller: controller.controllers['phone']!,
//           hint: 'Numéro de téléphone',
//           icon: Icons.phone,
//           isRequired: true,
//           keyboardType: TextInputType.phone,
//           validator: (value) {
//             if (value == null || value.isEmpty) {
//               return 'Veuillez entrer le numéro';
//             }
//             return null;
//           },
//           animationDelay: 500,
//           context: context,
//         ),
//         const SizedBox(height: 16),
//         buildModernTextField(
//           controller: controller.controllers['email']!,
//           hint: 'Adresse email',
//           icon: Icons.email,
//           keyboardType: TextInputType.emailAddress,
//           validator: (value) {
//             if (value != null && value.isNotEmpty) {
//               if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
//                 return 'Email invalide';
//               }
//             }
//             return null;
//           },
//           animationDelay: 600,
//           context: context,
//         ),
//         const SizedBox(height: 16),
//         buildModernTextField(
//           controller: controller.controllers['address']!,
//           hint: 'Adresse complète',
//           icon: Icons.location_on,
//           maxLines: 2,
//           animationDelay: 700,
//           context: context,
//         ),
//         const SizedBox(height: 16),
//         buildModernTextField(
//           controller: controller.controllers['birthdate']!,
//           hint: 'Date de naissance (jj/mm/aaaa)',
//           icon: Icons.calendar_today,
//           onTap: () async {
//             DateTime? picked = await showDatePicker(
//               context: context,
//               initialDate: DateTime.now(),
//               firstDate: DateTime(1900),
//               lastDate: DateTime.now(),
//               builder: (context, child) {
//                 return Theme(
//                   data: Theme.of(context).copyWith(
//                     colorScheme: Theme.of(context).colorScheme.copyWith(
//                           primary: const Color(0xFF00DDEB),
//                           surface: Theme.of(context).colorScheme.background,
//                         ),
//                   ),
//                   child: child!,
//                 );
//               },
//             );
//             if (picked != null) {
//               controller.controllers['birthdate']!.text = "${picked.day}/${picked.month}/${picked.year}";
//             }
//           },
//           animationDelay: 800,
//           context: context,
//         ),
//         const SizedBox(height: 16),
//         buildModernTextField(
//           controller: controller.controllers['profession']!,
//           hint: 'Profession',
//           icon: Icons.work,
//           animationDelay: 900,
//           context: context,
//         ),
//         const SizedBox(height: 16),
//         buildModernImagePicker(
//           controller: controller.controllers['photo']!,
//           hint: 'Photo du client',
//           animationDelay: 1000,
//           onPickImage: () async {
//             final picker = ImagePicker();
//             final pickedFile = await picker.pickImage(source: ImageSource.gallery);
//             if (pickedFile != null) {
//               setState(() {
//                 controller.controllers['photo']!.text = pickedFile.path;
//               });
//             }
//           },
//           context: context,
//         ),
//       ],
//     ),
//   );
// }

// Widget buildDeliverySection(BuildContext context, ClientFormController controller) {
//   return buildGlassCard(
//     context: context,
//     child: Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         buildSectionTitle('📅 Livraison', 1100, context),
//         const SizedBox(height: 16),
//         buildModernTextField(
//           controller: controller.controllers['deliveryDate']!,
//           hint: 'Date de livraison (jj/mm/aaaa)',
//           icon: Icons.event,
//           onTap: () async {
//             DateTime? picked = await showDatePicker(
//               context: context,
//               initialDate: DateTime.now(),
//               firstDate: DateTime.now(),
//               lastDate: DateTime(2100),
//               builder: (context, child) {
//                 return Theme(
//                   data: Theme.of(context).copyWith(
//                     colorScheme: Theme.of(context).colorScheme.copyWith(
//                           primary: const Color(0xFF00DDEB),
//                           surface: Theme.of(context).colorScheme.background,
//                         ),
//                   ),
//                   child: child!,
//                 );
//               },
//             );
//             if (picked != null) {
//               controller.controllers['deliveryDate']!.text = "${picked.day}/${picked.month}/${picked.year}";
//             }
//           },
//           animationDelay: 1200,
//           context: context,
//         ),
//       ],
//     ),
//   );
// }

// Widget buildMeasurementsSection(BuildContext context, ClientFormController controller) {
//   return buildGlassCard(
//     context: context,
//     child: Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         buildSectionTitle('📏 Mensurations', 1300, context),
//         const SizedBox(height: 20),
//         _buildMeasurementGroup(
//           context,
//           '📐 Mesures Générales',
//           [
//             ['Taille (cm)', controller.controllers['height']!, Icons.height, 'Taille (cm)'],
//             ['Poids (kg)', controller.controllers['weight']!, Icons.monitor_weight, 'Poids (kg)'],
//             ['Tour de cou (cm)', controller.controllers['neck']!, Icons.circle, 'Tour de cou (cm)'],
//           ],
//           1400,
//         ),
//         _buildMeasurementGroup(
//           context,
//           '👔 Torse',
//           [
//             ['Tour de poitrine (cm)', controller.controllers['chest']!, Icons.favorite, 'Tour de poitrine (cm)'],
//             ['Tour de taille (cm)', controller.controllers['waist']!, Icons.circle, 'Tour de taille (cm)'],
//             ['Tour de hanches (cm)', controller.controllers['hips']!, Icons.circle, 'Tour de hanches (cm)'],
//             if (controller.selectedClientType == 'Adulte' && controller.selectedGender == 'Femme') ...[
//               ['Tour sous-poitrine (cm)', controller.controllers['underBust']!, Icons.favorite_border, 'Tour sous-poitrine (cm)'],
//               ['Distance entre seins (cm)', controller.controllers['bustDistance']!, Icons.straighten, 'Distance entre seins (cm)'],
//               ['Hauteur poitrine (cm)', controller.controllers['bustHeight']!, Icons.height, 'Hauteur poitrine (cm)'],
//             ],
//             ['Carrure épaules (cm)', controller.controllers['shoulder']!, Icons.open_in_full, 'Carrure épaules (cm)'],
//             ['Tour de fesses (cm)', controller.controllers['buttocks']!, Icons.circle, 'Tour de fesses (cm)'],
//           ],
//           1500,
//         ),
//         _buildMeasurementGroup(
//           context,
//           '💪 Bras',
//           [
//             ['Longueur manche (cm)', controller.controllers['armLength']!, Icons.straighten, 'Longueur manche (cm)'],
//             ['Tour de bras (cm)', controller.controllers['armCircumference']!, Icons.circle, 'Tour de bras (cm)'],
//             ['Tour de poignet (cm)', controller.controllers['wrist']!, Icons.circle, 'Tour de poignet (cm)'],
//           ],
//           1600,
//         ),
//         _buildMeasurementGroup(
//           context,
//           '🦵 Jambes',
//           [
//             ['Longueur entrejambe (cm)', controller.controllers['inseam']!, Icons.straighten, 'Longueur entrejambe (cm)'],
//             ['Longueur pantalon (cm)', controller.controllers['pantLength']!, Icons.straighten, 'Longueur pantalon (cm)'],
//             ['Tour de cuisse (cm)', controller.controllers['thigh']!, Icons.circle, 'Tour de cuisse (cm)'],
//             ['Tour de genou (cm)', controller.controllers['knee']!, Icons.circle, 'Tour de genou (cm)'],
//             if (controller.selectedClientType == 'Adulte' && controller.selectedGender == 'Femme')
//               ['Tour de mollet (cm)', controller.controllers['calf']!, Icons.circle, 'Tour de mollet (cm)'],
//             ['Tour de cheville (cm)', controller.controllers['ankle']!, Icons.circle, 'Tour de cheville (cm)'],
//           ],
//           1700,
//         ),
//         _buildMeasurementGroup(
//           context,
//           '📏 Longueurs',
//           [
//             ['Longueur buste (cm)', controller.controllers['bustLength']!, Icons.straighten, 'Longueur buste (cm)'],
//             if (controller.selectedClientType == 'Adulte' && controller.selectedGender == 'Femme') ...[
//               ['Longueur buste dos (cm)', controller.controllers['backBustLength']!, Icons.straighten, 'Longueur buste dos (cm)'],
//               ['Longueur robe (cm)', controller.controllers['dressLength']!, Icons.straighten, 'Longueur robe (cm)'],
//               ['Longueur jupe (cm)', controller.controllers['skirtLength']!, Icons.straighten, 'Longueur jupe (cm)'],
//               ['Hauteur talon (cm)', controller.controllers['heelHeight']!, Icons.height, 'Hauteur talon (cm)'],
//             ],
//             ['Longueur totale (cm)', controller.controllers['totalLength']!, Icons.straighten, 'Longueur totale (cm)'],
//           ],
//           1800,
//         ),
//         if (controller.selectedClientType == 'Enfant')
//           _buildMeasurementGroup(
//             context,
//             '👶 Spécial Enfant',
//             [
//               ['Tour de tête (cm)', controller.controllers['headCircumference']!, Icons.circle, 'Tour de tête (cm)'],
//             ],
//             1900,
//           ),
//       ],
//     ),
//   );
// }

// Widget _buildMeasurementGroup(
//   BuildContext context,
//   String title,
//   List<List<dynamic>> measurements,
//   int baseDelay,
// ) {
//   return Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//       const SizedBox(height: 16),
//       Text(
//         title,
//         style: Theme.of(context).textTheme.titleMedium!.copyWith(
//               color: Theme.of(context).colorScheme.primary.withOpacity(0.9),
//             ),
//       ).animate().fadeIn(delay: Duration(milliseconds: baseDelay)),
//       const SizedBox(height: 12),
//       ...measurements.asMap().entries.map((entry) {
//         int index = entry.key;
//         List<dynamic> measurement = entry.value;
//         return Padding(
//           padding: const EdgeInsets.only(bottom: 12),
//           child: buildModernTextField(
//             controller: measurement[1],
//             hint: measurement[3],
//             icon: measurement[2],
//             keyboardType: TextInputType.number,
//             animationDelay: baseDelay + (index * 50),
//             context: context,
//           ),
//         );
//       }).toList(),
//     ],
//   );
// }

// Widget buildNotesSection(BuildContext context, ClientFormController controller) {
//   return buildGlassCard(
//     context: context,
//     child: Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         buildSectionTitle('📝 Notes', 2000, context),
//         const SizedBox(height: 16),
//         buildModernTextField(
//           controller: controller.controllers['notes']!,
//           hint: 'Notes supplémentaires',
//           icon: Icons.note,
//           maxLines: 4,
//           animationDelay: 2100,
//           context: context,
//         ),
//       ],
//     ),
//   );
// }






import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'client_form_controller.dart';
import 'client_form_widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

Widget buildClientTypeSection(
  BuildContext context,
  ClientFormController controller,
  ValueChanged<String?> onClientTypeChanged,
  ValueChanged<String?> onGenderChanged,
  ValueChanged<List<String>> onServicesChanged,
) {
  return buildGlassCard(
    context: context,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildSectionTitle('👤 Type de Client', 0, context),
        const SizedBox(height: 16),
        buildModernDropdown(
          value: controller.selectedClientType,
          items: controller.clientTypeOptions,
          hint: 'Type de client',
          onChanged: onClientTypeChanged,
          delay: 100,
          context: context,
        ),
        if (controller.selectedClientType == 'Adulte') ...[
          const SizedBox(height: 16),
          buildModernDropdown(
            value: controller.selectedGender,
            items: controller.genderOptions,
            hint: 'Genre',
            onChanged: onGenderChanged,
            delay: 200,
            context: context,
          ),
        ],
        const SizedBox(height: 16),
        buildModernMultiSelect(
          selectedValues: controller.selectedServices,
          items: controller.serviceOptions,
          hint: 'Services',
          onChanged: onServicesChanged,
          delay: 300,
          context: context,
        ),
      ],
    ),
  );
}

Widget buildPersonalInfoSection(
  BuildContext context,
  ClientFormController controller,
  void Function(VoidCallback) setState,
) {
  return buildGlassCard(
    context: context,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildSectionTitle('📋 Informations Personnelles', 400, context),
        const SizedBox(height: 20),
        buildModernTextField(
          controller: controller.controllers['name']!,
          hint: 'Nom complet',
          icon: Icons.person,
          isRequired: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer le nom complet';
            }
            return null;
          },
          animationDelay: 500,
          context: context,
        ),
        const SizedBox(height: 16),
        buildModernTextField(
          controller: controller.controllers['phone']!,
          hint: 'Numéro de téléphone',
          icon: Icons.phone,
          isRequired: true,
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer le numéro';
            }
            return null;
          },
          animationDelay: 600,
          context: context,
        ),
        const SizedBox(height: 16),
        buildModernTextField(
          controller: controller.controllers['email']!,
          hint: 'Adresse email',
          icon: Icons.email,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Email invalide';
              }
            }
            return null;
          },
          animationDelay: 700,
          context: context,
        ),
        const SizedBox(height: 16),
        buildModernTextField(
          controller: controller.controllers['address']!,
          hint: 'Adresse complète',
          icon: Icons.location_on,
          maxLines: 2,
          animationDelay: 800,
          context: context,
        ),
        const SizedBox(height: 16),
        buildModernTextField(
          controller: controller.controllers['birthdate']!,
          hint: 'Date de naissance (jj/mm/aaaa)',
          icon: Icons.calendar_today,
          onTap: () async {
            DateTime? picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: Theme.of(context).colorScheme.copyWith(
                          primary: const Color(0xFF00DDEB),
                          surface: Theme.of(context).colorScheme.background,
                        ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              controller.controllers['birthdate']!.text = "${picked.day}/${picked.month}/${picked.year}";
            }
          },
          animationDelay: 900,
          context: context,
        ),
        const SizedBox(height: 16),
        buildModernTextField(
          controller: controller.controllers['profession']!,
          hint: 'Profession',
          icon: Icons.work,
          animationDelay: 1000,
          context: context,
        ),
        const SizedBox(height: 16),
        buildModernImagePicker(
          controller: controller.controllers['photo']!,
          hint: 'Photo du client',
          animationDelay: 1100,
          onPickImage: () async {
            final picker = ImagePicker();
            final pickedFile = await picker.pickImage(source: ImageSource.gallery);
            if (pickedFile != null) {
              setState(() {
                controller.controllers['photo']!.text = pickedFile.path;
              });
            }
          },
          context: context,
        ),
      ],
    ),
  );
}

Widget buildDeliverySection(BuildContext context, ClientFormController controller) {
  return buildGlassCard(
    context: context,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildSectionTitle('📅 Livraison', 1200, context),
        const SizedBox(height: 16),
        buildModernTextField(
          controller: controller.controllers['deliveryDate']!,
          hint: 'Date de livraison (jj/mm/aaaa)',
          icon: Icons.event,
          onTap: () async {
            DateTime? picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime(2100),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: Theme.of(context).colorScheme.copyWith(
                          primary: const Color(0xFF00DDEB),
                          surface: Theme.of(context).colorScheme.background,
                        ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              controller.controllers['deliveryDate']!.text = "${picked.day}/${picked.month}/${picked.year}";
            }
          },
          animationDelay: 1300,
          context: context,
        ),
      ],
    ),
  );
}

Widget buildMeasurementsSection(BuildContext context, ClientFormController controller) {
  return buildGlassCard(
    context: context,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildSectionTitle('📏 Mensurations', 1400, context),
        const SizedBox(height: 20),
        _buildMeasurementGroup(
          context,
          '📐 Mesures Générales',
          [
            ['Taille (cm)', controller.controllers['height']!, Icons.height, 'Taille (cm)'],
            ['Poids (kg)', controller.controllers['weight']!, Icons.monitor_weight, 'Poids (kg)'],
            ['Tour de cou (cm)', controller.controllers['neck']!, Icons.circle, 'Tour de cou (cm)'],
          ],
          1500,
        ),
        _buildMeasurementGroup(
          context,
          '👔 Torse',
          [
            ['Tour de poitrine (cm)', controller.controllers['chest']!, Icons.favorite, 'Tour de poitrine (cm)'],
            ['Tour de taille (cm)', controller.controllers['waist']!, Icons.circle, 'Tour de taille (cm)'],
            ['Tour de hanches (cm)', controller.controllers['hips']!, Icons.circle, 'Tour de hanches (cm)'],
            if (controller.selectedClientType == 'Adulte' && controller.selectedGender == 'Femme') ...[
              ['Tour sous-poitrine (cm)', controller.controllers['underBust']!, Icons.favorite_border, 'Tour sous-poitrine (cm)'],
              ['Distance entre seins (cm)', controller.controllers['bustDistance']!, Icons.straighten, 'Distance entre seins (cm)'],
              ['Hauteur poitrine (cm)', controller.controllers['bustHeight']!, Icons.height, 'Hauteur poitrine (cm)'],
            ],
            ['Carrure épaules (cm)', controller.controllers['shoulder']!, Icons.open_in_full, 'Carrure épaules (cm)'],
            ['Tour de fesses (cm)', controller.controllers['buttocks']!, Icons.circle, 'Tour de fesses (cm)'],
          ],
          1600,
        ),
        _buildMeasurementGroup(
          context,
          '💪 Bras',
          [
            ['Longueur manche (cm)', controller.controllers['armLength']!, Icons.straighten, 'Longueur manche (cm)'],
            ['Tour de bras (cm)', controller.controllers['armCircumference']!, Icons.circle, 'Tour de bras (cm)'],
            ['Tour de poignet (cm)', controller.controllers['wrist']!, Icons.circle, 'Tour de poignet (cm)'],
          ],
          1700,
        ),
        _buildMeasurementGroup(
          context,
          '🦵 Jambes',
          [
            ['Longueur entrejambe (cm)', controller.controllers['inseam']!, Icons.straighten, 'Longueur entrejambe (cm)'],
            ['Longueur pantalon (cm)', controller.controllers['pantLength']!, Icons.straighten, 'Longueur pantalon (cm)'],
            ['Tour de cuisse (cm)', controller.controllers['thigh']!, Icons.circle, 'Tour de cuisse (cm)'],
            ['Tour de genou (cm)', controller.controllers['knee']!, Icons.circle, 'Tour de genou (cm)'],
            if (controller.selectedClientType == 'Adulte' && controller.selectedGender == 'Femme')
              ['Tour de mollet (cm)', controller.controllers['calf']!, Icons.circle, 'Tour de mollet (cm)'],
            ['Tour de cheville (cm)', controller.controllers['ankle']!, Icons.circle, 'Tour de cheville (cm)'],
          ],
          1800,
        ),
        _buildMeasurementGroup(
          context,
          '📏 Longueurs',
          [
            ['Longueur buste (cm)', controller.controllers['bustLength']!, Icons.straighten, 'Longueur buste (cm)'],
            if (controller.selectedClientType == 'Adulte' && controller.selectedGender == 'Femme') ...[
              ['Longueur buste dos (cm)', controller.controllers['backBustLength']!, Icons.straighten, 'Longueur buste dos (cm)'],
              ['Longueur robe (cm)', controller.controllers['dressLength']!, Icons.straighten, 'Longueur robe (cm)'],
              ['Longueur jupe (cm)', controller.controllers['skirtLength']!, Icons.straighten, 'Longueur jupe (cm)'],
              ['Hauteur talon (cm)', controller.controllers['heelHeight']!, Icons.height, 'Hauteur talon (cm)'],
            ],
            ['Longueur totale (cm)', controller.controllers['totalLength']!, Icons.straighten, 'Longueur totale (cm)'],
          ],
          1900,
        ),
        if (controller.selectedClientType == 'Enfant')
          _buildMeasurementGroup(
            context,
            '👶 Spécial Enfant',
            [
              ['Tour de tête (cm)', controller.controllers['headCircumference']!, Icons.circle, 'Tour de tête (cm)'],
            ],
            2000,
          ),
      ],
    ),
  );
}

Widget _buildMeasurementGroup(
  BuildContext context,
  String title,
  List<List<dynamic>> measurements,
  int baseDelay,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 16),
      Text(
        title,
        style: Theme.of(context).textTheme.titleMedium!.copyWith(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.9),
            ),
      ).animate().fadeIn(delay: Duration(milliseconds: baseDelay)),
      const SizedBox(height: 12),
      ...measurements.asMap().entries.map((entry) {
        int index = entry.key;
        List<dynamic> measurement = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: buildModernTextField(
            controller: measurement[1],
            hint: measurement[3],
            icon: measurement[2],
            keyboardType: TextInputType.number,
            animationDelay: baseDelay + (index * 50),
            context: context,
          ),
        );
      }).toList(),
    ],
  );
}

Widget buildNotesSection(BuildContext context, ClientFormController controller) {
  return buildGlassCard(
    context: context,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildSectionTitle('📝 Notes', 2100, context),
        const SizedBox(height: 16),
        buildModernTextField(
          controller: controller.controllers['notes']!,
          hint: 'Notes supplémentaires',
          icon: Icons.note,
          maxLines: 4,
          animationDelay: 2200,
          context: context,
        ),
      ],
    ),
  );
}