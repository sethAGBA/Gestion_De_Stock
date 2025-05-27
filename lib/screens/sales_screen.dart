import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:stock_management/helpers/database_helper.dart';
import 'package:stock_management/widgets/facture_dialog.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import 'package:file_saver/file_saver.dart';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({Key? key}) : super(key: key);

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> with SingleTickerProviderStateMixin {
  late Future<List<Facture>> _facturesFuture;
  String _searchQuery = '';
  String _selectedFilter = 'Toutes';
  DateTime? _selectedDay;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedVendor;
  List<String> _vendors = [];
  List<Map<String, dynamic>> _salesByProduct = [];
  List<Map<String, dynamic>> _salesByVendor = [];
  double _totalCA = 0.0;
  bool _isLoadingStats = false;
  String? _sortOrder;
  final _futureKey = GlobalKey();
  User? _currentUser;
  String? _logoPath;

  @override
  void initState() {
    super.initState();
    _facturesFuture = Future.value([]);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
      setState(() {
        _currentUser = user;
      });
      _initDatabase().then((_) {
        setState(() {
          _facturesFuture = DatabaseHelper.getFactures(
            includeArchived: true,
            vendeurNom: (user != null && user.role == 'Vendeur') ? user.name : null,
          );
        });
        _loadVendors();
        _loadStatistics();
        _loadLogoPath();
      }).catchError((e) {
        print('Erreur lors de l\'initialisation de la base de données : $e');
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Erreur'),
            content: Text('Erreur d\'initialisation : $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      });
    });
  }

  Future<void> _initDatabase() async {
    try {
      print('Initialisation de la base de données...');
      await DatabaseHelper.database;
    } catch (e) {
      print('Erreur dans _initDatabase : $e');
      throw e;
    }
  }

  Future<void> _loadVendors() async {
    final vendors = await DatabaseHelper.getVendors();
    setState(() {
      _vendors = vendors;
    });
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoadingStats = true);
    String? vendorToUse = _selectedVendor;
    if (_currentUser != null && _currentUser!.role == 'Vendeur') {
      vendorToUse = _currentUser!.name;
    }
    final salesByProduct = await DatabaseHelper.getSalesByProduct(
      specificDay: _selectedDay,
      startDate: _startDate,
      endDate: _endDate,
      vendor: vendorToUse,
    );
    final salesByVendor = await DatabaseHelper.getSalesByVendor(
      specificDay: _selectedDay,
      startDate: _startDate,
      endDate: _endDate,
      vendor: vendorToUse,
    );
    final totalCA = await DatabaseHelper.getTotalCA(
      specificDay: _selectedDay,
      startDate: _startDate,
      endDate: _endDate,
      vendor: vendorToUse,
    );
    setState(() {
      _salesByProduct = salesByProduct;
      _salesByVendor = salesByVendor;
      _totalCA = totalCA;
      _isLoadingStats = false;
    });
  }

  Future<void> _generateAndPrintPdf() async {
    final pdf = pw.Document();
    final dateFormat = NumberFormat('#,##0.00', 'fr_FR');

    pw.ImageProvider? logoImage;
    if (_logoPath != null && File(_logoPath!).existsSync()) {
      final logoBytes = File(_logoPath!).readAsBytesSync();
      logoImage = pw.MemoryImage(logoBytes);
    }

    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) => [
          if (logoImage != null)
            pw.Center(
              child: pw.Image(logoImage, height: 80),
            ),
          pw.SizedBox(height: 10),
          pw.Header(level: 0, child: pw.Text('Rapport des Statistiques des Ventes')),
          pw.SizedBox(height: 20),
          if (_selectedDay != null)
            pw.Text('Date: ${DateFormat('dd/MM/yyyy').format(_selectedDay!)}'),
          if (_startDate != null && _endDate != null)
            pw.Text('Période: ${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}'),
          if (_selectedVendor != null)
            pw.Text('Vendeur: $_selectedVendor'),
          pw.SizedBox(height: 20),
          pw.Text('Chiffre d\'Affaires Total: ${dateFormat.format(_totalCA)} FCFA'),
          pw.SizedBox(height: 20),
          pw.Text('Ventes par Produit', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Table.fromTextArray(
            headers: ['Produit', 'Unité', 'Quantité', 'CA (FCFA)'],
            data: _salesByProduct.map((sale) => [
              sale['nom'].toString(),
              sale['unite'].toString(),
              sale['totalQuantite'].toString(),
              dateFormat.format(sale['totalCA']),
            ]).toList(),
          ),
          pw.SizedBox(height: 20),
          pw.Text('Ventes par Vendeur', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Table.fromTextArray(
            headers: ['Vendeur', 'Factures', 'CA (FCFA)'],
            data: _salesByVendor.map((sale) => [
              sale['vendeurNom'].toString(),
              sale['invoiceCount'].toString(),
              dateFormat.format(sale['totalCA']),
            ]).toList(),
          ),
        ],
      ),
    );

    final pdfBytes = await pdf.save();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exporter le PDF'),
        content: const Text('Que souhaitez-vous faire avec le PDF généré ?'),
        actions: [
         TextButton(
  onPressed: () async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'statistiques_ventes_${DateTime.now().toIso8601String()}.pdf';
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(pdfBytes);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('PDF sauvegardé dans Documents : $fileName')),
    );
  },
  child: const Text('Enregistrer'),
),
          TextButton(
            onPressed: () async {
              await Printing.sharePdf(
                bytes: pdfBytes,
                filename: 'statistiques_ventes_${DateTime.now().toIso8601String()}.pdf',
              );
              Navigator.pop(context);
            },
            child: const Text('Partager'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  void _showFactureDetails(Facture facture) async {
    final db = await DatabaseHelper.database;
    final items = await db.rawQuery(
      '''
      SELECT bci.*, p.nom AS produitNom, p.unite
      FROM bon_commande_items bci
      JOIN produits p ON bci.produitId = p.id
      WHERE bci.bonCommandeId = ?
    ''',
      [facture.bonCommandeId],
    );
    final paiements = await db.query(
      'paiements',
      where: 'factureId = ?',
      whereArgs: [facture.id],
    );
    FactureArchivee? archivedFacture;
    if (facture.statut == 'Annulée') {
      final archived = await DatabaseHelper.getArchivedFacture(facture.id);
      archivedFacture = archived;
    }
    final formatter = NumberFormat('#,##0.00', 'fr_FR');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails de la facture ${facture.numero}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Client', facture.clientNom ?? 'Non spécifié'),
              _buildInfoRow('Adresse', facture.adresse ?? 'Non spécifiée'),
              _buildInfoRow('Adresse fournisseur', facture.magasinAdresse ?? 'Non spécifié'),
              _buildInfoRow('Vendeur', facture.vendeurNom ?? 'Non spécifié'),
              _buildInfoRow('Date', '${DateFormat('dd/MM/yyyy').format(facture.date)} à ${DateFormat('HH:mm').format(facture.date)}'),
              _buildInfoRow('Statut', facture.statut),
              _buildInfoRow('Statut paiement', facture.statutPaiement),
              _buildInfoRow('Total', '${formatter.format(facture.total)} FCFA'),
              _buildInfoRow('Ristourne', '${formatter.format(facture.ristourne)} FCFA'),
              _buildInfoRow('Payé', '${formatter.format(facture.montantPaye ?? 0.0)} FCFA'),
              if (facture.montantRemis != null)
                _buildInfoRow('Montant remis', '${formatter.format(facture.montantRemis)} FCFA'),
              if (facture.monnaie != null)
                _buildInfoRow('Monnaie', '${formatter.format(facture.monnaie)} FCFA'),
              _buildInfoRow('Reste à payer', '${formatter.format(facture.total - (facture.montantPaye ?? 0.0))} FCFA'),
              if (facture.statut == 'Annulée' && archivedFacture != null) ...[
                const SizedBox(height: 16),
                const Text('Détails de l\'annulation:', style: TextStyle(fontWeight: FontWeight.bold)),
                _buildInfoRow('Motif', archivedFacture.motifAnnulation),
                _buildInfoRow('Date d\'annulation', DateFormat('dd/MM/yyyy').format(archivedFacture.dateAnnulation)),
              ],
              const SizedBox(height: 16),
              const Text('Articles:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...items.map((item) {
                final quantite = (item['quantite'] as num?)?.toInt() ?? 0;
                final prixUnitaire = (item['prixUnitaire'] as num?)?.toDouble() ?? 0.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item['produitNom']} x $quantite ${item['unite']}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text('${formatter.format(quantite * prixUnitaire)} FCFA'),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
              const Text('Paiements:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...paiements.map((paiement) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${paiement['methode']} - ${DateFormat('dd/MM/yyyy').format(DateTime.fromMillisecondsSinceEpoch(paiement['date'] as int))}',
                            ),
                            Text('${formatter.format(paiement['montant'])} FCFA'),
                          ],
                        ),
                        if (paiement['montantRemis'] != null)
                          Text('Remis: ${formatter.format(paiement['montantRemis'])} FCFA'),
                        if (paiement['monnaie'] != null)
                          Text('Monnaie: ${formatter.format(paiement['monnaie'])} FCFA'),
                      ],
                    ),
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          if (facture.statut == 'Active') ...[
            TextButton(
              onPressed: () => _showCancelFactureDialog(facture),
              child: const Text('Annuler', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () async {
                final db = await DatabaseHelper.database;
                final items = await db.rawQuery(
                  '''
                  SELECT bci.*, p.nom AS produitNom, p.unite
                  FROM bon_commande_items bci
                  JOIN produits p ON bci.produitId = p.id
                  WHERE bci.bonCommandeId = ?
                ''',
                  [facture.bonCommandeId],
                );
                FactureDialog.showPrintOptions(
                  context: context,
                  numero: facture.numero,
                  date: facture.date,
                  clientNom: facture.clientNom,
                  adresse: facture.adresse,
                  magasinAdresse: facture.magasinAdresse,
                  vendeurNom: facture.vendeurNom ?? 'Non spécifié',
                  items: items
                      .map((item) => {
                            'produitId': item['produitId'],
                            'produitNom': item['produitNom'],
                            'quantite': item['quantite'],
                            'prixUnitaire': item['prixUnitaire'],
                            'unite': item['unite'],
                          })
                      .toList(),
                  sousTotal: facture.total + (facture.ristourne ?? 0.0),
                  ristourne: facture.ristourne ?? 0.0,
                  total: facture.total,
                  montantPaye: facture.montantPaye ?? 0.0,
                  resteAPayer: facture.total - (facture.montantPaye ?? 0.0),
                  montantRemis: facture.montantRemis,
                  monnaie: facture.monnaie,
                );
              },
              child: const Text('Imprimer/PDF'),
            ),
            if (facture.total - (facture.montantPaye ?? 0.0) > 0)
              TextButton(
                onPressed: () => _showAddPaymentDialog(facture),
                child: const Text('Ajouter paiement'),
              ),
          ],
        ],
      ),
    );
  }

  void _showCancelFactureDialog(Facture facture) {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    final motifController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Annuler la facture ${facture.numero}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Annulé par: ${user?.name ?? 'Utilisateur inconnu'}'),
            const SizedBox(height: 16.0),
            const Text('Veuillez entrer le motif de l\'annulation :'),
            const SizedBox(height: 16.0),
            TextField(
              controller: motifController,
              decoration: const InputDecoration(
                labelText: 'Motif',
                hintText: 'Ex. : Erreur de saisie',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              final motif = motifController.text.trim();
              if (motif.isEmpty) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Erreur'),
                    content: const Text('Le motif d\'annulation est requis.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
                return;
              }

              try {
                await DatabaseHelper.cancelFacture(facture.id, motif);
                setState(() {
                  _facturesFuture = DatabaseHelper.getFactures(
                    includeArchived: true,
                    vendeurNom: (_currentUser != null && _currentUser!.role == 'Vendeur') ? _currentUser!.name : null,
                  );
                  _loadStatistics();
                });
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Succès'),
                    content: Text('Facture ${facture.numero} annulée avec succès.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              } catch (e) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Erreur'),
                    content: Text('Erreur lors de l\'annulation : $e'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              }
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _showAddPaymentDialog(Facture facture) {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    double montantPaye = facture.montantPaye ?? 0.0;
    final montantController = TextEditingController();
    final montantRemisController = TextEditingController();
    String? methode = 'Espèces';
    final formatter = NumberFormat('#,##0.00', 'fr_FR');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            double montant = double.tryParse(montantController.text) ?? 0.0;
            double montantRemis = double.tryParse(montantRemisController.text) ?? 0.0;
            double monnaie = montantRemis > montant ? montantRemis - montant : 0.0;

            return AlertDialog(
              title: const Text('Ajouter un paiement'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Payé par: ${user?.name ?? 'Utilisateur inconnu'}'),
                    const SizedBox(height: 16.0),
                    TextField(
                      controller: montantController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Montant (FCFA)',
                        hintText: 'Entrez le montant',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 16.0),
                    TextField(
                      controller: montantRemisController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Montant remis (FCFA)',
                        hintText: 'Entrez le montant remis',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 16.0),
                    Text('Monnaie: ${formatter.format(monnaie)} FCFA'),
                    const SizedBox(height: 16.0),
                    DropdownButton<String>(
                      value: methode,
                      isExpanded: true,
                      items: ['Espèces', 'Carte', 'Virement'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          methode = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                TextButton(
                  onPressed: () async {
                    final montant = double.tryParse(montantController.text);
                    final montantRemis = double.tryParse(montantRemisController.text);
                    if (montant == null || montant <= 0) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Erreur'),
                          content: const Text('Veuillez entrer un montant valide.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                      return;
                    }
                    if (montantRemis == null || montantRemis < montant) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Erreur'),
                          content: const Text('Le montant remis doit être supérieur ou égal au montant.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                      return;
                    }
                    if (montantPaye + montant > facture.total) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Erreur'),
                          content: const Text('Le paiement dépasse le montant dû.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                      return;
                    }

                    try {
                      await DatabaseHelper.addPayment(
                        facture.id,
                        montant,
                        methode!,
                        montantRemis: montantRemis,
                        monnaie: monnaie,
                      );
                      setState(() {
                        _facturesFuture = DatabaseHelper.getFactures(
                          includeArchived: true,
                          vendeurNom: (_currentUser != null && _currentUser!.role == 'Vendeur') ? _currentUser!.name : null,
                        );
                        _loadStatistics();
                      });
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Succès'),
                          content: Text('Paiement de ${formatter.format(montant)} FCFA ajouté avec succès'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    } catch (e) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Erreur'),
                          content: Text('Erreur lors de l\'ajout du paiement : $e'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  child: const Text('Ajouter'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _selectDay(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDay ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDay = picked;
        _startDate = null;
        _endDate = null;
        _facturesFuture = DatabaseHelper.getFactures(
          includeArchived: true,
          vendeurNom: (_currentUser != null && _currentUser!.role == 'Vendeur') ? _currentUser!.name : null,
        );
        _loadStatistics();
      });
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _selectedDay = null;
        _facturesFuture = DatabaseHelper.getFactures(
          includeArchived: true,
          vendeurNom: (_currentUser != null && _currentUser!.role == 'Vendeur') ? _currentUser!.name : null,
        );
        _loadStatistics();
      });
    }
  }

  Future<void> _loadLogoPath() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _logoPath = prefs.getString('logo_path');
    });
  }

  Future<void> _pickLogo(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('logo_path', result.files.single.path!);
      setState(() {
        _logoPath = result.files.single.path!;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logo enregistré !')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final formatter = NumberFormat('#,##0.00', 'fr_FR');

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        title: Text(
          'Gestion des Factures',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.grey.shade900,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: () {
                final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
                FactureDialog.showAddFactureDialog(
                  context,
                  () {
                    setState(() {
                      _facturesFuture = DatabaseHelper.getFactures(
                        includeArchived: true,
                        vendeurNom: (user != null && user.role == 'Vendeur') ? user.name : null,
                      );
                      _loadVendors();
                      _loadStatistics();
                    });
                  },
                  vendeurNom: user?.name,
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Nouvelle Facture'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              _generateAndPrintPdf();
            },
          ),
        ],
      ),
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: theme.primaryColor,
              ),
              child: Text(
                'Navigation',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.receipt),
              title: Text('Factures'),
              selected: true,
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.inventory),
              title: Text('Produits'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.dashboard),
              title: Text('Tableau de bord'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildSearchAndFilters(),
              const SizedBox(height: 16),
              _buildStatisticsSection(theme, isDarkMode, formatter),
              const SizedBox(height: 16),
              SizedBox(
                height: MediaQuery.of(context).size.height - 400,
                child: FutureBuilder<List<Facture>>(
                  key: _futureKey,
                  future: _facturesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      print('Erreur FutureBuilder: ${snapshot.error}');
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                            const SizedBox(height: 16),
                            Text(
                              'Erreur de chargement',
                              style: theme.textTheme.titleLarge?.copyWith(color: Colors.red.shade300),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              snapshot.error.toString(),
                              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _facturesFuture = DatabaseHelper.getFactures(
                                    includeArchived: true,
                                    vendeurNom: (_currentUser != null && _currentUser!.role == 'Vendeur') ? _currentUser!.name : null,
                                  );
                                  _loadStatistics();
                                });
                              },
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      );
                    }

                    final factures = snapshot.data ?? [];
                    print('Nombre de factures chargées: ${factures.length}');
                    final filteredFactures = factures.where((facture) {
                      final query = _searchQuery.toLowerCase();
                      final matchesSearch = facture.numero.toLowerCase().contains(query) ||
                          (facture.clientNom?.toLowerCase().contains(query) ?? false) ||
                          (facture.vendeurNom?.toLowerCase().contains(query) ?? false);
                      bool matchesFilter = true;
                      if (_selectedFilter == 'Payées') {
                        matchesFilter = facture.statutPaiement == 'Payé';
                      } else if (_selectedFilter == 'En attente') {
                        matchesFilter = facture.statutPaiement == 'En attente';
                      } else if (_selectedFilter == 'Annulées') {
                        matchesFilter = facture.statut == 'Annulée';
                      } else if (_selectedFilter == 'Ce mois') {
                        final now = DateTime.now();
                        matchesFilter = facture.date.year == now.year && facture.date.month == now.month;
                      }
                      bool matchesDate = true;
                      if (_selectedDay != null) {
                        matchesDate = facture.date.year == _selectedDay!.year &&
                            facture.date.month == _selectedDay!.month &&
                            facture.date.day == _selectedDay!.day;
                      } else if (_startDate != null && _endDate != null) {
                        matchesDate = facture.date.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
                            facture.date.isBefore(_endDate!.add(const Duration(days: 1)));
                      }
                      bool matchesVendor = true;
                      if (_selectedVendor != null && _selectedVendor!.isNotEmpty) {
                        matchesVendor = facture.vendeurNom == _selectedVendor;
                      }
                      return matchesSearch && matchesFilter && matchesDate && matchesVendor;
                    }).toList();

                    if (_sortOrder == 'ascending') {
                      filteredFactures.sort((a, b) => a.date.compareTo(b.date));
                    } else if (_sortOrder == 'descending') {
                      filteredFactures.sort((a, b) => b.date.compareTo(a.date));
                    }

                    print('Nombre de factures filtrées: ${filteredFactures.length}');

                    if (filteredFactures.isEmpty) {
                      return Center(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 64,
                                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'Aucun résultat pour "$_searchQuery"'
                                    : _selectedFilter != 'Toutes'
                                        ? 'Aucune facture pour le filtre "$_selectedFilter"'
                                        : 'Aucune facture disponible',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () {
                                  final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
                                  FactureDialog.showAddFactureDialog(
                                    context,
                                    () {
                                      setState(() {
                                        _facturesFuture = DatabaseHelper.getFactures(
                                          includeArchived: true,
                                          vendeurNom: (user != null && user.role == 'Vendeur') ? user.name : null,
                                        );
                                        _loadVendors();
                                        _loadStatistics();
                                      });
                                    },
                                    vendeurNom: user?.name,
                                  );
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Créer une facture'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                              if (_selectedFilter != 'Toutes' ||
                                  _searchQuery.isNotEmpty ||
                                  _selectedDay != null ||
                                  _startDate != null ||
                                  _selectedVendor != null ||
                                  _sortOrder != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _searchQuery = '';
                                        _selectedFilter = 'Toutes';
                                        _selectedDay = null;
                                        _startDate = null;
                                        _endDate = null;
                                        _selectedVendor = null;
                                        _sortOrder = null;
                                        _facturesFuture = DatabaseHelper.getFactures(
                                          includeArchived: true,
                                          vendeurNom: (_currentUser != null && _currentUser!.role == 'Vendeur') ? _currentUser!.name : null,
                                        );
                                        _loadStatistics();
                                      });
                                    },
                                    child: const Text('Réinitialiser tous les filtres'),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }

                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: screenWidth > 800 ? 2 : 1,
                        childAspectRatio: 1.6,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: filteredFactures.length,
                      itemBuilder: (context, index) {
                        final facture = filteredFactures[index];
                        final resteAPayer = facture.total - (facture.montantPaye ?? 0.0);
                        return _buildFactureCard(
                          facture: facture,
                          resteAPayer: resteAPayer,
                          formatter: formatter,
                          isDarkMode: isDarkMode,
                          theme: theme,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.image),
                label: const Text('Choisir un logo'),
                onPressed: () => _pickLogo(context),
              ),
              if (_logoPath != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Image.file(
                    File(_logoPath!),
                    height: 32,
                    width: 32,
                    fit: BoxFit.contain,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _facturesFuture = DatabaseHelper.getFactures(
                  includeArchived: true,
                  vendeurNom: (_currentUser != null && _currentUser!.role == 'Vendeur') ? _currentUser!.name : null,
                );
              });
            },
            decoration: InputDecoration(
              hintText: 'Rechercher une facture...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade100,
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Toutes'),
                const SizedBox(width: 8),
                _buildFilterChip('Payées'),
                const SizedBox(width: 8),
                _buildFilterChip('En attente'),
                const SizedBox(width: 8),
                _buildFilterChip('Annulées'),
                const SizedBox(width: 8),
                _buildFilterChip('Ce mois'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _selectDay(context),
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    _selectedDay == null
                        ? 'Choisir un jour'
                        : DateFormat('dd/MM/yyyy').format(_selectedDay!),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedDay != null ? Theme.of(context).primaryColor : null,
                    foregroundColor: _selectedDay != null ? Colors.white : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _selectDateRange(context),
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    _startDate == null || _endDate == null
                        ? 'Choisir une période'
                        : '${DateFormat('dd/MM').format(_startDate!)} - ${DateFormat('dd/MM').format(_endDate!)}',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _startDate != null && _endDate != null ? Theme.of(context).primaryColor : null,
                    foregroundColor: _startDate != null && _endDate != null ? Colors.white : null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!(_currentUser != null && _currentUser!.role == 'Vendeur')) ...[
            DropdownButton<String>(
              hint: const Text('Sélectionner un vendeur'),
              value: _selectedVendor,
              isExpanded: true,
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Tous les vendeurs'),
                ),
                ..._vendors.map((vendor) => DropdownMenuItem<String>(
                      value: vendor,
                      child: Text(vendor),
                    )),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedVendor = value;
                  _facturesFuture = DatabaseHelper.getFactures(
                    includeArchived: true,
                    vendeurNom: (_currentUser != null && _currentUser!.role == 'Vendeur') ? _currentUser!.name : null,
                  );
                  _loadStatistics();
                });
              },
            ),
            const SizedBox(height: 16),
          ],
          if (_selectedDay != null ||
              _startDate != null ||
              _endDate != null ||
              _selectedVendor != null ||
              _searchQuery.isNotEmpty ||
              _selectedFilter != 'Toutes' ||
              _sortOrder != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: Icon(Icons.clear),
                label: Text('Réinitialiser les filtres'),
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _selectedFilter = 'Toutes';
                    _selectedDay = null;
                    _startDate = null;
                    _endDate = null;
                    _selectedVendor = null;
                    _sortOrder = null;
                    _facturesFuture = DatabaseHelper.getFactures(
                      includeArchived: true,
                      vendeurNom: (_currentUser != null && _currentUser!.role == 'Vendeur') ? _currentUser!.name : null,
                    );
                    _loadStatistics();
                  });
                },
              ),
            ),
          DropdownButton<String>(
            hint: const Text('Trier par date'),
            value: _sortOrder,
            isExpanded: true,
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Aucun tri'),
              ),
              const DropdownMenuItem<String>(
                value: 'ascending',
                child: Text('Croissant (plus ancien)'),
              ),
              const DropdownMenuItem<String>(
                value: 'descending',
                child: Text('Décroissant (plus récent)'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _sortOrder = value;
                _facturesFuture = DatabaseHelper.getFactures(
                  includeArchived: true,
                  vendeurNom: (_currentUser != null && _currentUser!.role == 'Vendeur') ? _currentUser!.name : null,
                );
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    return FilterChip(
      label: Text(label),
      selected: _selectedFilter == label,
      onSelected: (bool selected) {
        setState(() {
          _selectedFilter = selected ? label : 'Toutes';
          _facturesFuture = DatabaseHelper.getFactures(
            includeArchived: true,
            vendeurNom: (_currentUser != null && _currentUser!.role == 'Vendeur') ? _currentUser!.name : null,
          );
          _loadStatistics();
        });
      },
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildFactureCard({
    required Facture facture,
    required double resteAPayer,
    required NumberFormat formatter,
    required bool isDarkMode,
    required ThemeData theme,
  }) {
    final statusColor = facture.statut == 'Annulée'
        ? Colors.red
        : facture.statutPaiement == 'Payé'
            ? Colors.green
            : Colors.orange;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => _showFactureDetails(facture),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Facture ${facture.numero}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: facture.statut == 'Annulée' ? Colors.red : null,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (facture.statut == 'Annulée')
                              const Padding(
                                padding: EdgeInsets.only(left: 8.0),
                                child: Icon(Icons.cancel, color: Colors.red),
                              ),
                          ],
                        ),
                        Text(
                          DateFormat('dd/MM/yyyy').format(facture.date),
                          style: theme.textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      facture.statut == 'Annulée' ? 'Annulée' : facture.statutPaiement,
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Client: ${facture.clientNom ?? 'Non spécifié'}',
                          style: theme.textTheme.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Vendeur: ${facture.vendeurNom ?? 'Non spécifié'}',
                          style: theme.textTheme.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Total: ${formatter.format(facture.total)} FCFA',
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (facture.statut == 'Active')
                    Column(
                      children: [
                        IconButton(
                          icon: Icon(Icons.print, color: theme.primaryColor),
                          onPressed: () async {
                            final db = await DatabaseHelper.database;
                            final items = await db.rawQuery(
                              '''
                              SELECT bci.*, p.nom AS produitNom, p.unite
                              FROM bon_commande_items bci
                              JOIN produits p ON bci.produitId = p.id
                              WHERE bci.bonCommandeId = ?
                            ''',
                              [facture.bonCommandeId],
                            );
                            FactureDialog.showPrintOptions(
                              context: context,
                              numero: facture.numero,
                              date: facture.date,
                              clientNom: facture.clientNom,
                              adresse: facture.adresse,
                              magasinAdresse: facture.magasinAdresse,
                              vendeurNom: facture.vendeurNom ?? 'Non spécifié',
                              items: items
                                  .map((item) => {
                                        'produitId': item['produitId'],
                                        'produitNom': item['produitNom'],
                                        'quantite': item['quantite'],
                                        'prixUnitaire': item['prixUnitaire'],
                                        'unite': item['unite'],
                                      })
                                  .toList(),
                              sousTotal: facture.total + (facture.ristourne ?? 0.0),
                              ristourne: facture.ristourne ?? 0.0,
                              total: facture.total,
                              montantPaye: facture.montantPaye ?? 0.0,
                              resteAPayer: facture.total - (facture.montantPaye ?? 0.0),
                              montantRemis: facture.montantRemis,
                              monnaie: facture.monnaie,
                            );
                          },
                          tooltip: 'Imprimer ou générer PDF',
                        ),
                        if (resteAPayer > 0)
                          IconButton(
                            icon: Icon(Icons.payment, color: theme.primaryColor),
                            onPressed: () => _showAddPaymentDialog(facture),
                            tooltip: 'Ajouter un paiement',
                          ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value, textAlign: TextAlign.end, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection(ThemeData theme, bool isDarkMode, NumberFormat formatter) {
    String _safeTruncate(String text, int maxLength) {
      return text.length <= maxLength ? text : text.substring(0, maxLength);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: _isLoadingStats
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Statistiques des Ventes',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: Icon(Icons.print, color: theme.primaryColor),
                      onPressed: _generateAndPrintPdf,
                      tooltip: 'Exporter les statistiques en PDF',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: Icon(Icons.monetization_on, color: theme.primaryColor),
                    title: Text('Chiffre d\'Affaires Total', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${formatter.format(_totalCA)} FCFA'),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ventes par Produit', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: _salesByProduct.isEmpty
                              ? Center(child: Text('Aucune donnée disponible'))
                              : BarChart(
                                  BarChartData(
                                    barGroups: _salesByProduct.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final sale = entry.value;
                                      return BarChartGroupData(
                                        x: index,
                                        barRods: [
                                          BarChartRodData(
                                            toY: sale['totalQuantite'].toDouble(),
                                            color: theme.primaryColor,
                                            width: 10,
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                    titlesData: FlTitlesData(
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (value, meta) {
                                            final index = value.toInt();
                                            if (index >= _salesByProduct.length) return Text('');
                                            return Padding(
                                              padding: const EdgeInsets.only(top: 8),
                                              child: Text(
                                                _safeTruncate(_salesByProduct[index]['nom'].toString(), 5),
                                                style: TextStyle(fontSize: 10),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                                      ),
                                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    gridData: FlGridData(show: false),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 16),
                        ..._salesByProduct.map((sale) => ListTile(
                              title: Text(sale['nom']),
                              subtitle: Text(
                                  'Quantité: ${sale['totalQuantite']} ${sale['unite']} | CA: ${formatter.format(sale['totalCA'])} FCFA'),
                            )),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ventes par Vendeur', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: _salesByVendor.isEmpty
                              ? Center(child: Text('Aucune donnée disponible'))
                              : PieChart(
                                  PieChartData(
                                    sections: _salesByVendor.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final sale = entry.value;
                                      return PieChartSectionData(
                                        value: sale['totalCA'].toDouble(),
                                        title: _safeTruncate(sale['vendeurNom'].toString(), 5),
                                        color: Colors.primaries[index % Colors.primaries.length],
                                        radius: 80,
                                        titleStyle: TextStyle(fontSize: 12, color: Colors.white),
                                      );
                                    }).toList(),
                                    sectionsSpace: 2,
                                    centerSpaceRadius: 40,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 16),
                        ..._salesByVendor.map((sale) => ListTile(
                              title: Text(sale['vendeurNom']),
                              subtitle: Text(
                                  'Factures: ${sale['invoiceCount']} | CA: ${formatter.format(sale['totalCA'])} FCFA'),
                            )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}