import 'package:flutter_test/flutter_test.dart';
import 'package:neuroplay/features/subscription/domain/entitlement_models.dart';

void main() {
  group('SubscriptionEntitlement Domain Unit Tests', () {
    test('Default free tier grants core exercises and daily workout independently of billing', () {
      final free = SubscriptionEntitlement.defaultFree();

      expect(free.isFree, isTrue);
      expect(free.isPaidActive, isFalse);
      expect(free.tier, SubscriptionTier.free);
      expect(free.status, SubscriptionStatus.active);

      // Core brain training is always accessible on free tier
      expect(free.canAccess(SubscriptionFeature.standardGames), isTrue);
      expect(free.canAccess(SubscriptionFeature.dailyWorkout), isTrue);

      // Advanced tier features are not accessible on free tier
      expect(free.canAccess(SubscriptionFeature.cloudSync), isFalse);
      expect(free.canAccess(SubscriptionFeature.deepAnalytics), isFalse);
      expect(free.canAccess(SubscriptionFeature.facultyDistribution), isFalse);
    });

    test('Active Pro tier grants all features within valid expiration window', () {
      final pro = SubscriptionEntitlement(
        userId: 'user_123',
        tier: SubscriptionTier.pro,
        status: SubscriptionStatus.active,
        features: const [
          SubscriptionFeature.standardGames,
          SubscriptionFeature.dailyWorkout,
          SubscriptionFeature.cloudSync,
          SubscriptionFeature.deepAnalytics,
          SubscriptionFeature.facultyDistribution,
          SubscriptionFeature.prioritySupport,
        ],
        validUntil: DateTime.now().toUtc().add(const Duration(days: 30)),
        autoRenew: true,
        provider: BillingProvider.apple,
        externalSubscriptionId: 'sub_apple_999',
      );

      expect(pro.isFree, isFalse);
      expect(pro.isPaidActive, isTrue);
      expect(pro.canAccess(SubscriptionFeature.standardGames), isTrue);
      expect(pro.canAccess(SubscriptionFeature.dailyWorkout), isTrue);
      expect(pro.canAccess(SubscriptionFeature.cloudSync), isTrue);
      expect(pro.canAccess(SubscriptionFeature.deepAnalytics), isTrue);
      expect(pro.canAccess(SubscriptionFeature.facultyDistribution), isTrue);
      expect(pro.canAccess(SubscriptionFeature.prioritySupport), isTrue);
      expect(pro.canAccess(SubscriptionFeature.familySharing), isFalse);
    });

    test('Expired Pro tier cleanly revokes premium features without blocking core games', () {
      final expiredPro = SubscriptionEntitlement(
        userId: 'user_expired',
        tier: SubscriptionTier.pro,
        status: SubscriptionStatus.expired,
        features: const [
          SubscriptionFeature.standardGames,
          SubscriptionFeature.dailyWorkout,
          SubscriptionFeature.cloudSync,
        ],
        validUntil: DateTime.now().toUtc().subtract(const Duration(days: 2)),
      );

      final now = DateTime.now().toUtc();
      expect(expiredPro.isExpiredAt(now), isTrue);
      expect(expiredPro.isPaidActive, isFalse);

      // Core games must still work
      expect(expiredPro.canAccess(SubscriptionFeature.standardGames), isTrue);
      expect(expiredPro.canAccess(SubscriptionFeature.dailyWorkout), isTrue);

      // Premium features must be rejected
      expect(expiredPro.canAccess(SubscriptionFeature.cloudSync), isFalse);
    });

    test('Past-due status within grace period preserves access while retrying payment', () {
      final gracePro = SubscriptionEntitlement(
        userId: 'user_grace',
        tier: SubscriptionTier.pro,
        status: SubscriptionStatus.pastDue,
        features: const [
          SubscriptionFeature.standardGames,
          SubscriptionFeature.dailyWorkout,
          SubscriptionFeature.cloudSync,
        ],
        validUntil: DateTime.now().toUtc().add(const Duration(days: 7)),
      );

      expect(gracePro.isPaidActive, isTrue);
      expect(gracePro.canAccess(SubscriptionFeature.cloudSync), isTrue);
    });

    test('JSON serialization and deserialization roundtrip accurately', () {
      final original = SubscriptionEntitlement(
        userId: 'user_roundtrip',
        tier: SubscriptionTier.pro,
        status: SubscriptionStatus.trialing,
        features: const [
          SubscriptionFeature.standardGames,
          SubscriptionFeature.dailyWorkout,
          SubscriptionFeature.cloudSync,
        ],
        validUntil: DateTime.utc(2026, 12, 31, 23, 59, 59),
        autoRenew: true,
        provider: BillingProvider.google,
        externalSubscriptionId: 'g_sub_456',
        cachedAt: DateTime.utc(2026, 10, 24, 12),
      );

      final json = original.toJson();
      final restored = SubscriptionEntitlement.fromJson(json);

      expect(restored.userId, original.userId);
      expect(restored.tier, original.tier);
      expect(restored.status, original.status);
      expect(restored.features, original.features);
      expect(restored.validUntil, original.validUntil);
      expect(restored.autoRenew, original.autoRenew);
      expect(restored.provider, original.provider);
      expect(restored.externalSubscriptionId, original.externalSubscriptionId);
    });

    test('Production Safety Gate keeps paid checkout disabled by default', () {
      expect(SubscriptionSafetyGate.enablePaidCheckout, isFalse);
      expect(SubscriptionSafetyGate.preReleaseNotice, contains('pre-release'));
    });

    test('RestoreResult models success, notFound, and ownershipConflict', () {
      final success = RestoreResult.success(SubscriptionEntitlement.defaultFree());
      expect(success.isSuccess, isTrue);

      final notFound = RestoreResult.notFound();
      expect(notFound.isSuccess, isFalse);
      expect(notFound.conflictReason, 'NO_ACTIVE_SUBSCRIPTION_FOUND');

      final conflict = RestoreResult.ownershipConflict(maskedOwner: 'abc12345...');
      expect(conflict.isSuccess, isFalse);
      expect(conflict.conflictReason, 'OWNERSHIP_CONFLICT');
      expect(conflict.errorMessage, contains('abc12345...'));
    });
  });
}
