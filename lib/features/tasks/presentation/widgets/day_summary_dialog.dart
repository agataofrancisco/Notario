import 'package:flutter/material.dart';
import '../../domain/entities/task.dart';

class DaySummaryDialog extends StatelessWidget {
  final List<Task> completedTasks;
  final List<Task> skippedTasks;
  final List<Task> pendingTasks;

  const DaySummaryDialog({
    super.key,
    required this.completedTasks,
    required this.skippedTasks,
    required this.pendingTasks,
  });

  @override
  Widget build(BuildContext context) {
    final total =
        completedTasks.length + skippedTasks.length + pendingTasks.length;
    final percent =
        total == 0 ? 0 : (completedTasks.length / total * 100).round();
    final isSuccess = percent >= 70;
    final stateColor = isSuccess
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.error;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Column(
        children: [
          Icon(isSuccess ? Icons.emoji_events_outlined : Icons.trending_flat,
              size: 40, color: stateColor),
          const SizedBox(height: 8),
          Text(isSuccess ? 'Resumo do dia' : 'Resumo do dia',
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: stateColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text('$percent%',
                      style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: stateColor)),
                  Text('das tarefas concluídas',
                      style: TextStyle(color: stateColor)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildRow(Icons.check_circle, 'Concluídas',
                '${completedTasks.length}', Colors.green),
            const SizedBox(height: 8),
            _buildRow(Icons.skip_next, 'Puladas', '${skippedTasks.length}',
                Colors.orange),
            const SizedBox(height: 8),
            _buildRow(Icons.schedule, 'Pendentes', '${pendingTasks.length}',
                Colors.blue),
            const SizedBox(height: 16),
            Text(
              isSuccess
                  ? 'Concluíste a maioria das tarefas planeadas.'
                  : 'Podes rever as tarefas pendentes e ajustar o plano.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.grey.shade600, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Fechar'),
        ),
      ],
    );
  }

  Widget _buildRow(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700))),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: color, fontSize: 16)),
        ],
      ),
    );
  }
}
