import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notario/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:notario/features/auth/presentation/bloc/auth_state.dart';
import '../bloc/task_bloc.dart';
import '../widgets/task_list_item.dart';
import './task_form_screen.dart';
import '../../../../shared/widgets/app_components.dart';

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
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: BlocConsumer<TaskBloc, TaskState>(
        listener: (context, state) {
          // Mostra um snackbar em caso de erro ou sucesso na operação
          if (state is TaskError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is TaskOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
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
          if (state is TaskError) {
            return AppFeedbackState(
              icon: Icons.cloud_off_outlined,
              title: 'Não foi possível carregar tarefas',
              message: state.message,
              actionLabel: 'Tentar novamente',
              isError: true,
              onAction: () {
                final auth = context.read<AuthBloc>().state;
                if (auth is AuthAuthenticated) {
                  context
                      .read<TaskBloc>()
                      .add(TaskLoadRequested(auth.user.uid));
                }
              },
            );
          }
          if (state is TaskLoaded) {
            if (state.tasks.isEmpty) {
              return const AppFeedbackState(
                icon: Icons.checklist_outlined,
                title: 'Ainda não há tarefas',
                message:
                    'Use “Nova Tarefa” para começar a organizar o seu dia.',
              );
            }
            final sortedTasks = [...state.tasks]..sort((a, b) {
                final completionOrder =
                    (a.isConcluida ? 1 : 0).compareTo(b.isConcluida ? 1 : 0);
                return completionOrder != 0
                    ? completionOrder
                    : a.dataInicio.compareTo(b.dataInicio);
              });
            // Usa o novo widget TaskCard
            return AppContentFrame(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                itemCount: sortedTasks.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final task = sortedTasks[index];
                  return TaskListItem(
                    task: task,
                    onTaskChanged: () {
                      final auth = context.read<AuthBloc>().state;
                      if (auth is AuthAuthenticated) {
                        context
                            .read<TaskBloc>()
                            .add(TaskLoadRequested(auth.user.uid));
                      }
                    },
                    onDelete: () {
                      context
                          .read<TaskBloc>()
                          .add(TaskDeleteRequested(task.id));
                    },
                  );
                },
              ),
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
