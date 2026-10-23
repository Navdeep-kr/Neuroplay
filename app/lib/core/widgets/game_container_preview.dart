import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neuroplay/core/theme/app_colors.dart';
import 'package:neuroplay/core/theme/app_radii.dart';
import 'package:neuroplay/core/theme/app_spacing.dart';
import 'package:neuroplay/core/theme/app_theme.dart';
import 'package:neuroplay/core/widgets/app_badge.dart';
import 'package:neuroplay/core/widgets/app_button.dart';
import 'package:neuroplay/core/widgets/app_card.dart';

/// Reusable container shell for cognitive games.
///
/// Provides game header, pause/resume modal, accessible canvas area,
/// and clear disclaimer that game scoring is in prototype/preview stage.
class GameContainerPreview extends StatefulWidget {
  const GameContainerPreview({
    required this.title,
    required this.domain,
    required this.instructions,
    super.key,
    this.durationMinutes = 3,
    this.onCompleted,
  });

  final String title;
  final String domain;
  final String instructions;
  final int durationMinutes;
  final VoidCallback? onCompleted;

  @override
  State<GameContainerPreview> createState() => _GameContainerPreviewState();
}

class _GameContainerPreviewState extends State<GameContainerPreview> {
  bool _isPlaying = false;
  bool _isPaused = false;
  bool _isCompleted = false;
  int _score = 0;
  int _secondsRemaining = 0;
  Timer? _timer;
  final FocusNode _gameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.durationMinutes * 60;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _gameFocusNode.dispose();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _isPlaying = true;
      _isPaused = false;
      _isCompleted = false;
      _score = 0;
      _secondsRemaining = 45; // 45 seconds for interactive preview
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused && mounted) {
        if (_secondsRemaining > 0) {
          setState(() => _secondsRemaining--);
        } else {
          _completeGame();
        }
      }
    });
    _gameFocusNode.requestFocus();
  }

  void _completeGame() {
    _timer?.cancel();
    setState(() {
      _isPlaying = false;
      _isCompleted = true;
    });
    widget.onCompleted?.call();
  }

  void _pauseGame() {
    setState(() => _isPaused = true);
  }

  void _resumeGame() {
    setState(() => _isPaused = false);
    _gameFocusNode.requestFocus();
  }

  void _recordTargetHit() {
    if (!_isPlaying || _isPaused) return;
    setState(() => _score += 10);
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final isDark = theme.brightness == Brightness.dark;

    return Focus(
      focusNode: _gameFocusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.space ||
                event.logicalKey == LogicalKeyboardKey.enter)) {
          if (_isPlaying && !_isPaused) {
            _recordTargetHit();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Prototype / Preview Disclaimer Banner
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : AppColors.slate100,
              borderRadius: AppRadii.rMd,
              border: Border.all(color: tokens.cardBorder),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.science_outlined,
                  size: 16,
                  color: isDark ? AppColors.mint400 : AppColors.mint700,
                ),
                AppSpacing.gapW8,
                Expanded(
                  child: Text(
                    'Preview Simulation — Production game engine & backend score validation arrive in Phase 3',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.navy700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.gapH16,

          // Header with Domain, Title, Time, Score
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppBadge(
                      label: widget.domain,
                      variant: AppBadgeVariant.mint,
                    ),
                    AppSpacing.gapH4,
                    Text(
                      widget.title,
                      style: theme.textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),
              if (_isPlaying) ...[
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: tokens.subtleBackground,
                        borderRadius: AppRadii.rMd,
                        border: Border.all(color: tokens.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('TIME', style: theme.textTheme.labelSmall),
                          Text(
                            '${_secondsRemaining}s',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.gapW8,
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: tokens.subtleBackground,
                        borderRadius: AppRadii.rMd,
                        border: Border.all(color: tokens.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('SCORE', style: theme.textTheme.labelSmall),
                          Text(
                            '$_score',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.gapW8,
                    IconButton(
                      icon: Icon(
                        _isPaused
                            ? Icons.play_arrow_rounded
                            : Icons.pause_rounded,
                      ),
                      tooltip: _isPaused ? 'Resume Game' : 'Pause Game',
                      onPressed: _isPaused ? _resumeGame : _pauseGame,
                    ),
                  ],
                ),
              ],
            ],
          ),
          AppSpacing.gapH16,

          // Main Interactive Canvas Container
          AppCard(
            padding: EdgeInsets.zero,
            child: SizedBox(
              height: 340,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Playfield / Canvas Area
                  if (_isPlaying && !_isPaused) ...[
                    Positioned.fill(
                      child: InkWell(
                        onTap: _recordTargetHit,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.colorScheme.primary
                                          .withAlpha(40),
                                      blurRadius: 16,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.touch_app_rounded,
                                  color: Colors.white,
                                  size: 44,
                                ),
                              ),
                              AppSpacing.gapH16,
                              Text(
                                'Tap or press Spacebar to respond',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              AppSpacing.gapH4,
                              Text(
                                'Demonstrates interactive input latency & haptics',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ] else if (_isPaused) ...[
                    // Paused Overlay
                    Positioned.fill(
                      child: ColoredBox(
                        color: (isDark ? Colors.black : Colors.white)
                            .withAlpha(200),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Game Paused',
                                style: theme.textTheme.headlineSmall,
                              ),
                              AppSpacing.gapH16,
                              AppButton(
                                label: 'Resume',
                                icon: Icons.play_arrow_rounded,
                                onPressed: _resumeGame,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ] else if (_isCompleted) ...[
                    // Completed Summary View
                    Padding(
                      padding: AppSpacing.pXl,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 48,
                            color: AppColors.success,
                          ),
                          AppSpacing.gapH12,
                          Text(
                            'Session Complete',
                            style: theme.textTheme.headlineSmall,
                          ),
                          AppSpacing.gapH8,
                          Text(
                            'Preview Score: $_score points (Demo simulation)',
                            style: theme.textTheme.bodyMedium,
                          ),
                          AppSpacing.gapH24,
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AppButton(
                                label: 'Try Again',
                                variant: AppButtonVariant.secondary,
                                onPressed: _startGame,
                              ),
                              AppSpacing.gapW12,
                              AppButton(
                                label: 'Finish',
                                onPressed: () {
                                  setState(() => _isCompleted = false);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Instructions & Start View
                    Padding(
                      padding: AppSpacing.pXl,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.psychology_outlined,
                            size: 48,
                            color: theme.colorScheme.primary,
                          ),
                          AppSpacing.gapH16,
                          Text(
                            'How to Play',
                            style: theme.textTheme.headlineSmall,
                          ),
                          AppSpacing.gapH8,
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: Text(
                              widget.instructions,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                          AppSpacing.gapH24,
                          AppButton(
                            label: 'Start Session Preview',
                            icon: Icons.play_arrow_rounded,
                            onPressed: _startGame,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
