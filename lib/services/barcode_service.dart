import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/models.dart';

class BarcodeService {
  static const double _labelWidth = 200;
  static const double _labelPadding = 8;

  static Future<File> generateBarcodesPdf(List<Produit> produits) async {
    final pdf = pw.Document();
    final dateStamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(16),
        build: (context) => [
          pw.Wrap(
            spacing: 12,
            runSpacing: 12,
            children: produits.map((p) {
              final data = (p.codeBarres?.isNotEmpty ?? false)
                  ? p.codeBarres!
                  : (p.sku?.isNotEmpty ?? false)
                      ? p.sku!
                      : 'SKU-${p.id}';
              return pw.Container(
                width: _labelWidth,
                padding: const pw.EdgeInsets.all(_labelPadding),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey500),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      p.nom,
                      maxLines: 2,
                      overflow: pw.TextOverflow.clip,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.BarcodeWidget(
                      data: data,
                      barcode: pw.Barcode.code128(),
                      width: _labelWidth - (_labelPadding * 3),
                      height: 50,
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      data,
                      style: pw.TextStyle(fontSize: 8),
                    ),
                    if (p.sku != null && p.sku!.isNotEmpty && p.sku != data)
                      pw.Text(
                        'SKU: ${p.sku}',
                        style: pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/barcodes_$dateStamp.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
