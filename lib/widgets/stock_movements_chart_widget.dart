import 'package:flutter/material.dart';
import 'dart:math';

class StockMovementsChartWidget extends StatelessWidget {
  final List<String> months;
  final List<StockMovement> movements;

  const StockMovementsChartWidget({
    Key? key,
    required this.months,
    this.movements = const [],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (months.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
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
          _buildHeader(),
          const SizedBox(height: 20.0),
          _buildLegend(),
          const SizedBox(height: 10.0),
          SizedBox(
            height: 200.0,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ChartWidget(
                months: months,
                movements: movements,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(16.0),
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
      child: const Center(
        child: Text(
          'Aucune donnée disponible',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16.0,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Mouvements de stock',
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
    );
  }

  Widget _buildLegend() {
    return Row(
      children: [
        _buildLegendItem(Colors.green.shade300, 'Entrées'),
        const SizedBox(width: 16.0),
        _buildLegendItem(Colors.red.shade300, 'Sorties'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12.0,
          height: 12.0,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2.0),
          ),
        ),
        const SizedBox(width: 4.0),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.0,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}

class ChartWidget extends StatelessWidget {
  final List<String> months;
  final List<StockMovement> movements;

  const ChartWidget({
    Key? key,
    required this.months,
    required this.movements,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final random = Random();
    final inValues = List.generate(months.length, (_) => 40 + random.nextInt(60));
    final outValues = List.generate(months.length, (_) => 20 + random.nextInt(40));
    
    final maxValue = (inValues + outValues)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        months.length,
        (index) {
          final inHeight = (inValues[index] / maxValue) * 160;
          final outHeight = (outValues[index] / maxValue) * 160;
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildBar(inHeight, Colors.green.shade300),
                _buildBar(outHeight, Colors.red.shade300),
                const SizedBox(height: 8.0),
                SizedBox(
                  width: 40.0,
                  child: Text(
                    months[index],
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12.0,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBar(double height, Color color) {
    return Container(
      width: 32.0,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4.0)),
      ),
    );
  }
}

class StockMovement {
  final String month;
  final int inQuantity;
  final int outQuantity;

  const StockMovement({
    required this.month,
    required this.inQuantity,
    required this.outQuantity,
  });
}