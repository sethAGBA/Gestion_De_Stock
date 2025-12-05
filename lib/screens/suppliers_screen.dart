import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import '../widgets/suppliers_table_widget.dart';
import '../models/models.dart';

class SuppliersScreen extends StatelessWidget {
  const SuppliersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headline = theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.2);
    final surface = theme.colorScheme.surface;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fournisseurs'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.colorScheme.primary,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.08),
              theme.colorScheme.secondary.withOpacity(0.06),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: FutureBuilder<List<Supplier>>(
                  future: DatabaseHelper.getSuppliers(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Erreur : ${snapshot.error}'));
                    }
                    final suppliers = snapshot.data ?? [];
                    final totalSuppliers = suppliers.length;
                    final categoriesCount = suppliers.map((s) => s.category).toSet().length;
                    final contactables = suppliers.where((s) => s.telephone.isNotEmpty || s.email.isNotEmpty).length;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: surface,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 14,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Vue d\'ensemble', style: headline),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 12,
                                      children: [
                                        _StatChip(
                                          label: 'Fournisseurs',
                                          value: totalSuppliers.toString(),
                                          icon: Icons.store_mall_directory_outlined,
                                          color: theme.colorScheme.primary,
                                        ),
                                        _StatChip(
                                          label: 'Catégories',
                                          value: categoriesCount.toString(),
                                          icon: Icons.category_outlined,
                                          color: theme.colorScheme.secondary,
                                        ),
                                        _StatChip(
                                          label: 'Coordonnées renseignées',
                                          value: contactables.toString(),
                                          icon: Icons.contacts_outlined,
                                          color: Colors.teal,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 16,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: SuppliersTableWidget(
                            suppliers: suppliers,
                            embedInCard: true,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: color.withOpacity(0.08),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700])),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
