import 'package:flutter/material.dart';

class ExitsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Sorties de stock (Placeholder)\n- Vente/Consommation interne\n- Bons de sortie\n- Retours clients\n- Historique',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}