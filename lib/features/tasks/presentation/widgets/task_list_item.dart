import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/task.dart';
import '../screens/task_form_screen.dart';
import '../screens/execution_screen.dart';

class TaskListItem extends StatelessWidget {
  final Task task;

  const TaskListItem({
    super.key,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    final Color priorityColor = _getPriorityColor(task.prioridade);
    final IconData statusIcon = _getStatusIcon(task.estado);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: priorityColor.withOpacity(0.7), width: 1),
      ),
      child: InkWell(
        onTap: () {
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
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (task.estado == EstadoTarefa.pendente ||
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
                          color: Colors.grey[700],
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoChip(
                    context,
                    icon: Icons.calendar_today_outlined,
                    label: DateFormat('dd/MM/yy \'às\' HH:mm', 'pt_PT')
                        .format(task.dataInicio),
                  ),
                  _buildInfoChip(
                    context,
                    icon: Icons.timer_outlined,
                    label: '${task.duracaoMinutos} min',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context,
      {required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade800),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade900),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(Prioridade prioridade) {
    switch (prioridade) {
      case Prioridade.alta:
        return Colors.red.shade400;
      case Prioridade.media:
        return Colors.orange.shade400;
      case Prioridade.baixa:
        return Colors.blue.shade400;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(EstadoTarefa estado) {
    switch (estado) {
      case EstadoTarefa.pendente:
        return Icons.hourglass_empty_rounded;
      case EstadoTarefa.emExecucao:
        return Icons.play_circle_fill_rounded;
      case EstadoTarefa.concluida:
        return Icons.check_circle;
      case EstadoTarefa.cancelada:
        return Icons.cancel_rounded;
      case EstadoTarefa.pulada:
        return Icons.skip_next_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }
}
