import 'package:flutter/material.dart';

class SuppliersScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Gestion des fournisseurs (Placeholder)\n- Fiche fournisseur\n- Historique commandes\n- Suivi livraisons',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}