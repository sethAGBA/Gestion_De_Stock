import 'dart:io';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'pdf_service.dart';

class ModernInvoiceService {
  // Cache pour les fonts
  static pw.Font? _cachedTimes;
  static pw.Font? _cachedTimesBold;

  static String _dash(String? value) => (value == null || value.trim().isEmpty) ? '-' : value.trim();
  
  // Palettes de couleurs modernes
  // Palette adoucie (gris/bleu foncé)
  static const PdfColor primaryBlue = PdfColor.fromInt(0xFF2D3748); // gris bleuté
  static const PdfColor darkBlue = PdfColor.fromInt(0xFF1F2937); // gris anthracite
  static const PdfColor lightBlue = PdfColor.fromInt(0xFFE5E7EB); // gris clair
  static const PdfColor headerBlue = PdfColor.fromInt(0xFF374151); // gris foncé
  
  // Constantes de mise en forme
  static const double _pageMargin = 0.0;
  static const double _contentPadding = 32.0;
  static const double _headerHeight = 140.0;
  
  /// Charge les fonts avec cache
  static Future<void> _loadFonts() async {
    _cachedTimes ??= pw.Font.times();
    _cachedTimesBold ??= pw.Font.timesBold();
  }

  /// Crée la forme d'onde décorative en haut
  static pw.Widget _buildHeaderWave({
    required PdfColor color,
    required double width,
    required double height,
  }) {
    return pw.Container(
      width: width,
      height: height,
      color: color,
    );
  }

  /// Crée la forme d'onde décorative en bas
  static pw.Widget _buildFooterWave({
    required PdfColor color,
    required double width,
    required double height,
  }) {
    return pw.Container(
      width: width,
      height: height,
      color: color,
    );
  }

  /// En-tête moderne avec logo et vagues
  static pw.Widget _buildModernHeader({
    required Map<String, dynamic> societe,
    required String numero,
    required DateTime date,
    required PdfColor primaryColor,
    pw.ImageProvider? logoImage,
    required pw.Font timesBold,
    required pw.Font times,
  }) {
    final dateFormatter = DateFormat('dd MMM yyyy', 'fr_FR');
    final slogan = (societe['slogan'] ?? '').toString();
    final accountNumber = (societe['account'] ?? societe['compte'] ?? '').toString();
    
    return pw.Container(
      height: _headerHeight,
      child: pw.Stack(
        children: [
          // Vague de fond
          pw.Positioned.fill(
            child: _buildHeaderWave(
              color: primaryColor,
              width: PdfPageFormat.a4.width,
              height: _headerHeight,
            ),
          ),
          
          // Contenu du header
          pw.Positioned.fill(
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(_contentPadding),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Logo et nom société
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      if (logoImage != null)
                        pw.Container(
                          width: 50,
                          height: 50,
                          decoration: pw.BoxDecoration(
                            color: PdfColors.white,
                            borderRadius: pw.BorderRadius.circular(8),
                          ),
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                        ),
                      pw.SizedBox(width: 12),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.Text(
                            (societe['nom'] ?? 'COMPANY').toString().toUpperCase(),
                            style: pw.TextStyle(
                              font: timesBold,
                              fontSize: 16,
                              color: PdfColors.white,
                              letterSpacing: 1,
                            ),
                          ),
                          if ((societe['adresse'] ?? '').toString().isNotEmpty)
                            pw.Text(
                              societe['adresse'],
                              style: pw.TextStyle(
                                font: times,
                                fontSize: 8,
                                color: PdfColors.white,
                              ),
                            ),
                          if ((societe['telephone'] ?? '').toString().isNotEmpty)
                            pw.Text(
                              'Tel: ${societe['telephone']}',
                              style: pw.TextStyle(
                                font: times,
                                fontSize: 8,
                                color: PdfColors.white,
                              ),
                            ),
                          if ((societe['email'] ?? '').toString().isNotEmpty)
                            pw.Text(
                              societe['email'],
                              style: pw.TextStyle(
                                font: times,
                                fontSize: 8,
                                color: PdfColors.white,
                              ),
                            ),
                          if (slogan.isNotEmpty)
                            pw.Text(
                              slogan,
                              style: pw.TextStyle(
                                font: times,
                                fontSize: 8,
                                color: PdfColors.white,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  
                  // Informations facture
                  pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Text(
                          'FACTURE',
                          style: pw.TextStyle(
                            font: timesBold,
                            fontSize: 18,
                            color: primaryColor,
                            letterSpacing: 2,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          'N° Facture',
                          style: pw.TextStyle(
                            font: times,
                            fontSize: 8,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.Text(
                          numero,
                          style: pw.TextStyle(
                            font: timesBold,
                            fontSize: 10,
                            color: PdfColors.black,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        if (accountNumber.isNotEmpty) ...[
                          pw.Text(
                            'Compte',
                            style: pw.TextStyle(
                              font: times,
                              fontSize: 8,
                              color: PdfColors.grey700,
                            ),
                          ),
                          pw.Text(
                            accountNumber,
                            style: pw.TextStyle(
                              font: timesBold,
                              fontSize: 10,
                              color: PdfColors.black,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                        ],
                        pw.Text(
                          'Date facture',
                          style: pw.TextStyle(
                            font: times,
                            fontSize: 8,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.Text(
                          dateFormatter.format(date),
                          style: pw.TextStyle(
                            font: timesBold,
                            fontSize: 10,
                            color: PdfColors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Section informations client et vendeur
  static pw.Widget _buildInfoSection({
    required String? clientNom,
    required String? clientAdresse,
    required String? vendeurNom,
    required String? magasinAdresse,
    required String? modePaiement,
    required String statutPaiement,
    required Map<String, dynamic> societe,
    required pw.Font timesBold,
    required pw.Font times,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: _contentPadding, vertical: 24),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          // Informations client
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'CLIENT',
                  style: pw.TextStyle(
                    font: timesBold,
                    fontSize: 10,
                    color: darkBlue,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  _dash(clientNom) == '-' ? 'Client' : _dash(clientNom),
                  style: pw.TextStyle(
                    font: timesBold,
                    fontSize: 12,
                  ),
                ),
                pw.Text(
                  _dash(clientAdresse),
                  style: pw.TextStyle(
                    font: times,
                    fontSize: 9,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Text(
                  'Mode de paiement: ${_dash(modePaiement)}',
                  style: pw.TextStyle(font: times, fontSize: 9),
                ),
                pw.Text(
                  'Statut: ${_dash(statutPaiement)}',
                  style: pw.TextStyle(font: times, fontSize: 9),
                ),
              ],
            ),
          ),
          
          // Informations société/vendeur
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'ENTITÉ',
                  style: pw.TextStyle(
                    font: timesBold,
                    fontSize: 10,
                    color: darkBlue,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  _dash(magasinAdresse?.isNotEmpty == true ? magasinAdresse : societe['adresse']?.toString()),
                  style: pw.TextStyle(
                    font: times,
                    fontSize: 9,
                    color: PdfColors.grey700,
                  ),
                  textAlign: pw.TextAlign.right,
                ),
                pw.Text(
                  'Vendeur: ${_dash(vendeurNom)}',
                  style: pw.TextStyle(
                    font: times,
                    fontSize: 9,
                    color: PdfColors.grey700,
                  ),
                ),
                if ((societe['telephone'] ?? '').toString().isNotEmpty)
                  pw.Text(
                    societe['telephone'],
                    style: pw.TextStyle(
                      font: times,
                      fontSize: 9,
                      color: PdfColors.grey700,
                    ),
                  ),
                if ((societe['email'] ?? '').toString().isNotEmpty)
                  pw.Text(
                    societe['email'],
                    style: pw.TextStyle(
                      font: times,
                      fontSize: 9,
                      color: PdfColors.grey700,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Tableau des articles moderne
  static pw.Widget _buildModernTable({
    required List<Map<String, dynamic>> items,
    required NumberFormat formatter,
    required NumberFormat qtyFormatter,
    required pw.Font timesBold,
    required pw.Font times,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: _contentPadding),
      child: pw.Table(
        border: pw.TableBorder.symmetric(
          outside: pw.BorderSide.none,
        ),
        columnWidths: {
          0: const pw.FixedColumnWidth(30),
          1: const pw.FlexColumnWidth(3),
          2: const pw.FlexColumnWidth(1),
          3: const pw.FlexColumnWidth(1),
          4: const pw.FlexColumnWidth(1),
        },
        children: [
          // En-tête du tableau
          pw.TableRow(
              decoration: pw.BoxDecoration(
                color: primaryBlue,
                borderRadius: pw.BorderRadius.vertical(
                  top: pw.Radius.circular(8),
                ),
              ),
              children: [
              _buildTableHeader('No', timesBold),
              _buildTableHeader('Désignation', timesBold, align: pw.TextAlign.left),
              _buildTableHeader('Prix', timesBold, align: pw.TextAlign.right),
              _buildTableHeader('Qté', timesBold, align: pw.TextAlign.center),
              _buildTableHeader('Total', timesBold, align: pw.TextAlign.right),
              ],
            ),
          
          // Lignes du tableau
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final q = (item['quantite'] as num?)?.toDouble() ?? 0;
            final pu = (item['prixUnitaire'] as num?)?.toDouble() ?? 0;
            final total = q * pu;
            final nom = item['produitNom']?.toString() ?? 
                        item['nom']?.toString() ?? 
                        'Produit';
            final lot = item['lot'] ?? item['numeroLot'];
            final exp = item['dateExpiration'] is int
                ? DateTime.fromMillisecondsSinceEpoch(item['dateExpiration'] as int)
                : null;
            
            return pw.TableRow(
              decoration: pw.BoxDecoration(
                color: index.isEven ? PdfColors.white : lightBlue,
              ),
              children: [
                _buildTableCell('${index + 1}', times),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(10),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        nom,
                        style: pw.TextStyle(font: times, fontSize: 9),
                        textAlign: pw.TextAlign.left,
                      ),
                      if (lot != null || exp != null)
                        pw.Text(
                          [
                            if (lot != null) 'Lot: $lot',
                            if (exp != null) 'Exp: ${DateFormat('dd/MM/yy').format(exp)}',
                          ].join(' • '),
                          style: pw.TextStyle(font: times, fontSize: 7, color: PdfColors.grey700),
                        ),
                    ],
                  ),
                ),
                _buildTableCell('${formatter.format(pu)} FCFA', times, align: pw.TextAlign.right),
                _buildTableCell(qtyFormatter.format(q), times, align: pw.TextAlign.center),
                _buildTableCell('${formatter.format(total)} FCFA', times, align: pw.TextAlign.right),
              ],
            );
          }),
        ],
      ),
    );
  }

  /// Cellule d'en-tête de tableau
  static pw.Widget _buildTableHeader(
    String text,
    pw.Font font, {
    pw.TextAlign align = pw.TextAlign.center,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(10),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: 9,
          color: PdfColors.white,
        ),
        textAlign: align,
      ),
    );
  }

  /// Cellule de tableau
  static pw.Widget _buildTableCell(
    String text,
    pw.Font font, {
    pw.TextAlign align = pw.TextAlign.center,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(10),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: 9,
        ),
        textAlign: align,
      ),
    );
  }

  /// Résumé financier moderne
  static pw.Widget _buildModernSummary({
    required double sousTotal,
    required double ristourne,
    required double total,
    required double montantPaye,
    required double resteAPayer,
    double? montantRemis,
    double? monnaie,
    required String vendeurNom,
    required String? modePaiement,
    required String? magasinAdresse,
    required String statutPaiement,
    required Map<String, dynamic> societe,
    required NumberFormat formatter,
    required pw.Font timesBold,
    required pw.Font times,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: _contentPadding, vertical: 24),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          // Section Payment Info
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: lightBlue,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Infos de paiement',
                    style: pw.TextStyle(
                      font: timesBold,
                      fontSize: 10,
                      color: darkBlue,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text('Montant: ${formatter.format(total)} FCFA', style: pw.TextStyle(font: times, fontSize: 9)),
                  pw.Text('Compte: ${_dash(societe['account']?.toString() ?? societe['compte']?.toString())}', style: pw.TextStyle(font: times, fontSize: 9)),
                  pw.Text('Banque: ${_dash(societe['banque']?.toString())}', style: pw.TextStyle(font: times, fontSize: 9)),
                  pw.SizedBox(height: 8),
                  pw.Text('Mode: ${_dash(modePaiement)}', style: pw.TextStyle(font: times, fontSize: 9)),
                  pw.Text('Statut: ${_dash(statutPaiement)}', style: pw.TextStyle(font: times, fontSize: 9)),
                  pw.Text('Vendeur: ${_dash(vendeurNom)}', style: pw.TextStyle(font: times, fontSize: 9)),
                  pw.Text(
                    'Entité: ${_dash(magasinAdresse?.isNotEmpty == true ? magasinAdresse : societe['nom']?.toString())}',
                    style: pw.TextStyle(font: times, fontSize: 9),
                  ),
                ],
              ),
            ),
          ),
          
          pw.SizedBox(width: 40),
          
          // Totaux
          pw.Container(
            width: 220,
            child: pw.Column(
              children: [
                _buildSummaryRow('Sous-total', formatter.format(sousTotal), times),
                if (ristourne > 0)
                  _buildSummaryRow('Taxe/Remise', formatter.format(ristourne), times),
                _buildSummaryRow('Montant payé', formatter.format(montantPaye), times),
                if (montantRemis != null)
                  _buildSummaryRow('Montant remis', formatter.format(montantRemis), times),
                if (monnaie != null)
                  _buildSummaryRow('Monnaie', formatter.format(monnaie), times),
                _buildSummaryRow('Reste à payer', formatter.format(resteAPayer), times),
                pw.Divider(thickness: 1, color: PdfColors.grey400),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: pw.BoxDecoration(
                    color: darkBlue,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'TOTAL',
                        style: pw.TextStyle(
                          font: timesBold,
                          fontSize: 14,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.Text(
                        '${formatter.format(total)} FCFA',
                        style: pw.TextStyle(
                          font: timesBold,
                          fontSize: 14,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Ligne de résumé
  static pw.Widget _buildSummaryRow(String label, String value, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(font: font, fontSize: 10)),
          pw.Text('$value FCFA', style: pw.TextStyle(font: font, fontSize: 10)),
        ],
      ),
    );
  }

  /// Footer moderne avec QR code et signature
  static pw.Widget _buildModernFooter({
    required Map<String, dynamic> societe,
    required String numero,
    required int pageNumber,
    required int totalPages,
    required PdfColor primaryColor,
    required String vendeurNom,
    required pw.Font timesBold,
    required pw.Font times,
  }) {
    return pw.Container(
      height: 120,
      child: pw.Stack(
        children: [
          // Vague de fond
          pw.Positioned.fill(
            child: _buildFooterWave(
              color: primaryColor,
              width: PdfPageFormat.a4.width,
              height: 120,
            ),
          ),
          
          // Contenu
          pw.Positioned.fill(
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(_contentPadding),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Bloc gauche : QR + message + mentions
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        child: pw.BarcodeWidget(
                          data: 'INVOICE:$numero',
                          barcode: pw.Barcode.qrCode(),
                          width: 60,
                          height: 60,
                        ),
                      ),
                      pw.SizedBox(width: 16),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.Text(
                            (societe['message'] ?? 'Merci pour votre achat !').toString(),
                            style: pw.TextStyle(
                              font: timesBold,
                              fontSize: 10,
                              color: PdfColors.white,
                            ),
                          ),
                          if ((societe['email'] ?? '').toString().isNotEmpty)
                            pw.Text(
                              societe['email'],
                              style: pw.TextStyle(
                                font: times,
                                fontSize: 7,
                                color: PdfColors.white,
                              ),
                            ),
                          if ((societe['adresse'] ?? '').toString().isNotEmpty)
                            pw.Text(
                              societe['adresse'],
                              style: pw.TextStyle(
                                font: times,
                                fontSize: 7,
                                color: PdfColors.white,
                              ),
                            ),
                          if ((societe['telephone'] ?? '').toString().isNotEmpty)
                            pw.Text(
                              societe['telephone'],
                              style: pw.TextStyle(
                                font: times,
                                fontSize: 7,
                                color: PdfColors.white,
                              ),
                            ),
                          if ((societe['nif'] ?? '').toString().isNotEmpty)
                            pw.Text(
                              'NIF: ${societe['nif']}',
                              style: pw.TextStyle(
                                font: times,
                                fontSize: 7,
                                color: PdfColors.white,
                              ),
                            ),
                          if ((societe['rc'] ?? '').toString().isNotEmpty)
                            pw.Text(
                              'RCCM: ${societe['rc']}',
                              style: pw.TextStyle(
                                font: times,
                                fontSize: 7,
                                color: PdfColors.white,
                              ),
                            ),
                          if ((societe['mention'] ?? '').toString().isNotEmpty)
                            pw.Text(
                              societe['mention'],
                              style: pw.TextStyle(
                                font: times,
                                fontSize: 7,
                                color: PdfColors.white,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  
                  // Bloc droit : vendeur + page
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.Text(
                        'Vendeur: ${_dash(vendeurNom)}',
                        style: pw.TextStyle(
                          font: timesBold,
                          fontSize: 10,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.Text(
                        'Page $pageNumber/$totalPages',
                        style: pw.TextStyle(
                          font: times,
                          fontSize: 8,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Génère une facture moderne au format A4
  static Future<File> generateModernInvoice({
    required String numero,
    required DateTime date,
    required String? clientNom,
    required String? clientAdresse,
    required String? magasinAdresse,
    required String vendeurNom,
    String? modePaiement,
    String? statutPaiement,
    required List<Map<String, dynamic>> items,
    required double sousTotal,
    required double ristourne,
    required double total,
    required double montantPaye,
    required double resteAPayer,
    double? montantRemis,
    double? monnaie,
    PdfColor? customColor,
  }) async {
    // Validation
    if (items.isEmpty) {
      throw ArgumentError('La liste des articles ne peut pas être vide');
    }

    await _loadFonts();
    final pdf = pw.Document();
    final formatter = NumberFormat('#,##0.00', 'fr_FR');
    final qtyFormatter = NumberFormat('#,##0.##', 'fr_FR');
    final times = _cachedTimes!;
    final timesBold = _cachedTimesBold!;

    // Informations société
    final societe = await PdfService.getSocieteInfo();
    
    // Logo
    pw.ImageProvider? logoImage;
    final logoPath = societe['logo'];
    if (logoPath != null && logoPath.toString().isNotEmpty) {
      final logoFile = File(logoPath);
      if (await logoFile.exists()) {
        try {
          final logoBytes = await logoFile.readAsBytes();
          logoImage = pw.MemoryImage(logoBytes);
        } catch (e) {
          print('Erreur chargement logo: $e');
        }
      }
    }

    final primaryColor = customColor ?? primaryBlue;
    final statut = statutPaiement ?? (resteAPayer <= 0 ? 'Payé' : 'En attente');

    // Construction du PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(_pageMargin),
        header: (context) => _buildModernHeader(
          societe: societe,
          numero: numero,
          date: date,
          primaryColor: primaryColor,
          logoImage: logoImage,
          timesBold: timesBold,
          times: times,
        ),
        footer: (context) => _buildModernFooter(
          societe: societe,
          numero: numero,
          pageNumber: context.pageNumber,
          totalPages: context.pagesCount,
          primaryColor: primaryColor,
          vendeurNom: vendeurNom,
          timesBold: timesBold,
          times: times,
        ),
        build: (context) => [
          // Informations client/société
          _buildInfoSection(
            clientNom: clientNom,
            clientAdresse: clientAdresse,
            vendeurNom: vendeurNom,
            magasinAdresse: magasinAdresse,
            modePaiement: modePaiement,
            statutPaiement: statut,
            societe: societe,
            timesBold: timesBold,
            times: times,
          ),
          
          // Tableau des articles
          _buildModernTable(
            items: items,
            formatter: formatter,
            qtyFormatter: qtyFormatter,
            timesBold: timesBold,
            times: times,
          ),
          
          // Résumé financier
          _buildModernSummary(
            sousTotal: sousTotal,
            ristourne: ristourne,
            total: total,
            montantPaye: montantPaye,
            resteAPayer: resteAPayer,
            montantRemis: montantRemis,
            monnaie: monnaie,
            vendeurNom: vendeurNom,
            modePaiement: modePaiement,
            magasinAdresse: magasinAdresse,
            statutPaiement: statut,
            societe: societe,
            formatter: formatter,
            timesBold: timesBold,
            times: times,
          ),
        ],
      ),
    );

    // Sauvegarde
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/facture_moderne_$numero.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// Nettoie le cache
  static void clearCache() {
    _cachedTimes = null;
    _cachedTimesBold = null;
  }
}
