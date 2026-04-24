import 'package:flutter/material.dart';

class AvatarWidget extends StatelessWidget {
  final String? userName;
  final double size;
  final Color primaryColor;
  final Color skinColor;
  final Color hairColor;
  final Color clothingColor;

  const AvatarWidget({
    super.key,
    this.userName,
    this.size = 120,
    this.primaryColor = const Color(0xFF4CAF50),
    this.skinColor = const Color(0xFFE8B8A3),
    this.hairColor = const Color(0xFF5D4037),
    this.clothingColor = const Color(0xFF4CAF50),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipRect(
        child: CustomPaint(
          painter: AvatarPainter(
            skinColor: skinColor,
            hairColor: hairColor,
            clothingColor: clothingColor,
          ),
        ),
      ),
    );
  }
}

class AvatarPainter extends CustomPainter {
  final Color skinColor;
  final Color hairColor;
  final Color clothingColor;

  AvatarPainter({
    required this.skinColor,
    required this.hairColor,
    required this.clothingColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.25);
    final radius = size.width * 0.22;

    // ──────── Cheveux (haut du crâne) ────────
    final hairPaint = Paint()
      ..color = hairColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(center.dx, center.dy - radius * 0.15),
      radius * 0.55,
      hairPaint,
    );

    // ──────── Tête (visage) ────────
    final headPaint = Paint()
      ..color = skinColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.50, headPaint);

    // ──────── Yeux ────────
    final eyePaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;

    final eyeRadius = radius * 0.08;
    final eyeDistance = radius * 0.15;

    // Oeil gauche
    canvas.drawCircle(
      Offset(center.dx - eyeDistance, center.dy - radius * 0.08),
      eyeRadius,
      eyePaint,
    );

    // Oeil droit
    canvas.drawCircle(
      Offset(center.dx + eyeDistance, center.dy - radius * 0.08),
      eyeRadius,
      eyePaint,
    );

    // Pupilles (reflet)
    final pupilPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(center.dx - eyeDistance + eyeRadius * 0.4, center.dy - radius * 0.10),
      eyeRadius * 0.4,
      pupilPaint,
    );

    canvas.drawCircle(
      Offset(center.dx + eyeDistance + eyeRadius * 0.4, center.dy - radius * 0.10),
      eyeRadius * 0.4,
      pupilPaint,
    );

    // ──────── Nez ────────
    final nosePaint = Paint()
      ..color = skinColor.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(center.dx, center.dy + radius * 0.05),
      radius * 0.05,
      nosePaint,
    );

    // ──────── Bouche (sourire) ────────
    final mouthPaint = Paint()
      ..color = const Color(0xFFC65869)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.06
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + radius * 0.18),
        width: radius * 0.25,
        height: radius * 0.15,
      ),
      0,
      3.14159,
      false,
      mouthPaint,
    );

    // ──────── Cou ────────
    final neckPaint = Paint()
      ..color = skinColor
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + radius * 0.55),
        width: radius * 0.35,
        height: radius * 0.25,
      ),
      neckPaint,
    );

    // ──────── Corps (vêtement) ────────
    final clothingPaint = Paint()
      ..color = clothingColor
      ..style = PaintingStyle.fill;

    // Torse
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx, center.dy + radius * 1.0),
          width: radius * 1.0,
          height: radius * 1.2,
        ),
        Radius.circular(radius * 0.2),
      ),
      clothingPaint,
    );

    // ──────── Bras ────────
    final armPaint = Paint()
      ..color = skinColor
      ..style = PaintingStyle.fill;

    // Bras gauche
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx - radius * 0.65, center.dy + radius * 0.85),
          width: radius * 0.25,
          height: radius * 0.7,
        ),
        Radius.circular(radius * 0.12),
      ),
      armPaint,
    );

    // Bras droit
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx + radius * 0.65, center.dy + radius * 0.85),
          width: radius * 0.25,
          height: radius * 0.7,
        ),
        Radius.circular(radius * 0.12),
      ),
      armPaint,
    );

    // ──────── Mains ────────
    final handPaint = Paint()
      ..color = skinColor
      ..style = PaintingStyle.fill;

    // Main gauche
    canvas.drawCircle(
      Offset(center.dx - radius * 0.77, center.dy + radius * 1.35),
      radius * 0.12,
      handPaint,
    );

    // Main droite
    canvas.drawCircle(
      Offset(center.dx + radius * 0.77, center.dy + radius * 1.35),
      radius * 0.12,
      handPaint,
    );

    // ──────── Jambes ────────
    final legPaint = Paint()
      ..color = const Color(0xFF37474F)
      ..style = PaintingStyle.fill;

    // Jambe gauche
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx - radius * 0.25, center.dy + radius * 1.75),
          width: radius * 0.22,
          height: radius * 0.8,
        ),
        Radius.circular(radius * 0.11),
      ),
      legPaint,
    );

    // Jambe droite
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx + radius * 0.25, center.dy + radius * 1.75),
          width: radius * 0.22,
          height: radius * 0.8,
        ),
        Radius.circular(radius * 0.11),
      ),
      legPaint,
    );

    // ──────── Chaussures ────────
    final shoePaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;

    // Chaussure gauche
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx - radius * 0.25, center.dy + radius * 2.2),
          width: radius * 0.3,
          height: radius * 0.2,
        ),
        Radius.circular(radius * 0.08),
      ),
      shoePaint,
    );

    // Chaussure droite
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx + radius * 0.25, center.dy + radius * 2.2),
          width: radius * 0.3,
          height: radius * 0.2,
        ),
        Radius.circular(radius * 0.08),
      ),
      shoePaint,
    );
  }

  @override
  bool shouldRepaint(AvatarPainter oldDelegate) {
    return oldDelegate.skinColor != skinColor ||
        oldDelegate.hairColor != hairColor ||
        oldDelegate.clothingColor != clothingColor;
  }
}
