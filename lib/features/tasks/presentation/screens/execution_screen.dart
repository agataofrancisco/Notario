import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/task.dart';
import '../bloc/execution_bloc.dart';
import '../../data/repositories/task_repository.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/config/app_timezone.dart';
import '../widgets/hourglass_timer.dart';
import '../../../../shared/widgets/app_components.dart';
import '../../../../shared/utils/plain_text.dart';

class ExecutionScreen extends StatelessWidget {
  final Task task;

  const ExecutionScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ExecutionBloc(
        repository: context.read<TaskRepository>(),
        notificationService: NotificationService(),
      )..add(ExecutionStarted(task)),
      child: const _ExecutionView(),
    );
  }
}

class _ExecutionView extends StatelessWidget {
  const _ExecutionView();

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ExecutionBloc, ExecutionState>(
      listener: (context, state) {
        if (state is ExecutionCompleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tarefa concluída! Parabéns! 🚀')),
          );
          Navigator.of(context).pop();
        } else if (state is ExecutionInitial) {
          // Se voltou ao estado inicial (por skip ou cancel), fecha a tela
          // (desde que não seja o initial logo na entrada, mas o Bloc começa Initial...
          //  Precisamos distinguir. O estado inicial só ocorre no começo ou após reset/skip/cancel)
          // Uma opção melhor seria ter States específicos como ExecutionSkippedSuccess, mas Initial serve se verificarmos algo ou simplesmente assumirmos que
          // se a tela está montada e volta para Initial, é pq acabou.
          // PORÉM, na entrada é Initial.
          // O ideal é verificar se houve uma transição.
          // Simplificando: o Bloc emite Initial no Skipped/Cancelled.
          // Mas ao entrar na tela, adicionamos Started.
          // Se o evento Started é processado rapido, sai do Initial.
          // Vamos verificar se o navigator pode dar pop.
          if (Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Modo Foco'),
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              final shouldPop = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Parar execução?'),
                  content: const Text(
                      'O temporizador será pausado. Você poderá retomar depois.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Sair'),
                    ),
                  ],
                ),
              );

              if (shouldPop == true && context.mounted) {
                await context.read<ExecutionBloc>().pauseForExit();
                if (!context.mounted) return;
                Navigator.of(context).pop();
              }
            },
          ),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'skip') {
                  context.read<ExecutionBloc>().add(ExecutionSkipped());
                } else if (value == 'cancel') {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Cancelar Tarefa?'),
                      content:
                          const Text('A tarefa será marcada como cancelada.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Não'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            context
                                .read<ExecutionBloc>()
                                .add(ExecutionCancelled());
                          },
                          child: const Text('Sim, Cancelar'),
                        ),
                      ],
                    ),
                  );
                } else if (value == 'reschedule') {
                  // Mostrar date picker para reagendar
                  // Usa contexto do builder para acessar o bloc se necessário,
                  // mas aqui context é do build principal, que tem o Provider (via child do provider?).
                  // Espere... O BlocProvider está acima do _ExecutionView.
                  // Então context.read<ExecutionBloc> funciona.
                  final now = AppTimeZone.now();
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: now.add(const Duration(days: 1)),
                    firstDate: now,
                    lastDate: DateTime(now.year + 1),
                  );

                  if (pickedDate != null && context.mounted) {
                    final pickedTime = await showTimePicker(
                      context: context,
                      initialTime: const TimeOfDay(hour: 9, minute: 0),
                    );

                    if (pickedTime != null && context.mounted) {
                      final newDateTime = AppTimeZone.at(
                        pickedDate,
                        pickedTime.hour,
                        pickedTime.minute,
                      );
                      context
                          .read<ExecutionBloc>()
                          .add(ExecutionRescheduled(newDateTime));
                    }
                  }
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'skip',
                  child: Row(
                    children: [
                      Icon(Icons.skip_next, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Pular Tarefa'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'cancel',
                  child: Row(
                    children: [
                      Icon(Icons.cancel, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Cancelar Tarefa'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'reschedule',
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Reagendar'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: BlocBuilder<ExecutionBloc, ExecutionState>(
          builder: (context, state) {
            if (state is ExecutionInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            final task = state.task!;
            final totalSeconds = (task.duracaoMinutos) * 60;
            final elapsed = state.elapsedSeconds;
            // Calcular progresso inverso (vai diminuindo)
            // Se elapsed > total (overtime), progresso fica cheio ou outra cor
            double progress = 1.0 - (elapsed / totalSeconds);
            if (progress < 0) progress = 0;

            final remainingSeconds = state.remainingSeconds;
            final isOvertime = remainingSeconds < 0;

            Color timerColor = Theme.of(context).colorScheme.primary;
            if (progress < 0.2) timerColor = const Color(0xFF946200);
            if (isOvertime) timerColor = Theme.of(context).colorScheme.error;
            final timerSize =
                (MediaQuery.sizeOf(context).width - 64).clamp(160.0, 240.0);

            final isFinishing = state is ExecutionFinishing;

            return Stack(
              children: [
                AppContentFrame(
                  maxWidth: 620,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 12),
                        Text(
                          task.titulo,
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (task.descricao != null &&
                            task.descricao!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            toPlainText(task.descricao),
                            style: GoogleFonts.inter(),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 24),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: timerSize,
                              height: timerSize,
                              child: HourglassTimer(
                                progress: progress,
                                size: timerSize,
                                color: timerColor,
                              ),
                            ),
                            Semantics(
                              label:
                                  isOvertime ? 'Tempo extra' : 'Tempo restante',
                              value: _formatTime(isOvertime
                                  ? elapsed - totalSeconds
                                  : remainingSeconds),
                              child: ExcludeSemantics(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      isOvertime ? 'TEMPO EXTRA' : 'RESTANTE',
                                      style: GoogleFonts.inter(
                                        color: Colors.grey,
                                        fontSize: 12,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    Text(
                                      _formatTime(isOvertime
                                          ? elapsed - totalSeconds
                                          : remainingSeconds),
                                      style: GoogleFonts.inter(
                                        fontSize: timerSize * 0.19,
                                        fontWeight: FontWeight.bold,
                                        color: timerColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            if (state is ExecutionRunning)
                              OutlinedButton.icon(
                                onPressed: isFinishing
                                    ? null
                                    : () {
                                        context
                                            .read<ExecutionBloc>()
                                            .add(ExecutionPaused());
                                      },
                                icon: const Icon(Icons.pause),
                                label: const Text('Pausar'),
                              )
                            else if (state is ExecutionPausedState)
                              OutlinedButton.icon(
                                onPressed: isFinishing
                                    ? null
                                    : () {
                                        context
                                            .read<ExecutionBloc>()
                                            .add(ExecutionResumed());
                                      },
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('Retomar'),
                              ),
                            FilledButton.icon(
                              onPressed: isFinishing
                                  ? null
                                  : () {
                                      context
                                          .read<ExecutionBloc>()
                                          .add(ExecutionFinished());
                                    },
                              icon: const Icon(Icons.check),
                              label: const Text('Concluir'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                if (isFinishing)
                  Container(
                    color: Colors.black26,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
