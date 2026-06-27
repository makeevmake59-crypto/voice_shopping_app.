import 'dart:math';
import 'package:flutter/material.dart';

class CategoryPieChart extends StatelessWidget {
  final Map<String, double> data;
  final List<Color> colors;

  const CategoryPieChart({super.key, required this.data, required this.colors});

  @override
  Widget build(BuildContext context) {
    final total = data.values.fold(0.0, (sum, item) => sum + item);
    if (total == 0) return const SizedBox.shrink();

    return Container(
      width: 160,
      height: 160,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: CustomPaint(
        painter: _PieChartPainter(data: data, colors: colors, total: total),
      ),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final Map<String, double> data;
  final List<Color> colors;
  final double total;

  _PieChartPainter(
      {required this.data, required this.colors, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    var startAngle = -pi / 2;
    var colorIndex = 0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24; // Толщина кольца диаграммы

    data.forEach((category, value) {
      if (value == 0) return;

      final sweepAngle = (value / total) * 2 * pi;
      paint.color = colors[colorIndex % colors.length];

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);

      startAngle += sweepAngle;
      colorIndex++;
    });
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) => true;
}
