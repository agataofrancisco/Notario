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

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.titulo ?? '');
    _descriptionController = TextEditingController(text: widget.task?.descricao ?? '');
    _startDate = widget.task?.dataInicio ?? DateTime.now();
    _startTime = TimeOfDay.fromDateTime(widget.task?.dataInicio ?? DateTime.now());
    _durationMinutes = widget.task?.duracaoMinutos ?? 60;
    _priority = widget.task?.prioridade ?? Prioridade.media;
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

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro: Usuário não autenticado.')),
        );
        return;
      }

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
          criadoEm: DateTime.now(),
          atualizadoEm: DateTime.now(),
        );
        context.read<TaskBloc>().add(TaskCreateRequested(newTask));
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Editar Tarefa' : 'Nova Tarefa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _submitForm,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descrição (Opcional)'),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              const Text('Data e Hora de Início', style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Data'),
                        child: Text(DateFormat('dd/MM/yyyy').format(_startDate)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: _selectTime,
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Hora'),
                        child: Text(_startTime.format(context)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Duração (minutos)', style: TextStyle(fontWeight: FontWeight.bold)),
              Slider(
                value: _durationMinutes.toDouble(),
                min: 15,
                max: 240,
                divisions: 15,
                label: '$_durationMinutes min',
                onChanged: (value) {
                  setState(() {
                    _durationMinutes = value.round();
                  });
                },
              ),
              const SizedBox(height: 24),
              const Text('Prioridade', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<Prioridade>(
                value: _priority,
                items: Prioridade.values.map((p) {
                  return DropdownMenuItem(
                    value: p,
                    child: Text(p.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _priority = value;
                    });
                  }
                },
                decoration: const InputDecoration(labelText: 'Prioridade'),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitForm,
                  icon: const Icon(Icons.save),
                  label: const Text('Salvar Tarefa'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
