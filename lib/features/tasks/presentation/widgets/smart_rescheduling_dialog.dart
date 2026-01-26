import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/task_bloc.dart';

/// Diálogo para mostrar opções de reagendamento inteligente
class SmartReschedulingDialog extends StatelessWidget {
  final Map<String, dynamic> validationResult;
  final String userId;
  final VoidCallback? onReschedulingComplete;

  const SmartReschedulingDialog({
    super.key,
    required this.validationResult,
    required this.userId,
    this.onReschedulingComplete,
  });

  @override
  Widget build(BuildContext context) {
    final podeReagendar = validationResult['podeReagendar'] as bool? ?? false;
    final tarefasParaMover = validationResult['tarefasParaMover'] as List<dynamic>? ?? [];
    final reagendamentoSugerido = validationResult['reagendamentoSugerido'] as List<Map<String, dynamic>>? ?? [];
    final diasAlternativos = validationResult['diasAlternativos'] as List<DateTime>? ?? [];
    final tempoLiberado = validationResult['tempoLiberado'] as int? ?? 0;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            podeReagendar ? Icons.schedule : Icons.warning,
            color: podeReagendar ? Colors.orange : Colors.red,
          ),
          const SizedBox(width: 8),
          const Text('Reagendamento Inteligente'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mensagem principal
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: podeReagendar ? Colors.orange.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: podeReagendar ? Colors.orange.shade200 : Colors.red.shade200,
                ),
              ),
              child: Text(
                validationResult['mensagem'] as String,
                style: TextStyle(
                  color: podeReagendar ? Colors.orange.shade800 : Colors.red.shade800,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            if (podeReagendar && tarefasParaMover.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Tarefas a Mover (${_formatTempo(tempoLiberado)} liberados):',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              ...tarefasParaMover.map((tarefa) => _buildTaskToMoveCard(tarefa)),
              
              if (reagendamentoSugerido.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Reagendamento Sugerido:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                ...reagendamentoSugerido.map((sugestao) => _buildReschedulingSuggestion(sugestao)),
              ],
            ],

            if (diasAlternativos.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Dias Alternativos Disponíveis:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: diasAlternativos.map((dia) => Chip(
                  label: Text(DateFormat('dd/MM (EEE)', 'pt_PT').format(dia)),
                  backgroundColor: Colors.green.shade100,
                )).toList(),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        
        if (podeReagendar && reagendamentoSugerido.isNotEmpty)
          BlocConsumer<TaskBloc, TaskState>(
            listener: (context, state) {
              if (state is TaskReschedulingResult) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.mensagem),
                    backgroundColor: state.sucesso ? Colors.green : Colors.red,
                  ),
                );
                if (state.sucesso) {
                  onReschedulingComplete?.call();
                }
              }
            },
            builder: (context, state) {
              final isLoading = state is TaskLoading;
              return ElevatedButton(
                onPressed: isLoading ? null : () {
                  context.read<TaskBloc>().add(
                    TaskExecuteReschedulingRequested(
                      userId: userId,
                      reagendamentoSugerido: reagendamentoSugerido,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: isLoading 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Executar Reagendamento'),
              );
            },
          ),
      ],
    );
  }

  Widget _buildTaskToMoveCard(Map<String, dynamic> tarefa) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              Icons.move_down,
              color: Colors.orange.shade600,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tarefa['titulo'] as String,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '${_formatTempo(tarefa['duracaoMinutos'] as int)} • ${tarefa['prioridade']}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReschedulingSuggestion(Map<String, dynamic> sugestao) {
    final dataAtual = DateTime.parse(sugestao['dataAtual'] as String);
    final dataSugerida = DateTime.parse(sugestao['dataSugerida'] as String);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sugestao['titulo'] as String,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.arrow_forward, size: 16, color: Colors.blue.shade600),
                const SizedBox(width: 4),
                Text(
                  'De ${DateFormat('dd/MM').format(dataAtual)} para ${DateFormat('dd/MM').format(dataSugerida)}',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTempo(int minutos) {
    if (minutos < 60) return '${minutos}min';
    final horas = minutos ~/ 60;
    final mins = minutos % 60;
    return mins == 0 ? '${horas}h' : '${horas}h ${mins}min';
  }
}