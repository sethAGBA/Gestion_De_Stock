import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class PdfService {
  static Future<File> _generatePdf({
    required String numero,
    required DateTime date,
    required String? clientNom,
    required String? clientAdresse,
    required String? magasinAdresse,
    required String vendeurNom,
    required List<Map<String, dynamic>> items,
    required double sousTotal,
    required double ristourne,
    required double total,
    required double montantPaye,
    required double resteAPayer,
    double? montantRemis,
    double? monnaie,
  }) async {
    final pdf = pw.Document();
    final formatter = NumberFormat('#,##0.00', 'fr_FR');

    final dottedLine = pw.Row(
      children: List.generate(
        40,
        (index) => pw.Container(
          width: 5,
          height: 2,
          color: PdfColors.black,
          margin: const pw.EdgeInsets.only(right: 5),
        ),
      ),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(24),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 2),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  height: 60,
                  width: 120,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'Logo',
                      style: const pw.TextStyle(color: PdfColors.grey),
                    ),
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Center(
                  child: pw.Text(
                    'FACTURE',
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 24),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Adresse Fournisseur:',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text(magasinAdresse ?? 'Non spécifié'),
                          pw.SizedBox(height: 16),
                          pw.Text('Numéro: $numero'),
                          pw.Text('Date: ${date.toString().substring(0, 10)}'),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'Client:',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text(clientNom ?? '............................'),
                          pw.Text(clientAdresse ?? 'Non spécifiée'),
                          pw.SizedBox(height: 16),
                          pw.Text('Vendeur: $vendeurNom'),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 24),
                pw.Text(
                  'Articles:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.black),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3),
                    1: const pw.FlexColumnWidth(1),
                    2: const pw.FlexColumnWidth(1),
                    3: const pw.FlexColumnWidth(1),
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Description',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Qté',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Prix Unitaire',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Total',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    ...items.map((item) {
                      final quantite = (item['quantite'] as num?)?.toInt() ?? 0;
                      final prixUnitaire = (item['prixUnitaire'] as num?)?.toDouble() ?? 0.0;
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('${item['produitNom']} (${item['unite']})'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('$quantite'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('${formatter.format(prixUnitaire)} FCFA'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                                '${formatter.format(quantite * prixUnitaire)} FCFA'),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
                pw.SizedBox(height: 24),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Sous-total: ${formatter.format(sousTotal)} FCFA'),
                        pw.Text('Ristourne: ${formatter.format(ristourne)} FCFA'),
                        pw.Text(
                          'Total: ${formatter.format(total)} FCFA',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text('Payé: ${formatter.format(montantPaye)} FCFA'),
                        if (montantRemis != null)
                          pw.Text(
                              'Montant remis: ${formatter.format(montantRemis)} FCFA'),
                        if (monnaie != null && monnaie > 0)
                          pw.Text('Monnaie: ${formatter.format(monnaie)} FCFA'),
                        pw.Text(
                            'Reste à payer: ${formatter.format(resteAPayer >= 0 ? resteAPayer : 0)} FCFA'),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 32),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Row(
                      children: [
                        pw.Text(
                          'Signature du Client',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(width: 8),
                        pw.SizedBox(
                          width: 200,
                          child: dottedLine,
                        ),
                      ],
                    ),
                    pw.Row(
                      children: [
                        pw.Text(
                          'Signature du Vendeur',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(width: 8),
                        pw.SizedBox(
                          width: 200,
                          child: dottedLine,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/facture_$numero.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static Future<void> saveFacture({
    required String numero,
    required DateTime date,
    required String? clientNom,
    required String? clientAdresse,
    required String? magasinAdresse,
    required String vendeurNom,
    required List<Map<String, dynamic>> items,
    required double sousTotal,
    required double ristourne,
    required double total,
    required double montantPaye,
    required double resteAPayer,
    double? montantRemis,
    double? monnaie,
  }) async {
    await _generatePdf(
      numero: numero,
      date: date,
      clientNom: clientNom,
      clientAdresse: clientAdresse,
      magasinAdresse: magasinAdresse,
      vendeurNom: vendeurNom,
      items: items,
      sousTotal: sousTotal,
      ristourne: ristourne,
      total: total,
      montantPaye: montantPaye,
      resteAPayer: resteAPayer,
      montantRemis: montantRemis,
      monnaie: monnaie,
    );
  }

  static Future<void> shareFacture({
    required String numero,
    required DateTime date,
    required String? clientNom,
    required String? clientAdresse,
    required String? magasinAdresse,
    required String vendeurNom,
    required List<Map<String, dynamic>> items,
    required double sousTotal,
    required double ristourne,
    required double total,
    required double montantPaye,
    required double resteAPayer,
    double? montantRemis,
    double? monnaie,
  }) async {
    final file = await _generatePdf(
      numero: numero,
      date: date,
      clientNom: clientNom,
      clientAdresse: clientAdresse,
      magasinAdresse: magasinAdresse,
      vendeurNom: vendeurNom,
      items: items,
      sousTotal: sousTotal,
      ristourne: ristourne,
      total: total,
      montantPaye: montantPaye,
      resteAPayer: resteAPayer,
      montantRemis: montantRemis,
      monnaie: monnaie,
    );
    await Share.shareXFiles([XFile(file.path)], text: 'Facture $numero');
  }

  static Future<List<int>> getPdfBytes({
    required String numero,
    required DateTime date,
    required String? clientNom,
    required String? clientAdresse,
    required String? magasinAdresse,
    required String vendeurNom,
    required List<Map<String, dynamic>> items,
    required double sousTotal,
    required double ristourne,
    required double total,
    required double montantPaye,
    required double resteAPayer,
    double? montantRemis,
    double? monnaie,
  }) async {
    final pdf = pw.Document();
    final formatter = NumberFormat('#,##0.00', 'fr_FR');

    final dottedLine = pw.Row(
      children: List.generate(
        40,
        (index) => pw.Container(
          width: 5,
          height: 2,
          color: PdfColors.black,
          margin: const pw.EdgeInsets.only(right: 5),
        ),
      ),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(24),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 2),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  height: 60,
                  width: 120,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'Logo',
                      style: const pw.TextStyle(color: PdfColors.grey),
                    ),
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Center(
                  child: pw.Text(
                    'FACTURE',
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 24),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Adresse Fournisseur:',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text(magasinAdresse ?? 'Non spécifié'),
                          pw.SizedBox(height: 16),
                          pw.Text('Numéro: $numero'),
                          pw.Text('Date: ${date.toString().substring(0, 10)}'),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'Client:',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text(clientNom ?? '............................'),
                          pw.Text(clientAdresse ?? 'Non spécifiée'),
                          pw.SizedBox(height: 16),
                          pw.Text('Vendeur: $vendeurNom'),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 24),
                pw.Text(
                  'Articles:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.black),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3),
                    1: const pw.FlexColumnWidth(1),
                    2: const pw.FlexColumnWidth(1),
                    3: const pw.FlexColumnWidth(1),
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Description',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Qté',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Prix Unitaire',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Total',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    ...items.map((item) {
                      final quantite = (item['quantite'] as num?)?.toInt() ?? 0;
                      final prixUnitaire = (item['prixUnitaire'] as num?)?.toDouble() ?? 0.0;
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('${item['produitNom']} (${item['unite']})'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('$quantite'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('${formatter.format(prixUnitaire)} FCFA'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                                '${formatter.format(quantite * prixUnitaire)} FCFA'),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
                pw.SizedBox(height: 24),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Sous-total: ${formatter.format(sousTotal)} FCFA'),
                        pw.Text('Ristourne: ${formatter.format(ristourne)} FCFA'),
                        pw.Text(
                          'Total: ${formatter.format(total)} FCFA',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text('Payé: ${formatter.format(montantPaye)} FCFA'),
                        if (montantRemis != null)
                          pw.Text(
                              'Montant remis: ${formatter.format(montantRemis)} FCFA'),
                        if (monnaie != null && monnaie > 0)
                          pw.Text('Monnaie: ${formatter.format(monnaie)} FCFA'),
                        pw.Text(
                            'Reste à payer: ${formatter.format(resteAPayer >= 0 ? resteAPayer : 0)} FCFA'),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 32),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Row(
                      children: [
                        pw.Text(
                          'Signature du Client',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(width: 8),
                        pw.SizedBox(
                          width: 200,
                          child: dottedLine,
                        ),
                      ],
                    ),
                    pw.Row(
                      children: [
                        pw.Text(
                          'Signature du Vendeur',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(width: 8),
                        pw.SizedBox(
                          width: 200,
                          child: dottedLine,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return await pdf.save();
  }

  static Future<File> saveInventory({
    required String numero,
    required DateTime date,
    required String? magasinAdresse,
    required String utilisateurNom,
    required List<Map<String, dynamic>> items,
    required double totalStockValue,
  }) async {
    final pdf = pw.Document();
    final formatter = NumberFormat('#,##0.00', 'fr_FR');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(24),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 2),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  height: 60,
                  width: 120,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'Logo',
                      style: const pw.TextStyle(color: PdfColors.grey),
                    ),
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Center(
                  child: pw.Text(
                    'RAPPORT D\'INVENTAIRE',
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 24),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Adresse Magasin:',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text(magasinAdresse ?? 'Non spécifié'),
                          pw.SizedBox(height: 16),
                          pw.Text('Numéro: $numero'),
                          pw.Text('Date: ${date.toString().substring(0, 10)}'),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'Utilisateur:',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text(utilisateurNom),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 24),
                pw.Text(
                  'Produits:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.black),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2),
                    1: const pw.FlexColumnWidth(1),
                    2: const pw.FlexColumnWidth(1),
                    3: const pw.FlexColumnWidth(1),
                    4: const pw.FlexColumnWidth(1),
                    5: const pw.FlexColumnWidth(1),
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Nom',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Catégorie',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Stock',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Avarié',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Prix Unitaire',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Valeur Stock',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    ...items.map((item) {
                      final quantiteStock = (item['quantiteStock'] as num?)?.toInt() ?? 0;
                      final quantiteAvariee = (item['quantiteAvariee'] as num?)?.toInt() ?? 0;
                      final prixVente = (item['prixVente'] as num?)?.toDouble() ?? 0.0;
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('${item['nom']} (${item['unite']})'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('${item['categorie']}'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('$quantiteStock'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('$quantiteAvariee'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('${formatter.format(prixVente)} FCFA'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                                '${formatter.format(quantiteStock * prixVente)} FCFA'),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
                pw.SizedBox(height: 24),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Valeur Totale du Stock: ${formatter.format(totalStockValue)} FCFA',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 32),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Row(
                      children: [
                        pw.Text(
                          'Signature du Responsable',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(width: 8),
                        pw.SizedBox(
                          width: 200,
                          child: pw.Row(
                            children: List.generate(
                              40,
                              (index) => pw.Container(
                                width: 5,
                                height: 2,
                                color: PdfColors.black,
                                margin: const pw.EdgeInsets.only(right: 5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    final file = File('/Users/cavris/Documents/inventaire_$numero.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}