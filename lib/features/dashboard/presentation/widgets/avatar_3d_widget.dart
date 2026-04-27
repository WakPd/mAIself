import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/providers/metrics_provider.dart';

// ─── État Avatar ──────────────────────────────────────────────────────────────

enum AvatarState { energized, normal, tired, focused }

AvatarState computeAvatarState(MetricsState m) {
  final avg = (m.energy + m.sleep + m.focus) / 3;
  if (m.energy > 0.8 && m.focus > 0.7) return AvatarState.focused;
  if (avg > 0.7) return AvatarState.energized;
  if (avg < 0.45) return AvatarState.tired;
  return AvatarState.normal;
}

// ─── Avatar 3D Widget ─────────────────────────────────────────────────────────

class Avatar3DWidget extends StatefulWidget {
  final MetricsState metrics;

  const Avatar3DWidget({super.key, required this.metrics});

  @override
  State<Avatar3DWidget> createState() => _Avatar3DWidgetState();
}

class _Avatar3DWidgetState extends State<Avatar3DWidget>
    with TickerProviderStateMixin {
  late AnimationController _rotationCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _floatCtrl;
  late AnimationController _stateTransitionCtrl;

  late Animation<double> _rotationAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _floatAnim;

  AvatarState _currentState = AvatarState.normal;
  AvatarState _previousState = AvatarState.normal;

  @override
  void initState() {
    super.initState();

    _rotationCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _stateTransitionCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _rotationAnim = Tween<double>(begin: 0, end: 2 * math.pi)
        .animate(_rotationCtrl);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _floatAnim = Tween<double>(begin: -6, end: 6)
        .animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    _currentState = computeAvatarState(widget.metrics);
    _previousState = _currentState;
  }

  @override
  void didUpdateWidget(Avatar3DWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newState = computeAvatarState(widget.metrics);
    if (newState != _currentState) {
      _previousState = _currentState;
      _currentState = newState;
      _stateTransitionCtrl.forward(from: 0);
    }

    // Ajuste la vitesse de rotation selon l'énergie
    final speed = 4 + (widget.metrics.energy * 8);
    _rotationCtrl.duration = Duration(milliseconds: (speed * 1000).toInt());
    if (!_rotationCtrl.isAnimating) _rotationCtrl.repeat();
  }

  @override
  void dispose() {
    _rotationCtrl.dispose();
    _pulseCtrl.dispose();
    _floatCtrl.dispose();
    _stateTransitionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(
          [_rotationAnim, _pulseAnim, _floatAnim, _stateTransitionCtrl]),
      builder: (context, child) {
        final t = _stateTransitionCtrl.value;
        final colors = _lerpStateColors(_previousState, _currentState, t);

        return Transform.translate(
          offset: Offset(0, _floatAnim.value),
          child: Transform.scale(
            scale: _pulseAnim.value,
            child: SizedBox(
              width: 200,
              height: 260,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Glow de fond
                  _buildGlowEffect(colors),
                  // Avatar 3D
                  CustomPaint(
                    size: const Size(200, 260),
                    painter: _HolographicAvatarPainter(
                      rotationAngle: _rotationAnim.value,
                      colors: colors,
                      state: _currentState,
                      energy: widget.metrics.energy,
                      sleep: widget.metrics.sleep,
                      focus: widget.metrics.focus,
                      pulse: _pulseAnim.value,
                    ),
                  ),
                  // Badge d'état
                  Positioned(
                    bottom: 0,
                    child: _buildStateBadge(_currentState, colors),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlowEffect(_AvatarColors colors) {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            colors.primary.withValues(alpha: 0.25),
            colors.primary.withValues(alpha: 0.08),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }

  Widget _buildStateBadge(AvatarState state, _AvatarColors colors) {
    final (label, icon) = switch (state) {
      AvatarState.energized => ('En pleine forme', Icons.bolt_rounded),
      AvatarState.normal => ('Équilibré', Icons.spa_rounded),
      AvatarState.tired => ('Fatigué', Icons.bedtime_rounded),
      AvatarState.focused => ('Déterminé', Icons.psychology_rounded),
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primary, colors.secondary],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  _AvatarColors _lerpStateColors(
      AvatarState a, AvatarState b, double t) {
    final ca = _colorsForState(a);
    final cb = _colorsForState(b);
    return _AvatarColors(
      primary: Color.lerp(ca.primary, cb.primary, t)!,
      secondary: Color.lerp(ca.secondary, cb.secondary, t)!,
      accent: Color.lerp(ca.accent, cb.accent, t)!,
      skin: Color.lerp(ca.skin, cb.skin, t)!,
    );
  }

  _AvatarColors _colorsForState(AvatarState state) {
    return switch (state) {
      AvatarState.energized => _AvatarColors(
          primary: const Color(0xFF00E676),
          secondary: const Color(0xFF00BCD4),
          accent: const Color(0xFF76FF03),
          skin: const Color(0xFFB2DFDB),
        ),
      AvatarState.normal => _AvatarColors(
          primary: const Color(0xFF4FC3F7),
          secondary: const Color(0xFF7E57C2),
          accent: const Color(0xFF29B6F6),
          skin: const Color(0xFFB3E5FC),
        ),
      AvatarState.tired => _AvatarColors(
          primary: const Color(0xFF78909C),
          secondary: const Color(0xFF546E7A),
          accent: const Color(0xFF90A4AE),
          skin: const Color(0xFFCFD8DC),
        ),
      AvatarState.focused => _AvatarColors(
          primary: const Color(0xFFFF6F00),
          secondary: const Color(0xFFE91E63),
          accent: const Color(0xFFFFAB40),
          skin: const Color(0xFFFFCCBC),
        ),
    };
  }
}

// ─── Couleurs ─────────────────────────────────────────────────────────────────

class _AvatarColors {
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color skin;

  const _AvatarColors({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.skin,
  });
}

// ─── CustomPainter : Humanoïde holographique ─────────────────────────────────

class _HolographicAvatarPainter extends CustomPainter {
  final double rotationAngle;
  final _AvatarColors colors;
  final AvatarState state;
  final double energy;
  final double sleep;
  final double focus;
  final double pulse;

  _HolographicAvatarPainter({
    required this.rotationAngle,
    required this.colors,
    required this.state,
    required this.energy,
    required this.sleep,
    required this.focus,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 - 10;

    // Profondeur 3D via le cosinus de l'angle de rotation
    final cosA = math.cos(rotationAngle);
    final sinA = math.sin(rotationAngle);

    _drawOrbits(canvas, cx, cy, cosA);
    _drawBody(canvas, cx, cy, cosA, sinA);
    _drawParticles(canvas, cx, cy, cosA, sinA);
    _drawScanLines(canvas, size, cx, cy);
    _drawHolographicGrid(canvas, cx, cy, cosA);
  }

  void _drawBody(Canvas canvas, double cx, double cy, double cosA, double sinA) {
    final scaleX = math.max(0.05, cosA.abs());
    final isFront = cosA >= 0;

    // ── Tête ──
    final headRadius = 28.0;
    final headY = cy - 75.0;

    // Lueur de tête
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          colors.primary.withValues(alpha: 0.6),
          colors.primary.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(
          center: Offset(cx, headY), radius: headRadius * 1.8));
    canvas.drawCircle(Offset(cx, headY), headRadius * 1.8, glowPaint);

    // Corps de la tête - ellipse 3D
    final headPaint = Paint()
      ..shader = LinearGradient(
        begin: isFront ? Alignment.centerLeft : Alignment.centerRight,
        end: isFront ? Alignment.centerRight : Alignment.centerLeft,
        colors: [
          colors.skin.withValues(alpha: 0.9),
          colors.primary.withValues(alpha: 0.7),
          colors.skin.withValues(alpha: 0.5),
        ],
      ).createShader(Rect.fromCenter(
          center: Offset(cx, headY),
          width: headRadius * 2 * scaleX,
          height: headRadius * 2));
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, headY),
          width: headRadius * 2 * scaleX,
          height: headRadius * 2),
      headPaint,
    );

    // Contour holographique de la tête
    final headOutlinePaint = Paint()
      ..color = colors.primary.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, headY),
          width: headRadius * 2 * scaleX,
          height: headRadius * 2),
      headOutlinePaint,
    );

    // Yeux
    if (scaleX > 0.2) {
      _drawEyes(canvas, cx, headY, scaleX, isFront);
    }

    // ── Cou ──
    final neckPaint = Paint()
      ..color = colors.skin.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromCenter(
          center: Offset(cx, cy - 40),
          width: 12 * scaleX,
          height: 14),
      neckPaint,
    );

    // ── Torse ──
    final torsoPath = Path();
    final torsoW = 44 * scaleX;
    final torsoH = 58.0;
    final torsoTop = cy - 33.0;
    torsoPath.addRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: Offset(cx, torsoTop + torsoH / 2),
          width: torsoW,
          height: torsoH),
      const Radius.circular(8),
    ));

    final torsoPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          colors.primary.withValues(alpha: 0.85),
          colors.secondary.withValues(alpha: 0.7),
          colors.primary.withValues(alpha: 0.5),
        ],
      ).createShader(Rect.fromCenter(
          center: Offset(cx, torsoTop + torsoH / 2),
          width: torsoW,
          height: torsoH));
    canvas.drawPath(torsoPath, torsoPaint);

    // Contour torse
    final torsoOutline = Paint()
      ..color = colors.primary.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(torsoPath, torsoOutline);

    // Lignes de circuit sur le torse
    if (scaleX > 0.3) {
      _drawCircuitLines(canvas, cx, torsoTop, torsoW, torsoH, scaleX);
    }

    // ── Bras ──
    _drawArm(canvas, cx - torsoW / 2 - 2, cy - 28, scaleX, true, cosA);
    _drawArm(canvas, cx + torsoW / 2 + 2, cy - 28, scaleX, false, cosA);

    // ── Jambes ──
    _drawLegs(canvas, cx, cy + 25, scaleX);
  }

  void _drawEyes(
      Canvas canvas, double cx, double headY, double scaleX, bool isFront) {
    final eyeOffset = 9 * scaleX;
    final eyeY = headY - 3;
    final eyeRadius = 5.0 * math.min(1.0, scaleX);

    for (final xSign in [-1.0, 1.0]) {
      final ex = cx + xSign * eyeOffset;

      // Lueur oeil
      final eyeGlow = Paint()
        ..shader = RadialGradient(
          colors: [
            colors.accent.withValues(alpha: 0.8),
            colors.accent.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(
            center: Offset(ex, eyeY), radius: eyeRadius * 2));
      canvas.drawCircle(Offset(ex, eyeY), eyeRadius * 2, eyeGlow);

      // Iris
      final eyePaint = Paint()
        ..shader = RadialGradient(
          colors: [Colors.white, colors.accent],
        ).createShader(Rect.fromCircle(
            center: Offset(ex, eyeY), radius: eyeRadius));
      canvas.drawCircle(Offset(ex, eyeY), eyeRadius, eyePaint);

      // Pupille
      canvas.drawCircle(
        Offset(ex, eyeY),
        eyeRadius * 0.4,
        Paint()..color = Colors.black.withValues(alpha: 0.8),
      );
    }
  }

  void _drawCircuitLines(Canvas canvas, double cx, double torsoTop,
      double torsoW, double torsoH, double scaleX) {
    final paint = Paint()
      ..color = colors.accent.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final lines = [
      // Ligne centrale verticale
      [cx, torsoTop + 8, cx, torsoTop + torsoH - 8],
      // Ligne horizontale haute
      [cx - torsoW * 0.3, torsoTop + 15, cx + torsoW * 0.3, torsoTop + 15],
      // Ligne horizontale bas
      [cx - torsoW * 0.3, torsoTop + 35, cx + torsoW * 0.3, torsoTop + 35],
    ];

    for (final l in lines) {
      canvas.drawLine(
        Offset(
            cx + (l[0] - cx) * scaleX / (torsoW / 44), l[1]),
        Offset(
            cx + (l[2] - cx) * scaleX / (torsoW / 44), l[3]),
        paint,
      );
    }

    // Cercle cœur holographique
    canvas.drawCircle(
      Offset(cx, torsoTop + 25),
      7 * scaleX,
      Paint()
        ..color = colors.accent.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.drawCircle(
      Offset(cx, torsoTop + 25),
      3 * scaleX,
      Paint()..color = colors.accent.withValues(alpha: 0.8),
    );
  }

  void _drawArm(Canvas canvas, double x, double y, double scaleX, bool isLeft,
      double cosA) {
    final armH = 46.0;
    final armW = 10 * scaleX;

    // Légère oscillation des bras
    final swing = math.sin(rotationAngle * 2) * 4 * (isLeft ? 1 : -1);

    final armPath = Path();
    armPath.addRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: Offset(x, y + armH / 2 + swing),
          width: armW,
          height: armH),
      Radius.circular(armW / 2),
    ));

    final armPaint = Paint()
      ..color = colors.secondary.withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;
    canvas.drawPath(armPath, armPaint);

    final armOutline = Paint()
      ..color = colors.primary.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(armPath, armOutline);
  }

  void _drawLegs(Canvas canvas, double cx, double y, double scaleX) {
    final legH = 52.0;
    final legW = 14 * scaleX;
    final gap = 10 * scaleX;

    for (final xOff in [-gap, gap]) {
      final lx = cx + xOff;
      // Légère marche
      final walk = math.sin(rotationAngle * 2 + (xOff > 0 ? math.pi : 0)) * 3;

      final legPath = Path();
      legPath.addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(lx, y + legH / 2 + walk),
            width: legW,
            height: legH),
        Radius.circular(legW / 2),
      ));

      canvas.drawPath(
          legPath,
          Paint()
            ..color = colors.secondary.withValues(alpha: 0.7)
            ..style = PaintingStyle.fill);
      canvas.drawPath(
          legPath,
          Paint()
            ..color = colors.primary.withValues(alpha: 0.6)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0);
    }
  }

  void _drawOrbits(Canvas canvas, double cx, double cy, double cosA) {
    final orbitPaint = Paint()
      ..color = colors.primary.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // 3 anneaux orbitaux
    for (int i = 0; i < 3; i++) {
      final radius = 65.0 + i * 18;
      final angle = rotationAngle + (i * math.pi / 3);
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx, cy - 20),
            width: radius * 2,
            height: radius * 0.35),
        orbitPaint,
      );

      // Satellite sur l'orbite
      final sx = cx + radius * math.cos(angle);
      final sy = (cy - 20) + radius * 0.175 * math.sin(angle);
      final dotSize = 3.0 + i;
      canvas.drawCircle(
        Offset(sx, sy),
        dotSize,
        Paint()..color = colors.accent.withValues(alpha: 0.8),
      );
    }
  }

  void _drawParticles(
      Canvas canvas, double cx, double cy, double cosA, double sinA) {
    final rng = math.Random(42);

    // Nombre de particules selon l'énergie
    final particleCount = (energy * 20).toInt() + 5;

    for (int i = 0; i < particleCount; i++) {
      final t = (rotationAngle / (2 * math.pi) + i / particleCount) % 1.0;
      final r = 55 + rng.nextDouble() * 60;
      final angle = i * (2 * math.pi / particleCount) + rotationAngle;
      final px = cx + r * math.cos(angle);
      final py = (cy - 20) + r * 0.4 * math.sin(angle);

      final opacity = (math.sin(t * math.pi * 2 + i) * 0.5 + 0.5) * 0.7;
      canvas.drawCircle(
        Offset(px, py),
        1.5 + rng.nextDouble() * 2,
        Paint()..color = colors.accent.withValues(alpha: opacity),
      );
    }
  }

  void _drawScanLines(Canvas canvas, Size size, double cx, double cy) {
    // Lignes de scan holographique
    final scanY =
        ((rotationAngle / (2 * math.pi)) * size.height * 1.5) % size.height;

    final scanPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          colors.primary.withValues(alpha: 0.12),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, scanY - 15, size.width, 30));

    canvas.drawRect(
      Rect.fromLTWH(0, scanY - 15, size.width, 30),
      scanPaint,
    );
  }

  void _drawHolographicGrid(Canvas canvas, double cx, double cy, double cosA) {
    // Grille holographique au sol
    final gridPaint = Paint()
      ..color = colors.primary.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final groundY = cy + 82.0;
    final gridW = 90.0;
    final gridH = 20.0;

    for (int i = -3; i <= 3; i++) {
      final x = cx + i * (gridW / 3);
      canvas.drawLine(
        Offset(x, groundY - gridH),
        Offset(cx + i * (gridW / 3) * 0.3, groundY + gridH),
        gridPaint,
      );
    }
    for (int j = -1; j <= 2; j++) {
      final t = (j + 1) / 3;
      final w = gridW * (0.3 + 0.7 * t);
      canvas.drawLine(
        Offset(cx - w, groundY - gridH + j * (gridH * 2 / 3)),
        Offset(cx + w, groundY - gridH + j * (gridH * 2 / 3)),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_HolographicAvatarPainter old) => true;
}
