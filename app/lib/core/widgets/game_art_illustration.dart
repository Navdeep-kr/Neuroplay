import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Bespoke vector illustration component for NEUROPLAY cognitive games.
/// Provides Retina-crisp, resolution-independent, glowing visual art for cards and hero banners.
class GameArtworkIllustration extends StatelessWidget {
  const GameArtworkIllustration({
    required this.slug,
    super.key,
    this.height = 140,
    this.width,
    this.borderRadius = 12,
  });

  final String slug;
  final double height;
  final double? width;
  final double borderRadius;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          height: height,
          width: width ?? double.infinity,
          decoration: BoxDecoration(
            gradient: _getBackgroundGradient(slug),
          ),
          child: CustomPaint(
            painter: _GameVectorPainter(slug: slug),
          ),
        ),
      );

  LinearGradient _getBackgroundGradient(String slug) {
    switch (slug) {
      case 'memory-matrix':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF312E81)],
        );
      case 'reflex-forge':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF18181B), Color(0xFF451A03), Color(0xFF7C2D12)],
        );
      case 'focus-reactor':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF022C22), Color(0xFF064E3B), Color(0xFF0F766E)],
        );
      case 'logic-labyrinth':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF082F49), Color(0xFF0C4A6E), Color(0xFF164E63)],
        );
      case 'number-pulse':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E1065), Color(0xFF4C1D95), Color(0xFF581C87)],
        );
      case 'word-weaver':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF042F2E), Color(0xFF134E4A), Color(0xFF115E59)],
        );
      default:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
        );
    }
  }
}

class _GameVectorPainter extends CustomPainter {
  _GameVectorPainter({required this.slug});

  final String slug;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    switch (slug) {
      case 'memory-matrix':
        _paintMemoryMatrix(canvas, size, cx, cy);
        break;
      case 'reflex-forge':
        _paintReflexForge(canvas, size, cx, cy);
        break;
      case 'focus-reactor':
        _paintFocusReactor(canvas, size, cx, cy);
        break;
      case 'logic-labyrinth':
        _paintLogicLabyrinth(canvas, size, cx, cy);
        break;
      case 'number-pulse':
        _paintNumberPulse(canvas, size, cx, cy);
        break;
      case 'word-weaver':
        _paintWordWeaver(canvas, size, cx, cy);
        break;
      default:
        _paintDefaultGlow(canvas, size, cx, cy);
        break;
    }
  }

  void _paintMemoryMatrix(Canvas canvas, Size size, double cx, double cy) {
    // Ambient back glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0x59818CF8),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 60));
    canvas.drawCircle(Offset(cx, cy), 60, glowPaint);

    // 3x3 Isometric Matrix Tiles
    const tileSize = 20.0;
    const gap = 6.0;
    final startX = cx - (tileSize * 1.5 + gap);
    final startY = cy - (tileSize * 1.5 + gap);

    final litTiles = {
      [0, 1],
      [1, 1],
      [2, 0],
      [1, 2]
    };

    for (var r = 0; r < 3; r++) {
      for (var c = 0; c < 3; c++) {
        final x = startX + c * (tileSize + gap);
        final y = startY + r * (tileSize + gap);
        final isLit = litTiles.any((pair) => pair[0] == r && pair[1] == c);

        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, tileSize, tileSize),
          const Radius.circular(5),
        );

        if (isLit) {
          final litPaint = Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF38BDF8), Color(0xFF818CF8)],
            ).createShader(rect.outerRect);
          canvas
            ..drawRRect(rect, litPaint)
            ..drawCircle(Offset(x + tileSize / 2, y + tileSize / 2), 3,
                Paint()..color = const Color(0xCCFFFFFF));
        } else {
          final basePaint = Paint()
            ..color = const Color(0x99312E81)
            ..style = PaintingStyle.fill;
          final borderPaint = Paint()
            ..color = const Color(0x4D6366F1)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0;
          canvas
            ..drawRRect(rect, basePaint)
            ..drawRRect(rect, borderPaint);
        }
      }
    }
  }

  void _paintReflexForge(Canvas canvas, Size size, double cx, double cy) {
    // Ambient orange/rose flare
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0x4DF97316),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 65));
    canvas.drawCircle(Offset(cx, cy), 65, glowPaint);

    // Fast speed motion streaks
    final streakPaint = Paint()
      ..color = const Color(0x40FB923C)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    for (var i = -2; i <= 2; i++) {
      final y = cy + i * 16.0;
      final startX = cx - 50.0 - (i.abs() * 10);
      final endX = cx + 45.0 + (i.abs() * 8);
      canvas.drawLine(Offset(startX, y), Offset(endX, y), streakPaint);
    }

    // Dynamic dual rotating diamonds (Forge crystals)
    final crystalPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFBBF24), Color(0xFFEA580C)],
      ).createShader(
          Rect.fromCenter(center: Offset(cx, cy), width: 44, height: 44));

    final path = Path()
      ..moveTo(cx, cy - 24)
      ..lineTo(cx + 22, cy)
      ..lineTo(cx, cy + 24)
      ..lineTo(cx - 22, cy)
      ..close();
    canvas.drawPath(path, crystalPaint);

    final corePaint = Paint()
      ..color = const Color(0xE6FFFFFF)
      ..style = PaintingStyle.fill;
    final corePath = Path()
      ..moveTo(cx, cy - 10)
      ..lineTo(cx + 10, cy)
      ..lineTo(cx, cy + 10)
      ..lineTo(cx - 10, cy)
      ..close();
    canvas.drawPath(corePath, corePaint);
  }

  void _paintFocusReactor(Canvas canvas, Size size, double cx, double cy) {
    final ringPaint = Paint()
      ..color = const Color(0x4D10B981)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas
      ..drawCircle(Offset(cx, cy), 18, ringPaint)
      ..drawCircle(Offset(cx, cy), 36, ringPaint)
      ..drawCircle(Offset(cx, cy), 54, ringPaint);

    final crossPaint = Paint()
      ..color = const Color(0x6634D399)
      ..strokeWidth = 1.0;
    canvas
      ..drawLine(Offset(cx - 56, cy), Offset(cx + 56, cy), crossPaint)
      ..drawLine(Offset(cx, cy - 56), Offset(cx, cy + 56), crossPaint);

    final reticlePaint = Paint()
      ..color = const Color(0xFF10B981)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    const r = 16.0;
    canvas
      ..drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
          -math.pi / 4 + 0.3, math.pi / 2 - 0.6, false, reticlePaint)
      ..drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
          math.pi / 4 + 0.3, math.pi / 2 - 0.6, false, reticlePaint)
      ..drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
          3 * math.pi / 4 + 0.3, math.pi / 2 - 0.6, false, reticlePaint)
      ..drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
          -3 * math.pi / 4 + 0.3, math.pi / 2 - 0.6, false, reticlePaint)
      ..drawCircle(Offset(cx, cy), 4, Paint()..color = const Color(0xFF6EE7B7));

    final pPaint = Paint()..color = const Color(0xB3FBBF24);
    canvas
      ..drawCircle(Offset(cx + 28, cy - 22), 3, pPaint)
      ..drawCircle(Offset(cx - 32, cy + 20), 2.5, pPaint)
      ..drawCircle(Offset(cx + 38, cy + 18), 3.5, pPaint);
  }

  void _paintLogicLabyrinth(Canvas canvas, Size size, double cx, double cy) {
    final pathPaint = Paint()
      ..color = const Color(0x6638BDF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final p1 = Path()
      ..moveTo(cx - 48, cy - 30)
      ..lineTo(cx - 16, cy - 30)
      ..lineTo(cx - 16, cy)
      ..lineTo(cx + 24, cy)
      ..lineTo(cx + 24, cy - 24)
      ..lineTo(cx + 48, cy - 24);
    canvas.drawPath(p1, pathPaint);

    final p2 = Path()
      ..moveTo(cx - 48, cy + 24)
      ..lineTo(cx - 24, cy + 24)
      ..lineTo(cx - 24, cy - 8)
      ..lineTo(cx, cy - 8)
      ..lineTo(cx, cy + 30)
      ..lineTo(cx + 40, cy + 30);
    canvas.drawPath(p2, pathPaint);

    final nodePaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
      ).createShader(Rect.fromCircle(center: Offset(cx - 16, cy), radius: 6));
    canvas
      ..drawCircle(Offset(cx - 16, cy), 6, nodePaint)
      ..drawCircle(
          Offset(cx - 48, cy - 30), 5, Paint()..color = const Color(0xFFFBBF24))
      ..drawCircle(
          Offset(cx + 48, cy - 24), 7, Paint()..color = const Color(0xFF00F0FF))
      ..drawCircle(Offset(cx + 48, cy - 24), 3, Paint()..color = Colors.white);
  }

  void _paintNumberPulse(Canvas canvas, Size size, double cx, double cy) {
    final wavePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFA855F7), Color(0xFFEC4899), Color(0xFFF43F5E)],
      ).createShader(Rect.fromLTWH(cx - 60, cy - 30, 120, 60))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    for (var x = -55.0; x <= 55.0; x += 1.0) {
      final y = math.sin((x / 55.0) * math.pi * 3) *
          (20.0 * (1.0 - (x.abs() / 70.0)));
      if (x == -55.0) {
        path.moveTo(cx + x, cy + y);
      } else {
        path.lineTo(cx + x, cy + y);
      }
    }
    canvas.drawPath(path, wavePaint);

    final points = [
      Offset(cx - 36, cy - 16),
      Offset(cx, cy + 18),
      Offset(cx + 36, cy - 16),
    ];

    for (var i = 0; i < points.length; i++) {
      final pt = points[i];
      final nodeGlow = Paint()
        ..color = const Color(0x66EC4899)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas
        ..drawCircle(pt, 8, nodeGlow)
        ..drawCircle(pt, 4, Paint()..color = Colors.white);
    }
  }

  void _paintWordWeaver(Canvas canvas, Size size, double cx, double cy) {
    final linePaint = Paint()
      ..color = const Color(0x662DD4BF)
      ..strokeWidth = 1.5;

    final center = Offset(cx, cy);
    final satellites = [
      Offset(cx - 40, cy - 24),
      Offset(cx + 38, cy - 20),
      Offset(cx - 32, cy + 24),
      Offset(cx + 42, cy + 22),
      Offset(cx, cy - 38),
    ];

    for (final sat in satellites) {
      canvas.drawLine(center, sat, linePaint);
    }
    canvas
      ..drawLine(satellites[0], satellites[4], linePaint)
      ..drawLine(satellites[1], satellites[4], linePaint)
      ..drawLine(satellites[2], satellites[3], linePaint);

    final centerGlow = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFF2DD4BF), Color(0xFF0F766E)],
      ).createShader(Rect.fromCircle(center: center, radius: 10));
    canvas
      ..drawCircle(center, 9, centerGlow)
      ..drawCircle(center, 4, Paint()..color = Colors.white);

    final satPaint = Paint()..color = const Color(0xFF99F6E4);
    for (final sat in satellites) {
      canvas.drawCircle(sat, 4, satPaint);
    }
  }

  void _paintDefaultGlow(Canvas canvas, Size size, double cx, double cy) {
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0x4D10B981),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 50));
    canvas.drawCircle(Offset(cx, cy), 50, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _GameVectorPainter oldDelegate) =>
      oldDelegate.slug != slug;
}

/// Grand Lumosity-Style Flagship Neural Cortex Illustration for the Daily Workout Banner
class NeuralCortexHeroIllustration extends StatelessWidget {
  const NeuralCortexHeroIllustration({super.key, this.size = 110});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _NeuralCortexPainter(),
        ),
      );
}

class _NeuralCortexPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.width / 2;

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0x6610B981),
          const Color(0x33064E3B),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius));
    canvas.drawCircle(Offset(cx, cy), radius, glowPaint);

    final orbitPaint = Paint()
      ..color = const Color(0x4034D399)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas
      ..drawCircle(Offset(cx, cy), radius * 0.72, orbitPaint)
      ..drawCircle(Offset(cx, cy), radius * 0.48, orbitPaint);

    final coreGlow = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFF6EE7B7), Color(0xFF059669)],
      ).createShader(
          Rect.fromCircle(center: Offset(cx, cy), radius: radius * 0.28));
    canvas.drawCircle(Offset(cx, cy), radius * 0.28, coreGlow);

    final brainPath = Path();
    final s = radius * 0.18;
    brainPath
      ..addArc(
          Rect.fromCircle(
              center: Offset(cx - s * 0.7, cy - s * 0.6), radius: s * 0.7),
          -math.pi,
          math.pi * 0.8)
      ..addArc(
          Rect.fromCircle(
              center: Offset(cx - s * 0.7, cy + s * 0.6), radius: s * 0.7),
          math.pi * 0.2,
          math.pi * 0.8)
      ..addArc(
          Rect.fromCircle(
              center: Offset(cx + s * 0.7, cy - s * 0.6), radius: s * 0.7),
          -math.pi * 0.8,
          math.pi * 0.8)
      ..addArc(
          Rect.fromCircle(
              center: Offset(cx + s * 0.7, cy + s * 0.6), radius: s * 0.7),
          0,
          math.pi * 0.8);

    final brainPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(brainPath, brainPaint);

    final angles = [0.4, 1.8, 3.2, 4.6, 5.8];
    final flarePaint = Paint()..color = const Color(0xFFECFDF5);
    for (final a in angles) {
      final rDist = radius * 0.72;
      final px = cx + math.cos(a) * rDist;
      final py = cy + math.sin(a) * rDist;
      canvas.drawCircle(Offset(px, py), 3.5, flarePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
