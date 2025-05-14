import 'package:flutter/material.dart';
import '../models/models.dart';

class SuppliersTableWidget extends StatelessWidget {
  final List<Supplier> suppliers;

  const SuppliersTableWidget({
    Key? key,
    required this.suppliers,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                TextButton.icon(
                  onPressed: () {},
                  icon: const Text('Voir plus'),
                  label: const Icon(Icons.arrow_forward, size: 16.0),
                ),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            itemBuilder: (context, index) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Text(
                          index == 0 ? 'Supplier X' : (index == 1 ? 'Soluveier X' : 'Supureier Y'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (index < 2)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(index == 0 ? 'Article A' : 'Article B'),
                          ),
                          Expanded(
                            child: Text(index == 0 ? 'Électronique' : 'Français'),
                          ),
                          Expanded(
                            child: Text('FCFA ${index == 0 ? '50.00' : '150.00'}'),
                          ),
                          TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                            ),
                            child: Text(
                              index == 0 ? 'Modifier' : 'Supprimer',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 12.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (index < 2) const SizedBox(height: 16.0),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}