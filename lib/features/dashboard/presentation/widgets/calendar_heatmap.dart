import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/statistics_service.dart';

class CalendarHeatmap extends StatelessWidget {
  final List<DailyStats> weeklyStats;
  final Function(DateTime)? onDayTap;

  const CalendarHeatmap({
    super.key,
    required this.weeklyStats,
    this.onDayTap,
  });

  Color _getColorForScore(double score) {
    if (score >= 80) return Colors.green.shade400;
    if (score >= 60) return Colors.lightGreen.shade400;
    if (score >= 40) return Colors.orange.shade300;
    if (score >= 20) return Colors.deepOrange.shade300;
    if (score > 0) return Colors.red.shade300;
    return Colors.grey.shade200;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Semana Atual',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: weeklyStats.map((stats) {
                final isToday = stats.date.day == DateTime.now().day &&
                    stats.date.month == DateTime.now().month &&
                    stats.date.year == DateTime.now().year;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => onDayTap?.call(stats.date),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        children: [
                          Text(
                            DateFormat('EEE', 'pt_PT')
                                .format(stats.date)
                                .substring(0, 1)
                                .toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight:
                                  isToday ? FontWeight.bold : FontWeight.normal,
                              color: isToday
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _getColorForScore(stats.score),
                              borderRadius: BorderRadius.circular(8),
                              border: isToday
                                  ? Border.all(
                                      color: Theme.of(context).primaryColor,
                                      width: 2,
                                    )
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                stats.date.day.toString(),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: stats.hasData
                                      ? Colors.white
                                      : Colors.grey[600],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (stats.hasData)
                            Text(
                              '${stats.completedTasks}/${stats.totalTasks}',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('Excelente', Colors.green.shade400),
        const SizedBox(width: 8),
        _buildLegendItem('Bom', Colors.lightGreen.shade400),
        const SizedBox(width: 8),
        _buildLegendItem('Regular', Colors.orange.shade300),
        const SizedBox(width: 8),
        _buildLegendItem('Fraco', Colors.red.shade300),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
