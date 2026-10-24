import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:neuroplay/core/theme/app_colors.dart';
import 'package:neuroplay/core/theme/app_radii.dart';

/// Micro-shake widget for subtle error feedback without punitive visual clutter.
class ShakeWidget extends StatefulWidget {
  const ShakeWidget({
    required this.child,
    required this.shakeTrigger,
    super.key,
    this.offset = 6,
    this.duration = const Duration(milliseconds: 320),
  });

  final Widget child;
  final int shakeTrigger;
  final double offset;
  final Duration duration;

  @override
  State<ShakeWidget> createState() => _ShakeWidgetState();
}

class _ShakeWidgetState extends State<ShakeWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
  }

  @override
  void didUpdateWidget(covariant ShakeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shakeTrigger != oldWidget.shakeTrigger) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final sineValue = math.sin(_controller.value * 4 * math.pi) *
              (1 - _controller.value);
          return Transform.translate(
            offset: Offset(sineValue * widget.offset, 0),
            child: child,
          );
        },
        child: widget.child,
      );
}

/// Spring scale micro-interaction wrapper for interactive game elements.
class SpringTouchFeedback extends StatefulWidget {
  const SpringTouchFeedback({
    required this.child,
    required this.onTap,
    super.key,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  State<SpringTouchFeedback> createState() => _SpringTouchFeedbackState();
}

class _SpringTouchFeedbackState extends State<SpringTouchFeedback>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _scaleAnimation = Tween<double>(begin: 1, end: 0.94).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
        reverseCurve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: widget.enabled ? (_) => _controller.forward() : null,
        onTapUp: widget.enabled
            ? (_) {
                _controller.reverse();
                widget.onTap?.call();
              }
            : null,
        onTapCancel: widget.enabled ? () => _controller.reverse() : null,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: widget.child,
        ),
      );
}

/// Floating score / combo popup pill that floats upward and fades out.
class FloatingScorePopup extends StatefulWidget {
  const FloatingScorePopup({
    required this.text,
    super.key,
    this.isCombo = false,
  });

  final String text;
  final bool isCombo;

  @override
  State<FloatingScorePopup> createState() => _FloatingScorePopupState();
}

class _FloatingScorePopupState extends State<FloatingScorePopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _fadeAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -32),
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Transform.translate(
          offset: _slideAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: widget.isCombo
                    ? const Color(0xFFF59E0B)
                    : AppColors.mint500,
                borderRadius: AppRadii.rFull,
                boxShadow: [
                  BoxShadow(
                    color: (widget.isCombo
                            ? const Color(0xFFF59E0B)
                            : AppColors.mint500)
                        .withValues(alpha: 0.4),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Text(
                widget.text,
                style: const TextStyle(
                  color: AppColors.navy900,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      );
}

/// Particle celebration overlay for completion victory states.
class ConfettiParticleOverlay extends StatefulWidget {
  const ConfettiParticleOverlay({
    required this.child,
    super.key,
    this.particleCount = 45,
  });

  final Widget child;
  final int particleCount;

  @override
  State<ConfettiParticleOverlay> createState() =>
      _ConfettiParticleOverlayState();
}

class _ConfettiParticleOverlayState extends State<ConfettiParticleOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..forward();

    final rand = math.Random();
    final colors = [
      AppColors.mint500,
      const Color(0xFF818CF8), // Indigo
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF38BDF8), // Cyan
      const Color(0xFFEC4899), // Pink
    ];

    _particles = List.generate(widget.particleCount, (i) {
      final angle = rand.nextDouble() * 2 * math.pi;
      final speed = 80 + rand.nextDouble() * 260;
      return _Particle(
        x: 0.5 + (rand.nextDouble() - 0.5) * 0.4,
        y: 0.35 + (rand.nextDouble() - 0.5) * 0.2,
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed - 120,
        color: colors[rand.nextInt(colors.length)],
        size: 4 + rand.nextDouble() * 6,
        rotationSpeed: (rand.nextDouble() - 0.5) * 8,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          widget.child,
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) => CustomPaint(
                  painter: _ConfettiPainter(
                    particles: _particles,
                    progress: _controller.value,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
}

class _Particle {
  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.rotationSpeed,
  });

  final double x;
  final double y;
  final double vx;
  final double vy;
  final Color color;
  final double size;
  final double rotationSpeed;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.particles, required this.progress});

  final List<_Particle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress;
    final gravity = 450;
    final opacity = (1.0 - (t - 0.4) / 0.6).clamp(0.0, 1.0);

    for (final p in particles) {
      final currentX = p.x * size.width + p.vx * t;
      final currentY = p.y * size.height + p.vy * t + 0.5 * gravity * t * t;

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas
        ..save()
        ..translate(currentX, currentY)
        ..rotate(p.rotationSpeed * t)
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: p.size,
              height: p.size * 0.6,
            ),
            const Radius.circular(2),
          ),
          paint,
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
