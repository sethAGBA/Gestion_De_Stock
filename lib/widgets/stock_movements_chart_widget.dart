import 'package:flutter/material.dart';
import 'dart:math';

class StockMovementsChartWidget extends StatefulWidget {
  final List<String> months;
  final List<StockMovement> movements;

  const StockMovementsChartWidget({
    Key? key,
    required this.months,
    this.movements = const [],
  }) : super(key: key);

  @override
  State<StockMovementsChartWidget> createState() => _StockMovementsChartWidgetState();
}

class _StockMovementsChartWidgetState extends State<StockMovementsChartWidget> {
  bool _animated = false;

  @override
  Widget build(BuildContext context) {
    if (widget.months.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      height: 400.0,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildHeader(),
              Row(
                children: [
                  const Text('Barres classiques'),
                  Switch(
                    value: _animated,
                    onChanged: (val) {
                      setState(() => _animated = val);
                    },
                  ),
                  const Text('Fréquence animée'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 36.0),
          _buildLegend(),
          const SizedBox(height: 32.0),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ChartWidget(
                months: widget.months,
                movements: widget.movements,
                animated: _animated,
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
    return const Text(
      'Mouvements de stock',
      style: TextStyle(
        fontSize: 18.0,
        fontWeight: FontWeight.bold,
      ),
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

class ChartWidget extends StatefulWidget {
  final List<String> months;
  final List<StockMovement> movements;
  final bool animated;

  const ChartWidget({
    Key? key,
    required this.months,
    required this.movements,
    this.animated = false,
  }) : super(key: key);

  @override
  State<ChartWidget> createState() => _ChartWidgetState();
}

class _ChartWidgetState extends State<ChartWidget> with SingleTickerProviderStateMixin {
  late List<double> inHeights;
  late List<double> outHeights;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _initHeights();
    if (widget.animated) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant ChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animated != oldWidget.animated) {
      if (widget.animated) {
        _controller.reset();
        _controller.forward();
      } else {
        _controller.reset();
      }
    }
  }

  void _initHeights() {
    final random = Random();
    final inValues = List.generate(widget.months.length, (_) => 40 + random.nextInt(60));
    final outValues = List.generate(widget.months.length, (_) => 20 + random.nextInt(40));
    final maxValue = (inValues + outValues).reduce((a, b) => a > b ? a : b).toDouble();
    inHeights = inValues.map((v) => (v / maxValue) * 160).toList();
    outHeights = outValues.map((v) => (v / maxValue) * 160).toList();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        widget.months.length,
        (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                widget.animated
                    ? AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return _buildBar(inHeights[index] * _controller.value, Colors.green.shade300);
                        },
                      )
                    : _buildBar(inHeights[index], Colors.green.shade300),
                widget.animated
                    ? AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return _buildBar(outHeights[index] * _controller.value, Colors.red.shade300);
                        },
                      )
                    : _buildBar(outHeights[index], Colors.red.shade300),
                const SizedBox(height: 8.0),
                SizedBox(
                  width: 40.0,
                  child: Text(
                    widget.months[index],
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