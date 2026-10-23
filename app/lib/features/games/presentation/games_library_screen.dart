import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:neuroplay/core/constants.dart';
import 'package:neuroplay/core/theme/app_breakpoints.dart';
import 'package:neuroplay/core/theme/app_radii.dart';
import 'package:neuroplay/core/theme/app_spacing.dart';
import 'package:neuroplay/core/widgets/app_badge.dart';
import 'package:neuroplay/core/widgets/app_button.dart';
import 'package:neuroplay/core/widgets/app_card.dart';
import 'package:neuroplay/core/widgets/app_state_views.dart';
import 'package:neuroplay/core/widgets/app_text_field.dart';
import 'package:neuroplay/core/widgets/game_container_preview.dart';
import 'package:neuroplay/features/training/data/training_repository.dart';
import 'package:neuroplay/features/training/domain/training_models.dart';

/// Screen listing all available cognitive training modules.
class GamesLibraryScreen extends ConsumerStatefulWidget {
  const GamesLibraryScreen({super.key});

  @override
  ConsumerState<GamesLibraryScreen> createState() => _GamesLibraryScreenState();
}

class _GamesLibraryScreenState extends ConsumerState<GamesLibraryScreen> {
  CognitiveDomain? _selectedDomain;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gamesAsync = ref.watch(gamesListProvider(_selectedDomain));
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xl,
          ),
          child: MaxWidthContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Games Library',
                  style: theme.textTheme.displaySmall,
                ),
                AppSpacing.gapH4,
                Text(
                  'Scientifically targeted exercises designed to challenge key cognitive faculties.',
                  style: theme.textTheme.bodyMedium,
                ),
                AppSpacing.gapH24,

                // Search Bar
                AppTextField(
                  controller: _searchController,
                  hint: 'Search exercises by title or domain...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  onChanged: (v) =>
                      setState(() => _searchQuery = v.trim().toLowerCase()),
                ),
                AppSpacing.gapH16,

                // Domain Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        selected: _selectedDomain == null,
                        label: const Text('All Domains'),
                        onSelected: (_) =>
                            setState(() => _selectedDomain = null),
                      ),
                      ...CognitiveDomain.values.map(
                        (domain) => Padding(
                          padding: const EdgeInsets.only(left: AppSpacing.sm),
                          child: FilterChip(
                            selected: _selectedDomain == domain,
                            avatar: Icon(domain.icon, size: 14),
                            label: Text(domain.label),
                            onSelected: (_) =>
                                setState(() => _selectedDomain = domain),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.gapH24,

                // Content Grid / States
                gamesAsync.when(
                  loading: () => const AppLoadingView(
                    message: 'Loading exercise catalog...',
                  ),
                  error: (err, stack) => AppErrorView(
                    title: 'Failed to load library',
                    message: 'Could not retrieve exercises.',
                    onRetry: () =>
                        ref.refresh(gamesListProvider(_selectedDomain)),
                  ),
                  data: (games) {
                    final filtered = games.where((g) {
                      if (_searchQuery.isEmpty) return true;
                      return g.title.toLowerCase().contains(_searchQuery) ||
                          g.description.toLowerCase().contains(_searchQuery) ||
                          g.domain.label.toLowerCase().contains(_searchQuery);
                    }).toList();

                    if (filtered.isEmpty) {
                      return AppEmptyView(
                        icon: Icons.search_off_rounded,
                        title: 'No exercises found',
                        description:
                            'No cognitive exercises matched your query "$_searchQuery". Try searching for "speed", "memory", or clear filters.',
                        actionLabel: 'Reset Filters',
                        onAction: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _selectedDomain = null;
                          });
                        },
                      );
                    }

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final isMultiCol = constraints.maxWidth > 700;
                        if (isMultiCol) {
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: AppSpacing.lg,
                              mainAxisSpacing: AppSpacing.lg,
                              mainAxisExtent: 210,
                            ),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) =>
                                _GameCatalogCard(game: filtered[index]),
                          );
                        }

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filtered.length,
                          separatorBuilder: (context, index) =>
                              AppSpacing.gapH16,
                          itemBuilder: (context, index) =>
                              _GameCatalogCard(game: filtered[index]),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GameCatalogCard extends StatelessWidget {
  const _GameCatalogCard({required this.game});

  final CognitiveGame game;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              AppBadge(
                label: game.domain.label,
                icon: game.domain.icon,
              ),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  AppBadge(
                    label: '${game.durationMinutes} min',
                    variant: AppBadgeVariant.outline,
                  ),
                  AppBadge(
                    label: game.difficulty,
                    variant: AppBadgeVariant.outline,
                  ),
                ],
              ),
            ],
          ),
          AppSpacing.gapH12,
          Text(
            game.title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          AppSpacing.gapH4,
          Text(
            game.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
          AppSpacing.gapH12,
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppButton(
                label: 'Play',
                icon: Icons.play_arrow_rounded,
                onPressed: () {
                  switch (game.slug) {
                    case 'memory-matrix':
                      context.push(AppRoutes.memoryMatrix);
                      break;
                    case 'reflex-forge':
                      context.push(AppRoutes.reflexForge);
                      break;
                    case 'focus-reactor':
                      context.push(AppRoutes.focusReactor);
                      break;
                    case 'logic-labyrinth':
                      context.push(AppRoutes.logicLabyrinth);
                      break;
                    case 'number-pulse':
                      context.push(AppRoutes.numberPulse);
                      break;
                    case 'word-weaver':
                      context.push(AppRoutes.wordWeaver);
                      break;
                    default:
                      _openPreviewModal(context);
                      break;
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openPreviewModal(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.rXl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Padding(
            padding: AppSpacing.pXl,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'Close game preview',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  GameContainerPreview(
                    title: game.title,
                    domain: game.domain.label,
                    instructions: game.instructions,
                    durationMinutes: game.durationMinutes,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
