import 'dart:async';
import 'package:flutter/material.dart';
import 'package:neuroplay/core/audio/sound_synthesizer.dart';
import 'package:neuroplay/core/theme/app_colors.dart';
import 'package:neuroplay/core/theme/app_radii.dart';
import 'package:neuroplay/core/theme/app_spacing.dart';

/// Cinematic pre-game countdown overlay.
///
/// Primes cognitive attention with a 3.. 2.. 1.. FOCUS sequence and
/// synchronized audio cues to transition the player into a peak flow state.
class GameCountdownOverlay extends StatefulWidget {
  const GameCountdownOverlay({
    required this.onComplete,
    super.key,
  });

  final VoidCallback onComplete;

  @override
  State<GameCountdownOverlay> createState() => _GameCountdownOverlayState();
}

class _GameCountdownOverlayState extends State<GameCountdownOverlay>
    with SingleTickerProviderStateMixin {
  int _count = 3;
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.25).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: const Interval(0.65, 1, curve: Curves.easeIn),
      ),
    );

    _runStep();
  }

  void _runStep() {
    _pulseController.forward(from: 0);
    SoundSynthesizer.playCountdown(isFinal: _count == 0);

    _timer = Timer(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      if (_count > 1) {
        setState(() => _count--);
        _runStep();
      } else if (_count == 1) {
        setState(() => _count = 0); // 0 = "FOCUS!"
        _runStep();
      } else {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = _count > 0 ? '$_count' : 'FOCUS!';
    final isFocus = _count == 0;

    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.72),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) => Stack(
                alignment: Alignment.center,
                children: [
                  // Outer glowing ripple ring
                  Container(
                    width: 140 * _scaleAnimation.value,
                    height: 140 * _scaleAnimation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: (isFocus
                                ? AppColors.mint500
                                : const Color(0xFF818CF8))
                            .withValues(alpha: _fadeAnimation.value * 0.6),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isFocus
                                  ? AppColors.mint500
                                  : const Color(0xFF818CF8))
                              .withValues(alpha: _fadeAnimation.value * 0.4),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  // Inner solid core
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: isFocus
                            ? [
                                AppColors.mint500,
                                const Color(0xFF065F46),
                              ]
                            : [
                                const Color(0xFF818CF8),
                                const Color(0xFF312E81),
                              ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isFocus
                                  ? AppColors.mint500
                                  : const Color(0xFF818CF8))
                              .withValues(alpha: 0.5),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        text,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: isFocus ? 1.5 : 0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.gapH24,
            TextButton(
              onPressed: widget.onComplete,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white70,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadii.rFull,
                ),
              ),
              child: const Text('Tap to Skip Countdown'),
            ),
          ],
        ),
      ),
    );
  }
}
