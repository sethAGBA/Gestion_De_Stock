// // // import 'package:flutter/material.dart';

// // // class ClientFormController {
// // //   final formKey = GlobalKey<FormState>();
// // //   String selectedGender = 'Homme';
// // //   String selectedClientType = 'Adulte';
// // //   final List<String> genderOptions = ['Homme', 'Femme'];
// // //   final List<String> clientTypeOptions = ['Adulte', 'Enfant'];

// // //   final Map<String, TextEditingController> controllers = {
// // //     'name': TextEditingController(),
// // //     'phone': TextEditingController(),
// // //     'email': TextEditingController(),
// // //     'address': TextEditingController(),
// // //     'notes': TextEditingController(),
// // //     'profession': TextEditingController(),
// // //     'birthdate': TextEditingController(),
// // //     'height': TextEditingController(),
// // //     'weight': TextEditingController(),
// // //     'neck': TextEditingController(),
// // //     'chest': TextEditingController(),
// // //     'waist': TextEditingController(),
// // //     'hips': TextEditingController(),
// // //     'shoulder': TextEditingController(),
// // //     'armLength': TextEditingController(),
// // //     'bustLength': TextEditingController(),
// // //     'totalLength': TextEditingController(),
// // //     'armCircumference': TextEditingController(),
// // //     'wrist': TextEditingController(),
// // //     'inseam': TextEditingController(),
// // //     'pantLength': TextEditingController(),
// // //     'thigh': TextEditingController(),
// // //     'knee': TextEditingController(),
// // //     'ankle': TextEditingController(),
// // //     'buttocks': TextEditingController(),
// // //     'underBust': TextEditingController(),
// // //     'bustDistance': TextEditingController(),
// // //     'bustHeight': TextEditingController(),
// // //     'skirtLength': TextEditingController(),
// // //     'dressLength': TextEditingController(),
// // //     'calf': TextEditingController(),
// // //     'heelHeight': TextEditingController(),
// // //     'backBustLength': TextEditingController(),
// // //     'headCircumference': TextEditingController(),
// // //   };

// // //   void saveClient(BuildContext context) {
// // //     if (formKey.currentState!.validate()) {
// // //       final clientData = {
// // //         'clientType': selectedClientType,
// // //         'gender': selectedGender,
// // //         for (var entry in controllers.entries) entry.key: entry.value.text,
// // //         if (selectedGender != 'Femme') ...{
// // //           'underBust': '',
// // //           'bustDistance': '',
// // //           'bustHeight': '',
// // //           'backBustLength': '',
// // //           'dressLength': '',
// // //           'skirtLength': '',
// // //           'calf': '',
// // //           'heelHeight': '',
// // //         },
// // //         if (selectedClientType != 'Enfant') 'headCircumference': '',
// // //       };
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         SnackBar(
// // //           content: Row(
// // //             children: [
// // //               const Icon(Icons.check_circle, color: Colors.green),
// // //               const SizedBox(width: 12),
// // //               const Text('Client ajouté avec succès !'),
// // //             ],
// // //           ),
// // //           backgroundColor: Theme.of(context).colorScheme.background,
// // //           behavior: SnackBarBehavior.floating,
// // //           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
// // //         ),
// // //       );
// // //       Navigator.pop(context, clientData);
// // //     }
// // //   }

// // //   void dispose() {
// // //     for (var controller in controllers.values) {
// // //       controller.dispose();
// // //     }
// // //   }
// // // }




// // import 'package:actis/helpers/database_helper.dart';
// // import 'package:flutter/material.dart';

// // class ClientFormController {
// //   final formKey = GlobalKey<FormState>();
// //   String selectedGender = 'Homme';
// //   String selectedClientType = 'Adulte';
// //   final List<String> genderOptions = ['Homme', 'Femme'];
// //   final List<String> clientTypeOptions = ['Adulte', 'Enfant'];

// //   final Map<String, TextEditingController> controllers = {
// //     'name': TextEditingController(),
// //     'phone': TextEditingController(),
// //     'email': TextEditingController(),
// //     'address': TextEditingController(),
// //     'notes': TextEditingController(),
// //     'profession': TextEditingController(),
// //     'birthdate': TextEditingController(),
// //     'height': TextEditingController(),
// //     'weight': TextEditingController(),
// //     'neck': TextEditingController(),
// //     'chest': TextEditingController(),
// //     'waist': TextEditingController(),
// //     'hips': TextEditingController(),
// //     'shoulder': TextEditingController(),
// //     'armLength': TextEditingController(),
// //     'bustLength': TextEditingController(),
// //     'totalLength': TextEditingController(),
// //     'armCircumference': TextEditingController(),
// //     'wrist': TextEditingController(),
// //     'inseam': TextEditingController(),
// //     'pantLength': TextEditingController(),
// //     'thigh': TextEditingController(),
// //     'knee': TextEditingController(),
// //     'ankle': TextEditingController(),
// //     'buttocks': TextEditingController(),
// //     'underBust': TextEditingController(),
// //     'bustDistance': TextEditingController(),
// //     'bustHeight': TextEditingController(),
// //     'skirtLength': TextEditingController(),
// //     'dressLength': TextEditingController(),
// //     'calf': TextEditingController(),
// //     'heelHeight': TextEditingController(),
// //     'backBustLength': TextEditingController(),
// //     'headCircumference': TextEditingController(),
// //     'photo': TextEditingController(),
// //     'deliveryDate': TextEditingController(),
// //   };

// //   void saveClient(BuildContext context) async {
// //     if (formKey.currentState!.validate()) {
// //       final clientData = {
// //         'clientType': selectedClientType,
// //         'gender': selectedGender,
// //         for (var entry in controllers.entries) entry.key: entry.value.text,
// //         if (selectedGender != 'Femme') ...{
// //           'underBust': '',
// //           'bustDistance': '',
// //           'bustHeight': '',
// //           'backBustLength': '',
// //           'dressLength': '',
// //           'skirtLength': '',
// //           'calf': '',
// //           'heelHeight': '',
// //         },
// //         if (selectedClientType != 'Enfant') 'headCircumference': '',
// //       };
// //       await DatabaseHelper().insertClient(clientData);
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(
// //           content: Row(
// //             children: [
// //               const Icon(Icons.check_circle, color: Colors.green),
// //               const SizedBox(width: 12),
// //               const Text('Client ajouté avec succès !'),
// //             ],
// //           ),
// //           backgroundColor: Theme.of(context).colorScheme.background,
// //           behavior: SnackBarBehavior.floating,
// //           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
// //         ),
// //       );
// //       Navigator.pop(context, clientData);
// //     }
// //   }

// //   void dispose() {
// //     for (var controller in controllers.values) {
// //       controller.dispose();
// //     }
// //   }
// // }



// import 'package:actis/helpers/database_helper.dart';
// import 'package:flutter/material.dart';

// class ClientFormController {
//   final formKey = GlobalKey<FormState>();
//   String selectedGender = 'Homme';
//   String selectedClientType = 'Adulte';
//   List<String> selectedServices = [];
//   final List<String> genderOptions = ['Homme', 'Femme'];
//   final List<String> clientTypeOptions = ['Adulte', 'Enfant'];
//   final List<String> serviceOptions = [
//     'Retouches',
//     'Robes sur mesure',
//     'Costumes',
//     'Robes de soirée',
//     'Robes de mariée',
//     'Pantalons',
//     'Chemises',
//     'Accessoires',
//   ];

//   final Map<String, TextEditingController> controllers = {
//     'name': TextEditingController(),
//     'phone': TextEditingController(),
//     'email': TextEditingController(),
//     'address': TextEditingController(),
//     'notes': TextEditingController(),
//     'profession': TextEditingController(),
//     'birthdate': TextEditingController(),
//     'height': TextEditingController(),
//     'weight': TextEditingController(),
//     'neck': TextEditingController(),
//     'chest': TextEditingController(),
//     'waist': TextEditingController(),
//     'hips': TextEditingController(),
//     'shoulder': TextEditingController(),
//     'armLength': TextEditingController(),
//     'bustLength': TextEditingController(),
//     'totalLength': TextEditingController(),
//     'armCircumference': TextEditingController(),
//     'wrist': TextEditingController(),
//     'inseam': TextEditingController(),
//     'pantLength': TextEditingController(),
//     'thigh': TextEditingController(),
//     'knee': TextEditingController(),
//     'ankle': TextEditingController(),
//     'buttocks': TextEditingController(),
//     'underBust': TextEditingController(),
//     'bustDistance': TextEditingController(),
//     'bustHeight': TextEditingController(),
//     'skirtLength': TextEditingController(),
//     'dressLength': TextEditingController(),
//     'calf': TextEditingController(),
//     'heelHeight': TextEditingController(),
//     'backBustLength': TextEditingController(),
//     'headCircumference': TextEditingController(),
//     'photo': TextEditingController(),
//     'deliveryDate': TextEditingController(),
//   };

//   void saveClient(BuildContext context, Map<String, dynamic> clientData, {int? clientId}) async {
//     if (formKey.currentState!.validate()) {
//       final clientData = {
//         if (clientId != null) 'id': clientId,
//         'clientType': selectedClientType,
//         'gender': selectedGender,
//         'services': selectedServices.join(','),
//         for (var entry in controllers.entries) entry.key: entry.value.text,
//         if (selectedGender != 'Femme') ...{
//           'underBust': '',
//           'bustDistance': '',
//           'bustHeight': '',
//           'backBustLength': '',
//           'dressLength': '',
//           'skirtLength': '',
//           'calf': '',
//           'heelHeight': '',
//         },
//         if (selectedClientType != 'Enfant') 'headCircumference': '',
//         'createdAt': DateTime.now().toIso8601String(),
//         'status': 'active',
//       };
//       if (clientId != null) {
//         await DatabaseHelper().updateClient(clientData);
//       } else {
//         await DatabaseHelper().insertClient(clientData);
//       }
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Row(
//             children: [
//               const Icon(Icons.check_circle, color: Colors.green),
//               const SizedBox(width: 12),
//               Text(clientId != null ? 'Client modifié avec succès !' : 'Client ajouté avec succès !'),
//             ],
//           ),
//           backgroundColor: Theme.of(context).colorScheme.background,
//           behavior: SnackBarBehavior.floating,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         ),
//       );
//       Navigator.pop(context, clientData);
//     }
//   }

//   void dispose() {
//     for (var controller in controllers.values) {
//       controller.dispose();
//     }
//   }
// }



import 'package:flutter/material.dart';
import 'package:actis/helpers/database_helper.dart';
import 'package:google_fonts/google_fonts.dart';

class ClientFormController {
  final formKey = GlobalKey<FormState>();
  String selectedGender = 'Homme';
  String selectedClientType = 'Adulte';
  List<String> selectedServices = [];
  final List<String> genderOptions = ['Homme', 'Femme'];
  final List<String> clientTypeOptions = ['Adulte', 'Enfant'];
  final List<String> serviceOptions = [
    'Retouches',
    'Robes sur mesure',
    'Costumes',
    'Robes de soirée',
    'Robes de mariée',
    'Pantalons',
    'Chemises',
    'Accessoires',
  ];

  final Map<String, TextEditingController> controllers = {
    'name': TextEditingController(),
    'phone': TextEditingController(),
    'email': TextEditingController(),
    'address': TextEditingController(),
    'notes': TextEditingController(),
    'profession': TextEditingController(),
    'birthdate': TextEditingController(),
    'height': TextEditingController(),
    'weight': TextEditingController(),
    'neck': TextEditingController(),
    'chest': TextEditingController(),
    'waist': TextEditingController(),
    'hips': TextEditingController(),
    'shoulder': TextEditingController(),
    'armLength': TextEditingController(),
    'bustLength': TextEditingController(),
    'totalLength': TextEditingController(),
    'armCircumference': TextEditingController(),
    'wrist': TextEditingController(),
    'inseam': TextEditingController(),
    'pantLength': TextEditingController(),
    'thigh': TextEditingController(),
    'knee': TextEditingController(),
    'ankle': TextEditingController(),
    'buttocks': TextEditingController(),
    'underBust': TextEditingController(),
    'bustDistance': TextEditingController(),
    'bustHeight': TextEditingController(),
    'skirtLength': TextEditingController(),
    'dressLength': TextEditingController(),
    'calf': TextEditingController(),
    'heelHeight': TextEditingController(),
    'backBustLength': TextEditingController(),
    'headCircumference': TextEditingController(),
    'photo': TextEditingController(),
    'deliveryDate': TextEditingController(),
  };

  Future<void> saveClient(BuildContext context, Map<String, dynamic> clientData, {int? clientId}) async {
    if (!formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.red),
              const SizedBox(width: 12),
              const Text('Veuillez corriger les erreurs du formulaire'),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.background,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    try {
      final data = {
        if (clientId != null) 'id': clientId,
        'clientType': selectedClientType,
        'gender': selectedGender,
        'services': selectedServices.join(','),
        for (var entry in controllers.entries) entry.key: entry.value.text,
        if (selectedGender != 'Femme') ...{
          'underBust': '',
          'bustDistance': '',
          'bustHeight': '',
          'backBustLength': '',
          'dressLength': '',
          'skirtLength': '',
          'calf': '',
          'heelHeight': '',
        },
        if (selectedClientType != 'Enfant') 'headCircumference': '',
        'createdAt': clientData['createdAt'] ?? DateTime.now().toIso8601String(),
        'status': clientData['status'] ?? 'active',
      };

      if (clientId != null) {
        await DatabaseHelper().updateClient(data);
      } else {
        await DatabaseHelper().insertClient(data);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 12),
              Text(clientId != null ? 'Client modifié avec succès !' : 'Client ajouté avec succès !'),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.background,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pop(context, data);
    } catch (e) {
      debugPrint('Error saving client: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.red),
              const SizedBox(width: 12),
              Text('Erreur lors de l\'enregistrement: $e'),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.background,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      rethrow;
    }
  }

  void dispose() {
    for (var controller in controllers.values) {
      controller.dispose();
    }
  }
}