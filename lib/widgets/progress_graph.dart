import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ProgressGraph extends StatelessWidget {
  const ProgressGraph({
    super.key,
    required this.title,
    required this.summary,
    required this.subtitle,
    required this.values,
    required this.labels,
    required this.color,
    required this.minY,
    required this.maxY,
    required this.yInterval,
    this.isBarChart = false,
  });

  final String title;
  final String summary;
  final String subtitle;
  final List<double> values;
  final List<String> labels;
  final Color color;
  final double minY;
  final double maxY;
  final double yInterval;
  final bool isBarChart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final titles = FlTitlesData(
      topTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      rightTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          interval: yInterval,
          getTitlesWidget: (value, meta) {
            return Text(
              value.toStringAsFixed(0),
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            );
          },
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          interval: 1,
          getTitlesWidget: (value, meta) {
            final index = value.toInt();

            if (value != index.toDouble() ||
                index < 0 ||
                index >= labels.length) {
              return const SizedBox.shrink();
            }

            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                labels[index],
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            );
          },
        ),
      ),
    );

    final grid = FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: yInterval,
      getDrawingHorizontalLine: (value) {
        return FlLine(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          strokeWidth: 1,
        );
      },
    );

    final border = FlBorderData(show: false);

    final Widget chart;

    if (isBarChart) {
      chart = BarChart(
        BarChartData(
          minY: minY,
          maxY: maxY,
          alignment: BarChartAlignment.spaceAround,
          titlesData: titles,
          gridData: grid,
          borderData: border,
          barTouchData: BarTouchData(enabled: false),
          barGroups: List.generate(
            values.length,
            (index) => BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: values[index],
                  width: 18,
                  color: color,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      chart = LineChart(
        LineChartData(
          minX: 0,
          maxX: (values.length - 1).toDouble(),
          minY: minY,
          maxY: maxY,
          titlesData: titles,
          gridData: grid,
          borderData: border,
          lineTouchData: LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                values.length,
                (index) => FlSpot(index.toDouble(), values[index]),
              ),
              color: color,
              barWidth: 3,
              isCurved: false,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: color.withValues(alpha: 0.10),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Sample data',
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            summary,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 210,
            child: chart,
          ),
        ],
      ),
    );
  }
}