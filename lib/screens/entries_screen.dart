import 'package:flutter/material.dart';

class EntriesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Entrées en stock (Placeholder)\n- Ajout manuel/Bon de livraison\n- Réception commande\n- Historique\n- Module achat (facultatif)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}