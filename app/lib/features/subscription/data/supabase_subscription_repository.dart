import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:neuroplay/core/constants.dart';
import 'package:neuroplay/core/utils/logger.dart';
import 'package:neuroplay/features/auth/data/auth_repository.dart';
import 'package:neuroplay/features/subscription/data/local_subscription_repository.dart';
import 'package:neuroplay/features/subscription/data/subscription_repository.dart';
import 'package:neuroplay/features/subscription/domain/entitlement_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase cloud implementation of [ISubscriptionRepository].
///
/// Implements zero-trust entitlement verification: reads client-safe RLS
/// records and delegates receipt validation to secure database functions.
class SupabaseSubscriptionRepository implements ISubscriptionRepository {
  SupabaseSubscriptionRepository({
    required SupabaseClient client,
    required IAuthRepository authRepo,
  })  : _client = client,
        _authRepo = authRepo,
        _fallback = LocalSubscriptionRepository(authRepo: authRepo) {
    _entitlementController =
        StreamController<SubscriptionEntitlement>.broadcast(
      onListen: () {
        _entitlementController.add(
          _cachedEntitlement ??
              SubscriptionEntitlement.defaultFree(
                userId: _authRepo.currentUser.id,
              ),
        );
      },
    );

    _authSubscription = _authRepo.authStateChanges.listen((user) {
      if (!user.isAuthenticated) {
        _cachedEntitlement = SubscriptionEntitlement.defaultFree();
        _entitlementController.add(_cachedEntitlement!);
      } else {
        unawaited(getEntitlement(forceRefresh: true));
      }
    });
  }

  final SupabaseClient _client;
  final IAuthRepository _authRepo;
  final LocalSubscriptionRepository _fallback;

  late final StreamController<SubscriptionEntitlement> _entitlementController;
  StreamSubscription<dynamic>? _authSubscription;
  SubscriptionEntitlement? _cachedEntitlement;

  @override
  Future<SubscriptionEntitlement> getEntitlement({
    bool forceRefresh = false,
  }) async {
    final user = _authRepo.currentUser;
    if (!user.isAuthenticated || user.isGuest) {
      final free = SubscriptionEntitlement.defaultFree(userId: user.id);
      _cachedEntitlement = free;
      _entitlementController.add(free);
      return free;
    }

    // Return cached entitlement if valid and not forcing refresh
    if (!forceRefresh && _cachedEntitlement != null) {
      final now = DateTime.now().toUtc();
      if (!_cachedEntitlement!.isExpiredAt(now)) {
        return _cachedEntitlement!;
      }
    }

    try {
      final response = await _client
          .from(Tables.subscriptionEntitlements)
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (response == null) {
        final free = SubscriptionEntitlement.defaultFree(userId: user.id);
        _cachedEntitlement = free;
        _entitlementController.add(free);
        return free;
      }

      final entitlement = SubscriptionEntitlement.fromJson(response);

      // Verify expiration against current UTC clock
      final now = DateTime.now().toUtc();
      if (entitlement.isExpiredAt(now)) {
        AppLogger.info(
          'Subscription term ended at ${entitlement.validUntil}. Downgrading to Free tier.',
          tag: 'SubscriptionRepo',
        );
        final expired = entitlement.copyWith(
          status: SubscriptionStatus.expired,
          tier: SubscriptionTier.free,
          features: const [
            SubscriptionFeature.standardGames,
            SubscriptionFeature.dailyWorkout,
          ],
        );
        _cachedEntitlement = expired;
        _entitlementController.add(expired);
        return expired;
      }

      _cachedEntitlement = entitlement;
      _entitlementController.add(entitlement);
      return entitlement;
    } on Object catch (e) {
      AppLogger.warning(
        'Failed to query cloud subscription entitlement: $e. Checking offline cache.',
        tag: 'SubscriptionRepo',
      );

      // Handle offline expiration
      if (_cachedEntitlement != null) {
        final now = DateTime.now().toUtc();
        if (_cachedEntitlement!.isExpiredAt(now)) {
          final free = SubscriptionEntitlement.defaultFree(userId: user.id);
          _cachedEntitlement = free;
          _entitlementController.add(free);
          return free;
        }
        return _cachedEntitlement!;
      }

      return _fallback.getEntitlement();
    }
  }

  @override
  Stream<SubscriptionEntitlement> watchEntitlement() =>
      _entitlementController.stream;

  @override
  Future<RestoreResult> restorePurchases() async {
    final user = _authRepo.currentUser;
    if (!user.isAuthenticated || user.isGuest) {
      return RestoreResult.error(
        'You must be signed in with a registered account to restore cloud purchases.',
      );
    }

    try {
      // In production, this queries the native StoreKit/Google Play SDK for active transactions.
      // We pass the simulated or acquired store receipt token to the secure RPC function.
      final response = await _client.rpc<Map<String, dynamic>>(
        'verify_and_restore_subscription',
        params: {
          'p_provider': defaultTargetPlatform == TargetPlatform.iOS
              ? 'apple'
              : defaultTargetPlatform == TargetPlatform.android
                  ? 'google'
                  : 'stripe',
          'p_external_id': 'tx_${user.id.substring(0, 8)}',
          'p_requesting_user_id': user.id,
        },
      );

      final isSuccess = response['success'] as bool? ?? false;
      if (isSuccess) {
        final refreshed = await getEntitlement(forceRefresh: true);
        return RestoreResult.success(refreshed);
      }

      final reason = response['reason'] as String?;
      if (reason == 'OWNERSHIP_CONFLICT') {
        final maskedOwner =
            response['existing_owner_masked'] as String? ?? 'another user';
        return RestoreResult.ownershipConflict(maskedOwner: maskedOwner);
      }

      return RestoreResult.notFound();
    } on Object catch (e) {
      AppLogger.error('Failed to restore purchases: $e',
          tag: 'SubscriptionRepo');
      return RestoreResult.error(
          'Unable to reach verification server. Please retry later.');
    }
  }

  @override
  Future<Uri> getManagementUrl() => _fallback.getManagementUrl();

  @override
  List<SubscriptionProduct> getAvailableProducts() =>
      _fallback.getAvailableProducts();

  @override
  Future<void> clearCachedEntitlement() async {
    _cachedEntitlement = null;
    await _fallback.clearCachedEntitlement();
  }

  void dispose() {
    _authSubscription?.cancel();
    _entitlementController.close();
    _fallback.dispose();
  }
}
