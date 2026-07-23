import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../tasks/presentation/bloc/task_bloc.dart';
import 'mini_calendar_card.dart';

class DashboardHero extends StatelessWidget {
  final DateTime selectedDate;
  final int percentCompleted;
  final String statusLabel;
  final Color statusColor;
  final String freeTimeLabel;
  final String? userId;
  final ValueChanged<DateTime> onChangeDate;

  const DashboardHero({
    super.key,
    required this.selectedDate,
    required this.percentCompleted,
    required this.statusLabel,
    required this.statusColor,
    required this.freeTimeLabel,
    this.userId,
    required this.onChangeDate,
  });

  void _showWeeklyStats(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final mondayStart = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

    context.read<TaskBloc>().add(TaskWeeklyStatsRequested(userId: authState.user.uid, weekStart: mondayStart));

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
            children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Carregando estatísticas...')],
          ),
        ),
      ),
    );
  }

  void _showWeeklyStatsDialog(BuildContext context, Map<String, dynamic> stats) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [Icon(Icons.analytics, color: Colors.blue), SizedBox(width: 8), Expanded(child: Text('Estatísticas da Semana', overflow: TextOverflow.ellipsis))],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatCard('Definidas', '${stats['tarefasDefinidas']}', Icons.assignment, Colors.blue),
              const SizedBox(height: 8),
              _buildStatCard('Concluídas', '${stats['tarefasConcluidas']} (${stats['percentualConclusao']}%)', Icons.check_circle, Colors.green),
              const SizedBox(height: 8),
              _buildStatCard('Pendentes', '${stats['tarefasPendentes']}', Icons.pending, Colors.orange),
              const SizedBox(height: 8),
              _buildStatCard('Puladas', '${stats['tarefasPuladas']}', Icons.skip_next, Colors.red),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              _buildStatCard('Tempo Planeado', _formatDuration(stats['tempoPlaneadoMinutos'] as int), Icons.schedule, Colors.purple),
              const SizedBox(height: 8),
              _buildStatCard('Tempo Realizado', _formatDuration(stats['tempoRealizadoMinutos'] as int), Icons.timer, Colors.indigo),
              const SizedBox(height: 8),
              _buildStatCard('Eficiência', '${stats['eficienciaTempo']}%', Icons.trending_up,
                  (stats['eficienciaTempo'] as int) >= 80 ? Colors.green : (stats['eficienciaTempo'] as int) >= 60 ? Colors.orange : Colors.red),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Fechar'))],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
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
                Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
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
    return Stack(
      children: [
        Container(
          height: 340,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
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
                    Expanded(child: _HeaderClock(selectedDate: selectedDate)),
                    IconButton(
                      onPressed: () => _showWeeklyStats(context),
                      icon: const Icon(Icons.analytics_outlined),
                      color: Colors.white,
                      tooltip: 'Estatísticas Semanais',
                    ),
                    IconButton(
                      onPressed: () => context.read<AuthBloc>().add(AuthLogoutRequested()),
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
                    _ProgressRing(percent: percentCompleted, label: '$percentCompleted%\nConcluído'),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Status', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w600)),
                          const SizedBox(height: 10),
                          _StatusPill(text: statusLabel, backgroundColor: statusColor),
                          const SizedBox(height: 10),
                          _StatusPill(text: freeTimeLabel, backgroundColor: const Color(0xFF2B5BC7)),
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
                MiniCalendarCard(selectedDate: selectedDate, userId: userId, onChangeDate: onChangeDate),
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

  const _HeaderClock({required this.selectedDate});

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(DateFormat("EEE, d 'de' MMMM", 'pt_PT').format(widget.selectedDate), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(DateFormat('HH:mm', 'pt_PT').format(_currentTime), style: const TextStyle(color: Colors.white, fontSize: 44, height: 1.0, fontWeight: FontWeight.w800)),
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
      width: 140, height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(width: 140, height: 140, child: CircularProgressIndicator(value: 1, strokeWidth: 14, valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withValues(alpha: 0.25)))),
          SizedBox(width: 140, height: 140, child: CircularProgressIndicator(value: value, strokeWidth: 14, strokeCap: StrokeCap.round, valueColor: const AlwaysStoppedAnimation<Color>(Colors.white), backgroundColor: Colors.transparent)),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 6))],
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
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
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12, height: 1.0)),
      ],
    );
  }
}
