import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PdfService {
  static Future<File> _generatePdf({
    required String numero,
    required DateTime date,
    required String? clientNom,
    required String? clientAdresse,
    String? magasinAdresse, // fallback si pas d'info société
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

    // Récupère toutes les infos société
    final societe = await getSocieteInfo();
    pw.ImageProvider? logoImage;
    final logoPath = societe['logo'];
    if (logoPath != null && File(logoPath).existsSync()) {
      final logoBytes = File(logoPath).readAsBytesSync();
      logoImage = pw.MemoryImage(logoBytes);
    }

    // Ajout de la ligne pointillée pour la signature
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
                  child: logoImage != null
                      ? pw.Image(logoImage, height: 60)
                      : pw.Center(
                          child: pw.Text(
                            'Logo',
                            style: pw.TextStyle(font: times, fontSize: 10, color: PdfColors.grey),
                          ),
                        ),
                ),
                pw.SizedBox(height: 8),
                // Infos société
                pw.Text(societe['nom'] ?? '', style: pw.TextStyle(font: timesBold, fontSize: 14)),
                if ((societe['adresse'] ?? '').isNotEmpty)
                  pw.Text(societe['adresse'], style: pw.TextStyle(font: times, fontSize: 10)),
                if ((societe['email'] ?? '').isNotEmpty)
                  pw.Text('Email: ${societe['email']}', style: pw.TextStyle(font: times, fontSize: 10)),
                if ((societe['telephone'] ?? '').isNotEmpty)
                  pw.Text('Téléphone: ${societe['telephone']}', style: pw.TextStyle(font: times, fontSize: 10)),
                if ((societe['responsable'] ?? '').isNotEmpty)
                  pw.Text('Responsable: ${societe['responsable']}', style: pw.TextStyle(font: times, fontSize: 10)),
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
                          if ((societe['adresse'] ?? '').isNotEmpty)
                            pw.Text(societe['adresse'], style: pw.TextStyle(font: times, fontSize: 10)),
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
                              '${formatter.format(prixUnitaire)} FCFA',
                              style: pw.TextStyle(font: times, fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              '${formatter.format(quantite * prixUnitaire)} FCFA',
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
                          'Sous-total: ${formatter.format(sousTotal)} FCFA',
                          style: pw.TextStyle(font: times, fontSize: 10),
                        ),
                        pw.Text(
                          'Ristourne: ${formatter.format(ristourne)} FCFA',
                          style: pw.TextStyle(font: times, fontSize: 10),
                        ),
                        pw.Text(
                          'Total: ${formatter.format(total)} FCFA',
                          style: pw.TextStyle(font: timesBold, fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          'Payé: ${formatter.format(montantPaye)} FCFA',
                          style: pw.TextStyle(font: times, fontSize: 10),
                        ),
                        if (montantRemis != null)
                          pw.Text(
                            'Montant remis: ${formatter.format(montantRemis)} FCFA',
                            style: pw.TextStyle(font: times, fontSize: 10),
                          ),
                        if (monnaie != null && monnaie > 0)
                          pw.Text(
                            'Monnaie: ${formatter.format(monnaie)} FCFA',
                            style: pw.TextStyle(font: times, fontSize: 10),
                          ),
                        pw.Text(
                          'Reste à payer: ${formatter.format(resteAPayer >= 0 ? resteAPayer : 0)} FCFA',
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

    print('Generating invoice PDF bytes with ${items.length} items: $items');

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
                              '${formatter.format(prixUnitaire)} FCFA',
                              style: pw.TextStyle(font: times, fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              '${formatter.format(quantite * prixUnitaire)} FCFA',
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
                          'Sous-total: ${formatter.format(sousTotal)} FCFA',
                          style: pw.TextStyle(font: times, fontSize: 10),
                        ),
                        pw.Text(
                          'Ristourne: ${formatter.format(ristourne)} FCFA',
                          style: pw.TextStyle(font: times, fontSize: 10),
                        ),
                        pw.Text(
                          'Total: ${formatter.format(total)} FCFA',
                          style: pw.TextStyle(font: timesBold, fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          'Payé: ${formatter.format(montantPaye)} FCFA',
                          style: pw.TextStyle(font: times, fontSize: 10),
                        ),
                        if (montantRemis != null)
                          pw.Text(
                            'Montant remis: ${formatter.format(montantRemis)} FCFA',
                            style: pw.TextStyle(font: times, fontSize: 10),
                          ),
                        if (monnaie != null && monnaie > 0)
                          pw.Text(
                            'Monnaie: ${formatter.format(monnaie)} FCFA',
                            style: pw.TextStyle(font: times, fontSize: 10),
                          ),
                        pw.Text(
                          'Reste à payer: ${formatter.format(resteAPayer >= 0 ? resteAPayer : 0)} FCFA',
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
    String? magasinAdresse,
    required String utilisateurNom,
    required List<Map<String, dynamic>> items,
    required double totalStockValue,
    required double totalSoldValue,
  }) async {
    final pdf = pw.Document();
    final formatter = NumberFormat('#,##0.00', 'fr_FR');
    final times = pw.Font.times();
    final timesBold = pw.Font.timesBold();

    const maxItems = 1000;
    final cappedItems = items.length > maxItems ? items.sublist(0, maxItems) : items;
    if (items.length > maxItems) {
      print('Warning: Items list truncated from \\${items.length} to $maxItems to prevent TooManyPagesException');
    }

    print('Generating inventory PDF with \\${cappedItems.length} items: $cappedItems');

    // Récupère toutes les infos société
    final societe = await getSocieteInfo();
    pw.ImageProvider? logoImage;
    final logoPath = societe['logo'];
    if (logoPath != null && File(logoPath).existsSync()) {
      final logoBytes = File(logoPath).readAsBytesSync();
      logoImage = pw.MemoryImage(logoBytes);
    }

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
                  child: logoImage != null
                      ? pw.Image(logoImage, height: 60)
                      : pw.Center(
                          child: pw.Text(
                            'Logo',
                            style: pw.TextStyle(font: times, fontSize: 10, color: PdfColors.grey),
                          ),
                        ),
                ),
                pw.SizedBox(height: 8),
                // Infos société
                pw.Text(societe['nom'] ?? '', style: pw.TextStyle(font: timesBold, fontSize: 14)),
                if ((societe['adresse'] ?? '').isNotEmpty)
                  pw.Text(societe['adresse'], style: pw.TextStyle(font: times, fontSize: 10)),
                if ((societe['email'] ?? '').isNotEmpty)
                  pw.Text('Email: ${societe['email']}', style: pw.TextStyle(font: times, fontSize: 10)),
                if ((societe['telephone'] ?? '').isNotEmpty)
                  pw.Text('Téléphone: ${societe['telephone']}', style: pw.TextStyle(font: times, fontSize: 10)),
                if ((societe['responsable'] ?? '').isNotEmpty)
                  pw.Text('Responsable: ${societe['responsable']}', style: pw.TextStyle(font: times, fontSize: 10)),
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
                            (utilisateurNom != null && utilisateurNom.trim().isNotEmpty)
                              ? utilisateurNom
                              : '..................................................',
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
                    0: const pw.FlexColumnWidth(2.5),
                    1: const pw.FlexColumnWidth(1.2),
                    2: const pw.FlexColumnWidth(0.8),
                    3: const pw.FlexColumnWidth(0.8),
                    4: const pw.FlexColumnWidth(0.8),
                    5: const pw.FlexColumnWidth(0.8),
                    6: const pw.FlexColumnWidth(1.0),
                    7: const pw.FlexColumnWidth(1.0),
                    8: const pw.FlexColumnWidth(1.0),
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
                              '${formatter.format(prixVente)} FCFA',
                              style: pw.TextStyle(font: times, fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              '${formatter.format(quantiteStock * prixVente)} FCFA',
                              style: pw.TextStyle(font: times, fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              '${formatter.format(soldValue)} FCFA',
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
                          'Valeur Totale du Stock: ${formatter.format(totalStockValue)} FCFA',
                          style: pw.TextStyle(font: timesBold, fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          'Valeur Totale Vendue: ${formatter.format(totalSoldValue)} FCFA',
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

  static Future<File> saveEntriesReport({
    required String numero,
    required DateTime date,
    String? magasinAdresse,
    required String utilisateurNom,
    required List<Map<String, dynamic>> items,
    required double totalValue,
  }) async {
    final pdf = pw.Document();
    final formatter = NumberFormat('#,##0.00', 'fr_FR');
    final dateFormatter = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');
    final times = pw.Font.times();
    final timesBold = pw.Font.timesBold();

    const maxItems = 1000;
    final cappedItems = items.length > maxItems ? items.sublist(0, maxItems) : items;
    if (items.length > maxItems) {
      print('Warning: Items list truncated from \\${items.length} to $maxItems to prevent TooManyPagesException');
    }

    print('Generating entries report PDF with \\${cappedItems.length} items: $cappedItems');

    // Récupère toutes les infos société
    final societe = await getSocieteInfo();
    pw.ImageProvider? logoImage;
    final logoPath = societe['logo'];
    if (logoPath != null && File(logoPath).existsSync()) {
      final logoBytes = File(logoPath).readAsBytesSync();
      logoImage = pw.MemoryImage(logoBytes);
    }

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
                  child: logoImage != null
                      ? pw.Image(logoImage, height: 60)
                      : pw.Center(
                          child: pw.Text(
                            'Logo',
                            style: pw.TextStyle(font: times, fontSize: 10, color: PdfColors.grey),
                          ),
                        ),
                ),
                pw.SizedBox(height: 8),
                // Infos société
                pw.Text(societe['nom'] ?? '', style: pw.TextStyle(font: timesBold, fontSize: 14)),
                if ((societe['adresse'] ?? '').isNotEmpty)
                  pw.Text(societe['adresse'], style: pw.TextStyle(font: times, fontSize: 10)),
                if ((societe['email'] ?? '').isNotEmpty)
                  pw.Text('Email: ${societe['email']}', style: pw.TextStyle(font: times, fontSize: 10)),
                if ((societe['telephone'] ?? '').isNotEmpty)
                  pw.Text('Téléphone: ${societe['telephone']}', style: pw.TextStyle(font: times, fontSize: 10)),
                if ((societe['responsable'] ?? '').isNotEmpty)
                  pw.Text('Responsable: ${societe['responsable']}', style: pw.TextStyle(font: times, fontSize: 10)),
                pw.SizedBox(height: 16),
                pw.Center(
                  child: pw.Text(
                    'RAPPORT DES ENTRÉES',
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
                            (utilisateurNom != null && utilisateurNom.trim().isNotEmpty)
                              ? utilisateurNom
                              : '..................................................',
                            style: pw.TextStyle(font: times, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 24),
                pw.Text(
                  'Entrées:',
                  style: pw.TextStyle(font: timesBold, fontSize: 10, fontWeight: pw.FontWeight.bold),
                ),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.black),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(0.5), // ID
                    1: const pw.FlexColumnWidth(2.0), // Nom du produit
                    2: const pw.FlexColumnWidth(1.2), // Catégorie
                    3: const pw.FlexColumnWidth(0.8), // Unité
                    4: const pw.FlexColumnWidth(0.8), // Stock initial
                    5: const pw.FlexColumnWidth(0.8), // Stock actuel
                    6: const pw.FlexColumnWidth(0.8), // Quantité entrée
                    7: const pw.FlexColumnWidth(1.0), // Prix Unitaire
                    8: const pw.FlexColumnWidth(1.0), // Valeur Stock
                    9: const pw.FlexColumnWidth(1.0), // Type
                    10: const pw.FlexColumnWidth(1.2), // Source
                    11: const pw.FlexColumnWidth(1.5), // Date
                    12: const pw.FlexColumnWidth(1.0), // Utilisateur
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'ID',
                            style: pw.TextStyle(font: timesBold, fontSize: 8, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Nom du produit',
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
                            'Unité',
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
                            'Stock Actuel',
                            style: pw.TextStyle(font: timesBold, fontSize: 8, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Qté Entrée',
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
                            'Type',
                            style: pw.TextStyle(font: timesBold, fontSize: 8, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Source',
                            style: pw.TextStyle(font: timesBold, fontSize: 8, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Date',
                            style: pw.TextStyle(font: timesBold, fontSize: 8, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Utilisateur',
                            style: pw.TextStyle(font: timesBold, fontSize: 8, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    ...cappedItems.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final quantite = (item['quantite'] is num ? item['quantite'] as num : num.tryParse(item['quantite'].toString()))?.toInt() ?? 0;
                      final prixUnitaire = (item['prixUnitaire'] is num ? item['prixUnitaire'] as num : num.tryParse(item['prixUnitaire'].toString()))?.toDouble() ?? 0.0;
                      final valeurStock = (item['valeurStock'] is num ? item['valeurStock'] as num : num.tryParse(item['valeurStock'].toString()))?.toDouble() ?? 0.0;
                      final quantiteInitiale = (item['quantiteInitiale'] is num ? item['quantiteInitiale'] as num : num.tryParse(item['quantiteInitiale'].toString()))?.toInt() ?? 0;
                      final quantiteStock = (item['quantiteStock'] is num ? item['quantiteStock'] as num : num.tryParse(item['quantiteStock'].toString()))?.toInt() ?? 0;
                      final produitNom = (item['produitNom']?.toString() ?? 'N/A').substring(0, (item['produitNom']?.toString().length ?? 0) > 50 ? 50 : null);
                      final categorie = (item['categorie']?.toString() ?? 'N/A').substring(0, (item['categorie']?.toString().length ?? 0) > 30 ? 30 : null);
                      final unite = (item['unite']?.toString() ?? 'N/A').substring(0, (item['unite']?.toString().length ?? 0) > 10 ? 10 : null);
                      final type = item['type']?.toString() ?? 'N/A';
                      final source = item['source']?.toString() ?? '';
                      final date = item['date'] is DateTime ? dateFormatter.format(item['date'] as DateTime) : 'N/A';
                      final utilisateur = item['utilisateur']?.toString() ?? 'N/A';
                      if (item['produitNom']!.toString().length > 50 || item['categorie']!.toString().length > 30 || item['unite']!.toString().length > 10) {
                        print('Truncated item: nom=${item['produitNom']}, categorie=${item['categorie']}, unite=${item['unite']}');
                      }
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              '${index + 1}',
                              style: pw.TextStyle(font: times, fontSize: 8),
                            ),
                          ),
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
                              categorie,
                              style: pw.TextStyle(font: times, fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              unite,
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
                              '$quantite${unite == 'kg' ? ' kg' : ''}',
                              style: pw.TextStyle(font: times, fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              '${formatter.format(prixUnitaire)} FCFA',
                              style: pw.TextStyle(font: times, fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              '${formatter.format(valeurStock)} FCFA',
                              style: pw.TextStyle(font: times, fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              type,
                              style: pw.TextStyle(font: times, fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              source,
                              style: pw.TextStyle(font: times, fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              date,
                              style: pw.TextStyle(font: times, fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              utilisateur,
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
                      'Note: Liste limitée à $maxItems entrées pour des raisons de performance. Total affiché reflète toutes les entrées.',
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
                          'Valeur Totale des Entrées: ${formatter.format(totalValue)} FCFA',
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
    final file = File('${directory.path}/entrees_$numero.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static Future<File> saveExitsReport({
    required String numero,
    required DateTime date,
    required String? magasinAdresse,
    required String utilisateurNom,
    required List<Map<String, dynamic>> items,
    required double totalValue,
  }) async {
    final pdf = pw.Document();
    final formatter = NumberFormat('#,##0.00', 'fr_FR');
    final dateFormatter = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');
    final times = pw.Font.times();
    final timesBold = pw.Font.timesBold();

    const maxItems = 1000;
    final cappedItems = items.length > maxItems ? items.sublist(0, maxItems) : items;
    if (items.length > maxItems) {
      print('Warning: Items list truncated from ${items.length} to $maxItems to prevent TooManyPagesException');
    }

    print('Generating exits report PDF with ${cappedItems.length} items: $cappedItems');

    // Ajout du logo si défini
    pw.ImageProvider? logoImage;
    final prefs = await SharedPreferences.getInstance();
    final logoPath = prefs.getString('logo_path');
    if (logoPath != null && File(logoPath).existsSync()) {
      final logoBytes = File(logoPath).readAsBytesSync();
      logoImage = pw.MemoryImage(logoBytes);
    }

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
                  child: logoImage != null
                      ? pw.Image(logoImage, height: 60)
                      : pw.Center(
                          child: pw.Text(
                            'Logo',
                            style: pw.TextStyle(font: times, fontSize: 10, color: PdfColors.grey),
                          ),
                        ),
                ),
                pw.SizedBox(height: 16),
                pw.Center(
                  child: pw.Text(
                    'RAPPORT DES SORTIES',
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
                            (utilisateurNom != null && utilisateurNom.trim().isNotEmpty)
                              ? utilisateurNom
                              : '..................................................',
                            style: pw.TextStyle(font: times, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 24),
                pw.Text(
                  'Sorties:',
                  style: pw.TextStyle(font: timesBold, fontSize: 10, fontWeight: pw.FontWeight.bold),
                ),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.black),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(0.5), // ID
                    1: const pw.FlexColumnWidth(2.0), // Nom du produit
                    2: const pw.FlexColumnWidth(1.2), // Catégorie
                    3: const pw.FlexColumnWidth(0.8), // Unité
                    4: const pw.FlexColumnWidth(0.8), // Quantité sortie
                    5: const pw.FlexColumnWidth(1.0), // Prix Unitaire
                    6: const pw.FlexColumnWidth(1.0), // Valeur Sortie
                    7: const pw.FlexColumnWidth(1.0), // Type
                    8: const pw.FlexColumnWidth(1.2), // Raison
                    9: const pw.FlexColumnWidth(1.5), // Date
                    10: const pw.FlexColumnWidth(1.0), // Utilisateur
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'ID',
                            style: pw.TextStyle(font: timesBold, fontSize: 8, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Nom du produit',
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
                            'Unité',
                            style: pw.TextStyle(font: timesBold, fontSize: 8, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Qté Sortie',
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
                            'Valeur Sortie',
                            style: pw.TextStyle(font: timesBold, fontSize: 8, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Type',
                            style: pw.TextStyle(font: timesBold, fontSize: 8, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Raison',
                            style: pw.TextStyle(font: timesBold, fontSize: 8, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Date',
                            style: pw.TextStyle(font: timesBold, fontSize: 8, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Utilisateur',
                            style: pw.TextStyle(font: timesBold, fontSize: 8, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    ...cappedItems.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final quantite = (item['quantite'] is num ? item['quantite'] as num : num.tryParse(item['quantite'].toString()))?.toInt() ?? 0;
                      final prixUnitaire = (item['prixUnitaire'] is num ? item['prixUnitaire'] as num : num.tryParse(item['prixUnitaire'].toString()))?.toDouble() ?? 0.0;
                      final valeurSortie = quantite * prixUnitaire;
                      final produitNom = (item['produitNom']?.toString() ?? 'N/A').substring(0, (item['produitNom']?.toString().length ?? 0) > 50 ? 50 : null);
                      final categorie = (item['categorie']?.toString() ?? 'N/A').substring(0, (item['categorie']?.toString().length ?? 0) > 30 ? 30 : null);
                      final unite = (item['unite']?.toString() ?? 'N/A').substring(0, (item['unite']?.toString().length ?? 0) > 10 ? 10 : null);
                      final type = item['type']?.toString() ?? 'N/A';
                      final raison = item['raison']?.toString() ?? '';
                      final date = item['date'] is DateTime ? dateFormatter.format(item['date'] as DateTime) : item['date']?.toString() ?? 'N/A';
                      final utilisateur = item['utilisateur']?.toString() ?? 'N/A';
                      if (item['produitNom']!.toString().length > 50 || item['categorie']!.toString().length > 30 || item['unite']!.toString().length > 10) {
                        print('Truncated item: nom=${item['produitNom']}, categorie=${item['categorie']}, unite=${item['unite']}');
                      }
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              '${index + 1}',
                              style: pw.TextStyle(font: times, fontSize: 8),
                            ),
                          ),
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
                              categorie,
                              style: pw.TextStyle(font: times, fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              unite,
                              style: pw.TextStyle(font: times, fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              '$quantite${unite == 'kg' ? ' kg' : ''}',
                              style: pw.TextStyle(font: times, fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              '${formatter.format(prixUnitaire)} FCFA',
                              style: pw.TextStyle(font: times, fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              '${formatter.format(valeurSortie)} FCFA',
                              style: pw.TextStyle(font: times, fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              type,
                              style: pw.TextStyle(font: times, fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              raison,
                              style: pw.TextStyle(font: times, fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              date,
                              style: pw.TextStyle(font: times, fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              utilisateur,
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
                      'Note: Liste limitée à $maxItems sorties pour des raisons de performance. Total affiché reflète toutes les sorties.',
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
                          'Valeur Totale des Sorties: ${formatter.format(totalValue)} FCFA',
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
    final file = File('${directory.path}/sorties_$numero.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }
  static Future<File> saveSingleProductReport({
    required String numero,
    required DateTime date,
    required String? magasinAdresse,
    required String utilisateurNom,
    required Map<String, dynamic> product,
    required List<Map<String, dynamic>> entries,
    required List<Map<String, dynamic>> exits,
    required double totalEntryValue,
    required double totalExitValue,
    required double currentStockValue,
  }) async {
    final pdf = pw.Document();
    final formatter = NumberFormat('#,##0.00', 'fr_FR');
    final dateFormatter = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');
    final times = pw.Font.times();
    final timesBold = pw.Font.timesBold();

    const maxItems = 1000;
    final cappedEntries = entries.length > maxItems ? entries.sublist(0, maxItems) : entries;
    final cappedExits = exits.length > maxItems ? exits.sublist(0, maxItems) : exits;
    if (entries.length > maxItems || exits.length > maxItems) {
      print('Warning: Items list truncated to $maxItems to prevent TooManyPagesException');
    }

    print('Generating single product report PDF for product: ${product['nom']}, '
        '${cappedEntries.length} entries, ${cappedExits.length} exits');

    // Ajout du logo si défini
    pw.ImageProvider? logoImage;
    final prefs = await SharedPreferences.getInstance();
    final logoPath = prefs.getString('logo_path');
    if (logoPath != null && File(logoPath).existsSync()) {
      final logoBytes = File(logoPath).readAsBytesSync();
      logoImage = pw.MemoryImage(logoBytes);
    }

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
                  child: logoImage != null
                      ? pw.Image(logoImage, height: 60)
                      : pw.Center(
                          child: pw.Text(
                            'Logo',
                            style: pw.TextStyle(font: times, fontSize: 10, color: PdfColors.grey),
                          ),
                        ),
                ),
                pw.SizedBox(height: 16),
                pw.Center(
                  child: pw.Text(
                    'RAPPORT DE PRODUIT',
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
                            (utilisateurNom != null && utilisateurNom.trim().isNotEmpty)
                              ? utilisateurNom
                              : '..................................................',
                            style: pw.TextStyle(font: times, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 24),
                pw.Text(
                  'Détails du Produit:',
                  style: pw.TextStyle(font: timesBold, fontSize: 10, fontWeight: pw.FontWeight.bold),
                ),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.black),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2.5),
                    1: const pw.FlexColumnWidth(1.5),
                    2: const pw.FlexColumnWidth(1.0),
                    3: const pw.FlexColumnWidth(1.0),
                    4: const pw.FlexColumnWidth(1.0),
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
                            'Unité',
                            style: pw.TextStyle(font: timesBold, fontSize: 8, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Stock Actuel',
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
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            '${(product['nom']?.toString() ?? 'N/A').substring(0, (product['nom']?.toString().length ?? 0) > 50 ? 50 : null)}',
                            style: pw.TextStyle(font: times, fontSize: 8),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            '${(product['categorie']?.toString() ?? 'N/A').substring(0, (product['categorie']?.toString().length ?? 0) > 30 ? 30 : null)}',
                            style: pw.TextStyle(font: times, fontSize: 8),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            '${(product['unite']?.toString() ?? 'N/A').substring(0, (product['unite']?.toString().length ?? 0) > 10 ? 10 : null)}',
                            style: pw.TextStyle(font: times, fontSize: 8),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            '${(product['quantiteStock'] is num ? product['quantiteStock'] as num : num.tryParse(product['quantiteStock'].toString()))?.toInt() ?? 0}${product['unite'] == 'kg' ? ' kg' : ''}',
                            style: pw.TextStyle(font: times, fontSize: 8),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            '${formatter.format((product['prixVente'] is num ? product['prixVente'] as num : num.tryParse(product['prixVente'].toString()))?.toDouble() ?? 0.0)} FCFA',
                            style: pw.TextStyle(font: times, fontSize: 8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 24),
                pw.Text(
                  'Entrées:',
                  style: pw.TextStyle(font: timesBold, fontSize: 10, fontWeight: pw.FontWeight.bold),
                ),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.black),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(0.5), // ID
                    1: const pw.FlexColumnWidth(0.8), // Quantité entrée
                    2: const pw.FlexColumnWidth(1.0), // Prix Unitaire
                    3: const pw.FlexColumnWidth(1.0), // Valeur Stock
                    4: const pw.FlexColumnWidth(1.0), // Type
                    5: const pw.FlexColumnWidth(1.2), // Source
                    6: const pw.FlexColumnWidth(1.5), // Date
                    7: const pw.FlexColumnWidth(1.0), // Utilisateur
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'ID',
                            style: pw.TextStyle(font: timesBold, fontSize: 8, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Qté Entrée',
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
                            'Type',
                            style: pw.TextStyle(font: timesBold, fontSize: 8, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Source',
                            style: pw.TextStyle(font: timesBold, fontSize: 8, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Date',
                            style: pw.TextStyle(font: timesBold, fontSize: 8, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Utilisateur',
                            style: pw.TextStyle(font: timesBold, fontSize: 8, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    if (cappedEntries.isEmpty)
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              'Aucune entrée',
                              style: pw.TextStyle(font: times, fontSize: 8),
                            ),
                          ),
                          ...List.generate(7, (_) => pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(''))),
                        ],
                      ),
                    ...cappedEntries.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final quantite = (item['quantite'] is num ? item['quantite'] as num : num.tryParse(item['quantite'].toString()))?.toInt() ?? 0;
                      final prixUnitaire = (item['prixUnitaire'] is num ? item['prixUnitaire'] as num : num.tryParse(item['prixUnitaire'].toString()))?.toDouble() ?? 0.0;
                      final valeurStock = (item['valeurStock'] is num ? item['valeurStock'] as num : num.tryParse(item['valeurStock'].toString()))?.toDouble() ?? 0.0;
                      final unite = (item['unite']?.toString() ?? 'N/A').substring(0, (item['unite']?.toString().length ?? 0) > 10 ? 10 : null);
                      final type = item['type']?.toString() ?? 'N/A';
                      final source = item['source']?.toString() ?? '';
                      final date = item['date'] is DateTime ? dateFormatter.format(item['date'] as DateTime) : 'N/A';
                      final utilisateur = item['utilisateur']?.toString() ?? 'N/A';
                      if ((item['unite']?.toString().length ?? 0) > 10) {
                        print('Truncated unite: ${item['unite']}');
                      }
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              '${index + 1}',
                              style: pw.TextStyle(font: times, fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              '$quantite${unite == 'kg' ? ' kg' : ''}',
                              style: pw.TextStyle(font: times, fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              '${formatter.format(prixUnitaire)} FCFA',
                              style: pw.TextStyle(font: times, fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              '${formatter.format(valeurStock)} FCFA',
                              style: pw.TextStyle(font: times, fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              type,
                              style: pw.TextStyle(font: times, fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              source,
                              style: pw.TextStyle(font: times, fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              date,
                              style: pw.TextStyle(font: times, fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              utilisateur,
                              style: pw.TextStyle(font: times, fontSize: 8),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
                if (entries.length > maxItems)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 8),
                    child: pw.Text(
                      'Note: Liste des entrées limitée à $maxItems pour des raisons de performance.',
                      style: pw.TextStyle(font: times, fontSize: 8, color: PdfColors.red),
                    ),
                  ),
                pw.SizedBox(height: 24),
                pw.Text(
                  'Sorties:',
                  style: pw.TextStyle(font: timesBold, fontSize: 10, fontWeight: pw.FontWeight.bold),
                ),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.black),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(0.5), // ID
                    1: const pw.FlexColumnWidth(0.8), // Quantité sortie
                    2: const pw.FlexColumnWidth(1.0), // Prix Unitaire
                    3: const pw.FlexColumnWidth(1.0), // Valeur Sortie
                    4: const pw.FlexColumnWidth(1.0), // Type
                    5: const pw.FlexColumnWidth(1.2), // Raison
                    6: const pw.FlexColumnWidth(1.5), // Date
                    7: const pw.FlexColumnWidth(1.0), // Utilisateur
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'ID',
                            style: pw.TextStyle(font: timesBold, fontSize: 8, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Qté Sortie',
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
                            'Valeur Sortie',
                            style: pw.TextStyle(font: timesBold, fontSize: 8, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Type',
                            style: pw.TextStyle(font: timesBold, fontSize: 8, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Raison',
                            style: pw.TextStyle(font: timesBold, fontSize: 8, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Date',
                            style: pw.TextStyle(font: timesBold, fontSize: 8, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Utilisateur',
                            style: pw.TextStyle(font: timesBold, fontSize: 8, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    if (cappedExits.isEmpty)
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              'Aucune sortie',
                              style: pw.TextStyle(font: times, fontSize: 8),
                            ),
                          ),
                          ...List.generate(7, (_) => pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(''))),
                        ],
                      ),
                    ...cappedExits.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final quantite = (item['quantite'] is num ? item['quantite'] as num : num.tryParse(item['quantite'].toString()))?.toInt() ?? 0;
                      final prixUnitaire = (item['prixUnitaire'] is num ? item['prixUnitaire'] as num : num.tryParse(item['prixUnitaire'].toString()))?.toDouble() ?? 0.0;
                      final valeurSortie = quantite * prixUnitaire;
                      final unite = (item['unite']?.toString() ?? 'N/A').substring(0, (item['unite']?.toString().length ?? 0) > 10 ? 10 : null);
                      final type = item['type']?.toString() ?? 'N/A';
                      final raison = item['raison']?.toString() ?? '';
                      final date = item['date'] is DateTime ? dateFormatter.format(item['date'] as DateTime) : item['date']?.toString() ?? 'N/A';
                      final utilisateur = item['utilisateur']?.toString() ?? 'N/A';
                      if ((item['unite']?.toString().length ?? 0) > 10) {
                        print('Truncated unite: ${item['unite']}');
                      }
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              '${index + 1}',
                              style: pw.TextStyle(font: times, fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              '$quantite${unite == 'kg' ? ' kg' : ''}',
                              style: pw.TextStyle(font: times, fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              '${formatter.format(prixUnitaire)} FCFA',
                              style: pw.TextStyle(font: times, fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              '${formatter.format(valeurSortie)} FCFA',
                              style: pw.TextStyle(font: times, fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              type,
                              style: pw.TextStyle(font: times, fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              raison,
                              style: pw.TextStyle(font: times, fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              date,
                              style: pw.TextStyle(font: times, fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              utilisateur,
                              style: pw.TextStyle(font: times, fontSize: 8),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
                if (exits.length > maxItems)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 8),
                    child: pw.Text(
                      'Note: Liste des sorties limitée à $maxItems pour des raisons de performance.',
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
                          'Valeur Totale des Entrées: ${formatter.format(totalEntryValue)} FCFA',
                          style: pw.TextStyle(font: timesBold, fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          'Valeur Totale des Sorties: ${formatter.format(totalExitValue)} FCFA',
                          style: pw.TextStyle(font: timesBold, fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          'Valeur du Stock Actuel: ${formatter.format(currentStockValue)} FCFA',
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
    final file = File('${directory.path}/produit_${numero}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// Charge toutes les infos société depuis SharedPreferences
  static Future<Map<String, dynamic>> getSocieteInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'nom': prefs.getString('societe_nom') ?? '',
      'email': prefs.getString('societe_email') ?? '',
      'telephone': prefs.getString('societe_telephone') ?? '',
      'adresse': prefs.getString('societe_adresse') ?? '',
      'responsable': prefs.getString('societe_responsable') ?? '',
      'logo': prefs.getString('societe_logo'),
    };
  }
}