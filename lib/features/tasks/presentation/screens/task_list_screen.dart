import 'package:flutter/material.dart';

class TaskListScreen extends StatelessWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todas as Tarefas'),
      ),
      body: const Center(
        child: Text('Lista completa de tarefas (em desenvolvimento)'),
      ),
    );
  }
}
