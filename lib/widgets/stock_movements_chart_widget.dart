import 'dart:math';

import 'package:flutter/material.dart';

class StockMovementsChartWidget extends StatefulWidget {
  final List<String> months;
  final List<StockMovement> movements;

  const StockMovementsChartWidget({
    Key? key,
    required this.months,
    this.movements = const [],
  }) : super(key: key);

  @override
  State<StockMovementsChartWidget> createState() =>
      _StockMovementsChartWidgetState();
}

class _StockMovementsChartWidgetState extends State<StockMovementsChartWidget> {
  bool _animated = true;

  @override
  Widget build(BuildContext context) {
    if (widget.months.isEmpty) {
      return _buildEmptyState(context);
    }

    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              isDarkMode
                  ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                  : [const Color(0xFFEFF6FF), const Color(0xFFE0E7FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color:
              isDarkMode
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          if (!isDarkMode)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 28,
              offset: const Offset(0, 18),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme, isDarkMode),
          const SizedBox(height: 20),
          _LegendRow(isDarkMode: isDarkMode),
          const SizedBox(height: 24),
          // Use Expanded so the chart takes remaining space and avoids overflow
          Expanded(
            child: ChartCanvas(
              months: widget.months,
              movements: widget.movements,
              animated: _animated,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDarkMode) {
    final titleStyle = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w700,
      color: isDarkMode ? Colors.white : Colors.grey.shade900,
    );
    final subtitleStyle = theme.textTheme.bodyMedium?.copyWith(
      color:
          isDarkMode
              ? Colors.white.withValues(alpha: 0.7)
              : Colors.grey.shade600,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.area_chart_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mouvements de stock', style: titleStyle),
                const SizedBox(height: 4),
                Text(
                  'Entrées et sorties sur les 12 derniers mois',
                  style: subtitleStyle,
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            Text(
              'Animation',
              style: theme.textTheme.bodyMedium?.copyWith(
                color:
                    isDarkMode
                        ? Colors.white.withValues(alpha: 0.8)
                        : Colors.grey.shade700,
              ),
            ),
            const SizedBox(width: 8),
            Switch.adaptive(
              value: _animated,
              activeColor: isDarkMode ? Colors.white : const Color(0xFF1D4ED8),
              onChanged: (val) => setState(() => _animated = val),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: theme.colorScheme.surface,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.show_chart_outlined, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Aucune donnée de mouvement',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 6),
          Text(
            'Enregistrez des entrées et sorties pour visualiser les tendances du stock.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class ChartCanvas extends StatefulWidget {
  final List<String> months;
  final List<StockMovement> movements;
  final bool animated;

  const ChartCanvas({
    Key? key,
    required this.months,
    required this.movements,
    required this.animated,
  }) : super(key: key);

  @override
  State<ChartCanvas> createState() => _ChartCanvasState();
}

class _ChartCanvasState extends State<ChartCanvas>
    with SingleTickerProviderStateMixin {
  AnimationController? _animController;

  AnimationController get _controller {
    if (_animController == null) {
      _animController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200),
      );
    }
    return _animController!;
  }
  late List<double> _entries;
  late List<double> _exits;
  late double _maxValue;

  @override
  void initState() {
    super.initState();
    // ensure controller is created via getter so it's always available
    _initialiseData();
    if (widget.animated) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant ChartCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.movements != oldWidget.movements ||
        widget.months != oldWidget.months) {
      _initialiseData();
    }
    if (widget.animated != oldWidget.animated) {
      if (widget.animated) {
        _controller
          ..reset()
          ..forward();
      } else {
        _controller
          ..stop()
          ..value = 1.0;
      }
    }
  }

  void _initialiseData() {
    final mapping = {
      for (final movement in widget.movements) movement.month: movement,
    };
    final random = Random();

    _entries =
        widget.months
            .map(
              (month) =>
                  mapping[month]?.inQuantity.toDouble() ??
                  (40 + random.nextInt(60)).toDouble(),
            )
            .toList();
    _exits =
        widget.months
            .map(
              (month) =>
                  mapping[month]?.outQuantity.toDouble() ??
                  (20 + random.nextInt(40)).toDouble(),
            )
            .toList();

    _maxValue = ([..._entries, ..._exits].fold<double>(
      0,
      (prev, value) => value > prev ? value : prev,
    )).clamp(1, double.infinity);
  }

  @override
  void dispose() {
    _animController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final minWidth = widget.months.length * 80.0;
        final width =
            constraints.maxWidth.isFinite ? constraints.maxWidth : minWidth;
        final chartWidth = width < minWidth ? minWidth : width;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: chartWidth,
            child: AnimatedBuilder(
              animation: _controller,
              builder:
                  (context, _) => CustomPaint(
                    painter: _LineChartPainter(
                      months: widget.months,
                      entries: _entries,
                      exits: _exits,
                      maxValue: _maxValue,
                      progress: widget.animated ? _controller.value : 1.0,
                      isDarkMode:
                          Theme.of(context).brightness == Brightness.dark,
                    ),
                  ),
            ),
          ),
        );
      },
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<String> months;
  final List<double> entries;
  final List<double> exits;
  final double maxValue;
  final double progress;
  final bool isDarkMode;

  _LineChartPainter({
    required this.months,
    required this.entries,
    required this.exits,
    required this.maxValue,
    required this.progress,
    required this.isDarkMode,
  });

  static const double _leftPadding = 36;
  static const double _rightPadding = 24;
  static const double _topPadding = 24;
  static const double _bottomPadding = 44;

  @override
  void paint(Canvas canvas, Size size) {
    final chartHeight =
        (size.height - _topPadding - _bottomPadding)
            .clamp(0, size.height)
            .toDouble();
    final chartWidth =
        (size.width - _leftPadding - _rightPadding)
            .clamp(0, size.width)
            .toDouble();
    if (chartHeight == 0 || chartWidth == 0 || months.isEmpty) {
      return;
    }

    final baseLine = size.height - _bottomPadding;
    final entryColor = const Color(0xFF22C55E);
    final exitColor = const Color(0xFFEF4444);

    void drawGrid() {
      final gridPaint =
          Paint()
            ..color = (isDarkMode ? Colors.white : Colors.indigo).withValues(
              alpha: 0.08,
            )
            ..strokeWidth = 1;
      const gridLines = 4;
      for (int i = 0; i <= gridLines; i++) {
        final dy = _topPadding + chartHeight * (i / gridLines);
        canvas.drawLine(
          Offset(_leftPadding, dy),
          Offset(size.width - _rightPadding, dy),
          gridPaint,
        );
      }
    }

    List<Offset> buildPoints(List<double> values) {
      final step = months.length == 1 ? 0.0 : chartWidth / (months.length - 1);
      return List.generate(values.length, (index) {
        final x =
            months.length == 1
                ? _leftPadding + chartWidth / 2
                : _leftPadding + (step * index);
        final ratio = (values[index] / maxValue) * progress;
        final y = baseLine - (chartHeight * ratio);
        return Offset(x, y);
      });
    }

    Path buildSmoothPath(List<Offset> points) {
      final path = Path();
      if (points.isEmpty) return path;
      path.moveTo(points.first.dx, points.first.dy);
      for (int i = 0; i < points.length - 1; i++) {
        final current = points[i];
        final next = points[i + 1];
        final control1 = Offset((current.dx + next.dx) / 2, current.dy);
        final control2 = Offset((current.dx + next.dx) / 2, next.dy);
        path.cubicTo(
          control1.dx,
          control1.dy,
          control2.dx,
          control2.dy,
          next.dx,
          next.dy,
        );
      }
      return path;
    }

    drawGrid();

    final entryPoints = buildPoints(entries);
    final exitPoints = buildPoints(exits);

    void drawSeries(List<Offset> points, Color color) {
      if (points.isEmpty) return;
      final linePaint =
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.0
            ..strokeCap = StrokeCap.round;

      final gradientPaint =
          Paint()
            ..shader = LinearGradient(
              colors: [
                color.withValues(alpha: 0.28),
                color.withValues(alpha: 0.05),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(
              Rect.fromLTWH(_leftPadding, _topPadding, chartWidth, chartHeight),
            );

      final path = buildSmoothPath(points);
      final areaPath =
          Path.from(path)
            ..lineTo(points.last.dx, baseLine)
            ..lineTo(points.first.dx, baseLine)
            ..close();

      canvas.drawPath(areaPath, gradientPaint);
      canvas.drawPath(path, linePaint);

      final dotPaint = Paint()..color = color;
      for (final point in points) {
        canvas.drawCircle(point, 4.5, dotPaint);
      }
    }

    drawSeries(entryPoints, entryColor);
    drawSeries(exitPoints, exitColor);

    final textStyle = TextStyle(
      color: isDarkMode ? Colors.white70 : Colors.indigo.shade600,
      fontSize: 11,
      fontWeight: FontWeight.w600,
    );

    for (int i = 0; i < months.length; i++) {
      final month = months[i];
      final offset =
          entryPoints.length == months.length
              ? entryPoints[i]
              : buildPoints(List.filled(months.length, 0))[i];
      final painter = TextPainter(
        text: TextSpan(text: month, style: textStyle),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: 80);
      final dx = offset.dx - painter.width / 2;
      final dy = baseLine + 12;
      painter.paint(canvas, Offset(dx, dy));
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.entries != entries ||
        oldDelegate.exits != exits ||
        oldDelegate.progress != progress ||
        oldDelegate.isDarkMode != isDarkMode;
  }
}

class _LegendRow extends StatelessWidget {
  final bool isDarkMode;

  const _LegendRow({Key? key, required this.isDarkMode}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: const [
        _LegendChip(color: Color(0xFF22C55E), label: 'Entrées'),
        _LegendChip(color: Color(0xFFEF4444), label: 'Sorties'),
      ],
    );
  }
}

class _LegendChip extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendChip({Key? key, required this.color, required this.label})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color.computeLuminance() > 0.55 ? Colors.indigo : color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
