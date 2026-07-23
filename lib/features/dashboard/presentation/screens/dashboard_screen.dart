import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../tasks/domain/entities/task.dart';
import '../../../tasks/presentation/bloc/task_bloc.dart';
import '../../../tasks/presentation/screens/task_form_screen.dart';
import '../../../tasks/presentation/widgets/task_list_item.dart';
import '../../../tasks/presentation/widgets/day_summary_dialog.dart';
import '../bloc/stats_bloc.dart';
import '../../../notes/presentation/screens/note_list_screen.dart';
import '../../../notes/presentation/screens/note_form_screen.dart';
import '../widgets/dashboard_hero.dart';
import '../widgets/empty_state.dart';

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
      context.read<TaskBloc>().add(TaskDayLoadRequested(authState.user.uid, _selectedDate));
    }
  }

  void _loadWeeklyStats() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final weekStart = _getWeekStart(DateTime.now());
      context.read<StatsBloc>().add(StatsLoadRequested(authState.user.uid, weekStart: weekStart));
    }
  }

  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: weekday - 1));
  }

  void _showDaySummary(List<Task> allTasks) {
    if (allTasks.isEmpty) return;
    final completed = allTasks.where((t) => t.isConcluida).toList();
    final skipped = allTasks.where((t) => t.isPulada).toList();
    final pending = allTasks.where((t) => t.isPendente).toList();
    showDialog(
      context: context,
      builder: (_) => DaySummaryDialog(completedTasks: completed, skippedTasks: skipped, pendingTasks: pending),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _currentIndex == 1
          ? AppBar(title: const Text('Minhas Notas'), elevation: 0, backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white)
          : null,
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_currentIndex == 0) {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TaskFormScreen(task: null)));
          } else {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NoteFormScreen(note: null)));
          }
        },
        elevation: 6,
        backgroundColor: const Color(0xFF667EEA),
        child: Icon(_currentIndex == 0 ? Icons.add_task : Icons.note_add, size: 28, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF667EEA),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Tarefas'),
          BottomNavigationBarItem(icon: Icon(Icons.sticky_note_2_outlined), activeIcon: Icon(Icons.sticky_note_2), label: 'Notas'),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_currentIndex == 1) return const NoteListView();

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
            final allTasks = state is TaskDayLoaded ? state.tasks : const <Task>[];
            final pendingTasks = allTasks.where((t) => t.estado == EstadoTarefa.pendente || t.estado == EstadoTarefa.emExecucao).toList();
            final completedTasks = allTasks.where((t) => t.isConcluida || t.isPulada).toList();
            final stats = _DashboardStats.fromTasks(allTasks);
            final authState = context.read<AuthBloc>().state;
            final userId = authState is AuthAuthenticated ? authState.user.uid : null;

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: DashboardHero(
                    selectedDate: _selectedDate,
                    percentCompleted: stats.percentCompleted,
                    statusLabel: stats.statusLabel,
                    statusColor: stats.statusColor,
                    freeTimeLabel: stats.freeTimeLabel,
                    userId: userId,
                    onChangeDate: (date) {
                      setState(() => _selectedDate = date);
                      _loadTasksForSelectedDate();
                    },
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Próximas Actividades', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                        if (completedTasks.isNotEmpty)
                          TextButton.icon(
                            onPressed: () => _showDaySummary(allTasks),
                            icon: const Icon(Icons.summarize, size: 18),
                            label: const Text('Resumo do Dia'),
                          ),
                      ],
                    ),
                  ),
                ),
                if (state is TaskLoading)
                  const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
                else if (state is TaskError)
                  SliverFillRemaining(child: Center(child: Text('Erro: ${state.message}')))
                else if (pendingTasks.isEmpty)
                  const SliverFillRemaining(child: EmptyState())
                else
                  SliverPadding(
                    padding: const EdgeInsets.only(bottom: 120),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => TaskListItem(
                          task: pendingTasks[index],
                          onDelete: () => context.read<TaskBloc>().add(TaskDeleteRequested(pendingTasks[index].id)),
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

