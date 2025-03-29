import 'package:flutter/material.dart';
import 'dart:math';
import '../../extension.dart';
import '../day_view_page.dart';
import '../month_view_page.dart';
import '../week_view_page.dart';

class MobileHomePage extends StatefulWidget {
  @override
  _MobileHomePageState createState() => _MobileHomePageState();
}

class _MobileHomePageState extends State<MobileHomePage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 4),
    )..repeat(reverse: true);

    _waveAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _waveAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white, // Белый цвет фона
                  Colors.white, // Белый цвет фона
                ],
              ),
            ),
            child: Stack(
              children: [
                // Верхняя волна (перевернутая)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: CustomPaint(
                    size: Size(double.infinity, 150),
                    painter: WavePainter(
                      color: Color(0xFF42D3FF).withOpacity(0.2),
                      waveHeight: 20,
                      animationValue: _waveAnimation.value,
                      isReversed: true, // Перевернутая волна
                      isTop: true, // Это верхняя волна
                    ),
                  ),
                ),
                // Нижняя волна
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: CustomPaint(
                    size: Size(double.infinity, 150),
                    painter: WavePainter(
                      color: Color(0xFF42D3FF).withOpacity(0.2),
                      waveHeight: 20,
                      animationValue: _waveAnimation.value,
                      isReversed: false, // Обычная волна
                      isTop: false, // Это нижняя волна
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Calendar",
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w300, // Легкий шрифт
                          color: Color(0xFF333333), // Темный цвет текста
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 40),
                      _buildButton(context, "Month View", Icons.calendar_today, MonthViewPageDemo()),
                      SizedBox(height: 20),
                      _buildButton(context, "Day View", Icons.view_day, DayViewPageDemo()),
                      SizedBox(height: 20),
                      _buildButton(context, "Week View", Icons.view_week, WeekViewDemo()),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildButton(BuildContext context, String text, IconData icon, Widget page) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        width: 280,
        height: 60,
        margin: EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Color(0xFFF5F5F5), // Светлый фон кнопок
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Color(0xFF42D3FF).withOpacity(0.5), // Оранжевая обводка
            width: 1,
          ),
        ),
        child: TextButton(
          onPressed: () => context.pushRoute(page),
          style: TextButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Color(0xFF333333), // Темный цвет текста
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Color(0xFF42D3FF), size: 24), // Оранжевые иконки
              SizedBox(width: 12),
              Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Кастомный painter для плавных волн
class WavePainter extends CustomPainter {
  final Color color;
  final double waveHeight;
  final double animationValue;
  final bool isReversed; // Для обратного направления
  final bool isTop; // Для верхней волны

  WavePainter({
    required this.color,
    required this.waveHeight,
    required this.animationValue,
    this.isReversed = false,
    this.isTop = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    if (isTop) {
      // Верхняя волна (перевернутая)
      path.moveTo(0, 0);
      for (double i = 0; i <= size.width; i += 10) {
        final phase = isReversed ? -animationValue * 2 * pi : animationValue * 2 * pi;
        final y = sin((i / size.width * 2 * pi) + phase) * waveHeight;
        path.lineTo(i, y);
      }
      path.lineTo(size.width, 0);
    } else {
      // Нижняя волна
      path.moveTo(0, size.height);
      for (double i = 0; i <= size.width; i += 10) {
        final phase = isReversed ? -animationValue * 2 * pi : animationValue * 2 * pi;
        final y = size.height - sin((i / size.width * 2 * pi) + phase) * waveHeight;
        path.lineTo(i, y);
      }
      path.lineTo(size.width, size.height);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}