import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notario/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:notario/features/auth/presentation/bloc/auth_state.dart';
import '../bloc/task_bloc.dart';
import '../widgets/task_card.dart';
import './task_form_screen.dart';
import './execution_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  @override
  void initState() {
    super.initState();
    // Garante que as tarefas sejam carregadas apenas uma vez
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      // Dispara o evento para carregar as tarefas
      context.read<TaskBloc>().add(TaskLoadRequested(authState.user.uid));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Tarefas'),
        centerTitle: true,
      ),
      body: BlocConsumer<TaskBloc, TaskState>(
        listener: (context, state) {
          // Mostra um snackbar em caso de erro ou sucesso na operação
          if (state is TaskError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message), backgroundColor: Colors.red),
            );
          } else if (state is TaskOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message), backgroundColor: Colors.green),
            );
            // Recarrega a lista após uma operação bem-sucedida
            final authState = context.read<AuthBloc>().state;
            if (authState is AuthAuthenticated) {
              context
                  .read<TaskBloc>()
                  .add(TaskLoadRequested(authState.user.uid));
            }
          }
        },
        builder: (context, state) {
          if (state is TaskLoading || state is TaskInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is TaskLoaded) {
            if (state.tasks.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Nenhuma tarefa encontrada. Toque no botão + para criar uma nova!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ),
              );
            }
            // Usa o novo widget TaskCard
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                  16, 16, 16, 80), // Padding para o FAB
              itemCount: state.tasks.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final task = state.tasks[index];
                return TaskCard(
                  task: task,
                  onTap: () {
                    // Navigate to Edit
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TaskFormScreen(task: task),
                      ),
                    );
                  },
                  onStart: () {
                    // Navigate to Execution Mode
                    // Import ExecutionScreen dynamicamente ou no topo se preferir
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ExecutionScreen(task: task),
                      ),
                    );
                  },
                  onSkip: () {
                    // Logic to Skip task
                    // Por enquanto, apenas mostra um snackbar
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Funcionalidade de Pular em desenvolvimento')),
                    );
                  },
                );
              },
            );
          }
          // Caso o estado não seja TaskLoaded, mas também não seja loading/initial
          return const Center(child: Text('Carregando tarefas...'));
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const TaskFormScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Nova Tarefa'),
      ),
    );
  }
}
