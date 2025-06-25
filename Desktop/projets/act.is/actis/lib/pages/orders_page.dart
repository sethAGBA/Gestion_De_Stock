
import 'package:actis/helpers/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

String formatAmount(double amount) {
  if (amount >= 1000000) {
    return '${(amount / 1000000).toStringAsFixed(1)}M FCFA';
  } else if (amount >= 1000) {
    return '${(amount / 1000).toStringAsFixed(1)}K FCFA';
  }
  return '${amount.toStringAsFixed(0)} FCFA';
}

class Order {
  final int id;
  final int clientId;
  final String? clientName;
  final String service;
  final double amount;
  final double amountPaid;
  final double remainingBalance;
  final String deliveryDate;
  final String orderDate;
  final String status;

  Order({
    required this.id,
    required this.clientId,
    this.clientName,
    required this.service,
    required this.amount,
    required this.amountPaid,
    required this.remainingBalance,
    required this.deliveryDate,
    required this.orderDate,
    required this.status,
  });

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: int.parse(map['id']?.toString() ?? '0'),
      clientId: int.parse(map['clientId']?.toString() ?? '0'),
      clientName: map['clientName'] as String?,
      service: map['service'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      amountPaid: (map['amountPaid'] as num?)?.toDouble() ?? 0.0,
      remainingBalance: (map['remainingBalance'] as num?)?.toDouble() ?? 0.0,
      deliveryDate: map['deliveryDate'] ?? '',
      orderDate: map['orderDate'] ?? DateTime.now().toIso8601String(),
      status: map['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'service': service,
      'amount': amount,
      'amountPaid': amountPaid,
      'remainingBalance': remainingBalance,
      'deliveryDate': deliveryDate,
      'orderDate': orderDate,
      'status': status,
    };
  }
}

class AddOrderPage extends StatefulWidget {
  final int clientId;
  final Order? order;

  const AddOrderPage({super.key, required this.clientId, this.order});

  @override
  State<AddOrderPage> createState() => _AddOrderPageState();
}

class _AddOrderPageState extends State<AddOrderPage> {
  final _formKey = GlobalKey<FormState>();
  final List<String> _services = [
    'Confection : Costumes',
    'Confection : Robes de soirée',
    'Confection : Robes de mariée',
    'Confection : Robes traditionnelles',
    'Confection : Jupes',
    'Confection : Chemises',
    'Confection : Blouses',
    'Confection : Ensembles hommes/femmes',
    'Confection : Uniformes scolaires',
    'Confection : Uniformes professionnels',
    'Retouches : Rétrécir/agrandir',
    'Retouches : Raccourcir/rallonger',
    'Retouches : Modifier encolure/pinces',
    'Retouches : Remplacer fermeture éclair',
    'Retouches : Remplacer boutons',
    'Retouches : Ajustements morphologiques',
    'Retouches : Reprise de doublure/ourlets',
    'Réparations : Couture déchirée',
    'Réparations : Raccommodage discret',
    'Réparations : Renforcement couture',
    'Réparations : Réfection vêtements abîmés',
    'Design : Création de patron',
    'Design : Dessin de modèle',
    'Personnalisation : Broderie',
    'Personnalisation : Perles/strass/paillettes',
    'Personnalisation : Marquage (initiales/logos)',
    'Accessoires : Cravates/nœuds papillon',
    'Accessoires : Écharpes/foulards',
    'Accessoires : Masques personnalisés',
    'Accessoires : Sacs/chapeaux/pochettes',
    'Cérémonie : Robe de mariée',
    'Cérémonie : Costume de mariage',
    'Cérémonie : Tenues de cortège',
    'Cérémonie : Tenues parents mariés',
    'Cérémonie : Tenues de baptême',
    'Cérémonie : Tenues de communion',
    'Cérémonie : Tenues funérailles',
    'Cérémonie : Tenues culturelles',
    'Production : Petites séries boutiques',
    'Production : Uniformes d’entreprise',
    'Production : Uniformes associatifs',
    'Conseil : Choix tissu/coupe',
    'Conseil : Style selon occasion',
    'Service : Prise de mesures à domicile',
    'Service : Livraison des tenues',
    'Service : Archivage mesures client',
  ];
  final Map<String, bool> _selectedServices = {};
  final TextEditingController _servicesController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _amountPaidController = TextEditingController();
  final TextEditingController _deliveryDateController = TextEditingController();
  String _status = 'pending';
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    for (var service in _services) {
      _selectedServices[service] = false;
    }
    if (widget.order != null) {
      final services = widget.order!.service.split(',').where((s) => s.isNotEmpty).toList();
      for (var service in services) {
        if (_services.contains(service)) {
          _selectedServices[service] = true;
        }
      }
      _servicesController.text = services.isNotEmpty ? services.join(', ') : 'Aucun service sélectionné';
      _amountController.text = widget.order!.amount.toString();
      _amountPaidController.text = widget.order!.amountPaid.toString();
      _deliveryDateController.text = widget.order!.deliveryDate;
      _status = widget.order!.status;
      if (widget.order!.deliveryDate.isNotEmpty) {
        _selectedDate = DateTime.parse(widget.order!.deliveryDate);
      }
    } else {
      _servicesController.text = 'Aucun service sélectionné';
    }
    _searchController.addListener(_filterServices);
  }

  void _filterServices() {
    setState(() {});
  }

  List<String> get _filteredServices {
    if (_searchController.text.isEmpty) return _services;
    return _services
        .where((service) => service.toLowerCase().contains(_searchController.text.toLowerCase()))
        .toList();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _deliveryDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _showServicesDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'Sélectionner les services',
                style: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
              ),
              content: Container(
                width: double.maxFinite,
                height: MediaQuery.of(context).size.height * 0.5,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Rechercher un service...',
                        hintStyle: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      style: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _filteredServices.length,
                        itemBuilder: (context, index) {
                          final service = _filteredServices[index];
                          return CheckboxListTile(
                            title: Text(
                              service,
                              style: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
                            ),
                            value: _selectedServices[service] ?? false,
                            onChanged: (value) {
                              setDialogState(() {
                                _selectedServices[service] = value ?? false;
                              });
                              setState(() {
                                final selected = _selectedServices.entries
                                    .where((entry) => entry.value)
                                    .map((entry) => entry.key)
                                    .toList();
                                _servicesController.text = selected.isNotEmpty
                                    ? selected.join(', ')
                                    : 'Aucun service sélectionné';
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Fermer',
                    style: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.order == null ? 'Nouvelle Commande' : 'Modifier Commande',
          style: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _servicesController,
                decoration: InputDecoration(
                  labelText: 'Services',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  labelStyle: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.list),
                    onPressed: _showServicesDialog,
                  ),
                ),
                readOnly: true,
                validator: (value) {
                  if (value == null || value == 'Aucun service sélectionné') {
                    return 'Veuillez sélectionner au moins un service';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Montant à payer (FCFA)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  labelStyle: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un montant';
                  }
                  if (double.tryParse(value) == null || double.parse(value)! < 0) {
                    return 'Veuillez entrer un montant valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountPaidController,
                decoration: InputDecoration(
                  labelText: 'Montant payé (FCFA)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  labelStyle: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un montant';
                  }
                  if (double.tryParse(value) == null || double.parse(value)! < 0) {
                    return 'Veuillez entrer un montant valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _deliveryDateController,
                decoration: InputDecoration(
                  labelText: 'Date de livraison',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  labelStyle: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context),
                  ),
                ),
                readOnly: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez sélectionner une date';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: InputDecoration(
                  labelText: 'Statut',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  labelStyle: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
                ),
                items: ['pending', 'completed', 'cancelled'].map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(
                      status == 'pending' ? 'En attente' : status == 'completed' ? 'Complété' : 'Annulé',
                      style: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _status = value!;
                  });
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final selectedServices = _selectedServices.entries
                          .where((entry) => entry.value)
                          .map((entry) => entry.key)
                          .toList();
                      final amount = double.parse(_amountController.text);
                      final amountPaid = double.parse(_amountPaidController.text);
                      final order = Order(
                        id: widget.order?.id ?? 0,
                        clientId: widget.order?.clientId ?? widget.clientId,
                        service: selectedServices.join(','),
                        amount: amount,
                        amountPaid: amountPaid,
                        remainingBalance: amount - amountPaid,
                        deliveryDate: _deliveryDateController.text,
                        orderDate: widget.order?.orderDate ?? DateTime.now().toIso8601String(),
                        status: _status,
                      );
                      try {
                        if (widget.order == null) {
                          await DatabaseHelper().insertOrder(order.toMap());
                        } else {
                          await DatabaseHelper().updateOrder({...order.toMap(), 'id': order.id});
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              widget.order == null ? 'Commande ajoutée avec succès' : 'Commande modifiée avec succès',
                              style: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
                            ),
                          ),
                        );
                        Navigator.pop(context, true);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Erreur lors de l\'enregistrement: $e',
                              style: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
                            ),
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    widget.order == null ? 'Ajouter Commande' : 'Modifier Commande',
                    style: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterServices);
    _searchController.dispose();
    _servicesController.dispose();
    _amountController.dispose();
    _amountPaidController.dispose();
    _deliveryDateController.dispose();
    super.dispose();
  }
}

class OrdersPage extends StatefulWidget {
  final int? clientId;
  final String? clientName;

  const OrdersPage({super.key, this.clientId, this.clientName});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> with TickerProviderStateMixin {
  List<Order> _orders = [];
  List<Order> _filteredOrders = [];
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
    _searchController.addListener(_filterOrders);
    _loadOrders();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.removeListener(_filterOrders);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    try {
      final orders = widget.clientId != null
          ? await DatabaseHelper().getOrdersForClient(widget.clientId!)
          : await DatabaseHelper().getOrders();
      setState(() {
        _orders = orders.map((map) => Order.fromMap(map)).toList();
        _filteredOrders = _orders;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur lors du chargement des commandes: $e',
            style: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
          ),
        ),
      );
    }
  }

  void _filterOrders() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredOrders = _orders.where((order) {
        return order.id.toString().contains(query) ||
            (order.clientName?.toLowerCase().contains(query) ?? false) ||
            order.service.toLowerCase().contains(query);
      }).toList();
    });
  }

  Map<String, List<Order>> _groupOrdersByDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final weekEnd = today.add(const Duration(days: 7));

    final groupedOrders = {
      'Aujourd\'hui': <Order>[],
      'Demain': <Order>[],
      'Cette semaine': <Order>[],
      'Plus tard': <Order>[],
    };

    for (var order in _filteredOrders) {
      if (order.deliveryDate.isEmpty) {
        groupedOrders['Plus tard']!.add(order);
        continue;
      }
      final deliveryDate = DateTime.parse(order.deliveryDate);
      final deliveryDay = DateTime(deliveryDate.year, deliveryDate.month, deliveryDate.day);
      if (deliveryDay == today) {
        groupedOrders['Aujourd\'hui']!.add(order);
      } else if (deliveryDay == tomorrow) {
        groupedOrders['Demain']!.add(order);
      } else if (deliveryDay.isAfter(today) && deliveryDay.isBefore(weekEnd)) {
        groupedOrders['Cette semaine']!.add(order);
      } else {
        groupedOrders['Plus tard']!.add(order);
      }
    }

    return groupedOrders;
  }

  Future<String> _generateInvoicePdf(Order order, Map<String, dynamic>? client, Map<String, dynamic>? settings) async {
    final pdf = pw.Document();
    pw.Font font;
    pw.ImageProvider? logoImage;

    try {
      font = await pw.Font.ttf(await DefaultAssetBundle.of(context).load('assets/fonts/Roboto-Regular.ttf'));
    } catch (e) {
      debugPrint('Erreur lors du chargement de la police Roboto: $e');
      font = pw.Font.helvetica();
    }

    if (settings?['businessLogoPath'] != null && settings!['businessLogoPath'].isNotEmpty) {
      try {
        final logoFile = File(settings['businessLogoPath']);
        if (await logoFile.exists()) {
          final logoBytes = await logoFile.readAsBytes();
          logoImage = pw.MemoryImage(logoBytes);
        }
      } catch (e) {
        debugPrint('Erreur lors du chargement du logo: $e');
      }
    }

    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(40),
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.center,
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              'Facture générée le ${DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now())} - Actis',
              style: pw.TextStyle(font: font, fontSize: 10, color: PdfColor.fromHex('78909C')),
            ),
          );
        },
        build: (pw.Context context) => [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        settings?['businessName'] ?? 'Actis',
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('003087'),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        settings?['businessAddress'] ?? '123 Rue de la Mode, Ville',
                        style: pw.TextStyle(font: font, fontSize: 12),
                      ),
                      pw.Text(
                        settings?['businessPhone'] ?? '+1234567890',
                        style: pw.TextStyle(font: font, fontSize: 12),
                      ),
                      pw.Text(
                        settings?['businessEmail'] ?? 'contact@actis.com',
                        style: pw.TextStyle(font: font, fontSize: 12),
                      ),
                    ],
                  ),
                  logoImage != null
                      ? pw.Container(
                          width: 80,
                          height: 80,
                          child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                        )
                      : pw.SizedBox(width: 80, height: 80),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Divider(thickness: 1, color: PdfColor.fromHex('B0BEC5')),
              pw.SizedBox(height: 20),
              pw.Text(
                'Facture #${order.id}',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('003087'),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Date d\'émission: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                    style: pw.TextStyle(font: font, fontSize: 12),
                  ),
                  pw.Text(
                    'Date de commande: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(order.orderDate))}',
                    style: pw.TextStyle(font: font, fontSize: 12),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Client',
                style: pw.TextStyle(font: font, fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Nom: ${client?['name'] ?? order.clientName ?? 'Inconnu'}',
                style: pw.TextStyle(font: font, fontSize: 12),
              ),
              pw.Text(
                'Téléphone: ${client?['phone'] ?? 'Non spécifié'}',
                style: pw.TextStyle(font: font, fontSize: 12),
              ),
              pw.Text(
                'Email: ${client?['email'] ?? 'Non spécifié'}',
                style: pw.TextStyle(font: font, fontSize: 12),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Détails de la Commande',
                style: pw.TextStyle(font: font, fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColor.fromHex('CFD8DC')),
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColor.fromHex('ECEFF1')),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Description',
                          style: pw.TextStyle(font: font, fontSize: 12, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Montant',
                          style: pw.TextStyle(font: font, fontSize: 12, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          order.service.isNotEmpty ? order.service : 'Aucun service',
                          style: pw.TextStyle(font: font, fontSize: 12),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          formatAmount(order.amount),
                          style: pw.TextStyle(font: font, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Date de livraison: ${order.deliveryDate.isEmpty ? 'Non spécifiée' : DateFormat('dd/MM/yyyy').format(DateTime.parse(order.deliveryDate))}',
                style: pw.TextStyle(font: font, fontSize: 12),
              ),
              pw.Text(
                'Statut: ${order.status == 'pending' ? 'En attente' : order.status == 'completed' ? 'Complété' : 'Annulé'}',
                style: pw.TextStyle(font: font, fontSize: 12),
              ),
              pw.SizedBox(height: 20),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Container(
                  width: 200,
                  child: pw.Table(
                    border: pw.TableBorder.all(color: PdfColor.fromHex('CFD8DC')),
                    children: [
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              'Montant total:',
                              style: pw.TextStyle(font: font, fontSize: 12, fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              formatAmount(order.amount),
                              style: pw.TextStyle(font: font, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              'Montant payé:',
                              style: pw.TextStyle(font: font, fontSize: 12, fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              formatAmount(order.amountPaid),
                              style: pw.TextStyle(font: font, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              'Reste à payer:',
                              style: pw.TextStyle(font: font, fontSize: 12, fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              formatAmount(order.remainingBalance),
                              style: pw.TextStyle(font: font, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(height: 40),
              pw.Text(
                'Validation',
                style: pw.TextStyle(font: font, fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Signature Client : ______',
                        style: pw.TextStyle(font: font, fontSize: 12),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Container(width: 150, height: 1, color: PdfColor.fromHex('000000')),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Signature Responsable : ______',
                        style: pw.TextStyle(font: font, fontSize: 12),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Container(width: 150, height: 1, color: PdfColor.fromHex('000000')),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/invoice_${order.id}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  Future<void> _shareInvoice(Order order) async {
    try {
      final client = await DatabaseHelper().getClient(order.clientId);
      final settings = await DatabaseHelper().getSettings();
      final pdfPath = await _generateInvoicePdf(order, client, settings);
      await Share.shareXFiles([XFile(pdfPath)], subject: 'Facture Commande #${order.id}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Facture partagée avec succès',
            style: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur lors du partage de la facture: $e',
            style: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
          ),
        ),
      );
    }
  }

  Future<void> _deleteOrder(Order order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Supprimer la commande',
          style: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
        ),
        content: Text(
          'Voulez-vous vraiment supprimer la commande #${order.id}?',
          style: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Annuler',
              style: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Supprimer',
              style: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily, color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await DatabaseHelper().deleteOrder(order.id);
        await _loadOrders();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Commande supprimée avec succès',
              style: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur lors de la suppression: $e',
              style: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
            ),
          ),
        );
      }
    }
  }

  Widget _buildSectionHeader(String title, int orderCount) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onBackground,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: GoogleFonts.poppins().fontFamily,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ),
          ),
          child: Text(
            '$orderCount commandes',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: GoogleFonts.poppins().fontFamily,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCard({
    required Order order,
    required int delay,
  }) {
    final services = order.service.split(',').where((s) => s.trim().isNotEmpty).toList();
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 600 + delay),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              HapticFeedback.lightImpact();
              _showOrderDetails(order);
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Icon(
                      Icons.local_shipping_outlined,
                      color: Theme.of(context).colorScheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                'Commande #${order.id}',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: GoogleFonts.poppins().fontFamily,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildStatusBadge(order.status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.clientName ?? 'Inconnu',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            fontSize: 14,
                            fontFamily: GoogleFonts.poppins().fontFamily,
                          ),
                        ),
                        Text(
                          services.isNotEmpty ? services.join(', ') : 'Aucun service',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            fontSize: 14,
                            fontFamily: GoogleFonts.poppins().fontFamily,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatAmount(order.amount),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: GoogleFonts.poppins().fontFamily,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.primary, size: 20),
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddOrderPage(
                                    clientId: order.clientId,
                                    order: order,
                                  ),
                                ),
                              );
                              if (result == true) {
                                await _loadOrders();
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 20),
                            onPressed: () => _shareInvoice(order),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                            onPressed: () => _deleteOrder(order),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color statusColor;
    switch (status) {
      case 'pending':
        statusColor = const Color(0xFFFF9800);
        break;
      case 'completed':
        statusColor = const Color(0xFF4CAF50);
        break;
      case 'cancelled':
        statusColor = const Color(0xFFF44336);
        break;
      default:
        statusColor = Theme.of(context).colorScheme.primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
        ),
      ),
      child: Text(
        status == 'pending' ? 'En attente' : status == 'completed' ? 'Complété' : 'Annulé',
        style: TextStyle(
          color: statusColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFamily: GoogleFonts.poppins().fontFamily,
        ),
      ),
    );
  }

  void _showOrderDetails(Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Détails de la commande',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onBackground,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: GoogleFonts.poppins().fontFamily,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildDetailRow('Numéro', '#${order.id}'),
                  _buildDetailRow('Client', order.clientName ?? 'Inconnu'),
                  _buildDetailRow('Services', order.service.isNotEmpty ? order.service : 'Aucun service'),
                  _buildDetailRow('Montant', formatAmount(order.amount)),
                  _buildDetailRow('Payé', formatAmount(order.amountPaid)),
                  _buildDetailRow('Reste', formatAmount(order.remainingBalance)),
                  _buildDetailRow(
                    'Date de livraison',
                    order.deliveryDate.isEmpty ? 'Non spécifiée' : DateFormat('dd/MM/yyyy').format(DateTime.parse(order.deliveryDate)),
                  ),
                  _buildDetailRow(
                    'Statut',
                      order.status == 'pending' ? 'En attente' : order.status == 'completed' ? 'Complété' : 'Annulé',
                    ),
                  const SizedBox(height: 32),
                  if (order.status != 'completed')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          HapticFeedback.lightImpact();
                          try {
                            await DatabaseHelper().updateOrder({
                              ...order.toMap(),
                              'id': order.id,
                              'status': 'completed',
                            });
                            await _loadOrders();
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Commande marquée comme livrée',
                                  style: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
                                ),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Erreur lors de la mise à jour: $e',
                                  style: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
                                ),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Marquer comme livré',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: GoogleFonts.poppins().fontFamily,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                fontSize: 14,
                fontFamily: GoogleFonts.poppins().fontFamily,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onBackground,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: GoogleFonts.poppins().fontFamily,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupedOrders = _groupOrdersByDate();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.clientName != null ? 'Commandes de ${widget.clientName}' : 'Commandes',
          style: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.background,
                  Theme.of(context).colorScheme.background.withOpacity(0.8),
                ],
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher par ID, client ou service...',
                      hintStyle: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                    ),
                    style: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
                  ),
                ),
                Expanded(
                  child: _filteredOrders.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.local_shipping,
                                size: 64,
                                color: Theme.of(context).colorScheme.secondary,
                              ).animate().scale(duration: 500.ms),
                              const SizedBox(height: 16),
                              Text(
                                _searchController.text.isNotEmpty ? 'Aucune commande trouvée' : 'Aucune commande disponible',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: GoogleFonts.poppins().fontFamily,
                                  color: Theme.of(context).colorScheme.onBackground,
                                ),
                              ).animate().fadeIn(delay: 200.ms),
                              const SizedBox(height: 8),
                              Text(
                                _searchController.text.isNotEmpty ? 'Essayez un autre terme de recherche' : '',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: GoogleFonts.poppins().fontFamily,
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                              ).animate().fadeIn(delay: 300.ms),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: groupedOrders.entries.where((entry) => entry.value.isNotEmpty).map((entry) {
                              final title = entry.key;
                              final orders = entry.value;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionHeader(title, orders.length),
                                  const SizedBox(height: 16),
                                  ...orders.asMap().entries.map((orderEntry) {
                                    final index = orderEntry.key;
                                    final order = orderEntry.value;
                                    return Column(
                                      children: [
                                        _buildOrderCard(
                                          order: order,
                                          delay: index * 200,
                                        ),
                                        const SizedBox(height: 12),
                                      ],
                                    );
                                  }).toList(),
                                  const SizedBox(height: 32),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: widget.clientId != null
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddOrderPage(clientId: widget.clientId!),
                  ),
                );
                if (result == true) {
                  await _loadOrders();
                }
              },
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.add).animate().rotate(duration: 500.ms),
            )
          : null,
    );
  }
}