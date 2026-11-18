import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../tasks/data/repositories/task_repository.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../core/config/app_timezone.dart';
import '../../../../core/config/app_config.dart';

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
  DateTime _weekStart = AppTimeZone.now();
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
    final base = AppTimeZone.dayStart(date);
    return base.subtract(Duration(days: base.weekday - 1));
  }

  Future<void> _loadWeekOccupancy() async {
    if (widget.userId == null) return;
    final colors = <String, Color>{};
    final weekEnd = _weekStart.add(const Duration(days: 7));

    try {
      final tasks = await context.read<TaskRepository>().getByRange(
            widget.userId!,
            startInclusive: _weekStart,
            endExclusive: weekEnd,
          );
      if (!mounted) return;

      final tasksByDay = <String, int>{};
      for (final task in tasks) {
        final dataInicio = AppTimeZone.inAppZone(task.dataInicio);
        final dayKey =
            '${dataInicio.year}-${dataInicio.month}-${dataInicio.day}';
        final duracao = task.duracaoMinutos;
        tasksByDay[dayKey] = (tasksByDay[dayKey] ?? 0) + duracao;
      }

      for (int i = 0; i < 7; i++) {
        final day = _weekStart.add(Duration(days: i));
        final dayKey = '${day.year}-${day.month}-${day.day}';
        final occupied = tasksByDay[dayKey] ?? 0;
        final ratio = occupied / AppConfig.workMinutesPerDay;

        if (ratio >= 0.9) {
          colors[dayKey] = const Color(0xFFE53935);
        } else if (ratio >= 0.7) {
          colors[dayKey] = const Color(0xFFFF9800);
        } else if (ratio > 0) {
          colors[dayKey] = AppTheme.primaryColor;
        } else {
          colors[dayKey] =
              Theme.of(context).colorScheme.surfaceContainerHighest;
        }
      }

      if (mounted) setState(() => _dayColors = colors);
    } catch (_) {}
  }

  void _navigateWeek(int direction) {
    setState(() {
      _weekStart = _weekStart.add(Duration(days: 7 * direction));
      widget
          .onChangeDate(widget.selectedDate.add(Duration(days: 7 * direction)));
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
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _navigateWeek(-1),
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Semana anterior'),
              Text(DateFormat('MMM yyyy', 'pt_PT').format(_weekStart),
                  style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant)),
              IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _navigateWeek(1),
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Próxima semana'),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(7, (index) {
                final d = days[index];
                final isSelected = DateUtils.isSameDay(d, widget.selectedDate);
                final isToday = DateUtils.isSameDay(d, AppTimeZone.now());
                final dayKey = '${d.year}-${d.month}-${d.day}';
                final dotColor = _dayColors[dayKey] ??
                    theme.colorScheme.surfaceContainerHighest;

                return Semantics(
                  button: true,
                  selected: isSelected,
                  label: DateFormat('EEEE d MMMM', 'pt_PT').format(d),
                  child: ExcludeSemantics(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => widget.onChangeDate(d),
                      child: SizedBox(
                        width: 44,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(labels[index],
                                  style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              Container(
                                width: 26,
                                height: 26,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : null,
                                  border: (isSelected || isToday)
                                      ? Border.all(
                                          color: isSelected
                                              ? AppTheme.primaryColor
                                              : theme
                                                  .colorScheme.outlineVariant,
                                          width: 2)
                                      : null,
                                ),
                                child: Text('${d.day}',
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: isSelected
                                                ? theme.colorScheme.onPrimary
                                                : theme.colorScheme
                                                    .onSurfaceVariant)),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                      color: dotColor, shape: BoxShape.circle)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
