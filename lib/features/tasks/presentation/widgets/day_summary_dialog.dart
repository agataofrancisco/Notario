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
    final total = completedTasks.length + skippedTasks.length + pendingTasks.length;
    final percent = total == 0 ? 0 : (completedTasks.length / total * 100).round();
    final isSuccess = percent >= 70;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Column(
        children: [
          Icon(isSuccess ? Icons.emoji_events : Icons.trending_flat, size: 48, color: isSuccess ? Colors.amber : Colors.grey),
          const SizedBox(height: 8),
          Text(isSuccess ? 'Dia Concluído! 🎉' : 'Dia Difícil 💪', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isSuccess ? [Colors.green.shade400, Colors.green.shade600] : [Colors.orange.shade400, Colors.red.shade400],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text('$percent%', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('de conclusão', style: TextStyle(color: Colors.white.withValues(alpha: 0.9))),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildRow(Icons.check_circle, 'Concluídas', '${completedTasks.length}', Colors.green),
          const SizedBox(height: 8),
          _buildRow(Icons.skip_next, 'Puladas', '${skippedTasks.length}', Colors.orange),
          const SizedBox(height: 8),
          _buildRow(Icons.schedule, 'Pendentes', '${pendingTasks.length}', Colors.blue),
          const SizedBox(height: 16),
          Text(
            isSuccess
                ? 'Parabéns! Mantém o ritmo que estás no caminho certo!'
                : 'Nem todos os dias são perfeitos. Continua a tentar!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: isSuccess ? Colors.green : Colors.orange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Fechar'),
        ),
      ],
    );
  }

  Widget _buildRow(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700))),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
        ],
      ),
    );
  }
}
