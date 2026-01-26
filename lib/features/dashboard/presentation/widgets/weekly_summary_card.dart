import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/statistics_service.dart';

class WeeklySummaryCard extends StatelessWidget {
  final List<DailyStats> weeklyStats;

  const WeeklySummaryCard({
    super.key,
    required this.weeklyStats,
  });

  @override
  Widget build(BuildContext context) {
    final totalDefined =
        weeklyStats.fold<int>(0, (sum, day) => sum + day.totalTasks);
    final totalCompleted =
        weeklyStats.fold<int>(0, (sum, day) => sum + day.completedTasks);
    final completionRate =
        totalDefined > 0 ? (totalCompleted / totalDefined * 100.0) : 0.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumo da Semana',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatBox(
                    icon: Icons.assignment,
                    label: 'Definidas',
                    value: totalDefined.toString(),
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatBox(
                    icon: Icons.check_circle,
                    label: 'Cumpridas',
                    value: totalCompleted.toString(),
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Taxa de Conclusão',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '${completionRate.toStringAsFixed(1)}%',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _getColorForRate(completionRate),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (completionRate / 100.0),
                minHeight: 6,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getColorForRate(completionRate),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForRate(double rate) {
    if (rate >= 80) return Colors.green;
    if (rate >= 60) return Colors.lightGreen;
    if (rate >= 40) return Colors.orange;
    return Colors.red;
  }
}
