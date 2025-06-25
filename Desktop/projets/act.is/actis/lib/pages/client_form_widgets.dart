// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:google_fonts/google_fonts.dart';

// Widget buildGlassCard({required Widget child, required BuildContext context}) {
//   return Container(
//     padding: const EdgeInsets.all(20),
//     decoration: BoxDecoration(
//       borderRadius: BorderRadius.circular(16),
//       color: Theme.of(context).cardTheme.color,
//       border: Border.all(
//         color: Theme.of(context).cardTheme.shape is RoundedRectangleBorder &&
//                 (Theme.of(context).cardTheme.shape as RoundedRectangleBorder).borderRadius != BorderRadius.zero
//             ? (Theme.of(context).cardTheme.shape as RoundedRectangleBorder).side.color
//             : Colors.transparent,
//         width: 1,
//       ),
//       boxShadow: [
//         BoxShadow(
//           color: Colors.black.withOpacity(0.2),
//           blurRadius: 10,
//           offset: const Offset(0, 4),
//         ),
//       ],
//     ),
//     child: child,
//   );
// }

// Widget buildSectionTitle(String title, int delay, BuildContext context) {
//   return Text(
//     title,
//     style: Theme.of(context).textTheme.titleLarge,
//   ).animate().fadeIn(delay: Duration(milliseconds: delay)).slideX(begin: -0.2);
// }

// Widget buildModernTextField({
//   required TextEditingController controller,
//   required String hint,
//   required IconData icon,
//   bool isRequired = false,
//   String? Function(String?)? validator,
//   TextInputType? keyboardType,
//   int maxLines = 1,
//   int animationDelay = 0,
//   VoidCallback? onTap,
//   required BuildContext context,
// }) {
//   return Container(
//     height: maxLines == 1 ? 70 : null, // Increased height for better hint visibility
//     decoration: BoxDecoration(
//       borderRadius: BorderRadius.circular(12),
//       border: Border.all(
//         color: Theme.of(context).inputDecorationTheme.border!.borderSide.color,
//         width: 1,
//       ),
//     ),
//     child: TextFormField(
//       controller: controller,
//       validator: validator,
//       keyboardType: keyboardType,
//       maxLines: maxLines,
//       onTap: onTap,
//       readOnly: onTap != null,
//       style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 18),
//       decoration: InputDecoration(
//         hintText: isRequired ? '$hint *' : hint,
//         hintStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
//               fontSize: 16,
//               color: Theme.of(context).inputDecorationTheme.labelStyle!.color,
//             ),
//         hintMaxLines: 2, // Allow hint text to wrap
//         prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22), // Reduced icon size
//         border: InputBorder.none,
//         contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24), // Increased padding
//       ),
//     ),
//   ).animate().slideY(begin: 0.3, end: 0.0, delay: Duration(milliseconds: animationDelay), duration: const Duration(milliseconds: 400));
// }

// Widget buildModernDropdown({
//   required String value,
//   required List<String> items,
//   required String hint,
//   required ValueChanged<String?> onChanged,
//   int delay = 0,
//   required BuildContext context,
// }) {
//   return Container(
//     height: 70, // Increased height for better hint visibility
//     decoration: BoxDecoration(
//       borderRadius: BorderRadius.circular(12),
//       border: Border.all(
//         color: Theme.of(context).inputDecorationTheme.border!.borderSide.color,
//         width: 1,
//       ),
//     ),
//     child: DropdownButtonFormField<String>(
//       value: value,
//       decoration: InputDecoration(
//         hintText: hint,
//         hintStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
//               fontSize: 16,
//               color: Theme.of(context).inputDecorationTheme.labelStyle!.color,
//             ),
//         hintMaxLines: 2, // Allow hint text to wrap
//         border: InputBorder.none,
//         contentPadding: const EdgeInsets.only(left: 12, right: 12, top: 24, bottom: 24), // Increased padding
//         prefixIcon: Icon(Icons.category, color: Theme.of(context).colorScheme.primary, size: 18), // Reduced icon size
//       ),
//       dropdownColor: Theme.of(context).colorScheme.background,
//       style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 16),
//       items: items.map((String item) {
//         return DropdownMenuItem<String>(
//           value: item,
//           child: Text(
//             item,
//             overflow: TextOverflow.ellipsis,
//             style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 16),
//           ),
//         );
//       }).toList(),
//       onChanged: onChanged,
//       isExpanded: true,
//     ),
//   ).animate().slideY(begin: 0.3, delay: Duration(milliseconds: delay), duration: const Duration(milliseconds: 400));
// }

// Widget buildModernHeader(BuildContext context) {
//   return Container(
//     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//     child: Row(
//       children: [
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'NOUVEAU CLIENT',
//                 style: Theme.of(context).textTheme.titleLarge!.copyWith(
//                       fontFamily: GoogleFonts.roboto().fontFamily,
//                       letterSpacing: 2,
//                     ),
//               ),
//               const SizedBox(height: 4),
//               Text(
//                 'Les informations du client',
//                 style: Theme.of(context).textTheme.titleSmall!.copyWith(
//                       color: Theme.of(context).colorScheme.primary,
//                       letterSpacing: 1,
//                     ),
//               ),
//             ],
//           ),
//         ),
//         Container(
//           // width: 48,
//           // height: 48,
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(12),
//             gradient: LinearGradient(
//               colors: [
//                 Theme.of(context).colorScheme.primary,
//                 Theme.of(context).colorScheme.primary.withOpacity(0.7),
//               ],
//             ),
//           ),
//           // child: const Icon(Icons.person_add, color: Colors.white),
//         ).animate().scale(delay: const Duration(milliseconds: 300)),
//       ],
//     ),
//   );
// }

// Widget buildFuturisticSaveButton(BuildContext context, VoidCallback onPressed) {
//   return Container(
//     padding: const EdgeInsets.all(20),
//     child: Container(
//       height: 56,
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(16),
//         gradient: LinearGradient(
//           colors: [
//             Theme.of(context).colorScheme.primary,
//             Theme.of(context).colorScheme.primary.withOpacity(0.7),
//           ],
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
//             blurRadius: 20,
//             offset: const Offset(0, 8),
//           ),
//         ],
//       ),
//       child: ElevatedButton(
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Colors.transparent,
//           shadowColor: Colors.transparent,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         ),
//         onPressed: onPressed,
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(Icons.save, color: Colors.white, size: 24),
//             const SizedBox(width: 12),
//             Text(
//               'ENREGISTRER CLIENT',
//               style: Theme.of(context).textTheme.labelLarge!.copyWith(
//                     color: Colors.white,
//                     letterSpacing: 1,
//                   ),
//             ),
//           ],
//         ),
//       ),
//     ).animate().scale(delay: const Duration(milliseconds: 2200)).then().shimmer(duration: const Duration(milliseconds: 2000)),
//   );
// }






// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:image_picker/image_picker.dart';
// import 'dart:io';

// Widget buildGlassCard({required Widget child, required BuildContext context}) {
//   return Container(
//     padding: const EdgeInsets.all(20),
//     decoration: BoxDecoration(
//       borderRadius: BorderRadius.circular(16),
//       color: Theme.of(context).cardTheme.color,
//       border: Border.all(
//         color: Theme.of(context).cardTheme.shape is RoundedRectangleBorder &&
//                 (Theme.of(context).cardTheme.shape as RoundedRectangleBorder).borderRadius != BorderRadius.zero
//             ? (Theme.of(context).cardTheme.shape as RoundedRectangleBorder).side.color
//             : Colors.transparent,
//         width: 1,
//       ),
//       boxShadow: [
//         BoxShadow(
//           color: Colors.black.withOpacity(0.2),
//           blurRadius: 10,
//           offset: const Offset(0, 4),
//         ),
//       ],
//     ),
//     child: child,
//   );
// }

// Widget buildSectionTitle(String title, int delay, BuildContext context) {
//   return Text(
//     title,
//     style: Theme.of(context).textTheme.titleLarge,
//   ).animate().fadeIn(delay: Duration(milliseconds: delay)).slideX(begin: -0.2);
// }

// Widget buildModernTextField({
//   required TextEditingController controller,
//   required String hint,
//   required IconData icon,
//   bool isRequired = false,
//   String? Function(String?)? validator,
//   TextInputType? keyboardType,
//   int maxLines = 1,
//   int animationDelay = 0,
//   VoidCallback? onTap,
//   required BuildContext context,
// }) {
//   return Container(
//     height: maxLines == 1 ? 70 : null,
//     decoration: BoxDecoration(
//       borderRadius: BorderRadius.circular(12),
//       border: Border.all(
//         color: Theme.of(context).inputDecorationTheme.border!.borderSide.color,
//         width: 1,
//       ),
//     ),
//     child: TextFormField(
//       controller: controller,
//       validator: validator,
//       keyboardType: keyboardType,
//       maxLines: maxLines,
//       onTap: onTap,
//       readOnly: onTap != null,
//       style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 18),
//       decoration: InputDecoration(
//         hintText: isRequired ? '$hint *' : hint,
//         hintStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
//               fontSize: 16,
//               color: Theme.of(context).inputDecorationTheme.labelStyle!.color,
//             ),
//         hintMaxLines: 2,
//         prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
//         border: InputBorder.none,
//         contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
//       ),
//     ),
//   ).animate().slideY(begin: 0.3, end: 0.0, delay: Duration(milliseconds: animationDelay), duration: const Duration(milliseconds: 400));
// }

// Widget buildModernDropdown({
//   required String value,
//   required List<String> items,
//   required String hint,
//   required ValueChanged<String?> onChanged,
//   int delay = 0,
//   required BuildContext context,
// }) {
//   return Container(
//     height: 70,
//     decoration: BoxDecoration(
//       borderRadius: BorderRadius.circular(12),
//       border: Border.all(
//         color: Theme.of(context).inputDecorationTheme.border!.borderSide.color,
//         width: 1,
//       ),
//     ),
//     child: DropdownButtonFormField<String>(
//       value: value,
//       decoration: InputDecoration(
//         hintText: hint,
//         hintStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
//               fontSize: 16,
//               color: Theme.of(context).inputDecorationTheme.labelStyle!.color,
//             ),
//         hintMaxLines: 2,
//         border: InputBorder.none,
//         contentPadding: const EdgeInsets.only(left: 12, right: 12, top: 24, bottom: 24),
//         prefixIcon: Icon(Icons.category, color: Theme.of(context).colorScheme.primary, size: 18),
//       ),
//       dropdownColor: Theme.of(context).colorScheme.background,
//       style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 16),
//       items: items.map((String item) {
//         return DropdownMenuItem<String>(
//           value: item,
//           child: Text(
//             item,
//             overflow: TextOverflow.ellipsis,
//             style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 16),
//           ),
//         );
//       }).toList(),
//       onChanged: onChanged,
//       isExpanded: true,
//     ),
//   ).animate().slideY(begin: 0.3, delay: Duration(milliseconds: delay), duration: const Duration(milliseconds: 400));
// }

// Widget buildModernImagePicker({
//   required TextEditingController controller,
//   required String hint,
//   required int animationDelay,
//   required VoidCallback onPickImage,
//   required BuildContext context,
// }) {
//   return Container(
//     height: 70,
//     decoration: BoxDecoration(
//       borderRadius: BorderRadius.circular(12),
//       border: Border.all(
//         color: Theme.of(context).inputDecorationTheme.border!.borderSide.color,
//         width: 1,
//       ),
//     ),
//     child: InkWell(
//       onTap: onPickImage,
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
//         child: Row(
//           children: [
//             Icon(Icons.camera_alt, color: Theme.of(context).colorScheme.primary, size: 22),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Text(
//                 controller.text.isEmpty ? hint : controller.text.split('/').last,
//                 style: Theme.of(context).textTheme.bodyMedium!.copyWith(
//                       fontSize: 16,
//                       color: controller.text.isEmpty
//                           ? Theme.of(context).inputDecorationTheme.labelStyle!.color
//                           : Theme.of(context).textTheme.bodyMedium!.color,
//                     ),
//                 overflow: TextOverflow.ellipsis,
//                 maxLines: 2,
//               ),
//             ),
//           ],
//         ),
//       ),
//     ),
//   ).animate().slideY(begin: 0.3, end: 0.0, delay: Duration(milliseconds: animationDelay), duration: const Duration(milliseconds: 400));
// }

// Widget buildModernHeader(BuildContext context) {
//   return Container(
//     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//     child: Row(
//       children: [
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'NOUVEAU CLIENT',
//                 style: Theme.of(context).textTheme.titleLarge!.copyWith(
//                       fontFamily: GoogleFonts.roboto().fontFamily,
//                       letterSpacing: 2,
//                     ),
//               ),
//               const SizedBox(height: 4),
//               Text(
//                 'ATELIER MODERNE',
//                 style: Theme.of(context).textTheme.titleSmall!.copyWith(
//                       color: Theme.of(context).colorScheme.primary,
//                       letterSpacing: 1,
//                     ),
//               ),
//             ],
//           ),
//         ),
//         Container(
//           width: 48,
//           height: 48,
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(12),
//             gradient: LinearGradient(
//               colors: [
//                 Theme.of(context).colorScheme.primary,
//                 Theme.of(context).colorScheme.primary.withOpacity(0.7),
//               ],
//             ),
//           ),
//           child: const Icon(Icons.person_add, color: Colors.white),
//         ).animate().scale(delay: const Duration(milliseconds: 300)),
//       ],
//     ),
//   );
// }

// Widget buildFuturisticSaveButton(BuildContext context, VoidCallback onPressed) {
//   return Container(
//     padding: const EdgeInsets.all(20),
//     child: Container(
//       height: 56,
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(16),
//         gradient: LinearGradient(
//           colors: [
//             Theme.of(context).colorScheme.primary,
//             Theme.of(context).colorScheme.primary.withOpacity(0.7),
//           ],
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
//             blurRadius: 20,
//             offset: const Offset(0, 8),
//           ),
//         ],
//       ),
//       child: ElevatedButton(
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Colors.transparent,
//           shadowColor: Colors.transparent,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         ),
//         onPressed: onPressed,
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(Icons.save, color: Colors.white, size: 24),
//             const SizedBox(width: 12),
//             Text(
//               'ENREGISTRER CLIENT',
//               style: Theme.of(context).textTheme.labelLarge!.copyWith(
//                     color: Colors.white,
//                     letterSpacing: 1,
//                   ),
//             ),
//           ],
//         ),
//       ),
//     ).animate().scale(delay: const Duration(milliseconds: 2200)).then().shimmer(duration: const Duration(milliseconds: 2000)),
//   );
// }







import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

Widget buildGlassCard({required Widget child, required BuildContext context}) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      color: Theme.of(context).cardTheme.color,
      border: Border.all(
        color: Theme.of(context).cardTheme.shape is RoundedRectangleBorder &&
                (Theme.of(context).cardTheme.shape as RoundedRectangleBorder).borderRadius != BorderRadius.zero
            ? (Theme.of(context).cardTheme.shape as RoundedRectangleBorder).side.color
            : Colors.transparent,
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: child,
  );
}

Widget buildSectionTitle(String title, int delay, BuildContext context) {
  return Text(
    title,
    style: Theme.of(context).textTheme.titleLarge,
  ).animate().fadeIn(delay: Duration(milliseconds: delay)).slideX(begin: -0.2);
}

Widget buildModernTextField({
  required TextEditingController controller,
  required String hint,
  required IconData icon,
  bool isRequired = false,
  String? Function(String?)? validator,
  TextInputType? keyboardType,
  int maxLines = 1,
  int animationDelay = 0,
  VoidCallback? onTap,
  required BuildContext context,
}) {
  return Container(
    height: maxLines == 1 ? 70 : null,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: Theme.of(context).inputDecorationTheme.border!.borderSide.color,
        width: 1,
      ),
    ),
    child: TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onTap: onTap,
      readOnly: onTap != null,
      style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 18),
      decoration: InputDecoration(
        hintText: isRequired ? '$hint *' : hint,
        hintStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
              fontSize: 16,
              color: Theme.of(context).inputDecorationTheme.labelStyle!.color,
            ),
        hintMaxLines: 2,
        prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      ),
    ),
  ).animate().slideY(begin: 0.3, end: 0.0, delay: Duration(milliseconds: animationDelay), duration: const Duration(milliseconds: 400));
}

Widget buildModernDropdown({
  required String value,
  required List<String> items,
  required String hint,
  required ValueChanged<String?> onChanged,
  int delay = 0,
  required BuildContext context,
}) {
  return Container(
    height: 70,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: Theme.of(context).inputDecorationTheme.border!.borderSide.color,
        width: 1,
      ),
    ),
    child: DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
              fontSize: 16,
              color: Theme.of(context).inputDecorationTheme.labelStyle!.color,
            ),
        hintMaxLines: 2,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.only(left: 12, right: 12, top: 24, bottom: 24),
        prefixIcon: Icon(Icons.category, color: Theme.of(context).colorScheme.primary, size: 18),
      ),
      dropdownColor: Theme.of(context).colorScheme.background,
      style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 16),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 16),
          ),
        );
      }).toList(),
      onChanged: onChanged,
      isExpanded: true,
    ),
  ).animate().slideY(begin: 0.3, delay: Duration(milliseconds: delay), duration: const Duration(milliseconds: 400));
}

Widget buildModernMultiSelect({
  required List<String> selectedValues,
  required List<String> items,
  required String hint,
  required ValueChanged<List<String>> onChanged,
  int delay = 0,
  required BuildContext context,
}) {
  return Container(
    height: 70,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: Theme.of(context).inputDecorationTheme.border!.borderSide.color,
        width: 1,
      ),
    ),
    child: InkWell(
      onTap: () async {
        final result = await showDialog<List<String>>(
          context: context,
          builder: (context) {
            List<String> tempSelected = List.from(selectedValues);
            return AlertDialog(
              title: Text(hint),
              content: SingleChildScrollView(
                child: Column(
                  children: items.map((item) {
                    return CheckboxListTile(
                      title: Text(item),
                      value: tempSelected.contains(item),
                      onChanged: (bool? value) {
                        if (value == true) {
                          tempSelected.add(item);
                        } else {
                          tempSelected.remove(item);
                        }
                        Navigator.pop(context, tempSelected);
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, selectedValues),
                  child: const Text('Annuler'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, tempSelected),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
        if (result != null) {
          onChanged(result);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Row(
          children: [
            Icon(Icons.design_services, color: Theme.of(context).colorScheme.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selectedValues.isEmpty ? hint : selectedValues.join(', '),
                style: TextStyle(
                  fontSize: 16,
                  color: selectedValues.isEmpty
                      ? Theme.of(context).inputDecorationTheme.labelStyle!.color
                      : Theme.of(context).textTheme.bodyMedium!.color,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    ),
  ).animate().slideY(begin: 0.3, delay: Duration(milliseconds: delay), duration: const Duration(milliseconds: 400));
}

Widget buildModernImagePicker({
  required TextEditingController controller,
  required String hint,
  required int animationDelay,
  required VoidCallback onPickImage,
  required BuildContext context,
}) {
  return Container(
    height: 70,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: Theme.of(context).inputDecorationTheme.border!.borderSide.color,
        width: 1,
      ),
    ),
    child: InkWell(
      onTap: onPickImage,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Row(
          children: [
            Icon(Icons.camera_alt, color: Theme.of(context).colorScheme.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                controller.text.isEmpty ? hint : controller.text.split('/').last,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 16,
                      color: controller.text.isEmpty
                          ? Theme.of(context).inputDecorationTheme.labelStyle!.color
                          : Theme.of(context).textTheme.bodyMedium!.color,
                    ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    ),
  ).animate().slideY(begin: 0.3, end: 0.0, delay: Duration(milliseconds: animationDelay), duration: const Duration(milliseconds: 400));
}

Widget buildModernHeader(BuildContext context, {String? title}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title ?? 'NOUVEAU CLIENT',
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      fontFamily: GoogleFonts.roboto().fontFamily,
                      letterSpacing: 2,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '* obligatoire',
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      letterSpacing: 1,
                    ),
              ),
            ],
          ),
        ),
        Container(
          // width: 48,
          // height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.7),
              ],
            ),
          ),
          // child: const Icon(Icons.person_add, color: Colors.white),
        ).animate().scale(delay: const Duration(milliseconds: 300)),
      ],
    ),
  );
}

Widget buildFuturisticSaveButton(BuildContext context, VoidCallback onPressed) {
  return Container(
    padding: const EdgeInsets.all(20),
    child: Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.7),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.save, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Text(
              'ENREGISTRER CLIENT',
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
            ),
          ],
        ),
      ),
    ).animate().scale(delay: const Duration(milliseconds: 2200)).then().shimmer(duration: const Duration(milliseconds: 2000)),
  );
}