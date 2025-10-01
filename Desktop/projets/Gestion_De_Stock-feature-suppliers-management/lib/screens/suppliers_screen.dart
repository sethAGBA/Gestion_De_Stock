import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import '../widgets/suppliers_table_widget.dart';
import '../models/models.dart';

class SuppliersScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestion des Fournisseurs'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<Supplier>>(
          future: DatabaseHelper.getSuppliers(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Erreur : \\${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('Aucun fournisseur enregistré.'));
            } else {
              return SuppliersTableWidget(suppliers: snapshot.data!);
            }
          },
        ),
      ),
    );
  }
}