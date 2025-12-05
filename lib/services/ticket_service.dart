import 'dart:io';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'pdf_service.dart';

class TicketService {
  // Cache pour les fonts
  static pw.Font? _cachedTimes;
  static pw.Font? _cachedTimesBold;
  
  // Constantes de mise en forme
  static const double _ticketWidth = 80.0; // mm
  static const double _logoHeight = 40.0;
  static const double _spacing = 4.0;
  static const double _sectionSpacing = 8.0;
  
  // Tailles de police
  static const double _fontSizeHeader = 11.0;
  static const double _fontSizeTitle = 10.0;
  static const double _fontSizeNormal = 8.0;
  static const double _fontSizeSmall = 7.0;
  static const double _fontSizeTiny = 6.5;

  static String _dash(String? value) => 
    (value == null || value.trim().isEmpty) ? '-' : value.trim();

  /// Charge les fonts avec cache
  static Future<void> _loadFonts() async {
    _cachedTimes ??= pw.Font.times();
    _cachedTimesBold ??= pw.Font.timesBold();
  }

  /// Crée une ligne de séparation simple
  static pw.Widget _buildSeparator({double thickness = 0.5}) {
    return pw.Container(
      margin: pw.EdgeInsets.symmetric(vertical: _spacing),
      child: pw.Divider(
        thickness: thickness,
        color: PdfColors.grey800,
      ),
    );
  }

  /// Crée une ligne pointillée
  static pw.Widget _buildDashedLine() {
    return pw.Container(
      margin: pw.EdgeInsets.symmetric(vertical: _spacing),
      child: pw.Row(
        children: List.generate(
          50,
          (index) => pw.Container(
            width: 2,
            height: 0.5,
            color: PdfColors.grey800,
            margin: const pw.EdgeInsets.only(right: 2),
          ),
        ),
      ),
    );
  }

  /// En-tête du ticket (logo + infos société)
  static pw.Widget _buildHeader(
    Map<String, dynamic> societe,
    pw.ImageProvider? logoImage,
    pw.Font timesBold,
    pw.Font times,
  ) {
    return pw.Column(
      children: [
        // Logo centré
        if (logoImage != null)
          pw.Center(
            child: pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Image(logoImage, height: _logoHeight),
            ),
          ),
        
        // Nom de la société en gras
        if ((societe['nom'] ?? '').toString().isNotEmpty)
          pw.Center(
            child: pw.Text(
              societe['nom'].toString().toUpperCase(),
              style: pw.TextStyle(
                font: timesBold,
                fontSize: _fontSizeHeader,
                letterSpacing: 0.5,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
        
        // Adresse
        if ((societe['adresse'] ?? '').toString().isNotEmpty)
          pw.Center(
            child: pw.Text(
              societe['adresse'],
              style: pw.TextStyle(font: times, fontSize: _fontSizeTiny),
              textAlign: pw.TextAlign.center,
            ),
          ),
        
        // Contact
        if ((societe['email'] ?? '').toString().isNotEmpty)
          pw.Center(
            child: pw.Text(
              societe['email'],
              style: pw.TextStyle(font: times, fontSize: _fontSizeTiny),
              textAlign: pw.TextAlign.center,
            ),
          ),
        if ((societe['telephone'] ?? '').toString().isNotEmpty)
          pw.Center(
            child: pw.Text(
              'Tel: ${_dash(societe['telephone'])}',
              style: pw.TextStyle(font: times, fontSize: _fontSizeTiny),
              textAlign: pw.TextAlign.center,
            ),
          ),
        if ((societe['rc'] ?? '').toString().isNotEmpty || (societe['nif'] ?? '').toString().isNotEmpty)
          pw.Center(
            child: pw.Text(
              'RC: ${_dash(societe['rc'])} | NIF: ${_dash(societe['nif'])}',
              style: pw.TextStyle(font: times, fontSize: _fontSizeTiny),
              textAlign: pw.TextAlign.center,
            ),
          ),
        
        pw.SizedBox(height: 2),
      ],
    );
  }

  /// Section informations ticket
  static pw.Widget _buildTicketInfo({
    required String numero,
    required DateTime date,
    required String? caissier,
    required String? clientNom,
    required pw.Font timesBold,
    required pw.Font times,
    String? magasin,
    String? modePaiement,
    String? statut,
  }) {
    final dateFormatter = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSeparator(),
        
        // Titre TICKET DE CAISSE
        pw.Center(
          child: pw.Text(
            'TICKET DE CAISSE : $numero',
            style: pw.TextStyle(
              font: timesBold,
              fontSize: _fontSizeTitle,
            ),
          ),
        ),
        
        pw.SizedBox(height: _spacing),
        
        // Caissier
        if (caissier != null && caissier.isNotEmpty)
          pw.Text(
            'Caisse ${_dash(caissier)}',
            style: pw.TextStyle(font: times, fontSize: _fontSizeSmall),
          ),
        if (magasin != null && magasin.isNotEmpty)
          pw.Text(
            'Magasin: ${_dash(magasin)}',
            style: pw.TextStyle(font: times, fontSize: _fontSizeSmall),
          ),
        
        // Date et heure
        pw.Text(
          dateFormatter.format(date),
          style: pw.TextStyle(font: times, fontSize: _fontSizeSmall),
        ),
        
        // Client (si présent)
        pw.Text(
          'Client: ${_dash(clientNom)}',
          style: pw.TextStyle(font: times, fontSize: _fontSizeSmall),
        ),
        pw.Text(
          'Paiement: ${_dash(modePaiement)}',
          style: pw.TextStyle(font: times, fontSize: _fontSizeSmall),
        ),
        pw.Text(
          'Statut: ${_dash(statut)}',
          style: pw.TextStyle(font: timesBold, fontSize: _fontSizeSmall),
        ),
        
        _buildSeparator(),
      ],
    );
  }

  /// Ligne de produit individuelle
  static List<pw.Widget> _buildProductLine({
    required String nom,
    required double quantite,
    required double prixUnitaire,
    required double total,
    String? lot,
    DateTime? expiration,
    required NumberFormat formatter,
    required NumberFormat qtyFormatter,
    required pw.Font timesBold,
    required pw.Font times,
  }) {
    return [
      // Nom du produit en gras
      pw.Text(
        nom,
        style: pw.TextStyle(font: timesBold, fontSize: _fontSizeNormal),
      ),
      
      // Quantité x Prix = Total
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            '${qtyFormatter.format(quantite)} x ${formatter.format(prixUnitaire)}',
            style: pw.TextStyle(font: times, fontSize: _fontSizeSmall),
          ),
          pw.Text(
            '${formatter.format(total)} FCFA',
            style: pw.TextStyle(font: times, fontSize: _fontSizeSmall),
          ),
        ],
      ),
      if ((lot != null && lot.isNotEmpty) || expiration != null)
        pw.Text(
          [
            if (lot != null && lot.isNotEmpty) 'Lot: $lot',
            if (expiration != null) 'Exp: ${DateFormat('dd/MM/yy').format(expiration)}',
          ].join(' • '),
          style: pw.TextStyle(font: times, fontSize: _fontSizeTiny, color: PdfColors.grey700),
        ),
      
      pw.SizedBox(height: 3),
    ];
  }

  /// Résumé financier
  static pw.Widget _buildFinancialSummary({
    required double sousTotal,
    required double ristourne,
    required double total,
    required double montantPaye,
    required double? montantRemis,
    required double resteAPayer,
    required double? monnaie,
    required NumberFormat formatter,
    required pw.Font timesBold,
    required pw.Font times,
    required String statut,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _buildDashedLine(),
        
        // Sous-total
        // Sous-total toujours affiché
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Sous-total',
              style: pw.TextStyle(font: times, fontSize: _fontSizeNormal),
            ),
            pw.Text(
              '${formatter.format(sousTotal)} FCFA',
              style: pw.TextStyle(font: times, fontSize: _fontSizeNormal),
            ),
          ],
        ),
        
        // Ristourne si > 0
        if (ristourne > 0)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Remise',
                style: pw.TextStyle(font: times, fontSize: _fontSizeNormal),
              ),
              pw.Text(
                '-${formatter.format(ristourne)} FCFA',
                style: pw.TextStyle(font: times, fontSize: _fontSizeNormal),
              ),
            ],
          ),
        
        pw.SizedBox(height: 2),
        
        // TOTAL en gras et plus grand
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'TOTAL',
              style: pw.TextStyle(
                font: timesBold,
                fontSize: _fontSizeTitle,
              ),
            ),
            pw.Text(
              '${formatter.format(total)} FCFA',
              style: pw.TextStyle(
                font: timesBold,
                fontSize: _fontSizeTitle,
              ),
            ),
          ],
        ),
        
        _buildDashedLine(),
        
        // Montant payé
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Montant payé',
              style: pw.TextStyle(font: times, fontSize: _fontSizeSmall),
            ),
            pw.Text(
              '${formatter.format(montantPaye)} FCFA',
              style: pw.TextStyle(font: times, fontSize: _fontSizeSmall),
            ),
          ],
        ),
        
        // Montant remis (si présent)
        if (montantRemis != null)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Montant remis',
                style: pw.TextStyle(font: times, fontSize: _fontSizeSmall),
              ),
              pw.Text(
                '${formatter.format(montantRemis)} FCFA',
                style: pw.TextStyle(font: times, fontSize: _fontSizeSmall),
              ),
            ],
          ),
        
        // Reste à payer (si > 0)
        if (resteAPayer > 0)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Reste dû',
                style: pw.TextStyle(
                  font: timesBold,
                  fontSize: _fontSizeSmall,
                ),
              ),
              pw.Text(
                '${formatter.format(resteAPayer)} FCFA',
                style: pw.TextStyle(
                  font: timesBold,
                  fontSize: _fontSizeSmall,
                ),
              ),
            ],
          ),
        
        // Monnaie rendue (si > 0)
        if (monnaie != null && monnaie > 0)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Monnaie rendue',
                style: pw.TextStyle(font: times, fontSize: _fontSizeSmall),
              ),
              pw.Text(
                '${formatter.format(monnaie)} FCFA',
                style: pw.TextStyle(font: times, fontSize: _fontSizeSmall),
              ),
            ],
          ),
        pw.SizedBox(height: 2),
        pw.Text(
          'Statut: $statut',
          style: pw.TextStyle(font: timesBold, fontSize: _fontSizeSmall),
          textAlign: pw.TextAlign.right,
        ),
      ],
    );
  }

  /// Footer avec message et QR code optionnel
  static pw.Widget _buildFooter({
    required Map<String, dynamic> societe,
    required String numero,
    required pw.Font timesBold,
    required pw.Font times,
    bool includeQrCode = true,
  }) {
    return pw.Column(
      children: [
        _buildDashedLine(),
        
        // Mentions légales
        if ((societe['mention'] ?? '').toString().isNotEmpty)
          pw.Center(
            child: pw.Text(
              societe['mention'],
              style: pw.TextStyle(font: times, fontSize: _fontSizeTiny),
              textAlign: pw.TextAlign.center,
            ),
          ),
        
        pw.SizedBox(height: _spacing),
        
        // Message de remerciement
        if ((societe['message'] ?? '').toString().isNotEmpty)
          pw.Center(
            child: pw.Text(
              societe['message'],
              style: pw.TextStyle(
                font: timesBold,
                fontSize: _fontSizeNormal,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
        
        // QR Code
        if (includeQrCode) ...[
          pw.SizedBox(height: _sectionSpacing),
          pw.Center(
            child: pw.BarcodeWidget(
              data: 'TICKET:$numero',
              barcode: pw.Barcode.qrCode(),
              width: 60,
              height: 60,
            ),
          ),
        ],
      ],
    );
  }

  /// Génère un ticket de caisse au format 80mm
  static Future<List<int>> getTicketBytes({
    required String numero,
    required DateTime date,
    required String? clientNom,
    required String? clientAdresse,
    required String? magasinAdresse,
    required String? vendeurNom,
    String? modePaiement,
    required List<Map<String, dynamic>> items,
    required double sousTotal,
    required double ristourne,
    required double total,
    required double montantPaye,
    required double resteAPayer,
    double? montantRemis,
    double? monnaie,
    bool includeQrCode = true,
  }) async {
    // Validation
    if (items.isEmpty) {
      throw ArgumentError('La liste des articles ne peut pas être vide');
    }
    if (numero.isEmpty) {
      throw ArgumentError('Le numéro de facture est requis');
    }

    // Chargement des ressources
    await _loadFonts();
    final pdf = pw.Document();
    final formatter = NumberFormat('#,##0.00', 'fr_FR');
    final qtyFormatter = NumberFormat('#,##0.##', 'fr_FR');
    final times = _cachedTimes!;
    final timesBold = _cachedTimesBold!;

    // Informations société
    final societe = await PdfService.getSocieteInfo();
    final statut = resteAPayer <= 0 ? 'Payé' : 'En attente';
    
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

    // Construction du PDF
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          _ticketWidth * PdfPageFormat.mm,
          double.infinity,
        ),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // En-tête
            _buildHeader(societe, logoImage, timesBold, times),
            
            // Infos ticket
            _buildTicketInfo(
              numero: numero,
              date: date,
              caissier: vendeurNom,
              clientNom: clientNom,
              magasin: magasinAdresse,
              modePaiement: modePaiement,
              statut: statut,
              timesBold: timesBold,
              times: times,
            ),
            
            // Liste des produits
            ...items.expand((item) {
              final q = (item['quantite'] as num?)?.toDouble() ?? 0;
              final pu = (item['prixUnitaire'] as num?)?.toDouble() ?? 0;
              final totalLigne = q * pu;
              final nomProduit = item['produitNom']?.toString() ?? 
                                 item['nom']?.toString() ?? 
                                 'Produit';
              final lot = (item['lot'] ?? item['numeroLot'])?.toString();
              final exp = item['dateExpiration'] is int
                  ? DateTime.fromMillisecondsSinceEpoch(item['dateExpiration'] as int)
                  : null;
              
              return _buildProductLine(
                nom: nomProduit,
                quantite: q,
                prixUnitaire: pu,
                total: totalLigne,
                lot: lot,
                expiration: exp,
                formatter: formatter,
                qtyFormatter: qtyFormatter,
                timesBold: timesBold,
                times: times,
              );
            }),
            
            // Résumé financier
            _buildFinancialSummary(
              sousTotal: sousTotal,
              ristourne: ristourne,
              total: total,
              montantPaye: montantPaye,
              montantRemis: montantRemis,
              resteAPayer: resteAPayer,
              monnaie: monnaie,
              formatter: formatter,
              timesBold: timesBold,
              times: times,
              statut: statut,
            ),
            
            // Footer
            _buildFooter(
              societe: societe,
              numero: numero,
              timesBold: timesBold,
              times: times,
              includeQrCode: includeQrCode,
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  /// Nettoie le cache
  static void clearCache() {
    _cachedTimes = null;
    _cachedTimesBold = null;
  }
}
