import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/note.dart';
import '../../../../shared/utils/plain_text.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const NoteCard({
    super.key,
    required this.note,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasReminder = note.lembrete != null;
    final reminderPassed =
        hasReminder && note.lembrete!.isBefore(DateTime.now());
    final reminderColor = reminderPassed
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      note.titulo,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (onDelete != null)
                    IconButton(
                      icon: Icon(Icons.delete_outline,
                          color: Theme.of(context).colorScheme.error),
                      onPressed: onDelete,
                      tooltip: 'Deletar nota',
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                toPlainText(note.conteudo),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (hasReminder) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: reminderColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        reminderPassed ? Icons.alarm_off : Icons.alarm,
                        size: 16,
                        color: reminderColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        reminderPassed
                            ? 'Lembrete passou: ${DateFormat('dd/MM/yyyy HH:mm').format(note.lembrete!)}'
                            : 'Lembrete: ${DateFormat('dd/MM/yyyy HH:mm').format(note.lembrete!)}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: reminderColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Criado em ${DateFormat('dd/MM/yyyy').format(note.criadoEm)}',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
