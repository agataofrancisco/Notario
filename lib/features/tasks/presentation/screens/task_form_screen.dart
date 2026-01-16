import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../bloc/task_bloc.dart';
import '../../../../core/services/auth_service.dart';
import '../../domain/entities/task.dart';

class TaskFormScreen extends StatefulWidget {
  final DateTime date;
  final Task? task; // Para edição

  const TaskFormScreen({
    super.key,
    required this.date,
    this.task,
  });

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();

  late DateTime _dataInicio;
  late TimeOfDay _horaInicio;
  int _duracaoMinutos = 60;
  Prioridade _prioridade = Prioridade.media;

  @override
  void initState() {
    super.initState();
    _dataInicio = widget.date;
    _horaInicio = const TimeOfDay(hour: 9, minute: 0);

    if (widget.task != null) {
      _tituloController.text = widget.task!.titulo;
      _descricaoController.text = widget.task!.descricao ?? '';
      _dataInicio = widget.task!.dataInicio;
      _horaInicio = TimeOfDay.fromDateTime(widget.task!.dataInicio);
      _duracaoMinutos = widget.task!.duracaoMinutos;
      _prioridade = widget.task!.prioridade;
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'Nova Tarefa' : 'Editar Tarefa'),
      ),
      body: BlocListener<TaskBloc, TaskState>(
        listener: (context, state) {
          if (state is TaskOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            Navigator.of(context).pop();
          } else if (state is TaskError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Título
                TextFormField(
                  controller: _tituloController,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira um título';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Descrição
                TextFormField(
                  controller: _descricaoController,
                  decoration: const InputDecoration(
                    labelText: 'Descrição (opcional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Data
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Data'),
                  subtitle: Text(
                    '${_dataInicio.day}/${_dataInicio.month}/${_dataInicio.year}',
                  ),
                  trailing: const Icon(Icons.edit),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _dataInicio,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => _dataInicio = date);
                    }
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                const SizedBox(height: 16),

                // Hora
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: const Text('Hora de Início'),
                  subtitle: Text(
                      '${_horaInicio.hour}:${_horaInicio.minute.toString().padLeft(2, '0')}'),
                  trailing: const Icon(Icons.edit),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _horaInicio,
                    );
                    if (time != null) {
                      setState(() => _horaInicio = time);
                    }
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                const SizedBox(height: 16),

                // Duração
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Duração: $_duracaoMinutos minutos',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Slider(
                      value: _duracaoMinutos.toDouble(),
                      min: 15,
                      max: 480,
                      divisions: 31,
                      label: '$_duracaoMinutos min',
                      onChanged: (value) {
                        setState(() => _duracaoMinutos = value.toInt());
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Prioridade
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prioridade',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<Prioridade>(
                      segments: const [
                        ButtonSegment(
                          value: Prioridade.baixa,
                          label: Text('Baixa'),
                          icon: Icon(Icons.arrow_downward),
                        ),
                        ButtonSegment(
                          value: Prioridade.media,
                          label: Text('Média'),
                          icon: Icon(Icons.remove),
                        ),
                        ButtonSegment(
                          value: Prioridade.alta,
                          label: Text('Alta'),
                          icon: Icon(Icons.arrow_upward),
                        ),
                      ],
                      selected: {_prioridade},
                      onSelectionChanged: (Set<Prioridade> newSelection) {
                        setState(() => _prioridade = newSelection.first);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Botão Salvar
                FilledButton.icon(
                  onPressed: _saveTask,
                  icon: const Icon(Icons.save),
                  label: Text(widget.task == null
                      ? 'Criar Tarefa'
                      : 'Salvar Alterações'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _saveTask() {
    if (!_formKey.currentState!.validate()) return;

    final authService = context.read<AuthService>();
    final user = authService.currentUser;
    if (user == null) return;

    final dataInicio = DateTime(
      _dataInicio.year,
      _dataInicio.month,
      _dataInicio.day,
      _horaInicio.hour,
      _horaInicio.minute,
    );

    final dataFim = dataInicio.add(Duration(minutes: _duracaoMinutos));

    final task = Task(
      id: widget.task?.id ?? const Uuid().v4(),
      userId: user.id,
      titulo: _tituloController.text,
      descricao:
          _descricaoController.text.isEmpty ? null : _descricaoController.text,
      dataInicio: dataInicio,
      dataFim: dataFim,
      duracaoMinutos: _duracaoMinutos,
      prioridade: _prioridade,
      estado: widget.task?.estado ?? EstadoTarefa.pendente,
      criadoEm: widget.task?.criadoEm ?? DateTime.now(),
      atualizadoEm: DateTime.now(),
    );

    if (widget.task == null) {
      context.read<TaskBloc>().add(TaskCreateRequested(task));
    } else {
      context.read<TaskBloc>().add(TaskUpdateRequested(task));
    }
  }
}
