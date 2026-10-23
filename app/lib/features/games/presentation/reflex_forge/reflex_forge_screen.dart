import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:neuroplay/core/constants.dart';
import 'package:neuroplay/core/theme/app_colors.dart';
import 'package:neuroplay/core/theme/app_radii.dart';
import 'package:neuroplay/core/theme/app_spacing.dart';
import 'package:neuroplay/core/widgets/app_badge.dart';
import 'package:neuroplay/core/widgets/app_card.dart';
import 'package:neuroplay/features/games/domain/game_interface.dart';
import 'package:neuroplay/features/games/presentation/widgets/game_completion_view.dart';
import 'package:neuroplay/features/games/presentation/widgets/game_header.dart';
import 'package:neuroplay/features/games/presentation/widgets/game_pause_dialog.dart';
import 'package:neuroplay/features/games/presentation/widgets/game_tutorial_dialog.dart';

/// Playable screen for the Reflex Forge cognitive task-switching exercise.
class ReflexForgeScreen extends StatefulWidget {
  const ReflexForgeScreen({
    super.key,
    this.initialDifficulty = GameDifficulty.medium,
    this.startImmediately = false,
    this.seed,
  });

  final GameDifficulty initialDifficulty;
  final bool startImmediately;
  final int? seed;

  @override
  State<ReflexForgeScreen> createState() => _ReflexForgeScreenState();
}

class _ReflexForgeScreenState extends State<ReflexForgeScreen> {
  final ReflexForgeDefinition _definition = ReflexForgeDefinition();
  late GameSession _session;
  StreamSubscription<GameState>? _stateSubscription;

  GameResult? _finalResult;

  @override
  void initState() {
    super.initState();
    _initSession(difficulty: widget.initialDifficulty, isPractice: false);

    if (!widget.startImmediately) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _showTutorialDialog());
    } else {
      _session.start();
    }
  }

  void _initSession({
    required GameDifficulty difficulty,
    required bool isPractice,
  }) {
    _stateSubscription?.cancel();
    final config = _definition.createDefaultConfig(
      difficulty: difficulty,
      isPractice: isPractice,
      seed: widget.seed,
    );

    _session = GameSession(
      id: 'rf-${DateTime.now().millisecondsSinceEpoch}',
      definition: _definition,
      config: config,
    );

    _finalResult = null;
    _stateSubscription = _session.stateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        if (state.isCompleted) {
          _finalResult = _session.finish(isOffline: true);
        }
      });
    });
  }

  void _showTutorialDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => GameTutorialDialog(
        title: _definition.name,
        category: _definition.category,
        icon: Icons.swap_horiz_rounded,
        instructions:
            'A central symbol will appear with a Shape (Circle, Square, Triangle, Diamond) '
            'and a Pattern (Solid, Striped, Dotted, Outline).\n\n'
            'Check the current rule at the top. Match either by SHAPE or by PATTERN.\n\n'
            'Be vigilant: the rule will switch periodically to challenge your mental flexibility!',
        tips: const [
          'Use keyboard keys [1], [2], [3] or tap the options directly.',
          'Beware of foils: an option matching the inactive attribute is a distractor.',
          'Faster accurate responses earn higher reaction speed multipliers.',
        ],
        initialDifficulty: widget.initialDifficulty,
        onStart: ({required difficulty, required isPractice}) {
          _initSession(difficulty: difficulty, isPractice: isPractice);
          _session.start();
        },
      ),
    );
  }

  void _handleOptionSelected(int index) {
    if (_session.isFinished) return;
    _session.dispatch(
      SelectReflexOptionAction(
        timestamp: _session.activeDuration,
        selectedIndex: index,
      ),
    );
    setState(() {});
  }

  void _handlePause() {
    _session.pause(reason: 'user_pause_menu');
    setState(() {});

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => GamePauseDialog(
        onResume: () {
          Navigator.of(context).pop();
          _session.resume();
          setState(() {});
        },
        onRestart: () {
          Navigator.of(context).pop();
          _initSession(
            difficulty: _session.config.difficulty,
            isPractice: (_session.config as ReflexForgeConfig).isPractice,
          );
          _session.start();
          setState(() {});
        },
        onQuit: () {
          Navigator.of(context).pop();
          context.go(AppRoutes.games);
        },
      ),
    );
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_finalResult != null) {
      return Scaffold(
        body: SafeArea(
          child: GameCompletionView(
            result: _finalResult!,
            gameTitle: _definition.name,
            onPlayAgain: () {
              _initSession(
                difficulty: _session.config.difficulty,
                isPractice: (_session.config as ReflexForgeConfig).isPractice,
              );
              _session.start();
              setState(() {});
            },
            onBackToLibrary: () => context.go(AppRoutes.games),
          ),
        ),
      );
    }

    final engine = _session.engine as ReflexForgeGameEngine;
    final config = _session.config as ReflexForgeConfig;
    final trial = engine.trialState;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _handlePause,
        const SingleActivator(LogicalKeyboardKey.digit1): () =>
            _handleOptionSelected(0),
        const SingleActivator(LogicalKeyboardKey.digit2): () =>
            _handleOptionSelected(1),
        const SingleActivator(LogicalKeyboardKey.digit3): () =>
            _handleOptionSelected(2),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Column(
                children: [
                  // Header HUD
                  GameHeader(
                    title: _definition.name,
                    currentRound: _session.state.currentRound,
                    totalRounds: _session.state.totalRounds,
                    score: _session.state.score,
                    isPractice: config.isPractice,
                    onPause: _handlePause,
                  ),
                  AppSpacing.gapH16,

                  // Rule Banner with optional shift pill
                  _buildRuleHeader(theme, trial),
                  AppSpacing.gapH24,

                  // Central Target Stimulus
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: _buildStimulusCard(theme, trial.stimulus),
                      ),
                    ),
                  ),
                  AppSpacing.gapH24,

                  // Options Row
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        trial.options.length,
                        (i) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs,
                            ),
                            child: _buildOptionButton(
                              theme,
                              index: i,
                              symbol: trial.options[i],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  AppSpacing.gapH16,
                  Text(
                    'Select the matching card (Keyboard 1, 2, 3)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.navy500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRuleHeader(ThemeData theme, ReflexForgeTrialState trial) {
    final isShapeRule = trial.rule == ReflexRule.matchShape;

    return Column(
      children: [
        if (trial.ruleShiftedThisRound)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 2,
              ),
              decoration: const BoxDecoration(
                color: AppColors.mint500,
                borderRadius: AppRadii.rFull,
              ),
              child: const Text(
                '⚡ RULE SHIFTED',
                style: TextStyle(
                  color: AppColors.navy900,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: AppRadii.rFull,
            border: Border.all(
              color: AppColors.mint500.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isShapeRule ? Icons.category_rounded : Icons.texture_rounded,
                size: 20,
                color: AppColors.mint500,
              ),
              AppSpacing.gapW8,
              Text(
                'ACTIVE RULE: ${trial.rule.title.toUpperCase()}',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStimulusCard(ThemeData theme, ReflexSymbol symbol) => AppCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'TARGET',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.navy500,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              AppSpacing.gapH16,
              _SymbolGraphic(symbol: symbol, size: 84),
              AppSpacing.gapH12,
              Text(
                symbol.label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildOptionButton(
    ThemeData theme, {
    required int index,
    required ReflexSymbol symbol,
  }) =>
      Semantics(
        label: 'Option ${index + 1}: ${symbol.label}',
        child: Material(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: AppRadii.rLg,
          child: InkWell(
            borderRadius: AppRadii.rLg,
            onTap: () => _handleOptionSelected(index),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: AppBadge(
                      label: '${index + 1}',
                    ),
                  ),
                  AppSpacing.gapH8,
                  _SymbolGraphic(symbol: symbol, size: 52),
                  AppSpacing.gapH8,
                  Text(
                    symbol.shape.label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    symbol.pattern.label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.navy500,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

/// Accessible visual rendering of geometric shapes with pattern indicators.
class _SymbolGraphic extends StatelessWidget {
  const _SymbolGraphic({required this.symbol, required this.size});

  final ReflexSymbol symbol;
  final double size;

  @override
  Widget build(BuildContext context) {
    IconData icon;
    switch (symbol.shape) {
      case ReflexShape.circle:
        icon = Icons.circle;
        break;
      case ReflexShape.square:
        icon = Icons.square_rounded;
        break;
      case ReflexShape.triangle:
        icon = Icons.change_history_rounded;
        break;
      case ReflexShape.diamond:
        icon = Icons.diamond_rounded;
        break;
    }

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _getPatternBackgroundColor(symbol.pattern),
        borderRadius: AppRadii.rLg,
        border: Border.all(
          color: AppColors.navy900.withValues(alpha: 0.3),
          width: symbol.pattern == ReflexPattern.outline ? 3 : 1,
        ),
      ),
      child: Icon(
        icon,
        size: size * 0.65,
        color: _getShapeColor(symbol.pattern),
      ),
    );
  }

  Color _getPatternBackgroundColor(ReflexPattern pattern) {
    switch (pattern) {
      case ReflexPattern.solid:
        return AppColors.mint500.withValues(alpha: 0.25);
      case ReflexPattern.striped:
        return AppColors.slate300;
      case ReflexPattern.dotted:
        return AppColors.slate200;
      case ReflexPattern.outline:
        return Colors.transparent;
    }
  }

  Color _getShapeColor(ReflexPattern pattern) {
    switch (pattern) {
      case ReflexPattern.solid:
        return AppColors.mint500;
      case ReflexPattern.striped:
      case ReflexPattern.dotted:
      case ReflexPattern.outline:
        return AppColors.navy800;
    }
  }
}
