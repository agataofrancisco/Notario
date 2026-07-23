import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/note.dart';
import '../bloc/note_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class NoteFormScreen extends StatefulWidget {
  final Note? note;

  const NoteFormScreen({super.key, this.note});

  @override
  State<NoteFormScreen> createState() => _NoteFormScreenState();
}

class _NoteFormScreenState extends State<NoteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _conteudoController = TextEditingController();

  DateTime? _lembrete;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _tituloController.text = widget.note!.titulo;
      _conteudoController.text = widget.note!.conteudo;
      _lembrete = widget.note!.lembrete;
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _conteudoController.dispose();
    super.dispose();
  }

  Future<void> _selectReminder() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _lembrete ?? DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date == null) return;

    if (!mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _lembrete ?? DateTime.now().add(const Duration(hours: 1)),
      ),
    );

    if (time == null) return;

    setState(() {
      _lembrete = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _saveNote() {
    if (!_formKey.currentState!.validate()) return;

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: Usuário não autenticado')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final note = Note(
      id: widget.note?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: authState.user.uid,
      titulo: _tituloController.text.trim(),
      conteudo: _conteudoController.text.trim(),
      lembrete: _lembrete,
      notificacaoEnviada: false,
      criadoEm: widget.note?.criadoEm ?? DateTime.now(),
      atualizadoEm: DateTime.now(),
    );

    if (widget.note == null) {
      context.read<NoteBloc>().add(NoteCreateRequested(note));
    } else {
      context.read<NoteBloc>().add(NoteUpdateRequested(note));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.note != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Nota' : 'Nova Nota'),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            ),
          ),
        ),
      ),
      body: BlocListener<NoteBloc, NoteState>(
        listener: (context, state) {
          if (state is NoteOperationSuccess) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
          if (state is NoteError) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Título
                TextFormField(
                  controller: _tituloController,
                  decoration: const InputDecoration(
                    labelText: 'Título *',
                    hintText: 'Ex: Comprar mantimentos',
                    prefixIcon: Icon(Icons.title),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Digite um título';
                    }
                    return null;
                  },
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),

                // Conteúdo
                TextFormField(
                  controller: _conteudoController,
                  decoration: const InputDecoration(
                    labelText: 'Conteúdo *',
                    hintText: 'Escreva sua nota aqui...',
                    prefixIcon: Icon(Icons.notes),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 8,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Digite o conteúdo da nota';
                    }
                    return null;
                  },
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 24),

                // Lembrete
                Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.notifications,
                      color: _lembrete != null
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    title: Text(
                      _lembrete != null
                          ? 'Lembrete: ${DateFormat('dd/MM/yyyy HH:mm').format(_lembrete!)}'
                          : 'Adicionar lembrete',
                    ),
                    subtitle: _lembrete != null
                        ? Text(_getRelativeTime(_lembrete!))
                        : const Text('Receba uma notificação'),
                    trailing: _lembrete != null
                        ? IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() => _lembrete = null),
                          )
                        : const Icon(Icons.chevron_right),
                    onTap: _selectReminder,
                  ),
                ),
                const SizedBox(height: 24),

                // Botão Salvar
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveNote,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(isEditing ? Icons.save : Icons.add),
                  label: Text(
                    isEditing ? 'Salvar Alterações' : 'Criar Nota',
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

  String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.isNegative) {
      return 'No passado';
    } else if (difference.inMinutes < 60) {
      return 'Em ${difference.inMinutes} minutos';
    } else if (difference.inHours < 24) {
      return 'Em ${difference.inHours} horas';
    } else {
      return 'Em ${difference.inDays} dias';
    }
  }
}
