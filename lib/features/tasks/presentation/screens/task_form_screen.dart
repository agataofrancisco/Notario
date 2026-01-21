import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:notario/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:notario/features/auth/presentation/bloc/auth_state.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/task.dart';
import '../bloc/task_bloc.dart';

class TaskFormScreen extends StatefulWidget {
  final Task? task;

  const TaskFormScreen({super.key, this.task});

  bool get isEditing => task != null;

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _startDate;
  late TimeOfDay _startTime;
  late int _durationMinutes;
  late Prioridade _priority;
  bool _isNegotiable = true;
  int _safetyMarginMinutes = 0;
  bool _isLoading = false;
  bool _isValidating = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.titulo ?? '');
    _descriptionController =
        TextEditingController(text: widget.task?.descricao ?? '');
    _startDate = widget.task?.dataInicio ?? DateTime.now();
    _startTime =
        TimeOfDay.fromDateTime(widget.task?.dataInicio ?? DateTime.now());
    _durationMinutes = widget.task?.duracaoMinutos ?? 60;
    _priority = widget.task?.prioridade ?? Prioridade.media;
    _isNegotiable = widget.task?.isNegotiable ?? true;
    _safetyMarginMinutes = widget.task?.safetyMarginMinutes ?? 0;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null && pickedDate != _startDate) {
      setState(() {
        _startDate = pickedDate;
      });
    }
  }

  Future<void> _selectTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (pickedTime != null && pickedTime != _startTime) {
      setState(() {
        _startTime = pickedTime;
      });
    }
  }

  void _performSave() {
    if (_formKey.currentState!.validate()) {
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) return;

      final finalDateTime = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        _startTime.hour,
        _startTime.minute,
      );

      if (widget.isEditing) {
        final updatedTask = widget.task!.copyWith(
          titulo: _titleController.text,
          descricao: _descriptionController.text,
          dataInicio: finalDateTime,
          duracaoMinutos: _durationMinutes,
          prioridade: _priority,
          dataFim: finalDateTime.add(Duration(minutes: _durationMinutes)),
          isNegotiable: _isNegotiable,
          safetyMarginMinutes: _safetyMarginMinutes,
          atualizadoEm: DateTime.now(),
        );
        context.read<TaskBloc>().add(TaskUpdateRequested(updatedTask));
      } else {
        final newTask = Task(
          id: const Uuid().v4(),
          userId: authState.user.uid,
          titulo: _titleController.text,
          descricao: _descriptionController.text,
          dataInicio: finalDateTime,
          dataFim: finalDateTime.add(Duration(minutes: _durationMinutes)),
          duracaoMinutos: _durationMinutes,
          prioridade: _priority,
          isNegotiable: _isNegotiable,
          safetyMarginMinutes: _safetyMarginMinutes,
          criadoEm: DateTime.now(),
          atualizadoEm: DateTime.now(),
        );
        context.read<TaskBloc>().add(TaskCreateRequested(newTask));
      }
    }
  }

  void _submitForm() {
    // Agora o submit SEMPRE passa pela validação primeiro
    _validateDay();
  }

  void _validateDay() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isValidating = true);
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      setState(() => _isValidating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: Usuário não autenticado.')),
      );
      return;
    }

    context.read<TaskBloc>().add(
          TaskValidateDayRequested(
            userId: authState.user.uid,
            data: _startDate,
            duracaoMinutos: _durationMinutes,
            prioridade: _priority.toJson(),
            taskIdToExclude: widget.task?.id,
          ),
        );
  }

  void _showValidationResult(TaskValidationResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              result.viavel ? Icons.check_circle : Icons.warning,
              color: result.viavel ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            const Text('Validação de Dia'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.mensagem,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text(
              'Tempo livre: ${result.tempoLivreMinutos} min (${(result.tempoLivreMinutos / 60).toStringAsFixed(1)}h)',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (result.diasAlternativos != null &&
                result.diasAlternativos!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Dias alternativos:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...result.diasAlternativos!.map((dia) => TextButton(
                    onPressed: () {
                      setState(() => _startDate = dia);
                      Navigator.pop(context);
                    },
                    child: Text(
                        DateFormat('dd/MM/yyyy (EEEE)', 'pt_PT').format(dia)),
                  )),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          if (result.viavel)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _performSave();
              },
              child: const Text('Salvar Tarefa'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Editar Tarefa' : 'Nova Tarefa'),
        actions: [
          IconButton(
            icon: _isValidating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle_outline),
            tooltip: 'Validar Dia',
            onPressed: (_isLoading || _isValidating) ? null : _validateDay,
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isLoading ? null : _submitForm,
          ),
        ],
      ),
      body: BlocListener<TaskBloc, TaskState>(
        listener: (context, state) {
          if (state is TaskOperationSuccess) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
          if (state is TaskError) {
            setState(() {
              _isLoading = false;
              _isValidating = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
          if (state is TaskValidationResult) {
            setState(() => _isValidating = false);
            _showValidationResult(state);
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Título *',
                    hintText: 'Ex: Estudar Flutter',
                    prefixIcon: Icon(Icons.title),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Digite um título';
                    }
                    if (value.trim().length < 3) {
                      return 'Título deve ter pelo menos 3 caracteres';
                    }
                    return null;
                  },
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descrição (opcional)',
                    hintText: 'Detalhes sobre a tarefa...',
                    prefixIcon: Icon(Icons.description),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _selectDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Data *',
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      DateFormat('dd/MM/yyyy').format(_startDate),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _selectTime,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Hora *',
                      prefixIcon: Icon(Icons.access_time),
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _startTime.format(context),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Duração *',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '$_durationMinutes min (${(_durationMinutes / 60).toStringAsFixed(1)}h)',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _durationMinutes.toDouble(),
                      min: 15,
                      max: 480,
                      divisions: 31,
                      label: '$_durationMinutes min',
                      onChanged: (value) {
                        setState(() {
                          _durationMinutes = value.round();
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Prioridade>(
                  initialValue: _priority,
                  decoration: const InputDecoration(
                    labelText: 'Prioridade *',
                    prefixIcon: Icon(Icons.flag),
                    border: OutlineInputBorder(),
                  ),
                  items: Prioridade.values.map((prioridade) {
                    Color color;
                    String label;
                    switch (prioridade) {
                      case Prioridade.alta:
                        color = Colors.red.shade400;
                        label = 'Alta (Urgente)';
                        break;
                      case Prioridade.media:
                        color = Colors.orange.shade400;
                        label = 'Média (Importante)';
                        break;
                      case Prioridade.baixa:
                        color = Colors.blue.shade400;
                        label = 'Baixa (Normal)';
                        break;
                    }
                    return DropdownMenuItem(
                      value: prioridade,
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(label),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _priority = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Negociável?'),
                  subtitle: const Text(
                      'Permitir reagendamento automático se necessário'),
                  value: _isNegotiable,
                  onChanged: (value) => setState(() => _isNegotiable = value),
                  contentPadding: EdgeInsets.zero,
                ),
                if (!_isNegotiable) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Margem de Segurança',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _safetyMarginMinutes.toDouble(),
                          min: 0,
                          max: 60,
                          divisions: 12,
                          label: '$_safetyMarginMinutes min',
                          onChanged: (value) {
                            setState(
                                () => _safetyMarginMinutes = value.round());
                          },
                        ),
                      ),
                      Text('$_safetyMarginMinutes min'),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitForm,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(widget.isEditing ? Icons.save : Icons.add),
                  label: Text(
                    widget.isEditing ? 'Salvar Alterações' : 'Criar Tarefa',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
