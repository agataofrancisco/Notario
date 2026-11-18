import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/task.dart';
import '../../domain/services/task_deadline_service.dart';
import '../screens/task_form_screen.dart';
import '../screens/execution_screen.dart';
import '../../../../core/config/app_timezone.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/utils/plain_text.dart';

class TaskListItem extends StatelessWidget {
  final Task task;
  final VoidCallback? onDelete;
  final VoidCallback? onTaskChanged;

  const TaskListItem({
    super.key,
    required this.task,
    this.onDelete,
    this.onTaskChanged,
  });

  @override
  Widget build(BuildContext context) {
    final Color priorityColor = _getPriorityColor(task.prioridade);
    final IconData statusIcon = _getStatusIcon(task.estado);
    final bool isCompleted = task.isConcluida;
    final bool isCancelled = task.isCancelada;
    final bool isDisabled = isCompleted || isCancelled;
    final deadlineContext =
        TaskDeadlineService.contextFor(task, AppTimeZone.now());

    return Dismissible(
      key: Key(task.id),
      direction: onDelete != null
          ? DismissDirection.endToStart
          : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        onDelete?.call();
      },
      child: Opacity(
        opacity: isDisabled ? 0.6 : 1.0,
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            side:
                BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: InkWell(
            onTap: isDisabled
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TaskFormScreen(task: task),
                      ),
                    );
                  },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          task.titulo,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    decoration: isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: isDisabled
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant
                                        : null,
                                  ),
                          softWrap: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: priorityColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          switch (task.prioridade) {
                            Prioridade.alta => 'Alta',
                            Prioridade.media => 'Média',
                            Prioridade.baixa => 'Baixa',
                          },
                          style: TextStyle(
                              color: priorityColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (isCompleted)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 24,
                          ),
                        )
                      else if (isCancelled)
                        Icon(statusIcon, color: Colors.red, size: 28)
                      else if (task.estado == EstadoTarefa.pendente ||
                          task.estado == EstadoTarefa.emExecucao ||
                          task.estado == EstadoTarefa.pulada)
                        IconButton(
                          icon: const Icon(
                            Icons.play_circle_fill_rounded,
                            size: 32,
                            color: Colors.green,
                          ),
                          onPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ExecutionScreen(task: task),
                              ),
                            );
                            onTaskChanged?.call();
                          },
                          tooltip: 'Iniciar Execução',
                        )
                      else
                        Icon(statusIcon, color: Theme.of(context).primaryColor),
                    ],
                  ),
                  if (deadlineContext != null && !isCompleted) ...[
                    const SizedBox(height: 8),
                    Semantics(
                      label: 'Prazo: ${deadlineContext.label}',
                      child: Chip(
                        avatar: Icon(
                          deadlineContext.urgency == DeadlineUrgency.overdue
                              ? Icons.warning_amber_rounded
                              : Icons.flag_outlined,
                          size: 18,
                        ),
                        label: Text(deadlineContext.label),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: deadlineContext.urgency ==
                                DeadlineUrgency.overdue
                            ? Theme.of(context).colorScheme.errorContainer
                            : Theme.of(context).colorScheme.secondaryContainer,
                      ),
                    ),
                  ],
                  if (task.syncStatus == SyncStatus.pending) ...[
                    const SizedBox(height: 6),
                    Semantics(
                      label:
                          'Alteração guardada no dispositivo; sincronização pendente',
                      child: Row(
                        children: [
                          Icon(Icons.sync_problem_outlined,
                              size: 15,
                              color: Theme.of(context).colorScheme.tertiary),
                          const SizedBox(width: 5),
                          Text('Sincronização pendente',
                              style: Theme.of(context).textTheme.labelSmall),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(statusIcon,
                          size: 16, color: _getStatusColor(task.estado)),
                      const SizedBox(width: 6),
                      Text(
                        _getStatusLabel(task.estado),
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: _getStatusColor(task.estado),
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (task.descricao != null && task.descricao!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        toPlainText(task.descricao),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isDisabled
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (isCompleted && task.concluidoEm != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.check_circle_outline,
                            size: 14, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          'Concluída em ${DateFormat("dd/MM/yy 'às' HH:mm", 'pt_PT').format(AppTimeZone.inAppZone(task.concluidoEm!))}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      /*Flexible(
                        child: _buildInfoChip(
                          context,
                          icon: Icons.calendar_today_outlined,
                          label: DateFormat("dd/MM/yy 'às' HH:mm", 'pt_PT')
                              .format(task.dataInicio),
                          isDisabled: isDisabled,
                        ),
                      ),*/
                      //const SizedBox(width: 8),
                      Flexible(
                        child: _buildInfoChip(
                          context,
                          icon: Icons.timer_outlined,
                          label: '${task.duracaoMinutos} min',
                          isDisabled: isDisabled,
                        ),
                      ),
                      if (task.estado == EstadoTarefa.pendente &&
                          !isDisabled) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child:
                              _buildRelativeTimeChip(context, task.dataInicio),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRelativeTimeChip(BuildContext context, DateTime startTime) {
    final now = AppTimeZone.now();
    final difference = startTime.difference(now);

    String label;
    if (difference.isNegative) {
      label = 'Atrasada';
    } else if (difference.inMinutes < 60) {
      label = 'Daqui a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      label = 'Daqui a ${difference.inHours}h';
    } else {
      label = 'Daqui a ${difference.inDays} dias';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .primaryContainer
            .withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time,
              size: 14, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context,
      {required IconData icon,
      required String label,
      bool isDisabled = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 14,
              color: isDisabled
                  ? Theme.of(context).colorScheme.onSurfaceVariant
                  : Theme.of(context).colorScheme.onSurface),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDisabled
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : Theme.of(context).colorScheme.onSurface),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(Prioridade prioridade) {
    return switch (prioridade) {
      Prioridade.alta => AppTheme.prioridadeAlta,
      Prioridade.media => AppTheme.prioridadeMedia,
      Prioridade.baixa => AppTheme.prioridadeBaixa,
    };
  }

  Color _getStatusColor(EstadoTarefa estado) {
    return switch (estado) {
      EstadoTarefa.pendente => AppTheme.estadoPendente,
      EstadoTarefa.emExecucao => AppTheme.estadoEmExecucao,
      EstadoTarefa.concluida => AppTheme.estadoConcluida,
      EstadoTarefa.cancelada => AppTheme.estadoCancelada,
      EstadoTarefa.pulada => AppTheme.estadoPulada,
    };
  }

  String _getStatusLabel(EstadoTarefa estado) {
    return switch (estado) {
      EstadoTarefa.pendente => 'Planeada',
      EstadoTarefa.emExecucao => 'Em execução',
      EstadoTarefa.concluida => 'Concluída',
      EstadoTarefa.cancelada => 'Cancelada',
      EstadoTarefa.pulada => 'Pulada',
    };
  }

  IconData _getStatusIcon(EstadoTarefa estado) {
    return switch (estado) {
      EstadoTarefa.pendente => Icons.hourglass_empty_rounded,
      EstadoTarefa.emExecucao => Icons.play_circle_fill_rounded,
      EstadoTarefa.concluida => Icons.check_circle,
      EstadoTarefa.cancelada => Icons.cancel_rounded,
      EstadoTarefa.pulada => Icons.skip_next_rounded,
    };
  }
}
