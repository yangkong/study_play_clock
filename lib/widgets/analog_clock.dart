import 'dart:math';
import 'package:flutter/material.dart';

class AnalogClock extends StatelessWidget {
  final int totalSeconds;
  final int initialSeconds;

  const AnalogClock({
    super.key, 
    required this.totalSeconds,
    this.initialSeconds = 0,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: CustomPaint(
          painter: ClockPainter(totalSeconds, initialSeconds),
        ),
      ),
    );
  }
}

class ClockPainter extends CustomPainter {
  final int totalSeconds;
  final int initialSeconds;

  ClockPainter(this.totalSeconds, this.initialSeconds);

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final center = Offset(centerX, centerY);
    final radius = min(centerX, centerY);

    final fillBrush = Paint()..color = const Color(0xFF444974);
    final outlineBrush = Paint()
      ..color = const Color(0xFFEAECFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16;
    final centerDotBrush = Paint()..color = const Color(0xFFEAECFF);

    final hourHandBrush = Paint()
      ..shader = const RadialGradient(colors: [Color(0xFFEA74AB), Color(0xFFC279FB)])
          .createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;

    final minuteHandBrush = Paint()
      ..shader = const RadialGradient(colors: [Color(0xFF748EF6), Color(0xFF77DDFF)])
          .createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;

    final secondHandBrush = Paint()
      ..color = Colors.orange[300]!
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawCircle(center, radius - 40, fillBrush);

    // Draw red gauge for remaining time if in game mode
    if (initialSeconds > 0) {
      final gaugeBrush = Paint()
        ..color = Colors.red.withOpacity(0.5)
        ..style = PaintingStyle.fill;
      
      double sweepAngle = (totalSeconds / initialSeconds) * 2 * pi;
      // Start from top (-90 degrees)
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 40),
        -pi / 2,
        sweepAngle,
        true,
        gaugeBrush,
      );
    }

    canvas.drawCircle(center, radius - 40, outlineBrush);

    final hour = (totalSeconds / 3600) % 12;
    final minute = (totalSeconds / 60) % 60;
    final second = totalSeconds % 60;

    final hourX = centerX + 60 * cos((hour * 30 + minute * 0.5 - 90) * pi / 180);
    final hourY = centerY + 60 * sin((hour * 30 + minute * 0.5 - 90) * pi / 180);
    canvas.drawLine(center, Offset(hourX, hourY), hourHandBrush);

    final minX = centerX + 90 * cos((minute * 6 - 90) * pi / 180);
    final minY = centerY + 90 * sin((minute * 6 - 90) * pi / 180);
    canvas.drawLine(center, Offset(minX, minY), minuteHandBrush);

    final secX = centerX + 110 * cos((second * 6 - 90) * pi / 180);
    final secY = centerY + 110 * sin((second * 6 - 90) * pi / 180);
    canvas.drawLine(center, Offset(secX, secY), secondHandBrush);

    canvas.drawCircle(center, 12, centerDotBrush);

    final dashBrush = Paint()
      ..color = const Color(0xFFEAECFF)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2;

    for (var i = 0; i < 360; i += 30) {
      final x1 = centerX + (radius - 40) * cos(i * pi / 180);
      final y1 = centerY + (radius - 40) * sin(i * pi / 180);

      final x2 = centerX + (radius - 60) * cos(i * pi / 180);
      final y2 = centerY + (radius - 60) * sin(i * pi / 180);
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), dashBrush);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
