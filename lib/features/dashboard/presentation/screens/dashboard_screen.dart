import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../tasks/domain/entities/task.dart';
import '../../../tasks/presentation/bloc/task_bloc.dart';
import '../../../tasks/presentation/screens/task_form_screen.dart';
import '../../../tasks/presentation/widgets/task_list_item.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadTasksForSelectedDate();
  }

  void _loadTasksForSelectedDate() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context
          .read<TaskBloc>()
          .add(TaskDayLoadRequested(authState.user.uid, _selectedDate));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => _loadTasksForSelectedDate(),
        child: BlocBuilder<TaskBloc, TaskState>(
          builder: (context, state) {
            final tasks = state is TaskDayLoaded ? state.tasks : const <Task>[];
            final stats = _DashboardStats.fromTasks(tasks);

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _DashboardHero(
                    selectedDate: _selectedDate,
                    stats: stats,
                    onLogoutPressed: () {
                      context.read<AuthBloc>().add(AuthLogoutRequested());
                    },
                    onChangeDate: (date) {
                      setState(() => _selectedDate = date);
                      _loadTasksForSelectedDate();
                    },
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      'Próximas Actividades',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                if (state is TaskLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (state is TaskError)
                  SliverFillRemaining(
                    child: Center(child: Text('Erro: ${state.message}')),
                  )
                else if (tasks.isEmpty)
                  SliverFillRemaining(child: _EmptyState())
                else
                  SliverPadding(
                    padding: const EdgeInsets.only(bottom: 120),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => TaskListItem(task: tasks[index]),
                        childCount: tasks.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: _NotarioFab(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TaskFormScreen(task: null)),
          );
        },
      ),
    );
  }
}

class _DashboardHero extends StatelessWidget {
  final DateTime selectedDate;
  final _DashboardStats stats;
  final VoidCallback onLogoutPressed;
  final ValueChanged<DateTime> onChangeDate;

  const _DashboardHero({
    required this.selectedDate,
    required this.stats,
    required this.onLogoutPressed,
    required this.onChangeDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();

    return Stack(
      children: [
        Container(
          height: 340,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFF7A5C),
                Color(0xFFFF9A62),
              ],
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _HeaderClock(
                        selectedDate: selectedDate,
                        locale: locale,
                      ),
                    ),
                    IconButton(
                      onPressed: onLogoutPressed,
                      icon: const Icon(Icons.logout),
                      color: Colors.white,
                      tooltip: 'Sair',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _ProgressRing(
                      percent: stats.percentCompleted,
                      label: '${stats.percentCompleted}%\nConcluído',
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Status',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _StatusPill(
                            text: stats.statusLabel,
                            backgroundColor: stats.statusColor,
                          ),
                          const SizedBox(height: 10),
                          _StatusPill(
                            text: stats.freeTimeLabel,
                            backgroundColor: const Color(0xFF2B5BC7),
                          ),
                          const SizedBox(height: 14),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _LegendDot(color: Color(0xFF2B5BC7), label: 'espaço\ndisponível'),
                              SizedBox(width: 14),
                              _LegendDot(color: Color(0xFFE53935), label: 'cheio'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _MiniCalendarCard(
                  selectedDate: selectedDate,
                  dayDotColor: stats.dayDotColor,
                  onChangeDate: onChangeDate,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderClock extends StatelessWidget {
  final DateTime selectedDate;
  final String locale;

  const _HeaderClock({required this.selectedDate, required this.locale});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeStr = DateFormat('HH:mm', locale).format(now);
    final dateStr = DateFormat("EEE, d 'de' MMMM", locale).format(selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dateStr,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          timeStr,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 44,
            height: 1.0,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ProgressRing extends StatelessWidget {
  final int percent;
  final String label;

  const _ProgressRing({required this.percent, required this.label});

  @override
  Widget build(BuildContext context) {
    final value = (percent / 100).clamp(0.0, 1.0);

    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 14,
              valueColor:
                  AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.25)),
            ),
          ),
          SizedBox(
            width: 140,
            height: 140,
            child: CircularProgressIndicator(
              value: value,
              strokeWidth: 14,
              strokeCap: StrokeCap.round,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              backgroundColor: Colors.transparent,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  final Color backgroundColor;

  const _StatusPill({required this.text, required this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}

class _MiniCalendarCard extends StatelessWidget {
  final DateTime selectedDate;
  final Color dayDotColor;
  final ValueChanged<DateTime> onChangeDate;

  const _MiniCalendarCard({
    required this.selectedDate,
    required this.dayDotColor,
    required this.onChangeDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

    final start = base.subtract(Duration(days: base.weekday - 1)); // segunda
    final days = List.generate(7, (i) => start.add(Duration(days: i)));
    const labels = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (index) {
          final d = days[index];
          final isSelected = DateUtils.isSameDay(d, selectedDate);
          final isToday = DateUtils.isSameDay(d, DateTime.now());

          // MVP: só o dia selecionado recebe “estado” real.
          // Os outros dias ficam neutros, mas o layout já está pronto.
          final dotColor = isSelected ? dayDotColor : Colors.grey.shade300;

          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => onChangeDate(d),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    labels[index],
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: (isSelected || isToday)
                          ? Border.all(
                              color: isSelected
                                  ? const Color(0xFFFF7A5C)
                                  : Colors.grey.shade400,
                              width: 2,
                            )
                          : null,
                    ),
                    child: Text(
                      '${d.day}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.black : Colors.grey.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NotarioFab extends StatelessWidget {
  final VoidCallback onPressed;

  const _NotarioFab({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      height: 76,
      child: FloatingActionButton(
        onPressed: onPressed,
        elevation: 10,
        backgroundColor: Colors.transparent,
        shape: const CircleBorder(),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFF7A5C),
                Color(0xFFFFB86B),
              ],
            ),
          ),
          child: Center(
            child: Text(
              'Notário',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardStats {
  final int totalTasks;
  final int completedTasks;
  final int percentCompleted;
  final String statusLabel;
  final Color statusColor;
  final String freeTimeLabel;
  final Color dayDotColor;

  const _DashboardStats({
    required this.totalTasks,
    required this.completedTasks,
    required this.percentCompleted,
    required this.statusLabel,
    required this.statusColor,
    required this.freeTimeLabel,
    required this.dayDotColor,
  });

  factory _DashboardStats.fromTasks(List<Task> tasks) {
    final total = tasks.length;
    final completed = tasks.where((t) => t.isConcluida).length;
    final percent = total == 0 ? 0 : ((completed / total) * 100).round();

    // “capacidade” (MVP): 16h úteis como já usado no validateDay
    const totalUsefulMinutes = 960;
    final occupiedMinutes = tasks
        .where((t) => t.estado == EstadoTarefa.pendente || t.estado == EstadoTarefa.emExecucao)
        .fold<int>(0, (sum, t) => sum + t.duracaoMinutos);
    final free = (totalUsefulMinutes - occupiedMinutes).clamp(0, totalUsefulMinutes);

    final isCheio = free <= 0 || (occupiedMinutes / totalUsefulMinutes) >= 0.9;
    final isApertado = (occupiedMinutes / totalUsefulMinutes) >= 0.7;

    final statusLabel = isCheio
        ? 'Cheio'
        : isApertado
            ? 'Apertado'
            : 'Indo bem';

    final statusColor = isCheio
        ? const Color(0xFFE53935)
        : isApertado
            ? const Color(0xFFFF9800)
            : const Color(0xFF3CC36B);

    final freeLabel = '${free.clamp(0, 999)} min livre';
    final dotColor = isCheio ? const Color(0xFFE53935) : const Color(0xFF2B5BC7);

    return _DashboardStats(
      totalTasks: total,
      completedTasks: completed,
      percentCompleted: percent.clamp(0, 100),
      statusLabel: statusLabel,
      statusColor: statusColor,
      freeTimeLabel: freeLabel,
      dayDotColor: dotColor,
    );
  }
}

class _DateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  const _DateSelector({
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Mantido apenas por compatibilidade com referências antigas.
    // O novo design usa o mini-calendário no header.
    return const SizedBox.shrink();
  }
}

class _DaySummary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Mantido apenas por compatibilidade com referências antigas.
    // O novo design mostra “status + tempo livre” no header.
    return const SizedBox.shrink();
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryItem(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(color: color, fontWeight: FontWeight.bold)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.check_circle_outline, size: 80, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text('Nenhuma tarefa para hoje!',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: Colors.grey[600])),
        const SizedBox(height: 8),
        Text('Aproveite o seu dia ou adicione uma nova tarefa.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey[500]))
      ],
    );
  }
}
