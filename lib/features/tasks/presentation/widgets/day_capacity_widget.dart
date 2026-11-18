import 'package:flutter/material.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../core/config/app_config.dart';

/// Resumo compacto e acessível da capacidade planeada do dia.
class DayCapacityWidget extends StatelessWidget {
  final int tempoLivreMinutos;
  final int tempoOcupadoMinutos;
  final int totalMinutos;
  final String status;

  const DayCapacityWidget({
    super.key,
    required this.tempoLivreMinutos,
    required this.tempoOcupadoMinutos,
    this.totalMinutos = AppConfig.workMinutesPerDay,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = totalMinutos <= 0
        ? 0.0
        : (tempoOcupadoMinutos / totalMinutos).clamp(0.0, 1.0);
    final color = ratio >= .9
        ? AppTheme.errorColor
        : ratio >= .7
            ? AppTheme.warningColor
            : AppTheme.successColor;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Capacidade do dia',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 14),
            Semantics(
              label: '$status. ${(ratio * 100).round()} por cento ocupado. '
                  '${_formatTime(tempoLivreMinutos)} livres.',
              child: ExcludeSemantics(
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(8),
                  color: color,
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Text('$status · ${(ratio * 100).round()}% ocupado',
                    style:
                        TextStyle(color: color, fontWeight: FontWeight.w600)),
                Text('${_formatTime(tempoLivreMinutos)} livres',
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int minutes) {
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;
    return remainder == 0 ? '${hours}h' : '${hours}h ${remainder}min';
  }
}
