import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../helpers/database_helper.dart';

class SuppliersTableWidget extends StatefulWidget {
  final List<Supplier> suppliers;
  final bool embedInCard;

  const SuppliersTableWidget({
    Key? key,
    required this.suppliers,
    this.embedInCard = false,
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
    final productController = TextEditingController(
      text: supplier?.productName ?? '',
    );
    final categoryController = TextEditingController(
      text: supplier?.category ?? '',
    );
    final priceController = TextEditingController(
      text: supplier?.price.toString() ?? '',
    );
    final contactController = TextEditingController(
      text: supplier?.contact ?? '',
    );
    final emailController = TextEditingController(text: supplier?.email ?? '');
    final telephoneController = TextEditingController(
      text: supplier?.telephone ?? '',
    );
    final adresseController = TextEditingController(
      text: supplier?.adresse ?? '',
    );
    final isEdit = supplier != null;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            isEdit ? 'Modifier le fournisseur' : 'Ajouter un fournisseur',
          ),
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
                final price =
                    double.tryParse(priceController.text.trim()) ?? 0.0;
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
      builder:
          (context) => AlertDialog(
            title: const Text('Supprimer le fournisseur'),
            content: Text(
              'Voulez-vous vraiment supprimer le fournisseur "${supplier.name}" ?',
            ),
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
    final isDarkMode = theme.brightness == Brightness.dark;
    final controller = ScrollController();
    final showHeader = !widget.embedInCard;

    final Widget addSupplierButton =
        widget.embedInCard
            ? OutlinedButton.icon(
              onPressed: () => _showSupplierDialog(),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Ajouter'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                side: BorderSide(
                  color: theme.colorScheme.primary.withValues(alpha: 0.4),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            )
            : FilledButton.icon(
              onPressed: () => _showSupplierDialog(),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Nouveau fournisseur'),
            );

    Widget buildTable() {
      if (_loading) {
        return const Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (_suppliers.isEmpty) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Text(
              'Aucun fournisseur enregistré.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ),
        );
      }

      return Scrollbar(
        controller: controller,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: controller,
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 28,
            horizontalMargin: 24,
            headingRowHeight: 56,
            headingTextStyle: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.grey.shade200 : Colors.grey.shade700,
            ),
            dataTextStyle: theme.textTheme.bodyMedium?.copyWith(
              color: isDarkMode ? Colors.grey.shade200 : Colors.grey.shade800,
            ),
            headingRowColor: WidgetStatePropertyAll<Color?>(
              isDarkMode
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.shade50,
            ),
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
            rows:
                _suppliers.map((supplier) {
                  return DataRow(
                    cells: [
                      DataCell(Text(supplier.name)),
                      DataCell(Text(supplier.productName)),
                      DataCell(Text(supplier.category)),
                      DataCell(
                        Text('${NumberFormat('#,##0.00', 'fr_FR').format(supplier.price)}\u00A0FCFA'),
                      ),
                      DataCell(Text(supplier.contact)),
                      DataCell(Text(supplier.email)),
                      DataCell(Text(supplier.telephone)),
                      DataCell(Text(supplier.adresse)),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.edit_rounded,
                                color: theme.colorScheme.primary,
                              ),
                              tooltip: 'Modifier',
                              onPressed:
                                  () => _showSupplierDialog(supplier: supplier),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.redAccent,
                              ),
                              tooltip: 'Supprimer',
                              onPressed: () => _deleteSupplier(supplier),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
          ),
        ),
      );
    }

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Fournisseurs',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                addSupplierButton,
              ],
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 12),
        ] else ...[
          Align(alignment: Alignment.centerRight, child: addSupplierButton),
          const SizedBox(height: 16),
        ],
        buildTable(),
      ],
    );

    if (widget.embedInCard) {
      return content;
    }

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color:
              isDarkMode
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          if (!isDarkMode)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 24,
              offset: const Offset(0, 16),
            ),
        ],
      ),
      child: content,
    );
  }
}
