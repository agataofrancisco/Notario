import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/task.dart';
import '../screens/task_form_screen.dart';
import '../screens/execution_screen.dart';

class TaskListItem extends StatelessWidget {
  final Task task;
  final VoidCallback? onDelete;

  const TaskListItem({
    super.key,
    required this.task,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final Color priorityColor = _getPriorityColor(task.prioridade);
    final IconData statusIcon = _getStatusIcon(task.estado);
    final bool isCompleted = task.isConcluida;
    final bool isCancelled = task.isCancelada;
    final bool isDisabled = isCompleted || isCancelled;

    return Dismissible(
      key: Key(task.id),
      direction: onDelete != null
          ? DismissDirection.endToStart
          : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: isDisabled ? 1 : 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
                color: isDisabled
                    ? Colors.grey.withValues(alpha: 0.3)
                    : priorityColor.withValues(alpha: 0.7),
                width: 1),
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
              padding: const EdgeInsets.all(16.0),
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
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    decoration: isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: isDisabled ? Colors.grey : null,
                                  ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
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
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ExecutionScreen(task: task),
                              ),
                            );
                          },
                          tooltip: 'Iniciar Execução',
                        )
                      else
                        Icon(statusIcon, color: Theme.of(context).primaryColor),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (task.descricao != null && task.descricao!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        task.descricao!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color:
                                  isDisabled ? Colors.grey : Colors.grey[700],
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
                          'Concluída em ${DateFormat("dd/MM/yy 'às' HH:mm", 'pt_PT').format(task.concluidoEm!)}',
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
    final now = DateTime.now();
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
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time, size: 14, color: Colors.blue.shade700),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade700,
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
        color: isDisabled ? Colors.grey.shade100 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 14,
              color: isDisabled ? Colors.grey.shade400 : Colors.grey.shade800),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color:
                      isDisabled ? Colors.grey.shade500 : Colors.grey.shade900),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(Prioridade prioridade) {
    return switch (prioridade) {
      Prioridade.alta => Colors.red.shade400,
      Prioridade.media => Colors.orange.shade400,
      Prioridade.baixa => Colors.blue.shade400,
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
