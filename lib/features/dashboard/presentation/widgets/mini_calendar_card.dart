import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MiniCalendarCard extends StatefulWidget {
  final DateTime selectedDate;
  final String? userId;
  final ValueChanged<DateTime> onChangeDate;

  const MiniCalendarCard({
    super.key,
    required this.selectedDate,
    this.userId,
    required this.onChangeDate,
  });

  @override
  State<MiniCalendarCard> createState() => _MiniCalendarCardState();
}

class _MiniCalendarCardState extends State<MiniCalendarCard> {
  DateTime _weekStart = DateTime.now();
  Map<String, Color> _dayColors = {};

  @override
  void initState() {
    super.initState();
    _weekStart = _getWeekStart(widget.selectedDate);
    _loadWeekOccupancy();
  }

  @override
  void didUpdateWidget(MiniCalendarCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!DateUtils.isSameDay(oldWidget.selectedDate, widget.selectedDate)) {
      final newWeekStart = _getWeekStart(widget.selectedDate);
      if (!DateUtils.isSameDay(_weekStart, newWeekStart)) {
        setState(() => _weekStart = newWeekStart);
        _loadWeekOccupancy();
      }
    }
  }

  DateTime _getWeekStart(DateTime date) {
    final base = DateTime(date.year, date.month, date.day);
    return base.subtract(Duration(days: base.weekday - 1));
  }

  Future<void> _loadWeekOccupancy() async {
    if (widget.userId == null) return;
    final colors = <String, Color>{};
    final weekEnd = _weekStart.add(const Duration(days: 7));

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('userId', isEqualTo: widget.userId)
          .where('dataInicio', isGreaterThanOrEqualTo: Timestamp.fromDate(_weekStart))
          .where('dataInicio', isLessThan: Timestamp.fromDate(weekEnd))
          .where('estado', whereIn: ['pendente', 'emExecucao', 'concluida'])
          .get();

      final tasksByDay = <String, int>{};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final dataInicio = (data['dataInicio'] as Timestamp).toDate();
        final dayKey = '${dataInicio.year}-${dataInicio.month}-${dataInicio.day}';
        final duracao = data['duracaoMinutos'] as int? ?? 0;
        tasksByDay[dayKey] = (tasksByDay[dayKey] ?? 0) + duracao;
      }

      for (int i = 0; i < 7; i++) {
        final day = _weekStart.add(Duration(days: i));
        final dayKey = '${day.year}-${day.month}-${day.day}';
        final occupied = tasksByDay[dayKey] ?? 0;
        final ratio = occupied / 960;

        if (ratio >= 0.9) {
          colors[dayKey] = const Color(0xFFE53935);
        } else if (ratio >= 0.7) {
          colors[dayKey] = const Color(0xFFFF9800);
        } else if (ratio > 0) {
          colors[dayKey] = const Color(0xFF667EEA);
        } else {
          colors[dayKey] = Colors.grey.shade300;
        }
      }

      if (mounted) setState(() => _dayColors = colors);
    } catch (_) {}
  }

  void _navigateWeek(int direction) {
    setState(() {
      _weekStart = _weekStart.add(Duration(days: 7 * direction));
      widget.onChangeDate(widget.selectedDate.add(Duration(days: 7 * direction)));
    });
    _loadWeekOccupancy();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = List.generate(7, (i) => _weekStart.add(Duration(days: i)));
    const labels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 18, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _navigateWeek(-1), iconSize: 20, padding: EdgeInsets.zero, constraints: const BoxConstraints(), tooltip: 'Semana anterior'),
              Text(DateFormat('MMM yyyy', 'pt_PT').format(_weekStart), style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
              IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _navigateWeek(1), iconSize: 20, padding: EdgeInsets.zero, constraints: const BoxConstraints(), tooltip: 'Próxima semana'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final d = days[index];
              final isSelected = DateUtils.isSameDay(d, widget.selectedDate);
              final isToday = DateUtils.isSameDay(d, DateTime.now());
              final dayKey = '${d.year}-${d.month}-${d.day}';
              final dotColor = _dayColors[dayKey] ?? Colors.grey.shade300;

              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => widget.onChangeDate(d),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(labels[index], style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Container(
                        width: 26, height: 26, alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: (isSelected || isToday) ? Border.all(color: isSelected ? const Color(0xFF667EEA) : Colors.grey.shade400, width: 2) : null,
                        ),
                        child: Text('${d.day}', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700, color: isSelected ? Colors.black : Colors.grey.shade700)),
                      ),
                      const SizedBox(height: 8),
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
