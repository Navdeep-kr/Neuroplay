import 'package:equatable/equatable.dart';

/// Available subscription entitlement tiers.
enum SubscriptionTier {
  free,
  pro,
  family,
  lifetime;

  String get displayName => switch (this) {
        free => 'Free Community',
        pro => 'NEUROPLAY Plus',
        family => 'NEUROPLAY Family',
        lifetime => 'NEUROPLAY Lifetime',
      };
}

/// Lifecycle status of an entitlement.
enum SubscriptionStatus {
  active,
  trialing,
  pastDue,
  canceled,
  expired;

  String get displayName => switch (this) {
        active => 'Active',
        trialing => 'Trialing',
        pastDue => 'Payment Retry (Grace Period)',
        canceled => 'Canceled (Active until term end)',
        expired => 'Expired',
      };
}

/// Originating billing provider.
enum BillingProvider {
  apple,
  google,
  stripe,
  manual;

  String get displayName => switch (this) {
        apple => 'Apple App Store',
        google => 'Google Play Store',
        stripe => 'Web (Stripe)',
        manual => 'Direct / Developer',
      };
}

/// Feature flags governed by entitlement tiers.
enum SubscriptionFeature {
  standardGames('standard_games', 'Access to all 6 core cognitive exercises'),
  dailyWorkout('daily_workout', 'Daily 3-game workout generation'),
  cloudSync('cloud_sync', 'Cross-device cloud synchronization'),
  deepAnalytics(
      'deep_analytics', 'Multi-year reaction time and accuracy analytics'),
  facultyDistribution(
      'faculty_distribution', 'Deep cognitive faculty index breakdown'),
  prioritySupport(
      'priority_support', 'Priority technical and accessibility support'),
  familySharing('family_sharing', 'Family sharing access for up to 5 members');

  const SubscriptionFeature(this.key, this.description);
  final String key;
  final String description;

  static SubscriptionFeature? fromKey(String key) {
    for (final f in values) {
      if (f.key == key) return f;
    }
    return null;
  }
}

/// Comprehensive, typed entitlement contract with zero-trust validation.
class SubscriptionEntitlement extends Equatable {
  const SubscriptionEntitlement({
    required this.userId,
    required this.tier,
    required this.status,
    required this.features,
    this.validUntil,
    this.autoRenew = false,
    this.provider = BillingProvider.manual,
    this.externalSubscriptionId,
    this.cachedAt,
  });

  /// Default baseline entitlement for guest or free accounts.
  factory SubscriptionEntitlement.defaultFree({String userId = 'guest'}) =>
      SubscriptionEntitlement(
        userId: userId,
        tier: SubscriptionTier.free,
        status: SubscriptionStatus.active,
        features: const [
          SubscriptionFeature.standardGames,
          SubscriptionFeature.dailyWorkout,
        ],
        cachedAt: DateTime.now().toUtc(),
      );

  factory SubscriptionEntitlement.fromJson(Map<String, dynamic> json) {
    final rawTier = json['tier'] as String? ?? 'free';
    final tier = SubscriptionTier.values.firstWhere(
      (t) => t.name.toLowerCase() == rawTier.toLowerCase(),
      orElse: () => SubscriptionTier.free,
    );

    final rawStatus = json['status'] as String? ?? 'active';
    final status = SubscriptionStatus.values.firstWhere(
      (s) =>
          s.name.toLowerCase() == rawStatus.replaceAll('_', '').toLowerCase(),
      orElse: () => SubscriptionStatus.active,
    );

    final rawProvider = json['provider'] as String? ?? 'manual';
    final provider = BillingProvider.values.firstWhere(
      (p) => p.name.toLowerCase() == rawProvider.toLowerCase(),
      orElse: () => BillingProvider.manual,
    );

    final rawFeatures = json['features'] as List<dynamic>? ?? [];
    final features = rawFeatures
        .map((f) => SubscriptionFeature.fromKey(f.toString()))
        .whereType<SubscriptionFeature>()
        .toList();

    DateTime? validUntil;
    if (json['valid_until'] != null) {
      validUntil = DateTime.tryParse(json['valid_until'].toString())?.toUtc();
    }

    DateTime? cachedAt;
    if (json['cached_at'] != null) {
      cachedAt = DateTime.tryParse(json['cached_at'].toString())?.toUtc();
    }

    return SubscriptionEntitlement(
      userId: json['user_id'] as String? ?? 'unknown',
      tier: tier,
      status: status,
      features: features.isEmpty
          ? const [
              SubscriptionFeature.standardGames,
              SubscriptionFeature.dailyWorkout
            ]
          : features,
      validUntil: validUntil,
      autoRenew: json['auto_renew'] as bool? ?? false,
      provider: provider,
      externalSubscriptionId: json['external_subscription_id'] as String?,
      cachedAt: cachedAt,
    );
  }

  final String userId;
  final SubscriptionTier tier;
  final SubscriptionStatus status;
  final List<SubscriptionFeature> features;
  final DateTime? validUntil;
  final bool autoRenew;
  final BillingProvider provider;
  final String? externalSubscriptionId;
  final DateTime? cachedAt;

  /// Whether this entitlement represents the free baseline tier.
  bool get isFree => tier == SubscriptionTier.free;

  /// Checks if the subscription term has elapsed.
  bool isExpiredAt(DateTime referenceTime) {
    if (tier == SubscriptionTier.lifetime) return false;
    if (validUntil == null) return false;
    return referenceTime.toUtc().isAfter(validUntil!);
  }

  /// Whether the user currently holds active paid access.
  bool get isPaidActive {
    if (isFree) return false;
    final now = DateTime.now().toUtc();
    if (isExpiredAt(now)) return false;
    return status == SubscriptionStatus.active ||
        status == SubscriptionStatus.trialing ||
        status == SubscriptionStatus.pastDue ||
        status == SubscriptionStatus.canceled;
  }

  /// Evaluates feature permission using zero-trust rules.
  bool canAccess(SubscriptionFeature feature) {
    // Core brain-training games & daily workouts are always free
    if (feature == SubscriptionFeature.standardGames ||
        feature == SubscriptionFeature.dailyWorkout) {
      return true;
    }

    // Premium features require a non-expired active entitlement
    if (!isPaidActive) return false;
    return features.contains(feature);
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'tier': tier.name,
        'status': status.name,
        'features': features.map((f) => f.key).toList(),
        'valid_until': validUntil?.toIso8601String(),
        'auto_renew': autoRenew,
        'provider': provider.name,
        'external_subscription_id': externalSubscriptionId,
        'cached_at': cachedAt?.toIso8601String(),
      };

  SubscriptionEntitlement copyWith({
    String? userId,
    SubscriptionTier? tier,
    SubscriptionStatus? status,
    List<SubscriptionFeature>? features,
    DateTime? validUntil,
    bool? autoRenew,
    BillingProvider? provider,
    String? externalSubscriptionId,
    DateTime? cachedAt,
  }) =>
      SubscriptionEntitlement(
        userId: userId ?? this.userId,
        tier: tier ?? this.tier,
        status: status ?? this.status,
        features: features ?? this.features,
        validUntil: validUntil ?? this.validUntil,
        autoRenew: autoRenew ?? this.autoRenew,
        provider: provider ?? this.provider,
        externalSubscriptionId:
            externalSubscriptionId ?? this.externalSubscriptionId,
        cachedAt: cachedAt ?? this.cachedAt,
      );

  @override
  List<Object?> get props => [
        userId,
        tier,
        status,
        features,
        validUntil,
        autoRenew,
        provider,
        externalSubscriptionId,
        cachedAt,
      ];
}

/// Catalog product definitions for subscriptions.
class SubscriptionProduct extends Equatable {
  const SubscriptionProduct({
    required this.id,
    required this.tier,
    required this.title,
    required this.description,
    required this.priceString,
    required this.periodMonths,
    this.freeTrialDays = 0,
  });

  final String id;
  final SubscriptionTier tier;
  final String title;
  final String description;
  final String priceString;
  final int periodMonths;
  final int freeTrialDays;

  @override
  List<Object?> get props => [
        id,
        tier,
        title,
        description,
        priceString,
        periodMonths,
        freeTrialDays,
      ];
}

/// Outcome of a restore purchases invocation.
class RestoreResult extends Equatable {
  const RestoreResult({
    required this.isSuccess,
    this.entitlement,
    this.conflictReason,
    this.errorMessage,
  });

  factory RestoreResult.success(SubscriptionEntitlement entitlement) =>
      RestoreResult(isSuccess: true, entitlement: entitlement);

  factory RestoreResult.notFound() => const RestoreResult(
        isSuccess: false,
        conflictReason: 'NO_ACTIVE_SUBSCRIPTION_FOUND',
        errorMessage:
            'No active subscription was found for this store account.',
      );

  factory RestoreResult.ownershipConflict({required String maskedOwner}) =>
      RestoreResult(
        isSuccess: false,
        conflictReason: 'OWNERSHIP_CONFLICT',
        errorMessage:
            'This subscription is linked to another NEUROPLAY account ($maskedOwner). Please log in with that account.',
      );

  factory RestoreResult.error(String message) => RestoreResult(
        isSuccess: false,
        errorMessage: message,
      );

  final bool isSuccess;
  final SubscriptionEntitlement? entitlement;
  final String? conflictReason;
  final String? errorMessage;

  @override
  List<Object?> get props => [
        isSuccess,
        entitlement,
        conflictReason,
        errorMessage,
      ];
}

/// Production safety lock ensuring paid checkouts remain disabled until
/// commercial store verification and merchant compliance are finalized.
abstract final class SubscriptionSafetyGate {
  /// Compile-time safety flag: default false in pre-release.
  static const bool enablePaidCheckout =
      bool.fromEnvironment('ENABLE_PAID_CHECKOUT');

  /// Human-readable explanation of current monetization status.
  static const String preReleaseNotice =
      'NEUROPLAY is currently operating in pre-release mode with zero monetization. All cognitive exercises and daily routines are 100% free.';
}
