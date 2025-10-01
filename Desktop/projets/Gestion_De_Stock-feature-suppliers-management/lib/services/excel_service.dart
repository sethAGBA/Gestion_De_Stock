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
    final times = pw.Font.times();
    final timesBold = pw.Font.timesBold();

    print('Generating invoice PDF with ${items.length} items: $items'); // Debug log

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
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) => [
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 2),
            ),
            padding: const pw.EdgeInsets.all(24),
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
                      style: pw.TextStyle(font: times, fontSize: 10, color: PdfColors.grey),
                    ),
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Center(
                  child: pw.Text(
                    'FACTURE',
                    style: pw.TextStyle(font: timesBold, fontSize: 28, fontWeight: pw.FontWeight.bold),
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
                            style: pw.TextStyle(font: timesBold, fontSize: 10, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text(
                            magasinAdresse ?? 'Non spécifié',
                            style: pw.TextStyle(font: times, fontSize: 10),
                          ),
                          pw.SizedBox(height: 16),
                          pw.Text(
                            'Numéro: $numero',
                            style: pw.TextStyle(font: times, fontSize: 10),
                          ),
                          pw.Text(
                            'Date: ${date.toString().substring(0, 10)}',
                            style: pw.TextStyle(font: times, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'Client:',
                            style: pw.TextStyle(font: timesBold, fontSize: 10, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text(
                            clientNom ?? 'Non spécifié',
                            style: pw.TextStyle(font: times, fontSize: 10),
                          ),
                          pw.Text(
                            clientAdresse ?? 'Non spécifiée',
                            style: pw.TextStyle(font: times, fontSize: 10),
                          ),
                          pw.SizedBox(height: 16),
                          pw.Text(
                            'Vendeur: $vendeurNom',
                            style: pw.TextStyle(font: times, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 24),
                pw.Text(
                  'Articles:',
                  style: pw.TextStyle(font: timesBold, fontSize: 10, fontWeight: pw.FontWeight.bold),
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
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Description',
                            style: pw.TextStyle(font: timesBold, fontSize: 8, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Qté',
                            style: pw.TextStyle(font: timesBold, fontSize: 8, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Prix Unitaire',
                            style: pw.TextStyle(font: timesBold, fontSize: 8, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Total',
                            style: pw.TextStyle(font: timesBold, fontSize: 8, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    ...items.map((item) {
                      final quantite = (item['quantite'] is num ? item['quantite'] as num : num.tryParse(item['quantite'].toString()))?.toInt() ?? 0;
                      final prixUnitaire = (item['prixUnitaire'] is num ? item['prixUnitaire'] as num : num.tryParse(item['prixUnitaire'].toString()))?.toDouble() ?? 0.0;
                      final produitNom = (item['produitNom']?.toString() ?? 'N/A').substring(0, (item['produitNom']?.toString().length ?? 0) > 50 ? 50 : null);
                      final unite = (item['unite']?.toString() ?? 'N/A').substring(0, (item['unite']?.toString().length ?? 0) > 10 ? 10 : null);
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              '$produitNom ($unite)',
                              style: pw.TextStyle(font: times, fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              '$quantite',
                              style: pw.TextStyle(font: times, fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              '${formatter.format(prixUnitaire)}\u00A0FCFA',
                              style: pw.TextStyle(font: times, fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              '${formatter.format(quantite * prixUnitaire)}\u00A0FCFA',
                              style: pw.TextStyle(font: times, fontSize: 8),
                            ),
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
                          'Sous-total: ${formatter.format(sousTotal)}\u00A0FCFA',
                          style: pw.TextStyle(font: times, fontSize: 10),
                        ),
                        pw.Text(
                          'Ristourne: ${formatter.format(ristourne)}\u00A0FCFA',
                          style: pw.TextStyle(font: times, fontSize: 10),
                        ),
                        pw.Text(
                          'Total: ${formatter.format(total)}\u00A0FCFA',
                          style: pw.TextStyle(font: timesBold, fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          'Payé: ${formatter.format(montantPaye)}\u00A0FCFA',
                          style: pw.TextStyle(font: times, fontSize: 10),
                        ),
                        if (montantRemis != null)
                          pw.Text(
                            'Montant remis: ${formatter.format(montantRemis)}\u00A0FCFA',
                            style: pw.TextStyle(font: times, fontSize: 10),
                          ),
                        if (monnaie != null && monnaie > 0)
                          pw.Text(
                            'Monnaie: ${formatter.format(monnaie)}\u00A0FCFA',
                            style: pw.TextStyle(font: times, fontSize: 10),
                          ),
                        pw.Text(
                          'Reste à payer: ${formatter.format(resteAPayer >= 0 ? resteAPayer : 0)}\u00A0FCFA',
                          style: pw.TextStyle(font: times, fontSize: 10),
                        ),
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
                          style: pw.TextStyle(font: timesBold, fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(width: 8),
                        pw.SizedBox(width: 200, child: dottedLine),
                      ],
                    ),
                    pw.Row(
                      children: [
                        pw.Text(
                          'Signature du Vendeur',
                          style: pw.TextStyle(font: timesBold, fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(width: 8),
                        pw.SizedBox(width: 200, child: dottedLine),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
    final times = pw.Font.times();
    final timesBold = pw.Font.timesBold();

    print('Generating invoice PDF bytes with ${items.length} items: $items'); // Debug log

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
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) => [
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 2),
            ),
            padding: const pw.EdgeInsets.all(24),
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
                      style: pw.TextStyle(font: times, fontSize: 10, color: PdfColors.grey),
                    ),
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Center(
                  child: pw.Text(
                    'FACTURE',
                    style: pw.TextStyle(font: timesBold, fontSize: 28, fontWeight: pw.FontWeight.bold),
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
                            style: pw.TextStyle(font: timesBold, fontSize: 10, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text(
                            magasinAdresse ?? 'Non spécifié',
                            style: pw.TextStyle(font: times, fontSize: 10),
                          ),
                          pw.SizedBox(height: 16),
                          pw.Text(
                            'Numéro: $numero',
                            style: pw.TextStyle(font: times, fontSize: 10),
                          ),
                          pw.Text(
                            'Date: ${date.toString().substring(0, 10)}',
                            style: pw.TextStyle(font: times, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'Client:',
                            style: pw.TextStyle(font: timesBold, fontSize: 10, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text(
                            clientNom ?? 'Non spécifié',
                            style: pw.TextStyle(font: times, fontSize: 10),
                          ),
                          pw.Text(
                            clientAdresse ?? 'Non spécifiée',
                            style: pw.TextStyle(font: times, fontSize: 10),
                          ),
                          pw.SizedBox(height: 16),
                          pw.Text(
                            'Vendeur: $vendeurNom',
                            style: pw.TextStyle(font: times, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 24),
                pw.Text(
                  'Articles:',
                  style: pw.TextStyle(font: timesBold, fontSize: 10, fontWeight: pw.FontWeight.bold),
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
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Description',
                            style: pw.TextStyle(font: timesBold, fontSize: 8, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Qté',
                            style: pw.TextStyle(font: timesBold, fontSize: 8, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Prix Unitaire',
                            style: pw.TextStyle(font: timesBold, fontSize: 8, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Total',
                            style: pw.TextStyle(font: timesBold, fontSize: 8, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    ...items.map((item) {
                      final quantite = (item['quantite'] is num ? item['quantite'] as num : num.tryParse(item['quantite'].toString()))?.toInt() ?? 0;
                      final prixUnitaire = (item['prixUnitaire'] is num ? item['prixUnitaire'] as num : num.tryParse(item['prixUnitaire'].toString()))?.toDouble() ?? 0.0;
                      final produitNom = (item['produitNom']?.toString() ?? 'N/A').substring(0, (item['produitNom']?.toString().length ?? 0) > 50 ? 50 : null);
                      final unite = (item['unite']?.toString() ?? 'N/A').substring(0, (item['unite']?.toString().length ?? 0) > 10 ? 10 : null);
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              '$produitNom ($unite)',
                              style: pw.TextStyle(font: times, fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              '$quantite',
                              style: pw.TextStyle(font: times, fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              '${formatter.format(prixUnitaire)}\u00A0FCFA',
                              style: pw.TextStyle(font: times, fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              '${formatter.format(quantite * prixUnitaire)}\u00A0FCFA',
                              style: pw.TextStyle(font: times, fontSize: 8),
                            ),
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
                          'Sous-total: ${formatter.format(sousTotal)}\u00A0FCFA',
                          style: pw.TextStyle(font: times, fontSize: 10),
                        ),
                        pw.Text(
                          'Ristourne: ${formatter.format(ristourne)}\u00A0FCFA',
                          style: pw.TextStyle(font: times, fontSize: 10),
                        ),
                        pw.Text(
                          'Total: ${formatter.format(total)}\u00A0FCFA',
                          style: pw.TextStyle(font: timesBold, fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          'Payé: ${formatter.format(montantPaye)}\u00A0FCFA',
                          style: pw.TextStyle(font: times, fontSize: 10),
                        ),
                        if (montantRemis != null)
                          pw.Text(
                            'Montant remis: ${formatter.format(montantRemis)}\u00A0FCFA',
                            style: pw.TextStyle(font: times, fontSize: 10),
                          ),
                        if (monnaie != null && monnaie > 0)
                          pw.Text(
                            'Monnaie: ${formatter.format(monnaie)}\u00A0FCFA',
                            style: pw.TextStyle(font: times, fontSize: 10),
                          ),
                        pw.Text(
                          'Reste à payer: ${formatter.format(resteAPayer >= 0 ? resteAPayer : 0)}\u00A0FCFA',
                          style: pw.TextStyle(font: times, fontSize: 10),
                        ),
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
                          style: pw.TextStyle(font: timesBold, fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(width: 8),
                        pw.SizedBox(width: 200, child: dottedLine),
                      ],
                    ),
                    pw.Row(
                      children: [
                        pw.Text(
                          'Signature du Vendeur',
                          style: pw.TextStyle(font: timesBold, fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(width: 8),
                        pw.SizedBox(width: 200, child: dottedLine),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
    required double totalSoldValue,
  }) async {
    final pdf = pw.Document();
    final formatter = NumberFormat('#,##0.00', 'fr_FR');
    final times = pw.Font.times();
    final timesBold = pw.Font.timesBold();

    // Cap items to prevent TooManyPagesException
    const maxItems = 1000; // Arbitrary limit; adjust based on testing
    final cappedItems = items.length > maxItems ? items.sublist(0, maxItems) : items;
    if (items.length > maxItems) {
      print('Warning: Items list truncated from ${items.length} to $maxItems to prevent TooManyPagesException');
    }

    print('Generating inventory PDF with ${cappedItems.length} items: $cappedItems'); // Debug log

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) => [
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 2),
            ),
            padding: const pw.EdgeInsets.all(24),
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
                      style: pw.TextStyle(font: times, fontSize: 10, color: PdfColors.grey),
                    ),
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Center(
                  child: pw.Text(
                    'RAPPORT D\'INVENTAIRE',
                    style: pw.TextStyle(font: timesBold, fontSize: 28, fontWeight: pw.FontWeight.bold),
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
                            style: pw.TextStyle(font: timesBold, fontSize: 10, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text(
                            magasinAdresse ?? 'Non spécifié',
                            style: pw.TextStyle(font: times, fontSize: 10),
                          ),
                          pw.SizedBox(height: 16),
                          pw.Text(
                            'Numéro: $numero',
                            style: pw.TextStyle(font: times, fontSize: 10),
                          ),
                          pw.Text(
                            'Date: ${date.toString().substring(0, 10)}',
                            style: pw.TextStyle(font: times, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'Responsable:',
                            style: pw.TextStyle(font: timesBold, fontSize: 10, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text(
                            utilisateurNom.isEmpty ? 'Non spécifié' : utilisateurNom,
                            style: pw.TextStyle(font: times, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 24),
                pw.Text(
                  'Produits:',
                  style: pw.TextStyle(font: timesBold, fontSize: 10, fontWeight: pw.FontWeight.bold),
                ),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.black),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2.5), // Nom
                    1: const pw.FlexColumnWidth(1.2), // Catégorie
                    2: const pw.FlexColumnWidth(0.8), // Stock Initial
                    3: const pw.FlexColumnWidth(0.8), // Stock
                    4: const pw.FlexColumnWidth(0.8), // Avarié
                    5: const pw.FlexColumnWidth(0.8), // Écart
                    6: const pw.FlexColumnWidth(1.0), // Prix Unitaire
                    7: const pw.FlexColumnWidth(1.0), // Valeur Stock
                    8: const pw.FlexColumnWidth(1.0), // Valeur Vendue
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Nom',
                            style: pw.TextStyle(font: timesBold, fontSize: 8, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Catégorie',
                            style: pw.TextStyle(font: timesBold, fontSize: 8, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Stock Initial',
                            style: pw.TextStyle(font: timesBold, fontSize: 8, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Stock',
                            style: pw.TextStyle(font: timesBold, fontSize: 8, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Avarié',
                            style: pw.TextStyle(font: timesBold, fontSize: 8, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Écart',
                            style: pw.TextStyle(font: timesBold, fontSize: 8, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Prix Unitaire',
                            style: pw.TextStyle(font: timesBold, fontSize: 8, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Valeur Stock',
                            style: pw.TextStyle(font: timesBold, fontSize: 8, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Valeur Vendue',
                            style: pw.TextStyle(font: timesBold, fontSize: 8, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    ...cappedItems.map((item) {
                      final nom = (item['nom']?.toString() ?? 'N/A').substring(0, (item['nom']?.toString().length ?? 0) > 50 ? 50 : null);
                      final categorie = (item['categorie']?.toString() ?? 'N/A').substring(0, (item['categorie']?.toString().length ?? 0) > 30 ? 30 : null);
                      final quantiteInitiale = (item['quantiteInitiale'] is num
                              ? item['quantiteInitiale'] as num
                              : num.tryParse(item['quantiteInitiale'].toString()))?.toInt() ?? 0;
                      final quantiteStock = (item['quantiteStock'] is num
                              ? item['quantiteStock'] as num
                              : num.tryParse(item['quantiteStock'].toString()))?.toInt() ?? 0;
                      final quantiteAvariee = (item['quantiteAvariee'] is num
                              ? item['quantiteAvariee'] as num
                              : num.tryParse(item['quantiteAvariee'].toString()))?.toInt() ?? 0;
                      final ecart = (item['ecart'] is num
                              ? item['ecart'] as num
                              : num.tryParse(item['ecart'].toString()))?.toInt() ?? 0;
                      final prixVente = (item['prixVente'] is num
                              ? item['prixVente'] as num
                              : num.tryParse(item['prixVente'].toString()))?.toDouble() ?? 0.0;
                      final soldValue = (item['soldValue'] is num
                              ? item['soldValue'] as num
                              : num.tryParse(item['soldValue'].toString()))?.toDouble() ?? 0.0;
                      final unite = (item['unite']?.toString() ?? 'N/A').substring(0, (item['unite']?.toString().length ?? 0) > 10 ? 10 : null);
                      if (item['nom']!.toString().length > 50 || item['categorie']!.toString().length > 30 || item['unite']!.toString().length > 10) {
                        print('Truncated item: nom=${item['nom']}, categorie=${item['categorie']}, unite=${item['unite']}');
                      }
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              '$nom ($unite)',
                              style: pw.TextStyle(font: times, fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              categorie,
                              style: pw.TextStyle(font: times, fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              '$quantiteInitiale${unite == 'kg' ? ' kg' : ''}',
                              style: pw.TextStyle(font: times, fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              '$quantiteStock${unite == 'kg' ? ' kg' : ''}',
                              style: pw.TextStyle(font: times, fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              '$quantiteAvariee${unite == 'kg' ? ' kg' : ''}',
                              style: pw.TextStyle(font: times, fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              '$ecart${unite == 'kg' ? ' kg' : ''}',
                              style: pw.TextStyle(font: times, fontSize: 8, color: ecart != 0 ? (ecart < 0 ? PdfColors.red : PdfColors.green) : PdfColors.black),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              '${formatter.format(prixVente)}\u00A0FCFA',
                              style: pw.TextStyle(font: times, fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              '${formatter.format(quantiteStock * prixVente)}\u00A0FCFA',
                              style: pw.TextStyle(font: times, fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              '${formatter.format(soldValue)}\u00A0FCFA',
                              style: pw.TextStyle(font: times, fontSize: 8),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
                if (items.length > maxItems)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 8),
                    child: pw.Text(
                      'Note: Liste limitée à $maxItems produits pour des raisons de performance. Total affiché reflète tous les produits.',
                      style: pw.TextStyle(font: times, fontSize: 8, color: PdfColors.red),
                    ),
                  ),
                pw.SizedBox(height: 24),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Valeur Totale du Stock: ${formatter.format(totalStockValue)}\u00A0FCFA',
                          style: pw.TextStyle(font: timesBold, fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          'Valeur Totale Vendue: ${formatter.format(totalSoldValue)}\u00A0FCFA',
                          style: pw.TextStyle(font: timesBold, fontSize: 10, fontWeight: pw.FontWeight.bold),
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
                          style: pw.TextStyle(font: timesBold, fontSize: 10, fontWeight: pw.FontWeight.bold),
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
          ),
        ],
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/inventaire_$numero.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static saveExitsReport({required String numero, required DateTime date, required String magasinAdresse, required String utilisateurNom, required List<Map<String, Object>> items, required double totalValue}) {}
}
