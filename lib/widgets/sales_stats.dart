import 'package:flutter/material.dart';
import 'package:stock_management/helpers/database_helper.dart';
import 'package:intl/intl.dart';

class SalesStats extends StatelessWidget {
  final DateTime? specificDay;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? vendor;

  const SalesStats({
    Key? key,
    this.specificDay,
    this.startDate,
    this.endDate,
    this.vendor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0.00', 'fr_FR');
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistiques des ventes',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          FutureBuilder<double>(
            future: DatabaseHelper.getTotalCA(
              specificDay: specificDay,
              startDate: startDate,
              endDate: endDate,
              vendor: vendor,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }
              if (snapshot.hasError) {
                return Text('Erreur: ${snapshot.error}', style: TextStyle(color: Colors.red));
              }
              final totalCA = snapshot.data ?? 0.0;
              return Card(
                elevation: 2,
                child: ListTile(
                  title: Text('Chiffre d\'affaires total', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${formatter.format(totalCA)} FCFA'),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          ExpansionTile(
            title: Text('Ventes par produit', style: TextStyle(fontWeight: FontWeight.bold)),
            children: [
              FutureBuilder<List<Map<String, dynamic>>>(
                future: DatabaseHelper.getSalesByProduct(
                  specificDay: specificDay,
                  startDate: startDate,
                  endDate: endDate,
                  vendor: vendor,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  if (snapshot.hasError) {
                    return Text('Erreur: ${snapshot.error}', style: TextStyle(color: Colors.red));
                  }
                  final products = snapshot.data ?? [];
                  if (products.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Aucune vente de produit pour cette période'),
                    );
                  }
                  return Column(
                    children: products.map((product) {
                      final quantite = (product['totalQuantite'] as num?)?.toInt() ?? 0;
                      final ca = (product['totalCA'] as num?)?.toDouble() ?? 0.0;
                      return ListTile(
                        title: Text(product['nom']),
                        subtitle: Text('$quantite ${product['unite']} vendu(s)'),
                        trailing: Text('${formatter.format(ca)} FCFA'),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          ExpansionTile(
            title: Text('Ventes par vendeur', style: TextStyle(fontWeight: FontWeight.bold)),
            children: [
              FutureBuilder<List<Map<String, dynamic>>>(
                future: DatabaseHelper.getSalesByVendor(
                  specificDay: specificDay,
                  startDate: startDate,
                  endDate: endDate,
                  vendor: vendor,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  if (snapshot.hasError) {
                    return Text('Erreur: ${snapshot.error}', style: TextStyle(color: Colors.red));
                  }
                  final vendors = snapshot.data ?? [];
                  if (vendors.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Aucune vente par vendeur pour cette période'),
                    );
                  }
                  return Column(
                    children: vendors.map((vendor) {
                      final invoiceCount = (vendor['invoiceCount'] as num?)?.toInt() ?? 0;
                      final ca = (vendor['totalCA'] as num?)?.toDouble() ?? 0.0;
                      return ListTile(
                        title: Text(vendor['vendeurNom']),
                        subtitle: Text('$invoiceCount facture(s)'),
                        trailing: Text('${formatter.format(ca)} FCFA'),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}