import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/note.dart';
import '../bloc/note_bloc.dart';
import 'note_form_screen.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class NoteListScreen extends StatefulWidget {
  const NoteListScreen({super.key});

  @override
  State<NoteListScreen> createState() => _NoteListScreenState();
}

class _NoteListScreenState extends State<NoteListScreen> {
  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  void _loadNotes() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<NoteBloc>().add(NoteLoadRequested(authState.user.uid));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Notas'),
      ),
      body: BlocListener<NoteBloc, NoteState>(
        listener: (context, state) {
          if (state is NoteOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            _loadNotes();
          }
        },
        child: BlocBuilder<NoteBloc, NoteState>(
          builder: (context, state) {
            if (state is NoteLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is NoteError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Erro ao carregar notas',
                      style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadNotes,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tentar Novamente'),
                    ),
                  ],
                ),
              );
            }

            if (state is NoteLoaded) {
              if (state.notes.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.note_add, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhuma nota criada',
                        style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Toque no + para criar sua primeira nota',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async => _loadNotes(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: state.notes.length,
                  itemBuilder: (context, index) {
                    final note = state.notes[index];
                    return _NoteCard(
                      note: note,
                      onTap: () => _navigateToForm(note),
                      onDelete: () => _confirmDelete(note),
                    );
                  },
                ),
              );
            }

            return const Center(child: Text('Carregando...'));
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToForm(null),
        tooltip: 'Nova Nota',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToForm(Note? note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteFormScreen(note: note),
      ),
    ).then((_) => _loadNotes());
  }

  void _confirmDelete(Note note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deletar Nota'),
        content: Text('Tem certeza que deseja deletar "${note.titulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<NoteBloc>().add(NoteDeleteRequested(note.id));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Deletar'),
          ),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NoteCard({
    required this.note,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasReminder = note.lembrete != null;
    final reminderPassed =
        hasReminder && note.lembrete!.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      note.titulo,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (hasReminder)
                    Icon(
                      reminderPassed
                          ? Icons.notifications_off
                          : Icons.notifications_active,
                      color: reminderPassed ? Colors.grey : Colors.orange,
                      size: 20,
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Conteúdo
              Text(
                note.conteudo,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Footer
              Row(
                children: [
                  // Data de criação
                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd/MM/yyyy').format(note.criadoEm),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),

                  // Lembrete
                  if (hasReminder) ...[
                    const SizedBox(width: 16),
                    Icon(
                      Icons.alarm,
                      size: 14,
                      color: reminderPassed ? Colors.grey : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd/MM HH:mm').format(note.lembrete!),
                      style: TextStyle(
                        fontSize: 12,
                        color: reminderPassed ? Colors.grey : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],

                  const Spacer(),

                  // Ações
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    color: Colors.red,
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
