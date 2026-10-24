import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neuroplay/core/theme/app_colors.dart';
import 'package:neuroplay/core/theme/app_radii.dart';
import 'package:neuroplay/core/theme/app_spacing.dart';
import 'package:neuroplay/core/theme/app_theme.dart';
import 'package:neuroplay/features/subscription/data/subscription_repository.dart';
import 'package:neuroplay/features/subscription/domain/entitlement_models.dart';
import 'package:neuroplay/features/subscription/presentation/controllers/subscription_controller.dart';

/// Screen presenting subscription status, feature entitlements, store restore,
/// and pre-release monetization status.
class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(subscriptionControllerProvider);
    final isPaidCheckoutEnabled = ref.watch(isPaidCheckoutEnabledProvider);
    final products = ref.watch(subscriptionProductsProvider);
    final tokens = context.tokens;
    final theme = Theme.of(context);

    // Listen for feedback messages
    ref.listen<SubscriptionState>(subscriptionControllerProvider, (prev, next) {
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
      }
      if (next.restoreMessage != null &&
          next.restoreMessage != prev?.restoreMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.restoreMessage!),
            backgroundColor: AppColors.mint700,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription & Entitlements'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Entitlement Status',
            onPressed: state.isLoading
                ? null
                : () => unawaited(
                      ref
                          .read(subscriptionControllerProvider.notifier)
                          .refresh(),
                    ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Current Entitlement Badge Card
            _CurrentStatusCard(entitlement: state.entitlement),
            AppSpacing.gapH24,

            // Pre-Release Demonstration Banner
            _PreReleaseNoticeCard(isPaidCheckoutEnabled: isPaidCheckoutEnabled),
            AppSpacing.gapH24,

            // Product Plans
            Text(
              'Available Plans',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            AppSpacing.gapH12,
            ...products.map(
              (p) => _ProductCard(
                product: p,
                isCheckoutEnabled: isPaidCheckoutEnabled,
              ),
            ),
            AppSpacing.gapH24,

            // Feature Matrix Comparison Table
            _FeatureMatrixCard(entitlement: state.entitlement),
            AppSpacing.gapH24,

            // Restore Purchases & Management Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: state.isRestoring
                        ? null
                        : () => unawaited(
                              ref
                                  .read(subscriptionControllerProvider.notifier)
                                  .restorePurchases(),
                            ),
                    icon: state.isRestoring
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.restore),
                    label: const Text('Restore Purchases'),
                  ),
                ),
                AppSpacing.gapW12,
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        unawaited(_showManagementDialog(context, ref)),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Manage Billing'),
                  ),
                ),
              ],
            ),
            AppSpacing.gapH24,

            // Transparent Disclosures Notice
            Container(
              padding: AppSpacing.pLg,
              decoration: BoxDecoration(
                color: tokens.subtleBackground,
                borderRadius: AppRadii.rLg,
                border: Border.all(color: tokens.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Billing Policy & Scope Disclosures',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AppSpacing.gapH6,
                  Text(
                    'Subscribers may cancel anytime through their respective platform store settings. Premium features remain active until the end of the paid billing cycle. Free Community features (all six core games, practice modes, and daily playlists) are guaranteed permanently without paywalls.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showManagementDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final url = await ref
        .read(subscriptionControllerProvider.notifier)
        .getManagementUrl();

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Manage Subscription'),
        content: Text(
          'To modify your plan, update payment methods, or cancel auto-renewal, visit your platform account portal:\n\n$url',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _CurrentStatusCard extends StatelessWidget {
  const _CurrentStatusCard({required this.entitlement});
  final SubscriptionEntitlement entitlement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final isPaid = entitlement.isPaidActive;

    return Container(
      padding: AppSpacing.pXl,
      decoration: BoxDecoration(
        color: isPaid ? tokens.mintContainer : tokens.cardBackground,
        borderRadius: AppRadii.rXl,
        border: Border.all(
          color: isPaid ? AppColors.mint500 : tokens.cardBorder,
          width: isPaid ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ACTIVE ENTITLEMENT',
                      style: theme.textTheme.labelSmall?.copyWith(
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.bold,
                        color:
                            isPaid ? tokens.onMintContainer : AppColors.navy500,
                      ),
                    ),
                    AppSpacing.gapH4,
                    Text(
                      entitlement.tier.displayName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isPaid
                            ? tokens.onMintContainer
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPaid ? AppColors.mint700 : AppColors.slate200,
                  borderRadius: AppRadii.rFull,
                ),
                child: Text(
                  entitlement.status.displayName,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isPaid ? Colors.white : AppColors.navy700,
                  ),
                ),
              ),
            ],
          ),
          if (entitlement.validUntil != null) ...[
            AppSpacing.gapH12,
            Text(
              'Term ends: ${entitlement.validUntil!.toLocal().toString().substring(0, 10)}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _PreReleaseNoticeCard extends StatelessWidget {
  const _PreReleaseNoticeCard({required this.isPaidCheckoutEnabled});
  final bool isPaidCheckoutEnabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isPaidCheckoutEnabled) return const SizedBox.shrink();

    return Container(
      padding: AppSpacing.pLg,
      decoration: BoxDecoration(
        color: AppColors.slate100,
        borderRadius: AppRadii.rLg,
        border: Border.all(color: AppColors.slate300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.navy700, size: 20),
          AppSpacing.gapW12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monetization Status: Pre-Release Free Access',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy900,
                  ),
                ),
                AppSpacing.gapH4,
                Text(
                  SubscriptionSafetyGate.preReleaseNotice,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.navy700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.isCheckoutEnabled,
  });

  final SubscriptionProduct product;
  final bool isCheckoutEnabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.rLg,
        side: BorderSide(color: tokens.cardBorder),
      ),
      child: Padding(
        padding: AppSpacing.pLg,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        product.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (product.freeTrialDays > 0) ...[
                        AppSpacing.gapW8,
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: tokens.mintContainer,
                            borderRadius: AppRadii.rSm,
                          ),
                          child: Text(
                            '${product.freeTrialDays}-Day Free Trial',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: tokens.onMintContainer,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  AppSpacing.gapH4,
                  Text(
                    product.description,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            AppSpacing.gapW16,
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  product.priceString,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                AppSpacing.gapH6,
                ElevatedButton(
                  onPressed: isCheckoutEnabled
                      ? () {
                          // Trigger verified in-app purchase flow
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                  ),
                  child: Text(isCheckoutEnabled ? 'Subscribe' : 'Locked'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureMatrixCard extends StatelessWidget {
  const _FeatureMatrixCard({required this.entitlement});
  final SubscriptionEntitlement entitlement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;

    final rows = [
      (SubscriptionFeature.standardGames, true),
      (SubscriptionFeature.dailyWorkout, true),
      (SubscriptionFeature.cloudSync, false),
      (SubscriptionFeature.deepAnalytics, false),
      (SubscriptionFeature.facultyDistribution, false),
      (SubscriptionFeature.prioritySupport, false),
    ];

    return Container(
      padding: AppSpacing.pLg,
      decoration: BoxDecoration(
        color: tokens.cardBackground,
        borderRadius: AppRadii.rXl,
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Entitlement Access Matrix',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          AppSpacing.gapH12,
          ...rows.map(
            (row) {
              final feature = row.$1;
              final freeIncluded = row.$2;
              final userHasAccess = entitlement.canAccess(feature);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      userHasAccess ? Icons.check_circle : Icons.lock_outline,
                      size: 18,
                      color:
                          userHasAccess ? AppColors.mint600 : AppColors.navy500,
                    ),
                    AppSpacing.gapW12,
                    Expanded(
                      child: Text(
                        feature.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: userHasAccess
                              ? theme.colorScheme.onSurface
                              : AppColors.navy500,
                        ),
                      ),
                    ),
                    Text(
                      freeIncluded ? 'Free Tier' : 'Plus Required',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: freeIncluded
                            ? AppColors.mint700
                            : AppColors.navy500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
