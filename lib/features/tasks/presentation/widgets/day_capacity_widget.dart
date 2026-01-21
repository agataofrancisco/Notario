import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Widget que mostra a capacidade do dia
/// Exibe minutos restantes, percentual ocupado, e status visual
class DayCapacityWidget extends StatelessWidget {
  final int tempoLivreMinutos;
  final int tempoOcupadoMinutos;
  final int totalMinutos;
  final String status; // "Indo bem", "Apertado", "Cheio"

  const DayCapacityWidget({
    super.key,
    required this.tempoLivreMinutos,
    required this.tempoOcupadoMinutos,
    this.totalMinutos = 960, // 16 horas úteis por padrão
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final percentualOcupado =
        (tempoOcupadoMinutos / totalMinutos * 100).clamp(0.0, 100.0);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _getGradientColors(percentualOcupado),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            // Título
            const Text(
              'Capacidade do Dia',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // Círculo de Progresso
            SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Círculo de fundo
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 12,
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.transparent,
                      ),
                    ),
                  ),
                  // Círculo de progresso
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 1500),
                      curve: Curves.easeOutCubic,
                      tween: Tween<double>(
                        begin: 0,
                        end: percentualOcupado / 100,
                      ),
                      builder: (context, value, child) {
                        return CustomPaint(
                          painter: _CircularProgressPainter(
                            progress: value,
                            color: Colors.white,
                            strokeWidth: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  // Texto central
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${percentualOcupado.toInt()}%',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'Ocupado',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Status e Tempo Livre
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Status
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                // Tempo Livre
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatarTempo(tempoLivreMinutos),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Indicadores de Espaço
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildIndicator(
                  icon: Icons.check_circle,
                  label: 'espaço disponível',
                  color: Colors.greenAccent,
                  visible: percentualOcupado < 70,
                ),
                if (percentualOcupado >= 70 && percentualOcupado < 90)
                  _buildIndicator(
                    icon: Icons.warning,
                    label: 'cheio',
                    color: Colors.orangeAccent,
                    visible: true,
                  ),
                if (percentualOcupado >= 90)
                  _buildIndicator(
                    icon: Icons.error,
                    label: 'sem espaço',
                    color: Colors.redAccent,
                    visible: true,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicator({
    required IconData icon,
    required String label,
    required Color color,
    required bool visible,
  }) {
    if (!visible) return const SizedBox.shrink();

    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  List<Color> _getGradientColors(double percentual) {
    if (percentual < 70) {
      // Verde - Indo bem
      return [
        const Color(0xFF4CAF50),
        const Color(0xFF66BB6A),
      ];
    } else if (percentual < 90) {
      // Laranja - Apertado
      return [
        const Color(0xFFFF9800),
        const Color(0xFFFFB74D),
      ];
    } else {
      // Vermelho - Cheio
      return [
        const Color(0xFFF44336),
        const Color(0xFFEF5350),
      ];
    }
  }

  String _formatarTempo(int minutos) {
    if (minutos < 60) {
      return '$minutos min';
    }
    final horas = minutos ~/ 60;
    final mins = minutos % 60;
    if (mins == 0) {
      return '${horas}h';
    }
    return '${horas}h ${mins}min';
  }
}

/// Painter customizado para o círculo de progresso
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2; // Começar no topo
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
