import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/config/app_timezone.dart';

class DateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  const DateSelector({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isToday = _isToday(selectedDate);
    final isTomorrow = _isTomorrow(selectedDate);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Botão Anterior
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                onDateChanged(selectedDate.subtract(const Duration(days: 1)));
              },
            ),

            // Data Selecionada
            Expanded(
              child: InkWell(
                onTap: () => _showDatePicker(context),
                child: Column(
                  children: [
                    Text(
                      isToday
                          ? 'Hoje'
                          : isTomorrow
                              ? 'Amanhã'
                              : DateFormat('EEEE', 'pt_PT')
                                  .format(selectedDate),
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd/MM/yyyy').format(selectedDate),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Botão Próximo
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                onDateChanged(selectedDate.add(const Duration(days: 1)));
              },
            ),
          ],
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = AppTimeZone.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isTomorrow(DateTime date) {
    final tomorrow = AppTimeZone.now().add(const Duration(days: 1));
    return date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: AppTimeZone.inAppZone(selectedDate),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      onDateChanged(picked);
    }
  }
}
