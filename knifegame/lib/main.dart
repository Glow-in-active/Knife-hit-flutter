import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(KnifeHitGame());
}

class KnifeHitGame extends StatelessWidget {
  const KnifeHitGame({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text('Knife Hit Game'),
        ),
        body: KnifeHitScreen(),
      ),
    );
  }
}

class KnifeHitScreen extends StatefulWidget {
  const KnifeHitScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _KnifeHitScreenState createState() => _KnifeHitScreenState();
}

class _KnifeHitScreenState extends State<KnifeHitScreen> with TickerProviderStateMixin {
  double _rotationAngle = 0;
  final List<double> _knifeAngles = [];
  bool _gameOver = false;
  late Timer _rotationTimer;
  late AnimationController _knifeAnimationController;
  bool _knifeFlying = false;

  final double _rotationSpeed = 0.04;
  final Duration _knifeFlightDuration = Duration(milliseconds: 100);

  @override
  void initState() {
    super.initState();
    _startLogRotation();

    _knifeAnimationController = AnimationController(
      vsync: this,
      duration: _knifeFlightDuration,
    );
  }

  @override
  void dispose() {
    _rotationTimer.cancel();
    _knifeAnimationController.dispose();
    super.dispose();
  }

  void _startLogRotation() {
    _rotationTimer = Timer.periodic(Duration(milliseconds: 16), (timer) {
      setState(() {
        _rotationAngle += _rotationSpeed;
        if (_rotationAngle >= 2 * pi) {
          _rotationAngle -= 2 * pi;
        }
      });
    });
  }

  void _throwKnife() {
    if (_gameOver || _knifeFlying) return;

    _knifeFlying = true;

    double targetAngle = pi / 2;

    double adjustedAngle = (targetAngle - _rotationAngle) % (2 * pi);

    for (double angle in _knifeAngles) {
      double angleDifference = ((adjustedAngle - angle) % (2 * pi)).abs();
      if (angleDifference < 0.2 || angleDifference > (2 * pi - 0.1)) {
        setState(() {
          _gameOver = true;
          _knifeFlying = false;
        });

        Future.delayed(Duration(seconds: 1), () {
          setState(() {
            _gameOver = false;
            _knifeAngles.clear();
          });
        });

        return;
      }
    }

    _knifeAngles.add(adjustedAngle);

    _knifeAnimationController.forward(from: 0).then((_) {
      setState(() {
        _knifeFlying = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(
          size: Size(double.infinity, double.infinity),
          painter: KnifeHitPainter(
            rotationAngle: _rotationAngle,
            knifeAngles: _knifeAngles,
            knifeAnimationProgress: _knifeAnimationController.value,
            knifeFlying: _knifeFlying,
          ),
        ),
        if (_gameOver)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Game Over!',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
        Positioned(
          bottom: 50,
          child: ElevatedButton(
            onPressed: _throwKnife,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              textStyle: TextStyle(fontSize: 20),
            ),
            child: Text('Throw Knife'),
          ),
        ),
      ],
    );
  }
}

class KnifeHitPainter extends CustomPainter {
  final double rotationAngle;
  final List<double> knifeAngles;
  final double knifeAnimationProgress;
  final bool knifeFlying;

  KnifeHitPainter({
    required this.rotationAngle,
    required this.knifeAngles,
    required this.knifeAnimationProgress,
    required this.knifeFlying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final logRadius = 100.0;

    _drawRotatingLog(canvas, center, logRadius);

    for (double angle in knifeAngles) {
      _drawKnife(canvas, center, logRadius, angle);
    }

    if (knifeFlying) {
      _drawFlyingKnife(canvas, center, logRadius, size.height);
    }
  }

  void _drawRotatingLog(Canvas canvas, Offset center, double radius) {
    final segmentPaint1 = Paint()..color = Colors.brown;
    final segmentPaint2 = Paint()..color = Colors.orange;

    for (int i = 0; i < 12; i++) {
      final startAngle = i * pi / 6 + rotationAngle;
      final sweepAngle = pi / 6;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        i % 2 == 0 ? segmentPaint1 : segmentPaint2,
      );
    }
  }

  void _drawKnife(Canvas canvas, Offset center, double radius, double angle) {
    final knifeLength = 50.0;
    final knifeWidth = 5.0;

    final dx = center.dx + radius * cos(angle + rotationAngle);
    final dy = center.dy + radius * sin(angle + rotationAngle);

    final normalAngle = angle + rotationAngle + pi;

    final tipX = dx - knifeLength * cos(normalAngle);
    final tipY = dy - knifeLength * sin(normalAngle);
    final leftX = tipX - knifeWidth * sin(normalAngle);
    final leftY = tipY + knifeWidth * cos(normalAngle);
    final rightX = tipX + knifeWidth * sin(normalAngle);
    final rightY = tipY - knifeWidth * cos(normalAngle);

    final knifePaint = Paint()..color = Colors.black;

    final knifePath = Path()
      ..moveTo(dx, dy)
      ..lineTo(leftX, leftY)
      ..lineTo(rightX, rightY)
      ..close();

    canvas.drawPath(knifePath, knifePaint);
  }

  void _drawFlyingKnife(Canvas canvas, Offset center, double logRadius, double screenHeight) {
    final knifeLength = 50.0;
    final knifeWidth = 5.0;

    final targetAngle = -pi / 2;
    final targetX = center.dx + logRadius * cos(targetAngle);
    final targetY = center.dy + logRadius * sin(targetAngle);

    final startY = screenHeight - 100;
    final currentX = center.dx;

    double currentY = startY + (targetY - startY) * knifeAnimationProgress;
    if (currentY < center.dy + logRadius) {
      currentY = center.dy + logRadius;
    }

    final knifePaint = Paint()..color = Colors.black;

    final knifePath = Path()
      ..moveTo(currentX, currentY - knifeLength)
      ..lineTo(currentX - knifeWidth, currentY)
      ..lineTo(currentX + knifeWidth, currentY)
      ..close();

    canvas.drawPath(knifePath, knifePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
