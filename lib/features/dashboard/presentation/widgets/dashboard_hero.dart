import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../tasks/presentation/bloc/task_bloc.dart';
import 'mini_calendar_card.dart';
import '../../../../core/config/app_timezone.dart';

class DashboardHero extends StatelessWidget {
  final DateTime selectedDate;
  final int percentCompleted;
  final int completedTasks;
  final int totalTasks;
  final String statusLabel;
  final Color statusColor;
  final String freeTimeLabel;
  final String? userId;
  final ValueChanged<DateTime> onChangeDate;

  const DashboardHero({
    super.key,
    required this.selectedDate,
    required this.percentCompleted,
    required this.completedTasks,
    required this.totalTasks,
    required this.statusLabel,
    required this.statusColor,
    required this.freeTimeLabel,
    this.userId,
    required this.onChangeDate,
  });

  void _showWeeklyStats(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    final now = AppTimeZone.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final mondayStart =
        DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

    context.read<TaskBloc>().add(TaskWeeklyStatsRequested(
        userId: authState.user.uid, weekStart: mondayStart));

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
              Text('Carregando estatísticas...')
            ],
          ),
        ),
      ),
    );
  }

  void _showWeeklyStatsDialog(
      BuildContext context, Map<String, dynamic> stats) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.analytics, color: Colors.blue),
            SizedBox(width: 8),
            Expanded(
                child: Text('Estatísticas da Semana',
                    overflow: TextOverflow.ellipsis))
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatCard('Definidas', '${stats['tarefasDefinidas']}',
                  Icons.assignment, Colors.blue),
              const SizedBox(height: 8),
              _buildStatCard(
                  'Concluídas',
                  '${stats['tarefasConcluidas']} (${stats['percentualConclusao']}%)',
                  Icons.check_circle,
                  Colors.green),
              const SizedBox(height: 8),
              _buildStatCard('Pendentes', '${stats['tarefasPendentes']}',
                  Icons.pending, Colors.orange),
              const SizedBox(height: 8),
              _buildStatCard('Puladas', '${stats['tarefasPuladas']}',
                  Icons.skip_next, Colors.red),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              _buildStatCard(
                  'Tempo Planeado',
                  _formatDuration(stats['tempoPlaneadoMinutos'] as int),
                  Icons.schedule,
                  Colors.purple),
              const SizedBox(height: 8),
              _buildStatCard(
                  'Tempo Realizado',
                  _formatDuration(stats['tempoRealizadoMinutos'] as int),
                  Icons.timer,
                  Colors.indigo),
              const SizedBox(height: 8),
              _buildStatCard(
                  'Eficiência',
                  '${stats['eficienciaTempo']}%',
                  Icons.trending_up,
                  (stats['eficienciaTempo'] as int) >= 80
                      ? Colors.green
                      : (stats['eficienciaTempo'] as int) >= 60
                          ? Colors.orange
                          : Colors.red),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'))
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

  String _formatDuration(int minutos) {
    if (minutos < 60) return '${minutos}min';
    final h = minutos ~/ 60;
    final m = minutos % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}min';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedLabel =
        DateFormat("EEEE, d 'de' MMMM", 'pt_PT').format(selectedDate);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('O seu dia', style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 3),
                    Text(selectedLabel, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showWeeklyStats(context),
                icon: const Icon(Icons.insights_outlined),
                tooltip: 'Estatísticas semanais',
              ),
              IconButton(
                onPressed: () =>
                    context.read<AuthBloc>().add(AuthLogoutRequested()),
                icon: const Icon(Icons.logout_outlined),
                tooltip: 'Terminar sessão',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  _ProgressRing(
                    percent: percentCompleted,
                    label: '$percentCompleted%\nconcluído',
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ritmo de hoje',
                            style: theme.textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(
                          totalTasks == 0
                              ? 'Sem tarefas planeadas'
                              : '$completedTasks de $totalTasks concluídas',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        _StatusPill(
                            text: statusLabel, backgroundColor: statusColor),
                        const SizedBox(height: 8),
                        Text(freeTimeLabel, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          MiniCalendarCard(
            selectedDate: selectedDate,
            userId: userId,
            onChangeDate: onChangeDate,
          ),
        ],
      ),
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
    final primary = Theme.of(context).colorScheme.primary;
    final track = Theme.of(context).colorScheme.outlineVariant;
    return SizedBox(
      width: 84,
      height: 84,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
              width: 84,
              height: 84,
              child: CircularProgressIndicator(
                  value: 1,
                  strokeWidth: 8,
                  valueColor: AlwaysStoppedAnimation<Color>(track))),
          SizedBox(
              width: 84,
              height: 84,
              child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                  valueColor: AlwaysStoppedAnimation<Color>(primary),
                  backgroundColor: Colors.transparent)),
          Text(label,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
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
        color: backgroundColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text,
          style:
              TextStyle(color: backgroundColor, fontWeight: FontWeight.w600)),
    );
  }
}
