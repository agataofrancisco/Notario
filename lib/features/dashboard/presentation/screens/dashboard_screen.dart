import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../tasks/domain/entities/task.dart';
import '../../../tasks/domain/services/task_deadline_service.dart';
import '../../../tasks/presentation/bloc/task_bloc.dart';
import '../../../tasks/presentation/screens/task_form_screen.dart';
import '../../../tasks/presentation/screens/execution_screen.dart';
import '../../../tasks/presentation/widgets/task_list_item.dart';
import '../../../tasks/presentation/widgets/day_summary_dialog.dart';
import '../bloc/stats_bloc.dart';
import '../../../notes/presentation/screens/note_list_screen.dart';
import '../../../notes/presentation/screens/note_form_screen.dart';
import '../widgets/dashboard_hero.dart';
import '../widgets/empty_state.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/services/google_calendar_service.dart';
import '../../../../core/config/app_timezone.dart';
import '../../../../core/config/app_config.dart';
import '../../../../shared/widgets/app_components.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  DateTime _selectedDate = AppTimeZone.now();
  String? _googleAgendaError;
  bool _isLoadingGoogleEvents = false;
  bool _calendarConnected = false;
  final Set<String> _dismissedGuidance = {};

  @override
  void initState() {
    super.initState();
    _loadTasksForSelectedDate();
    _loadWeeklyStats();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkCalendarStatus());
  }

  Future<void> _checkCalendarStatus() async {
    final calendarService = context.read<GoogleCalendarService>();
    final connected = await calendarService.isConnected;
    if (mounted) setState(() => _calendarConnected = connected);
  }

  void _loadTasksForSelectedDate() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context
          .read<TaskBloc>()
          .add(TaskDayLoadRequested(authState.user.uid, _selectedDate));
    }
  }

  Future<void> _loadGoogleEvents() async {
    if (_isLoadingGoogleEvents) return;
    final calendarService = context.read<GoogleCalendarService>();
    final syncService = context.read<SyncService>();
    final authState = context.read<AuthBloc>().state;
    if (!await calendarService.isConnected) {
      if (mounted) setState(() => _calendarConnected = false);
      return;
    }
    setState(() {
      _isLoadingGoogleEvents = true;
      _googleAgendaError = null;
    });
    try {
      if (authState is AuthAuthenticated) {
        await syncService.importGoogleDay(authState.user.uid, _selectedDate);
        if (!mounted) return;
        await syncService.syncUser(authState.user.uid);
      }
      if (!mounted) return;
      _loadTasksForSelectedDate();
    } catch (e) {
      if (mounted) {
        setState(() {
          _googleAgendaError = e.toString();
          if (e is GoogleCalendarException &&
              (e.failure == GoogleCalendarFailure.permissionDenied ||
                  e.failure == GoogleCalendarFailure.reauthorizationRequired)) {
            _calendarConnected = false;
          }
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingGoogleEvents = false);
    }
  }

  Future<void> _connectCalendar() async {
    if (_isLoadingGoogleEvents) return;
    final calendarService = context.read<GoogleCalendarService>();
    final syncService = context.read<SyncService>();
    final authState = context.read<AuthBloc>().state;
    setState(() {
      _isLoadingGoogleEvents = true;
      _googleAgendaError = null;
    });
    try {
      final connected = await calendarService.connect();
      if (!mounted) return;
      setState(() => _calendarConnected = connected);
      if (connected && authState is AuthAuthenticated) {
        await syncService.refreshGoogleCache(authState.user.uid);
        if (!mounted) return;
        await syncService.importGoogleDay(authState.user.uid, _selectedDate);
        if (!mounted) return;
        await syncService.syncUser(authState.user.uid);
        _loadTasksForSelectedDate();
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _googleAgendaError = error.toString();
          _calendarConnected = false;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingGoogleEvents = false);
    }
  }

  Future<void> _disconnectCalendar() async {
    final calendarService = context.read<GoogleCalendarService>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Desligar Google Calendar?'),
        content: const Text(
            'A sincronização vai parar, mas as atividades já guardadas no dispositivo permanecem disponíveis.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Manter ligado')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Desligar')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await calendarService.disconnect();
    if (mounted) setState(() => _calendarConnected = false);
  }

  void _loadWeeklyStats() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final weekStart = _getWeekStart(AppTimeZone.now());
      context
          .read<StatsBloc>()
          .add(StatsLoadRequested(authState.user.uid, weekStart: weekStart));
    }
  }

  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return AppTimeZone.dayStart(date).subtract(Duration(days: weekday - 1));
  }

  void _showDaySummary(List<Task> allTasks) {
    if (allTasks.isEmpty) return;
    final completed = allTasks.where((t) => t.isConcluida).toList();
    final skipped = allTasks.where((t) => t.isPulada).toList();
    final pending = allTasks.where((t) => t.isPendente).toList();
    showDialog(
      context: context,
      builder: (_) => DaySummaryDialog(
          completedTasks: completed,
          skippedTasks: skipped,
          pendingTasks: pending),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _currentIndex == 1
          ? AppBar(
              title: const Text('Minhas Notas'),
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              foregroundColor: Theme.of(context).colorScheme.onSurface)
          : null,
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_currentIndex == 0) {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const TaskFormScreen(task: null)));
          } else {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const NoteFormScreen(note: null)));
          }
        },
        elevation: 1,
        tooltip: _currentIndex == 0 ? 'Criar tarefa' : 'Criar nota',
        child: Icon(_currentIndex == 0 ? Icons.add_task : Icons.note_add),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.checklist_outlined),
              selectedIcon: Icon(Icons.checklist),
              label: 'Tarefas'),
          NavigationDestination(
              icon: Icon(Icons.sticky_note_2_outlined),
              selectedIcon: Icon(Icons.sticky_note_2),
              label: 'Notas'),
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
            final allTasks =
                state is TaskDayLoaded ? state.tasks : const <Task>[];
            final visibleTasks = allTasks.where((t) => !t.isCancelada).toList();
            final completedTasks =
                allTasks.where((t) => t.isConcluida || t.isPulada).toList();
            final stats = _DashboardStats.fromTasks(
              allTasks,
            );
            final authState = context.read<AuthBloc>().state;
            final userId =
                authState is AuthAuthenticated ? authState.user.uid : null;
            final activityRows = <_AgendaRow>[];
            for (final task in visibleTasks) {
              activityRows.add(_AgendaRow(
                time: task.dataInicio,
                isCompleted: task.isConcluida,
                child: TaskListItem(
                  task: task,
                  onTaskChanged: _loadTasksForSelectedDate,
                  onDelete: () => context
                      .read<TaskBloc>()
                      .add(TaskDeleteRequested(task.id)),
                ),
              ));
            }
            activityRows.sort((a, b) {
              final completionOrder =
                  (a.isCompleted ? 1 : 0).compareTo(b.isCompleted ? 1 : 0);
              return completionOrder != 0
                  ? completionOrder
                  : a.time.compareTo(b.time);
            });

            return SafeArea(
              top: true,
              bottom: false,
              child: AppContentFrame(
                maxWidth: 840,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: DashboardHero(
                        selectedDate: _selectedDate,
                        percentCompleted: stats.percentCompleted,
                        completedTasks: stats.completedTasks,
                        totalTasks: stats.totalTasks,
                        statusLabel: stats.statusLabel,
                        statusColor: stats.statusColor,
                        freeTimeLabel: stats.freeTimeLabel,
                        userId: userId,
                        onChangeDate: (date) {
                          setState(() => _selectedDate = date);
                          _loadTasksForSelectedDate();
                          _loadGoogleEvents();
                        },
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              _calendarConnected
                                  ? Icons.cloud_done_outlined
                                  : Icons.cloud_off_outlined,
                              size: 18,
                              color: _calendarConnected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Semantics(
                                liveRegion: true,
                                label: _calendarConnected
                                    ? 'Google Calendar ligado'
                                    : 'Google Calendar desligado',
                                child: Text(_calendarConnected
                                    ? 'Google Calendar ligado'
                                    : 'Google Calendar desligado'),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _isLoadingGoogleEvents
                                  ? null
                                  : _calendarConnected
                                      ? _disconnectCalendar
                                      : _connectCalendar,
                              icon: _isLoadingGoogleEvents
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : Icon(_calendarConnected
                                      ? Icons.link_off
                                      : Icons.link),
                              label: Text(
                                  _calendarConnected ? 'Desligar' : 'Ligar'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (state is TaskDayLoaded && state.guidance.planComplete)
                      SliverToBoxAdapter(
                        child: _buildGuidanceCard(context, state.guidance),
                      ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                      sliver: SliverToBoxAdapter(
                        child: AppSectionHeader(
                          title: 'Próximas atividades',
                          action: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 4,
                            runSpacing: 4,
                            children: [
                              IconButton(
                                tooltip: _calendarConnected
                                    ? 'Atualizar Google Calendar e Tasks'
                                    : 'Ligar Google Calendar',
                                onPressed: _isLoadingGoogleEvents
                                    ? null
                                    : _calendarConnected
                                        ? _loadGoogleEvents
                                        : _connectCalendar,
                                icon: _isLoadingGoogleEvents
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          semanticsLabel:
                                              'A atualizar Google Calendar e Tasks',
                                        ),
                                      )
                                    : const Icon(Icons.sync, size: 20),
                              ),
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
                    ),
                    if (_googleAgendaError != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Google Calendar/Tasks: $_googleAgendaError',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    if (state is TaskInitial || state is TaskLoading)
                      const SliverFillRemaining(
                        child: Center(
                          child: CircularProgressIndicator(
                            semanticsLabel: 'A carregar atividades do dia',
                          ),
                        ),
                      )
                    else if (state is TaskError)
                      SliverFillRemaining(
                        child: AppFeedbackState(
                          icon: Icons.cloud_off_outlined,
                          title: 'Não foi possível carregar o dia',
                          message: state.message,
                          actionLabel: 'Tentar novamente',
                          isError: true,
                          onAction: _loadTasksForSelectedDate,
                        ),
                      )
                    else if (activityRows.isEmpty)
                      const SliverFillRemaining(child: EmptyState())
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 180),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => activityRows[index].child,
                            childCount: activityRows.length,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGuidanceCard(BuildContext context, DailyGuidance guidance) {
    final keyPrefix =
        '${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}:';
    final suggestions = guidance.suggestions
        .where(
            (item) => !_dismissedGuidance.contains('$keyPrefix${item.task.id}'))
        .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb_outline,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Plano do dia concluído',
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                  '${guidance.freeMinutes} min livres. Se quiseres, podes avançar numa tarefa com prazo.'),
              if (suggestions.isEmpty) ...[
                const SizedBox(height: 8),
                Text(guidance.suggestions.isEmpty
                    ? 'Não há tarefas com prazo que caibam no tempo livre de hoje.'
                    : 'Sugestões dispensadas por hoje.'),
              ] else ...[
                const SizedBox(height: 12),
                for (final item in suggestions) ...[
                  _GuidanceSuggestionTile(
                    suggestion: item,
                    onStart: () => _startSuggestedTask(context, item),
                    onSchedule: () => _scheduleSuggestedTask(context, item),
                    onDismiss: () => setState(() =>
                        _dismissedGuidance.add('$keyPrefix${item.task.id}')),
                  ),
                  if (item != suggestions.last) const Divider(height: 20),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startSuggestedTask(
      BuildContext context, DeadlineSuggestion suggestion) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Iniciar esta tarefa?'),
        content: Text('Queres começar “${suggestion.task.titulo}” agora?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Agora não')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Iniciar')),
        ],
      ),
    );
    if (accepted != true || !context.mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ExecutionScreen(task: suggestion.task),
    ));
    if (mounted) _loadTasksForSelectedDate();
  }

  Future<void> _scheduleSuggestedTask(
      BuildContext context, DeadlineSuggestion suggestion) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reagendar tarefa?'),
        content: const Text(
            'O formulário abrirá com esta tarefa preparada para hoje. Confirma a nova data e hora antes de guardar.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Continuar')),
        ],
      ),
    );
    if (accepted != true || !context.mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => TaskFormScreen(
        task: suggestion.task,
        initialStart: AppTimeZone.now().add(const Duration(minutes: 15)),
      ),
    ));
    if (mounted) _loadTasksForSelectedDate();
  }
}

class _GuidanceSuggestionTile extends StatelessWidget {
  final DeadlineSuggestion suggestion;
  final VoidCallback onStart;
  final VoidCallback onSchedule;
  final VoidCallback onDismiss;

  const _GuidanceSuggestionTile({
    required this.suggestion,
    required this.onStart,
    required this.onSchedule,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final task = suggestion.task;
    final deadline = TaskDeadlineService.contextFor(task, AppTimeZone.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(task.titulo, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
            '${task.prioridade.displayName} · ${task.duracaoMinutos} min · ${deadline?.label ?? 'Sem prazo'}'),
        const SizedBox(height: 4),
        Text(suggestion.reason, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            FilledButton.tonalIcon(
                onPressed: onStart,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Iniciar')),
            OutlinedButton.icon(
                onPressed: onSchedule,
                icon: const Icon(Icons.event),
                label: const Text('Agendar')),
            TextButton(onPressed: onDismiss, child: const Text('Dispensar')),
          ],
        ),
      ],
    );
  }
}

class _AgendaRow {
  final DateTime time;
  final bool isCompleted;
  final Widget child;

  const _AgendaRow(
      {required this.time, required this.isCompleted, required this.child});
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

    const totalUsefulMinutes = AppConfig.workMinutesPerDay;
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
    final localOccupiedMinutes = tasks
        .where((t) =>
            !t.isCancelada && // Ignorar canceladas
            (t.estado == EstadoTarefa.pendente ||
                t.estado == EstadoTarefa.emExecucao ||
                t.estado == EstadoTarefa.concluida))
        .fold<int>(
            0,
            (sum, t) =>
                sum +
                (t.isConcluida
                    ? (t.tempoRealMinutos ?? t.duracaoMinutos)
                    : t.duracaoMinutos));
    final occupiedMinutes = localOccupiedMinutes;

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
