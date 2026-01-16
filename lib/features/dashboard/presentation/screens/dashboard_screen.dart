import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../tasks/domain/entities/task.dart';
import '../../../tasks/presentation/bloc/task_bloc.dart';
import '../../../tasks/presentation/screens/task_form_screen.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel Diário'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () {
              // Dispara o evento de logout para o AuthBloc
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadTasksForSelectedDate(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _DateSelector(
                selectedDate: _selectedDate,
                onDateChanged: (date) {
                  setState(() => _selectedDate = date);
                  _loadTasksForSelectedDate();
                },
              ),
            ),
            SliverToBoxAdapter(child: _DaySummary()),
            BlocBuilder<TaskBloc, TaskState>(
              builder: (context, state) {
                if (state is TaskLoading) {
                  return const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()));
                }
                if (state is TaskDayLoaded) {
                  if (state.tasks.isEmpty) {
                    return SliverFillRemaining(child: _EmptyState());
                  }
                  return SliverPadding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                if (state is TaskError) {
                  return SliverFillRemaining(
                      child: Center(child: Text('Erro: ${state.message}')));
                }
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navega para a criação de tarefa, passando a data selecionada
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  TaskFormScreen(task: null), // Passando nulo para criar
            ),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Nova Tarefa',
      ),
    );
  }
}

// ... (outros widgets permanecem os mesmos)

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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => onDateChanged(
                  selectedDate.subtract(const Duration(days: 1)))),
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030));
              if (date != null) onDateChanged(date);
            },
            child: Column(
              children: [
                Text(
                    isToday
                        ? 'Hoje'
                        : DateFormat('EEEE', 'pt_PT').format(selectedDate),
                    style: Theme.of(context).textTheme.titleLarge),
                Text(DateFormat('d MMMM yyyy', 'pt_PT').format(selectedDate),
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () =>
                  onDateChanged(selectedDate.add(const Duration(days: 1)))),
        ],
      ),
    );
  }
}

class _DaySummary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskBloc, TaskState>(
      builder: (context, state) {
        if (state is! TaskDayLoaded) return const SizedBox.shrink();

        final tasks = state.tasks;
        final concluidas = tasks.where((t) => t.isConcluida).length;
        final pendentes =
            tasks.where((t) => t.isPendente && !t.isAtrasada).length;
        final atrasadas = tasks.where((t) => t.isAtrasada).length;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _SummaryItem(
                  label: 'Pendentes',
                  value: pendentes.toString(),
                  color: Colors.orange.shade700),
              _SummaryItem(
                  label: 'Atrasadas',
                  value: atrasadas.toString(),
                  color: Colors.red.shade700),
              _SummaryItem(
                  label: 'Concluídas',
                  value: concluidas.toString(),
                  color: Colors.green.shade700),
            ],
          ),
        );
      },
    );
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

class _TaskCard extends StatelessWidget {
  final Task task;
  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: _PriorityIndicator(prioridade: task.prioridade),
        title: Text(task.titulo,
            style: TextStyle(
                decoration:
                    task.isConcluida ? TextDecoration.lineThrough : null)),
        subtitle: Text(
            '${DateFormat('HH:mm').format(task.dataInicio)} - ${task.duracaoMinutos} min'),
        trailing: _EstadoChip(estado: task.estado),
        onTap: () {
          // Permite a edição da tarefa
          Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => TaskFormScreen(task: task)));
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
    final color = {
      Prioridade.alta: Colors.red.shade400,
      Prioridade.media: Colors.orange.shade400,
      Prioridade.baixa: Colors.blue.shade400,
    }[prioridade];
    return Container(
        width: 5,
        height: 50,
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(2)));
  }
}

class _EstadoChip extends StatelessWidget {
  final EstadoTarefa estado;
  const _EstadoChip({required this.estado});

  @override
  Widget build(BuildContext context) {
    final icon = {
      EstadoTarefa.pendente: Icons.hourglass_empty_rounded,
      EstadoTarefa.emExecucao: Icons.play_circle_fill_rounded,
      EstadoTarefa.concluida: Icons.check_circle,
      EstadoTarefa.pulada: Icons.skip_next_rounded,
      EstadoTarefa.cancelada: Icons.cancel_rounded,
    }[estado];

    final color = {
      EstadoTarefa.pendente: Colors.orange.shade700,
      EstadoTarefa.emExecucao: Colors.blue.shade700,
      EstadoTarefa.concluida: Colors.green.shade700,
      EstadoTarefa.pulada: Colors.grey.shade600,
      EstadoTarefa.cancelada: Colors.red.shade700,
    }[estado];

    return Icon(icon, color: color, size: 28);
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
