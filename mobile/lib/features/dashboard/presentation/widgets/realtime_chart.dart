import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/app_colors.dart';

class RealtimeChart extends StatelessWidget {
  final String title;
  final List<double> dataPoints;
  final List<double>? dataPoints2;
  final Color color1;
  final Color? color2;
  final double maxY;
  final String label1;
  final String? label2;

  const RealtimeChart({
    super.key,
    required this.title,
    required this.dataPoints,
    this.dataPoints2,
    required this.color1,
    this.color2,
    required this.maxY,
    required this.label1,
    this.label2,
  });

  @override
  Widget build(BuildContext context) {
    List<FlSpot> spots1 = [];
    for (int i = 0; i < dataPoints.length; i++) {
      spots1.add(FlSpot(i.toDouble(), dataPoints[i]));
    }

    List<FlSpot> spots2 = [];
    if (dataPoints2 != null) {
      for (int i = 0; i < dataPoints2!.length; i++) {
        spots2.add(FlSpot(i.toDouble(), dataPoints2![i]));
      }
    }

    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(width: 12, height: 12, color: color1),
                const SizedBox(width: 4),
                Text(label1, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                if (label2 != null && color2 != null) ...[
                  const SizedBox(width: 16),
                  Container(width: 12, height: 12, color: color2),
                  const SizedBox(width: 4),
                  Text(label2!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ]
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: 59,
                  minY: 0,
                  maxY: maxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: AppColors.border,
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 44,
                        interval: maxY > 0 ? (maxY / 4).ceilToDouble() : 1,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                            textAlign: TextAlign.right,
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots1,
                      isCurved: true,
                      color: color1,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color1.withAlpha(25),
                      ),
                    ),
                    if (spots2.isNotEmpty && color2 != null)
                      LineChartBarData(
                        spots: spots2,
                        isCurved: true,
                        color: color2,
                        barWidth: 2,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: color2!.withAlpha(25),
                        ),
                      ),
                  ],
                ),
                duration: Duration.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
