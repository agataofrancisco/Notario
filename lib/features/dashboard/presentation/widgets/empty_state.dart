import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const EmptyState({
    super.key,
    this.icon = Icons.check_circle_outline,
    this.title = 'Nenhuma tarefa para hoje!',
    this.subtitle = 'Aproveite o seu dia ou adicione uma nova tarefa.',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 80, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey[600])),
        const SizedBox(height: 8),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[500])),
      ],
    );
  }
}
