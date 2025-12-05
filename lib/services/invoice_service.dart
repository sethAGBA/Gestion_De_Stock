import 'package:share_plus/share_plus.dart';
import 'facture.dart';

class InvoiceService {
  static Future<List<int>> getInvoiceBytes({
    required String numero,
    required DateTime date,
    required String? clientNom,
    required String? clientAdresse,
    required String? magasinAdresse,
    String? vendeurNom,
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
  }) async {
    final file = await ModernInvoiceService.generateModernInvoice(
      numero: numero,
      date: date,
      clientNom: clientNom,
      clientAdresse: clientAdresse,
      magasinAdresse: magasinAdresse,
      vendeurNom: vendeurNom ?? 'Non spécifié',
      modePaiement: modePaiement,
      statutPaiement: statutPaiement ?? (resteAPayer <= 0 ? 'Payé' : 'En attente'),
      items: items,
      sousTotal: sousTotal,
      ristourne: ristourne,
      total: total,
      montantPaye: montantPaye,
      resteAPayer: resteAPayer,
      montantRemis: montantRemis,
      monnaie: monnaie,
    );
    return await file.readAsBytes();
  }

  static Future<void> shareInvoice({
    required String numero,
    required DateTime date,
    required String? clientNom,
    required String? clientAdresse,
    required String? magasinAdresse,
    String? vendeurNom,
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
  }) async {
    final file = await ModernInvoiceService.generateModernInvoice(
      numero: numero,
      date: date,
      clientNom: clientNom,
      clientAdresse: clientAdresse,
      magasinAdresse: magasinAdresse,
      vendeurNom: vendeurNom ?? 'Non spécifié',
      modePaiement: modePaiement,
      statutPaiement: statutPaiement ?? (resteAPayer <= 0 ? 'Payé' : 'En attente'),
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
}
