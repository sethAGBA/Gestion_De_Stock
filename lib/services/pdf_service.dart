import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PdfService {
  static String _dash(String? value) => (value == null || value.trim().isEmpty) ? '-' : value.trim();
  static pw.Widget _buildReceiptHeader({
    required Map<String, dynamic> societe,
    required String title,
    String? subtitle,
    pw.ImageProvider? logoImage,
    required pw.Font times,
    required pw.Font timesBold,
  }) {
    final meta = [
      if ((societe['email'] ?? '').toString().isNotEmpty) 'Email: ${societe['email']}',
      if ((societe['telephone'] ?? '').toString().isNotEmpty) 'Tel: ${societe['telephone']}',
      if ((societe['site'] ?? '').toString().isNotEmpty) 'Site: ${societe['site']}',
      if ((societe['rc'] ?? '').toString().isNotEmpty) 'RC: ${societe['rc']}',
      if ((societe['nif'] ?? '').toString().isNotEmpty) 'NIF: ${societe['nif']}',
    ];
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            borderRadius: pw.BorderRadius.circular(12),
            color: PdfColors.grey100,
          ),
          child: logoImage != null
              ? pw.SizedBox(width: 90, height: 50, child: pw.Image(logoImage, fit: pw.BoxFit.contain))
              : pw.Container(
                  width: 90,
                  height: 50,
                  alignment: pw.Alignment.center,
                  child: pw.Text('Logo', style: pw.TextStyle(font: times, fontSize: 10, color: PdfColors.grey600)),
                ),
        ),
        pw.SizedBox(height: 6),
        pw.Text(societe['nom'] ?? '', style: pw.TextStyle(font: timesBold, fontSize: 18)),
        if ((societe['adresse'] ?? '').toString().isNotEmpty)
          pw.Text(societe['adresse'], style: pw.TextStyle(font: times, fontSize: 10)),
        pw.SizedBox(height: 4),
        pw.Text(title.toUpperCase(), style: pw.TextStyle(font: timesBold, fontSize: 16)),
        if (subtitle != null) pw.Text(subtitle, style: pw.TextStyle(font: times, fontSize: 10, color: PdfColors.grey700)),
        pw.SizedBox(height: 6),
        if (meta.isNotEmpty)
          pw.Text(
            meta.join(' | '),
            style: pw.TextStyle(font: times, fontSize: 9, color: PdfColors.grey700),
            textAlign: pw.TextAlign.center,
          ),
        pw.SizedBox(height: 6),
        pw.Divider(thickness: 0.6, color: PdfColors.grey500),
      ],
    );
  }

  static Future<File> _generatePdf({
    required String numero,
    required DateTime date,
    required String? clientNom,
    required String? clientAdresse,
    String? magasinAdresse, // fallback si pas d'info société
    required String vendeurNom,
    String? modePaiement,
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
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber}/${context.pagesCount}',
            style: pw.TextStyle(font: times, fontSize: 9, color: PdfColors.grey700),
          ),
      ),
      build: (pw.Context context) {
        final statutPaiement = resteAPayer <= 0 ? 'Payé' : 'En attente';
        final badgeColor = resteAPayer <= 0 ? PdfColors.green700 : PdfColors.orange700;
        final badgeLabel = resteAPayer <= 0 ? 'PAYÉ' : 'EN ATTENTE';
        final qrData = 'FACTURE:$numero';
        final merci = (societe['message'] ?? '').toString().isNotEmpty ? societe['message'] : 'Merci pour votre achat !';
        return [
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400, width: 1.4),
                borderRadius: pw.BorderRadius.circular(12),
                color: PdfColors.white,
              ),
              padding: const pw.EdgeInsets.all(24),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildReceiptHeader(
                    societe: societe,
                    title: 'Facture',
                    subtitle: 'Numéro: $numero - ${DateFormat('dd/MM/yyyy').format(date)}',
                    logoImage: logoImage,
                    times: times,
                    timesBold: timesBold,
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: pw.BoxDecoration(
                          color: badgeColor,
                          borderRadius: pw.BorderRadius.circular(10),
                        ),
                        child: pw.Text(
                          badgeLabel,
                          style: pw.TextStyle(font: timesBold, fontSize: 10, color: PdfColors.white),
                        ),
                      ),
                      pw.Container(
                        width: 72,
                        height: 72,
                        decoration: pw.BoxDecoration(
                          borderRadius: pw.BorderRadius.circular(10),
                          color: PdfColors.grey100,
                          border: pw.Border.all(color: PdfColors.grey300),
                        ),
                        child: pw.Center(
                          child: pw.BarcodeWidget(
                            data: qrData,
                            barcode: pw.Barcode.qrCode(),
                            width: 60,
                            height: 60,
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 12),
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Container(
                          padding: const pw.EdgeInsets.all(10),
                          decoration: pw.BoxDecoration(
                            borderRadius: pw.BorderRadius.circular(8),
                            color: PdfColors.grey200,
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Client', style: pw.TextStyle(font: timesBold, fontSize: 11)),
                              pw.Text(_dash(clientNom), style: pw.TextStyle(font: times, fontSize: 10)),
                              pw.Text(_dash(clientAdresse), style: pw.TextStyle(font: times, fontSize: 10)),
                            ],
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 12),
                      pw.Expanded(
                        child: pw.Container(
                          padding: const pw.EdgeInsets.all(10),
                          decoration: pw.BoxDecoration(
                            borderRadius: pw.BorderRadius.circular(8),
                            color: PdfColors.grey200,
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Références', style: pw.TextStyle(font: timesBold, fontSize: 11)),
                              pw.Text('Vendeur: ${_dash(vendeurNom)}', style: pw.TextStyle(font: times, fontSize: 10)),
                              pw.Text('Mode: ${_dash(modePaiement)}', style: pw.TextStyle(font: times, fontSize: 10)),
                            ],
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 10),
                    ],
                  ),
                  pw.SizedBox(height: 16),
                  pw.Text('Articles', style: pw.TextStyle(font: timesBold, fontSize: 11)),
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
                        final quantiteNum = (item['quantite'] is num ? item['quantite'] as num : num.tryParse(item['quantite'].toString()))?.toDouble() ?? 0.0;
                        final prixUnitaire = (item['prixUnitaire'] is num ? item['prixUnitaire'] as num : num.tryParse(item['prixUnitaire'].toString()))?.toDouble() ?? 0.0;
                        final produitNom = (item['produitNom']?.toString() ?? 'N/A');
                        final uniteFull = (item['unite']?.toString() ?? 'N/A');
                        final unite = uniteFull.substring(0, uniteFull.length > 10 ? 10 : uniteFull.length);
                        final mode = (item['tarifMode']?.toString() ?? 'Détail');
                        final allowDecimal = {
                          'kg', 'kilogramme', 'kilogrammes', 'litre', 'litres', 'l', 'liter'
                        }.contains(uniteFull.toLowerCase());
                        final qtyFormatter = NumberFormat(allowDecimal ? '#,##0.###' : '#,##0', 'fr_FR');
                        final quantite = qtyFormatter.format(allowDecimal ? quantiteNum : quantiteNum.round());
                        return pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(
                                '$produitNom ($unite) - $mode',
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
                                '${formatter.format(quantiteNum * prixUnitaire)}\u00A0FCFA',
                                style: pw.TextStyle(font: times, fontSize: 8),
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                  pw.SizedBox(height: 16),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Container(
                          padding: const pw.EdgeInsets.all(10),
                          decoration: pw.BoxDecoration(
                            borderRadius: pw.BorderRadius.circular(8),
                            color: PdfColors.grey200,
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Livraison', style: pw.TextStyle(font: timesBold, fontSize: 11)),
                              pw.Text('Magasin: ${_dash(magasinAdresse ?? societe['adresse'])}', style: pw.TextStyle(font: times, fontSize: 10)),
                              pw.Text('Adresse client: ${_dash(clientAdresse)}', style: pw.TextStyle(font: times, fontSize: 10)),
                            ],
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 12),
                      pw.Expanded(
                        child: pw.Container(
                          padding: const pw.EdgeInsets.all(10),
                          decoration: pw.BoxDecoration(
                            borderRadius: pw.BorderRadius.circular(8),
                            color: PdfColors.grey200,
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Paiement', style: pw.TextStyle(font: timesBold, fontSize: 11)),
                              pw.Text('Total: ${formatter.format(total)} FCFA', style: pw.TextStyle(font: times, fontSize: 10)),
                              pw.Text('Payé: ${formatter.format(montantPaye)} FCFA', style: pw.TextStyle(font: times, fontSize: 10)),
                              pw.Text('Reste: ${formatter.format(resteAPayer >= 0 ? resteAPayer : 0)} FCFA', style: pw.TextStyle(font: times, fontSize: 10)),
                              if (monnaie != null && monnaie > 0) pw.Text('Monnaie: ${formatter.format(monnaie)} FCFA', style: pw.TextStyle(font: times, fontSize: 10)),
                              pw.Text('Mode: ${_dash(modePaiement)}', style: pw.TextStyle(font: times, fontSize: 10)),
                              pw.SizedBox(height: 4),
                              pw.Text('Statut: $statutPaiement', style: pw.TextStyle(font: times, fontSize: 10)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 18),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Signature Client', style: pw.TextStyle(font: timesBold, fontSize: 10)),
                          pw.SizedBox(width: 180, child: dottedLine),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Signature Vendeur', style: pw.TextStyle(font: timesBold, fontSize: 10)),
                          pw.SizedBox(width: 180, child: dottedLine),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 12),
                  if ((societe['mention'] ?? '').toString().isNotEmpty)
                    pw.Text(
                      societe['mention'],
                      style: pw.TextStyle(font: times, fontSize: 9, color: PdfColors.grey800),
                    ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    merci,
                    style: pw.TextStyle(font: timesBold, fontSize: 11, color: PdfColors.blue900),
                  ),
                ],
              ),
            ),
          ];
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
    String? modePaiement,
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
      modePaiement: modePaiement,
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
    String? modePaiement,
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
      modePaiement: modePaiement,
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
    String? modePaiement,
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
      modePaiement: modePaiement,
      items: items,
      sousTotal: sousTotal,
      ristourne: ristourne,
      total: total,
      montantPaye: montantPaye,
      resteAPayer: resteAPayer,
      montantRemis: montantRemis,
      monnaie: monnaie,
    );
    final bytes = await file.readAsBytes();
    if (await file.exists()) {
      await file.delete();
    }
    return bytes;
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
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber}/${context.pagesCount}',
            style: pw.TextStyle(font: times, fontSize: 9, color: PdfColors.grey700),
          ),
        ),
        build: (pw.Context context) => [
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 2),
            ),
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildReceiptHeader(
                  societe: societe,
                  title: 'Rapport d\'inventaire',
                  subtitle: 'Numéro: $numero - ${DateFormat('dd/MM/yyyy').format(date)}',
                  logoImage: logoImage,
                  times: times,
                  timesBold: timesBold,
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

  static Future<File> saveEntriesReport({
    required String numero,
    required DateTime date,
    String? magasinAdresse,
    required String utilisateurNom,
    required List<Map<String, dynamic>> items,
    required double totalValue,
    DateTime? filterStart,
    DateTime? filterEnd,
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
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber}/${context.pagesCount}',
            style: pw.TextStyle(font: times, fontSize: 9, color: PdfColors.grey700),
          ),
        ),
        build: (pw.Context context) => [
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 2),
            ),
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildReceiptHeader(
                  societe: societe,
                  title: 'Rapport des entrées',
                  subtitle: 'Numéro: $numero - ${DateFormat('dd/MM/yyyy').format(date)}',
                  logoImage: logoImage,
                  times: times,
                  timesBold: timesBold,
                ),
                pw.SizedBox(height: 24),
                if (filterStart != null && filterEnd != null)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 12),
                    child: pw.Text(
                      filterStart.isAtSameMomentAs(filterEnd)
                          ? 'Période : ${DateFormat('dd/MM/yyyy').format(filterStart)}'
                          : 'Période : ${DateFormat('dd/MM/yyyy').format(filterStart)} - ${DateFormat('dd/MM/yyyy').format(filterEnd)}',
                      style: pw.TextStyle(font: times, fontSize: 10),
                    ),
                  ),
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
                              '${formatter.format(prixUnitaire)}\u00A0FCFA',
                              style: pw.TextStyle(font: times, fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              '${formatter.format(valeurStock)}\u00A0FCFA',
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
                          'Valeur Totale des Entrées: ${formatter.format(totalValue)}\u00A0FCFA',
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
          pw.SizedBox(height: 10),
          if ((societe['mention'] ?? '').toString().isNotEmpty)
            pw.Text(
              societe['mention'],
              style: pw.TextStyle(font: times, fontSize: 9, color: PdfColors.grey800),
            ),
          if ((societe['message'] ?? '').toString().isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4),
              child: pw.Text(
                societe['message'],
                style: pw.TextStyle(font: timesBold, fontSize: 10, color: PdfColors.blue900),
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
    DateTime? filterStart,
    DateTime? filterEnd,
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
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber}/${context.pagesCount}',
            style: pw.TextStyle(font: times, fontSize: 9, color: PdfColors.grey700),
          ),
        ),
        build: (pw.Context context) => [
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 2),
            ),
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildReceiptHeader(
                  societe: societe,
                  title: 'Rapport des sorties',
                  subtitle: 'Numéro: $numero - ${DateFormat('dd/MM/yyyy').format(date)}',
                  logoImage: logoImage,
                  times: times,
                  timesBold: timesBold,
                ),
                pw.SizedBox(height: 24),
                if (filterStart != null && filterEnd != null)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 12),
                    child: pw.Text(
                      filterStart.isAtSameMomentAs(filterEnd)
                          ? 'Période : ${DateFormat('dd/MM/yyyy').format(filterStart)}'
                          : 'Période : ${DateFormat('dd/MM/yyyy').format(filterStart)} - ${DateFormat('dd/MM/yyyy').format(filterEnd)}',
                      style: pw.TextStyle(font: times, fontSize: 10),
                    ),
                  ),
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
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber}/${context.pagesCount}',
            style: pw.TextStyle(font: times, fontSize: 9, color: PdfColors.grey700),
          ),
        ),
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
                            '${formatter.format((product['prixVente'] is num ? product['prixVente'] as num : num.tryParse(product['prixVente'].toString()))?.toDouble() ?? 0.0)}\u00A0FCFA',
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
                              '${formatter.format(prixUnitaire)}\u00A0FCFA',
                              style: pw.TextStyle(font: times, fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              '${formatter.format(valeurStock)}\u00A0FCFA',
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
                          'Valeur Totale des Entrées: ${formatter.format(totalEntryValue)}\u00A0FCFA',
                          style: pw.TextStyle(font: timesBold, fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          'Valeur Totale des Sorties: ${formatter.format(totalExitValue)}\u00A0FCFA',
                          style: pw.TextStyle(font: timesBold, fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          'Valeur du Stock Actuel: ${formatter.format(currentStockValue)}\u00A0FCFA',
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
      'rc': prefs.getString('societe_rc') ?? '',
      'nif': prefs.getString('societe_nif') ?? '',
      'site': prefs.getString('societe_site') ?? '',
      'mention': prefs.getString('societe_mention') ?? '',
      'message': prefs.getString('societe_message') ?? 'Merci pour votre achat !',
      'logo': prefs.getString('societe_logo'),
    };
  }
}
