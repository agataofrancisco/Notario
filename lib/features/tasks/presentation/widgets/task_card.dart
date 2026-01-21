import 'package:flutter/material.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../domain/entities/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onStart;
  final VoidCallback? onSkip;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onStart,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isDark
            ? BorderSide(color: Colors.white.withOpacity(0.05))
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPriorityIndicator(task.prioridade),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.titulo,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color:
                                isDark ? Colors.white : const Color(0xFF1F2937),
                          ),
                        ),
                        if (task.descricao != null &&
                            task.descricao!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            task.descricao!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  _buildStatusChip(context, task.estado),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 16,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_formatTime(task.dataInicio)} - ${_formatTime(task.dataFim)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  if (task.estado == EstadoTarefa.pendente) ...[
                    _buildActionButton(
                      context,
                      label: 'Pular',
                      icon: Icons.skip_next_rounded,
                      color: AppTheme.warningColor,
                      onPressed: onSkip,
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      context,
                      label: 'Iniciar',
                      icon: Icons.play_arrow_rounded,
                      color: AppTheme.primaryColor,
                      onPressed: onStart,
                      isPrimary: true,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityIndicator(Prioridade prioridade) {
    Color color;
    switch (prioridade) {
      case Prioridade.alta:
        color = AppTheme.prioridadeAlta;
        break;
      case Prioridade.media:
        color = AppTheme.prioridadeMedia;
        break;
      case Prioridade.baixa:
        color = AppTheme.prioridadeBaixa;
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

  Widget _buildStatusChip(BuildContext context, EstadoTarefa estado) {
    Color color;
    IconData icon;

    switch (estado) {
      case EstadoTarefa.pendente:
        color = AppTheme.estadoPendente;
        icon = Icons.schedule_rounded;
        break;
      case EstadoTarefa.emExecucao:
        color = AppTheme.estadoEmExecucao;
        icon = Icons.timer_rounded;
        break;
      case EstadoTarefa.concluida:
        color = AppTheme.estadoConcluida;
        icon = Icons.check_circle_rounded;
        break;
      case EstadoTarefa.pulada:
        color = AppTheme.estadoPulada;
        icon = Icons.skip_next_rounded;
        break;
      case EstadoTarefa.cancelada:
        color = AppTheme.estadoCancelada;
        icon = Icons.cancel_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            estado.displayName,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    VoidCallback? onPressed,
    bool isPrimary = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isPrimary ? color : Colors.transparent,
            border:
                isPrimary ? null : Border.all(color: color.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isPrimary ? Colors.white : color,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isPrimary ? Colors.white : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
