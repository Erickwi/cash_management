import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../data/models/transaction.dart';

class PieChartWidget extends StatelessWidget {
  final List<ExpenseByCategory> data;

  const PieChartWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('Sin datos'));
    }

    final total = data.fold<double>(0, (sum, item) => sum + item.total);

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: data.map((item) {
                final percentage = (item.total / total * 100);
                return PieChartSectionData(
                  value: item.total,
                  title: '${percentage.toStringAsFixed(1)}%',
                  color: Color(int.parse(item.color.replaceAll('#', '0xFF'))),
                  radius: 60,
                  titleStyle: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: data.map((item) {
            final percentage = (item.total / total * 100);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Color(int.parse(item.color.replaceAll('#', '0xFF'))),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${item.name} (${percentage.toStringAsFixed(1)}%)',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
