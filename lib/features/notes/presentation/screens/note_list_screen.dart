import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/note.dart';
import '../bloc/note_bloc.dart';
import 'note_form_screen.dart';
import '../widgets/note_card.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../../shared/widgets/app_components.dart';

class NoteListScreen extends StatelessWidget {
  const NoteListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Notas'),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: const NoteListView(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NoteFormScreen(note: null),
            ),
          ).then((_) {
            // Refresh logic handled by bloc listener in NoteListView
          });
        },
        tooltip: 'Nova Nota',
        icon: const Icon(Icons.add),
        label: const Text('Nova nota'),
      ),
    );
  }
}

class NoteListView extends StatefulWidget {
  const NoteListView({super.key});

  @override
  State<NoteListView> createState() => _NoteListViewState();
}

class _NoteListViewState extends State<NoteListView> {
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
    return BlocListener<NoteBloc, NoteState>(
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
            return AppFeedbackState(
              icon: Icons.cloud_off_outlined,
              title: 'Não foi possível carregar as notas',
              message: state.message,
              actionLabel: 'Tentar novamente',
              onAction: _loadNotes,
              isError: true,
            );
          }

          if (state is NoteLoaded) {
            if (state.notes.isEmpty) {
              return const AppFeedbackState(
                icon: Icons.sticky_note_2_outlined,
                title: 'Ainda não há notas',
                message:
                    'Use o botão de criar para guardar uma ideia ou lembrete.',
              );
            }

            return RefreshIndicator(
              onRefresh: () async => _loadNotes(),
              child: AppContentFrame(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  itemCount: state.notes.length,
                  itemBuilder: (context, index) {
                    final note = state.notes[index];
                    return Dismissible(
                      key: Key(note.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        color: Colors.red,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) {
                        context
                            .read<NoteBloc>()
                            .add(NoteDeleteRequested(note.id));
                      },
                      child: NoteCard(
                        note: note,
                        onTap: () => _navigateToForm(note),
                        onDelete: () => _confirmDelete(note),
                      ),
                    );
                  },
                ),
              ),
            );
          }

          return const Center(child: Text('Carregando...'));
        },
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
