import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:notario/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:notario/features/auth/presentation/bloc/auth_state.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/config/app_timezone.dart';
import '../../domain/entities/task.dart';
import '../../domain/services/task_deadline_service.dart';
import '../bloc/task_bloc.dart';
import '../widgets/smart_rescheduling_dialog.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/utils/plain_text.dart';

class TaskFormScreen extends StatefulWidget {
  final Task? task;
  final DateTime? initialStart;

  const TaskFormScreen({super.key, this.task, this.initialStart});

  bool get isEditing => task != null;

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _durationController;
  late DateTime _startDate;
  late TimeOfDay _startTime;
  late int _durationMinutes;
  late Prioridade _priority;
  DateTime? _deadline;
  String? _deadlineError;
  bool _isNegotiable = true;
  int _safetyMarginMinutes = 0;
  int _avisoAntesMinutos = 10;
  bool _isLoading = false;
  bool _isValidating = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.titulo ?? '');
    _descriptionController =
        TextEditingController(text: toPlainText(widget.task?.descricao));
    final existing = widget.initialStart != null
        ? AppTimeZone.inAppZone(widget.initialStart!)
        : widget.task == null
            ? AppTimeZone.now()
            : AppTimeZone.inAppZone(widget.task!.dataInicio);
    _startDate = existing;
    _startTime = TimeOfDay.fromDateTime(existing);
    _durationMinutes = widget.task?.duracaoMinutos ?? 60;
    _durationController = TextEditingController(text: '$_durationMinutes');
    _priority = widget.task?.prioridade ?? Prioridade.media;
    _deadline = widget.task?.deadline == null
        ? null
        : AppTimeZone.inAppZone(widget.task!.deadline!);
    _isNegotiable = widget.task?.isNegotiable ?? true;
    _safetyMarginMinutes = widget.task?.safetyMarginMinutes ?? 0;
    _avisoAntesMinutos = widget.task?.avisoAntesMinutos ?? 10;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
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

  Future<void> _selectDeadline() async {
    final current = _deadline ?? _startDate.add(const Duration(days: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: AppTimeZone.inAppZone(current),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null || !mounted) return;
    setState(() {
      _deadline = AppTimeZone.at(date, time.hour, time.minute);
      _deadlineError = null;
    });
  }

  bool _validateDeadline() {
    final plannedEnd = AppTimeZone.at(
      _startDate,
      _startTime.hour,
      _startTime.minute,
    ).add(Duration(minutes: _durationMinutes));
    final valid = TaskDeadlineService.isValid(
      deadline: _deadline,
      plannedEnd: plannedEnd,
    );
    setState(() => _deadlineError = valid
        ? null
        : 'O prazo tem de ser igual ou posterior ao fim planeado.');
    return valid;
  }

  void _performSave() {
    if (_formKey.currentState!.validate()) {
      if (!_validateDeadline()) return;
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) return;

      setState(() => _isLoading = true); // Mark as loading

      final finalDateTime =
          AppTimeZone.at(_startDate, _startTime.hour, _startTime.minute);

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
          avisoAntesMinutos: _avisoAntesMinutos,
          deadline: _deadline,
          clearDeadline: _deadline == null,
          atualizadoEm: AppTimeZone.now().toUtc(),
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
          avisoAntesMinutos: _avisoAntesMinutos,
          deadline: _deadline,
          criadoEm: AppTimeZone.now().toUtc(),
          atualizadoEm: AppTimeZone.now().toUtc(),
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
    if (!_validateDeadline()) return;

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
    if (result.viavel) {
      // Dia viável - pode salvar diretamente
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Dia Viável'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.mensagem),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tempo livre: ${result.tempoLivreMinutos} min (${(result.tempoLivreMinutos / 60).toStringAsFixed(1)}h)',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _performSave();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Salvar Tarefa'),
            ),
          ],
        ),
      );
    } else {
      // Dia não viável - verificar se pode reagendar ou não
      final podeReagendar = result.podeReagendar ?? false;
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) return;

      if (podeReagendar) {
        // Mostrar diálogo de reagendamento inteligente
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => SmartReschedulingDialog(
            validationResult: {
              'viavel': result.viavel,
              'podeReagendar': result.podeReagendar,
              'tempoLivreMinutos': result.tempoLivreMinutos,
              'mensagem': result.mensagem,
              'tarefasParaMover': result.tarefasParaMover,
              'reagendamentoSugerido': result.reagendamentoSugerido,
              'diasAlternativos': result.diasAlternativos,
              'tempoLiberado': result.tempoLiberado,
            },
            userId: authState.user.uid,
            onReschedulingComplete: () {
              // Após reagendamento bem-sucedido, salvar a nova tarefa
              _performSave();
            },
          ),
        );
      } else {
        // Não pode reagendar - dia completamente lotado
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.block, color: Colors.red),
                SizedBox(width: 8),
                Text('Dia Lotado'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      result.mensagem,
                      style: TextStyle(
                        color: Colors.red.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '❌ Não é possível agendar neste dia',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Todas as tarefas existentes têm prioridade igual ou superior à nova tarefa.',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  if (result.diasAlternativos != null &&
                      result.diasAlternativos!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      '✅ Dias alternativos disponíveis:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: result.diasAlternativos!.map((dia) {
                        return Chip(
                          label: Text(
                            DateFormat('dd/MM (EEE)', 'pt_PT').format(dia),
                          ),
                          backgroundColor: Colors.green.shade100,
                          avatar: Icon(Icons.calendar_today,
                              size: 16, color: Colors.green.shade700),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sugestão: Escolha um destes dias para agendar sua tarefa.',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Entendi'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Editar Tarefa' : 'Nova Tarefa'),
        elevation: 0,
        scrolledUnderElevation: 0,
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
        ],
      ),
      body: BlocListener<TaskBloc, TaskState>(
        listener: (context, state) {
          if (state is TaskOperationSuccess) {
            setState(() => _isLoading = false);
            // Voltar para o dashboard/tela anterior
            Navigator.of(context).pop();
            // Mostrar mensagem de sucesso
            Future.delayed(const Duration(milliseconds: 100), () {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            });
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Detalhes',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
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
                    Text('Planeamento',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
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
                    InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Prazo (opcional)',
                        prefixIcon: const Icon(Icons.flag_outlined),
                        border: const OutlineInputBorder(),
                        errorText: _deadlineError,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextButton.icon(
                              onPressed: _isLoading ? null : _selectDeadline,
                              icon: const Icon(Icons.event_outlined),
                              label: Text(_deadline == null
                                  ? 'Definir prazo'
                                  : DateFormat("dd/MM/yyyy 'às' HH:mm", 'pt_PT')
                                      .format(_deadline!)),
                            ),
                          ),
                          if (_deadline != null)
                            IconButton(
                              tooltip: 'Limpar prazo',
                              onPressed: _isLoading
                                  ? null
                                  : () => setState(() {
                                        _deadline = null;
                                        _deadlineError = null;
                                      }),
                              icon: const Icon(Icons.close),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          runSpacing: 4,
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
                        TextFormField(
                          controller: _durationController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Duração em minutos',
                            helperText: 'Entre 15 e 480 minutos',
                            prefixIcon: Icon(Icons.timer_outlined),
                            suffixText: 'min',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final minutes = int.tryParse(value?.trim() ?? '');
                            if (minutes == null ||
                                minutes < 15 ||
                                minutes > 480) {
                              return 'Indique um valor entre 15 e 480 minutos';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            final minutes = int.tryParse(value.trim());
                            if (minutes != null &&
                                minutes >= 15 &&
                                minutes <= 480) {
                              setState(() => _durationMinutes = minutes);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<Prioridade>(
                      initialValue: _priority,
                      isExpanded: true,
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
                            color = AppTheme.prioridadeAlta;
                            label = 'Alta (Urgente)';
                            break;
                          case Prioridade.media:
                            color = AppTheme.prioridadeMedia;
                            label = 'Média (Importante)';
                            break;
                          case Prioridade.baixa:
                            color = AppTheme.prioridadeBaixa;
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
                              Flexible(
                                child: Text(
                                  label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
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
                    DropdownButtonFormField<int>(
                      initialValue: widget.task?.avisoAntesMinutos ?? 10,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Lembrete *',
                        prefixIcon: Icon(Icons.notifications),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('Sem lembrete')),
                        DropdownMenuItem(
                            value: 5, child: Text('5 minutos antes')),
                        DropdownMenuItem(
                            value: 10, child: Text('10 minutos antes')),
                        DropdownMenuItem(
                            value: 15, child: Text('15 minutos antes')),
                        DropdownMenuItem(
                            value: 30, child: Text('30 minutos antes')),
                        DropdownMenuItem(
                            value: 60, child: Text('1 hora antes')),
                        DropdownMenuItem(
                            value: 1440, child: Text('1 dia antes')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _avisoAntesMinutos = value;
                          });
                        }
                      },
                      onSaved: (value) {
                        if (value != null) {
                          _avisoAntesMinutos = value;
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Negociável?'),
                      subtitle: const Text(
                          'Permitir reagendamento automático se necessário'),
                      value: _isNegotiable,
                      onChanged: (value) =>
                          setState(() => _isNegotiable = value),
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
        ),
      ),
    );
  }
}
