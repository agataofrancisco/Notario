import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../tasks/presentation/bloc/task_bloc.dart';
import '../../../tasks/domain/entities/task.dart';
import '../../../tasks/presentation/screens/task_form_screen.dart';
import '../../../../core/services/auth_service.dart';
import '../../../auth/presentation/screens/login_screen.dart';

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
    _loadTasks();
  }

  void _loadTasks() {
    final authService = context.read<AuthService>();
    final user = authService.currentUser;
    if (user != null) {
      context.read<TaskBloc>().add(TaskDayLoadRequested(
            user.id,
            _selectedDate,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NOTÁRIO'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthService>().signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadTasks(),
        child: CustomScrollView(
          slivers: [
            // Header com data
            SliverToBoxAdapter(
              child: _DateSelector(
                selectedDate: _selectedDate,
                onDateChanged: (date) {
                  setState(() => _selectedDate = date);
                  _loadTasks();
                },
              ),
            ),

            // Resumo do dia
            SliverToBoxAdapter(
              child: _DaySummary(date: _selectedDate),
            ),

            // Lista de tarefas
            BlocBuilder<TaskBloc, TaskState>(
              builder: (context, state) {
                if (state is TaskLoading) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (state is TaskDayLoaded) {
                  if (state.tasks.isEmpty) {
                    return SliverFillRemaining(
                      child: _EmptyState(date: _selectedDate),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final task = state.tasks[index];
                          return _TaskCard(task: task);
                        },
                        childCount: state.tasks.length,
                      ),
                    ),
                  );
                }

                return const SliverFillRemaining(
                  child: Center(child: Text('Erro ao carregar tarefas')),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TaskFormScreen(date: _selectedDate),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Nova Tarefa'),
      ),
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
    final isToday = DateUtils.isSameDay(selectedDate, DateTime.now());

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              onDateChanged(selectedDate.subtract(const Duration(days: 1)));
            },
          ),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (date != null) onDateChanged(date);
              },
              child: Column(
                children: [
                  Text(
                    isToday
                        ? 'Hoje'
                        : DateFormat('EEEE', 'pt_PT').format(selectedDate),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    DateFormat('d MMMM yyyy', 'pt_PT').format(selectedDate),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              onDateChanged(selectedDate.add(const Duration(days: 1)));
            },
          ),
        ],
      ),
    );
  }
}

class _DaySummary extends StatelessWidget {
  final DateTime date;

  const _DaySummary({required this.date});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskBloc, TaskState>(
      builder: (context, state) {
        if (state is! TaskDayLoaded) return const SizedBox.shrink();

        final tasks = state.tasks;
        final concluidas = tasks.where((t) => t.isConcluida).length;
        final pendentes = tasks.where((t) => t.isPendente).length;
        final emExecucao = tasks.where((t) => t.isEmExecucao).length;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _SummaryItem(
                icon: Icons.check_circle,
                label: 'Concluídas',
                value: concluidas.toString(),
                color: Colors.green,
              ),
              _SummaryItem(
                icon: Icons.pending,
                label: 'Pendentes',
                value: pendentes.toString(),
                color: Colors.orange,
              ),
              _SummaryItem(
                icon: Icons.play_circle,
                label: 'Em Execução',
                value: emExecucao.toString(),
                color: Colors.blue,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;

  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: _PriorityIndicator(prioridade: task.prioridade),
        title: Text(
          task.titulo,
          style: TextStyle(
            decoration: task.isConcluida ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DateFormat('HH:mm').format(task.dataInicio)),
            if (task.descricao != null && task.descricao!.isNotEmpty)
              Text(
                task.descricao!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: _EstadoChip(estado: task.estado),
        onTap: () {
          // TODO: Navegar para detalhes da tarefa
        },
      ),
    );
  }
}

class _PriorityIndicator extends StatelessWidget {
  final Prioridade prioridade;

  const _PriorityIndicator({required this.prioridade});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (prioridade) {
      case Prioridade.alta:
        color = Colors.red;
        break;
      case Prioridade.media:
        color = Colors.orange;
        break;
      case Prioridade.baixa:
        color = Colors.green;
        break;
    }

    return Container(
      width: 4,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _EstadoChip extends StatelessWidget {
  final EstadoTarefa estado;

  const _EstadoChip({required this.estado});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    switch (estado) {
      case EstadoTarefa.pendente:
        color = Colors.orange;
        icon = Icons.pending;
        break;
      case EstadoTarefa.emExecucao:
        color = Colors.blue;
        icon = Icons.play_circle;
        break;
      case EstadoTarefa.concluida:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case EstadoTarefa.pulada:
        color = Colors.grey;
        icon = Icons.skip_next;
        break;
      case EstadoTarefa.cancelada:
        color = Colors.red;
        icon = Icons.cancel;
        break;
    }

    return Icon(icon, color: color);
  }
}

class _EmptyState extends StatelessWidget {
  final DateTime date;

  const _EmptyState({required this.date});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma tarefa para este dia',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toque no botão + para adicionar',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
        ],
      ),
    );
  }
}
