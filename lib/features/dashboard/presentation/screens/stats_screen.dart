import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/stats_bloc.dart';
import '../widgets/calendar_heatmap.dart';
import '../widgets/stats_overview_card.dart';
import '../../../../core/services/statistics_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<StatsBloc>().add(StatsLoadRequested(authState.user.uid));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Estatísticas',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: BlocBuilder<StatsBloc, StatsState>(
        builder: (context, state) {
          if (state is StatsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is StatsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Erro ao carregar estatísticas',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: GoogleFonts.inter(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadStats,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            );
          }

          if (state is StatsLoaded) {
            return RefreshIndicator(
              onRefresh: () async => _loadStats(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  StatsOverviewCard(stats: state.overallStats),
                  const SizedBox(height: 16),
                  CalendarHeatmap(
                    weeklyStats: state.weeklyStats,
                    onDayTap: (date) {
                      // Poderia navegar para detalhes do dia
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Dia selecionado: ${date.day}/${date.month}'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildAchievementsCard(state.overallStats),
                  const SizedBox(height: 16),
                  _buildWeeklyBreakdown(state.weeklyStats),
                ],
              ),
            );
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.analytics_outlined,
                    size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'Carregue suas estatísticas',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAchievementsCard(OverallStats stats) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Conquistas',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildAchievementItem(
                    icon: Icons.emoji_events,
                    title: 'Melhor Sequência',
                    value: '${stats.maxStreak} dias',
                    color: Colors.amber,
                  ),
                ),
                Expanded(
                  child: _buildAchievementItem(
                    icon: Icons.trending_up,
                    title: 'Sequência Atual',
                    value: '${stats.currentStreak} dias',
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyBreakdown(List<DailyStats> weeklyStats) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detalhes da Semana',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...weeklyStats.map((stats) => _buildDayRow(stats)),
          ],
        ),
      ),
    );
  }

  Widget _buildDayRow(DailyStats stats) {
    final hasData = stats.hasData;
    final completionRate = stats.completionRate;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              '${stats.date.day}/${stats.date.month}',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: hasData ? completionRate / 100 : 0,
                          minHeight: 8,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getColorForRate(completionRate),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      hasData ? '${completionRate.toStringAsFixed(0)}%' : '-',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getColorForRate(completionRate),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  hasData
                      ? '${stats.completedTasks}/${stats.totalTasks} tarefas'
                      : 'Sem tarefas',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForRate(double rate) {
    if (rate >= 80) return Colors.green;
    if (rate >= 60) return Colors.lightGreen;
    if (rate >= 40) return Colors.orange;
    return Colors.red;
  }
}
