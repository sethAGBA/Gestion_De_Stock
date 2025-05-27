import 'package:flutter/material.dart';
import '../models/models.dart';
import '../helpers/database_helper.dart';

class SuppliersTableWidget extends StatefulWidget {
  final List<Supplier> suppliers;

  const SuppliersTableWidget({
    Key? key,
    required this.suppliers,
  }) : super(key: key);

  @override
  State<SuppliersTableWidget> createState() => _SuppliersTableWidgetState();
}

class _SuppliersTableWidgetState extends State<SuppliersTableWidget> {
  late List<Supplier> _suppliers;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _suppliers = widget.suppliers;
  }

  Future<void> _refreshSuppliers() async {
    setState(() => _loading = true);
    _suppliers = await DatabaseHelper.getSuppliers();
    setState(() => _loading = false);
  }

  Future<void> _showSupplierDialog({Supplier? supplier}) async {
    final nameController = TextEditingController(text: supplier?.name ?? '');
    final productController = TextEditingController(text: supplier?.productName ?? '');
    final categoryController = TextEditingController(text: supplier?.category ?? '');
    final priceController = TextEditingController(text: supplier?.price.toString() ?? '');
    final contactController = TextEditingController(text: supplier?.contact ?? '');
    final emailController = TextEditingController(text: supplier?.email ?? '');
    final telephoneController = TextEditingController(text: supplier?.telephone ?? '');
    final adresseController = TextEditingController(text: supplier?.adresse ?? '');
    final isEdit = supplier != null;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEdit ? 'Modifier le fournisseur' : 'Ajouter un fournisseur'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nom'),
                ),
                TextField(
                  controller: productController,
                  decoration: const InputDecoration(labelText: 'Produit'),
                ),
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(labelText: 'Catégorie'),
                ),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Prix'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                TextField(
                  controller: contactController,
                  decoration: const InputDecoration(labelText: 'Contact'),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: telephoneController,
                  decoration: const InputDecoration(labelText: 'Téléphone'),
                ),
                TextField(
                  controller: adresseController,
                  decoration: const InputDecoration(labelText: 'Adresse'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final product = productController.text.trim();
                final category = categoryController.text.trim();
                final price = double.tryParse(priceController.text.trim()) ?? 0.0;
                final contact = contactController.text.trim();
                final email = emailController.text.trim();
                final telephone = telephoneController.text.trim();
                final adresse = adresseController.text.trim();
                if (name.isEmpty || product.isEmpty || category.isEmpty) return;
                final newSupplier = Supplier(
                  id: supplier?.id ?? 0,
                  name: name,
                  productName: product,
                  category: category,
                  price: price,
                  contact: contact,
                  email: email,
                  telephone: telephone,
                  adresse: adresse,
                );
                if (isEdit) {
                  await DatabaseHelper.updateSupplier(newSupplier);
                } else {
                  await DatabaseHelper.addSupplier(newSupplier);
                }
                Navigator.pop(context, true);
              },
              child: Text(isEdit ? 'Enregistrer' : 'Ajouter'),
            ),
          ],
        );
      },
    );
    if (result == true) {
      await _refreshSuppliers();
    }
  }

  Future<void> _deleteSupplier(Supplier supplier) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le fournisseur'),
        content: Text('Voulez-vous vraiment supprimer le fournisseur "${supplier.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseHelper.deleteSupplier(supplier.id);
      await _refreshSuppliers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Fournisseurs',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'Ajouter un fournisseur',
                  onPressed: () => _showSupplierDialog(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _loading
              ? const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              : _suppliers.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(child: Text('Aucun fournisseur enregistré.')),
                    )
                  : Scrollbar(
                      thumbVisibility: true,
                      trackVisibility: true,
                      notificationPredicate: (notif) => notif.metrics.axis == Axis.horizontal,
                      controller: ScrollController(),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Nom')),
                            DataColumn(label: Text('Produit')),
                            DataColumn(label: Text('Catégorie')),
                            DataColumn(label: Text('Prix')),
                            DataColumn(label: Text('Contact')),
                            DataColumn(label: Text('Email')),
                            DataColumn(label: Text('Téléphone')),
                            DataColumn(label: Text('Adresse')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: _suppliers.map((supplier) {
                            return DataRow(
                              cells: [
                                DataCell(Text(supplier.name)),
                                DataCell(Text(supplier.productName)),
                                DataCell(Text(supplier.category)),
                                DataCell(Text('FCFA ${supplier.price.toStringAsFixed(2)}')),
                                DataCell(Text(supplier.contact)),
                                DataCell(Text(supplier.email)),
                                DataCell(Text(supplier.telephone)),
                                DataCell(Text(supplier.adresse)),
                                DataCell(Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      tooltip: 'Modifier',
                                      onPressed: () => _showSupplierDialog(supplier: supplier),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      tooltip: 'Supprimer',
                                      onPressed: () => _deleteSupplier(supplier),
                                    ),
                                  ],
                                )),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
        ],
      ),
    );
  }
}