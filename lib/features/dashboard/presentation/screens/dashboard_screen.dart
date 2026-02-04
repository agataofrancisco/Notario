import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../tasks/domain/entities/task.dart';
import '../../../tasks/presentation/bloc/task_bloc.dart';
import '../../../tasks/presentation/screens/task_form_screen.dart';
import '../../../tasks/presentation/widgets/task_list_item.dart';
import '../bloc/stats_bloc.dart';
import '../../../notes/presentation/screens/note_list_screen.dart';
import '../../../notes/presentation/screens/note_form_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadTasksForSelectedDate();
    _loadWeeklyStats();
  }

  void _loadTasksForSelectedDate() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context
          .read<TaskBloc>()
          .add(TaskDayLoadRequested(authState.user.uid, _selectedDate));
    }
  }

  void _loadWeeklyStats() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final weekStart = _getWeekStart(DateTime.now());
      context.read<StatsBloc>().add(
            StatsLoadRequested(authState.user.uid, weekStart: weekStart),
          );
    }
  }

  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: weekday - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _currentIndex == 1
          ? AppBar(
              title: const Text('Minhas Notas'),
              elevation: 0,
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            )
          : null,
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_currentIndex == 0) {
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const TaskFormScreen(task: null)),
            );
          } else {
            Navigator.of(context)
                .push(
              MaterialPageRoute(
                  builder: (_) => const NoteFormScreen(note: null)),
            )
                .then((_) {
              // Recarregar notas se necessário, mas o NoteListView já tem listener
            });
          }
        },
        elevation: 6,
        backgroundColor: const Color(0xFF667EEA), // Primary purple
        child: Icon(_currentIndex == 0 ? Icons.add_task : Icons.note_add,
            size: 28, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF667EEA),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Tarefas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sticky_note_2_outlined),
            activeIcon: Icon(Icons.sticky_note_2),
            label: 'Notas',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_currentIndex == 1) {
      return const NoteListView();
    }

    return BlocListener<TaskBloc, TaskState>(
      listener: (context, state) {
        if (state is TaskOperationSuccess) {
          _loadTasksForSelectedDate();
        }
      },
      child: RefreshIndicator(
        onRefresh: () async => _loadTasksForSelectedDate(),
        child: BlocBuilder<TaskBloc, TaskState>(
          builder: (context, state) {
            final allTasks =
                state is TaskDayLoaded ? state.tasks : const <Task>[];
            final pendingTasks = allTasks
                .where((t) =>
                    t.estado == EstadoTarefa.pendente ||
                    t.estado == EstadoTarefa.emExecucao)
                .toList();
            final stats = _DashboardStats.fromTasks(allTasks);
            final authState = context.read<AuthBloc>().state;
            final userId =
                authState is AuthAuthenticated ? authState.user.uid : null;

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _DashboardHero(
                    selectedDate: _selectedDate,
                    stats: stats,
                    userId: userId,
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
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
                else if (pendingTasks.isEmpty)
                  SliverFillRemaining(child: _EmptyState())
                else
                  SliverPadding(
                    padding: const EdgeInsets.only(bottom: 120),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => TaskListItem(
                          task: pendingTasks[index],
                          onDelete: () {
                            context.read<TaskBloc>().add(
                                TaskDeleteRequested(pendingTasks[index].id));
                          },
                        ),
                        childCount: pendingTasks.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DashboardHero extends StatelessWidget {
  final DateTime selectedDate;
  final _DashboardStats stats;
  final String? userId;
  final VoidCallback onLogoutPressed;
  final ValueChanged<DateTime> onChangeDate;

  const _DashboardHero({
    required this.selectedDate,
    required this.stats,
    required this.userId,
    required this.onLogoutPressed,
    required this.onChangeDate,
  });

  void _showWeeklyStats(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final mondayStart =
        DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

    context.read<TaskBloc>().add(
          TaskWeeklyStatsRequested(
            userId: authState.user.uid,
            weekStart: mondayStart,
          ),
        );

    showDialog(
      context: context,
      builder: (context) => BlocListener<TaskBloc, TaskState>(
        listener: (context, state) {
          if (state is TaskWeeklyStatsResult) {
            Navigator.of(context).pop();
            _showWeeklyStatsDialog(context, state.stats);
          }
        },
        child: const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Carregando estatísticas...'),
            ],
          ),
        ),
      ),
    );
  }

  void _showWeeklyStatsDialog(
      BuildContext context, Map<String, dynamic> stats) {
    final tarefasDefinidas = stats['tarefasDefinidas'] as int;
    final tarefasConcluidas = stats['tarefasConcluidas'] as int;
    final tarefasPendentes = stats['tarefasPendentes'] as int;
    final tarefasPuladas = stats['tarefasPuladas'] as int;
    final percentualConclusao = stats['percentualConclusao'] as int;
    final tempoPlaneado = stats['tempoPlaneadoMinutos'] as int;
    final tempoRealizado = stats['tempoRealizadoMinutos'] as int;
    final eficienciaTempo = stats['eficienciaTempo'] as int;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.analytics, color: Colors.blue),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Estatísticas da Semana',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatCard('Tarefas Definidas', tarefasDefinidas.toString(),
                  Icons.assignment, Colors.blue),
              const SizedBox(height: 8),
              _buildStatCard(
                  'Tarefas Concluídas',
                  '$tarefasConcluidas ($percentualConclusao%)',
                  Icons.check_circle,
                  Colors.green),
              const SizedBox(height: 8),
              _buildStatCard('Tarefas Pendentes', tarefasPendentes.toString(),
                  Icons.pending, Colors.orange),
              const SizedBox(height: 8),
              _buildStatCard('Tarefas Puladas', tarefasPuladas.toString(),
                  Icons.skip_next, Colors.red),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              _buildStatCard('Tempo Planeado', _formatTempo(tempoPlaneado),
                  Icons.schedule, Colors.purple),
              const SizedBox(height: 8),
              _buildStatCard('Tempo Realizado', _formatTempo(tempoRealizado),
                  Icons.timer, Colors.indigo),
              const SizedBox(height: 8),
              _buildStatCard(
                'Eficiência de Tempo',
                '$eficienciaTempo%',
                Icons.trending_up,
                eficienciaTempo >= 80
                    ? Colors.green
                    : eficienciaTempo >= 60
                        ? Colors.orange
                        : Colors.red,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                Text(value,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTempo(int minutos) {
    if (minutos < 60) return '${minutos}min';
    final horas = minutos ~/ 60;
    final mins = minutos % 60;
    return mins == 0 ? '${horas}h' : '${horas}h ${mins}min';
  }

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
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)], // Purple gradient
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
                            selectedDate: selectedDate, locale: locale)),
                    IconButton(
                      onPressed: () => _showWeeklyStats(context),
                      icon: const Icon(Icons.analytics_outlined),
                      color: Colors.white,
                      tooltip: 'Estatísticas Semanais',
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
                        label: '${stats.percentCompleted}%\nConcluído'),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Status',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _StatusPill(
                              text: stats.statusLabel,
                              backgroundColor: stats.statusColor),
                          const SizedBox(height: 10),
                          _StatusPill(
                              text: stats.freeTimeLabel,
                              backgroundColor: const Color(0xFF2B5BC7)),
                          const SizedBox(height: 14),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _LegendDot(
                                  color: Color(0xFF2B5BC7),
                                  label: 'espaço\ndisponível'),
                              SizedBox(width: 14),
                              _LegendDot(
                                  color: Color(0xFFE53935), label: 'cheio'),
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
                  userId: userId,
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

class _HeaderClock extends StatefulWidget {
  final DateTime selectedDate;
  final String locale;

  const _HeaderClock({required this.selectedDate, required this.locale});

  @override
  State<_HeaderClock> createState() => _HeaderClockState();
}

class _HeaderClockState extends State<_HeaderClock> {
  late DateTime _currentTime;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    // Atualizar a cada minuto
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      if (now.minute != _currentTime.minute) {
        setState(() => _currentTime = now);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm', widget.locale).format(_currentTime);
    final dateStr = DateFormat("EEE, d 'de' MMMM", widget.locale)
        .format(widget.selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(dateStr,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(
          timeStr,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 44,
              height: 1.0,
              fontWeight: FontWeight.w800),
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
              valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white.withValues(alpha: 0.25)),
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
                color: Colors.white, fontWeight: FontWeight.w700),
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
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        text,
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
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
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 12,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}

class _MiniCalendarCard extends StatefulWidget {
  final DateTime selectedDate;
  final String? userId;
  final Color dayDotColor;
  final ValueChanged<DateTime> onChangeDate;

  const _MiniCalendarCard({
    required this.selectedDate,
    required this.userId,
    required this.dayDotColor,
    required this.onChangeDate,
  });

  @override
  State<_MiniCalendarCard> createState() => _MiniCalendarCardState();
}

class _MiniCalendarCardState extends State<_MiniCalendarCard> {
  DateTime _weekStart = DateTime.now();
  Map<String, Color> _dayColors = {};

  @override
  void initState() {
    super.initState();
    _weekStart = _getWeekStart(widget.selectedDate);
    _loadWeekOccupancy();
  }

  @override
  void didUpdateWidget(_MiniCalendarCard oldWidget) {
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
          .where('dataInicio',
              isGreaterThanOrEqualTo: Timestamp.fromDate(_weekStart))
          .where('dataInicio', isLessThan: Timestamp.fromDate(weekEnd))
          .where('estado',
              whereIn: ['pendente', 'emExecucao', 'concluida']).get();

      final tasksByDay = <String, int>{};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final dataInicio = (data['dataInicio'] as Timestamp).toDate();
        final dayKey =
            '${dataInicio.year}-${dataInicio.month}-${dataInicio.day}';
        final duracao = data['duracaoMinutos'] as int? ?? 0;
        tasksByDay[dayKey] = (tasksByDay[dayKey] ?? 0) + duracao;
      }

      for (int i = 0; i < 7; i++) {
        final day = _weekStart.add(Duration(days: i));
        final dayKey = '${day.year}-${day.month}-${day.day}';
        final occupied = tasksByDay[dayKey] ?? 0;
        final ratio = occupied / 960; // 960 min = 16h úteis

        if (ratio >= 0.9) {
          colors[dayKey] = const Color(0xFFE53935); // Vermelho - cheio
        } else if (ratio >= 0.7) {
          colors[dayKey] = const Color(0xFFFF9800); // Laranja - apertado
        } else if (ratio > 0) {
          colors[dayKey] = const Color(0xFF667EEA); // Roxo - normal
        } else {
          colors[dayKey] = Colors.grey.shade300; // Cinza - vazio
        }
      }

      if (mounted) {
        setState(() => _dayColors = colors);
      }
    } catch (e) {
      // Silently fail
    }
  }

  void _navigateWeek(int direction) {
    setState(() {
      _weekStart = _weekStart.add(Duration(days: 7 * direction));
      final newSelected =
          widget.selectedDate.add(Duration(days: 7 * direction));
      widget.onChangeDate(newSelected);
    });
    _loadWeekOccupancy();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = List.generate(7, (i) => _weekStart.add(Duration(days: i)));
    const labels = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Navigation controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _navigateWeek(-1),
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Semana anterior',
              ),
              Text(
                DateFormat('MMM yyyy', 'pt_PT').format(_weekStart),
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _navigateWeek(1),
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Próxima semana',
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Days row
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
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
                                      ? const Color(
                                          0xFF667EEA) // Primary purple
                                      : Colors.grey.shade400,
                                  width: 2,
                                )
                              : null,
                        ),
                        child: Text(
                          '${d.day}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.black
                                : Colors.grey.shade700,
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
        ],
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
    // Filtrar tarefas canceladas do total
    final validTasks = tasks.where((t) => !t.isCancelada).toList();
    final total = validTasks.length;
    final completed = validTasks.where((t) => t.isConcluida).length;
    final percent = total == 0 ? 0 : ((completed / total) * 100).round();

    const totalUsefulMinutes = 960;
    // O tempo ocupado deve considerar tarefas pendentes, em execução e concluídas?
    // "Ocupado" geralmente refere-se ao tempo indisponível. Tarefas concluídas ocuparam tempo.
    // Mas se o objetivo é mostrar quanto tempo resta, devemos subtrair o que já foi gasto?
    // Se "Livre" é para novas tarefas, então o tempo gasto em concluídas NÃO é livre.
    // Portanto, devemos somar todas as tarefas ativas do dia.
    // MAS, a implementação original somava apenas pendente e emExecucao.
    // Se mudarmos para incluir concluídas, o gráfico de "barrinha" de status pode mudar o comportamento.
    // Vamos manter a lógica original de "ocupado" = "planejado para fazer ainda" OU assumir que o usuário
    // quer saber se o dia *como um todo* está cheio (incluindo o que já fez).
    // Geralmente "Cheio" refere-se à capacidade total do dia.
    // Vamos incluir concluídas no cálculo de ocupação para refletir a carga real do dia.
    final occupiedMinutes = tasks
        .where((t) =>
            !t.isCancelada && // Ignorar canceladas
            (t.estado == EstadoTarefa.pendente ||
                t.estado == EstadoTarefa.emExecucao ||
                t.estado == EstadoTarefa.concluida))
        .fold<int>(0, (sum, t) => sum + t.duracaoMinutos);

    final free =
        (totalUsefulMinutes - occupiedMinutes).clamp(0, totalUsefulMinutes);

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
    final dotColor =
        isCheio ? const Color(0xFFE53935) : const Color(0xFF2B5BC7);

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

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.check_circle_outline, size: 80, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text(
          'Nenhuma tarefa para hoje!',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        Text(
          'Aproveite o seu dia ou adicione uma nova tarefa.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Colors.grey[500]),
        )
      ],
    );
  }
}
