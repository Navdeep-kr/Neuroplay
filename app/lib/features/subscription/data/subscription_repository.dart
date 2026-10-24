import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neuroplay/core/network/supabase_client.dart';
import 'package:neuroplay/features/auth/data/auth_repository.dart';
import 'package:neuroplay/features/subscription/data/local_subscription_repository.dart';
import 'package:neuroplay/features/subscription/data/supabase_subscription_repository.dart';
import 'package:neuroplay/features/subscription/domain/entitlement_models.dart';

/// Contract for subscription entitlement queries, purchase restores,
/// and management portals.
abstract interface class ISubscriptionRepository {
  /// Fetches current entitlement, using secure offline cache when network is unavailable.
  Future<SubscriptionEntitlement> getEntitlement({bool forceRefresh = false});

  /// Broadcast stream of entitlement transitions.
  Stream<SubscriptionEntitlement> watchEntitlement();

  /// Restores native store purchases (Apple StoreKit 2 / Google Play Billing).
  Future<RestoreResult> restorePurchases();

  /// Produces the platform-specific deep-link for subscription cancellation/management.
  Future<Uri> getManagementUrl();

  /// Catalog of available subscription tiers.
  List<SubscriptionProduct> getAvailableProducts();

  /// Wipes user-specific cached entitlements on logout.
  Future<void> clearCachedEntitlement();
}

/// Active subscription repository provider (switches to Supabase when configured).
final subscriptionRepositoryProvider = Provider<ISubscriptionRepository>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  final client = SupabaseConfig.clientOrNull;

  if (client == null) {
    return LocalSubscriptionRepository(authRepo: authRepo);
  }

  return SupabaseSubscriptionRepository(
    client: client,
    authRepo: authRepo,
  );
});

/// Reactive stream of the user's current subscription entitlement.
final subscriptionEntitlementProvider =
    StreamProvider<SubscriptionEntitlement>((ref) {
  final repo = ref.watch(subscriptionRepositoryProvider);
  return repo.watchEntitlement();
});

/// Available subscription products catalog provider.
final subscriptionProductsProvider = Provider<List<SubscriptionProduct>>((ref) {
  final repo = ref.watch(subscriptionRepositoryProvider);
  return repo.getAvailableProducts();
});

/// Safety gate provider: indicates whether paid checkout is unlocked.
final isPaidCheckoutEnabledProvider = Provider<bool>(
  (ref) => SubscriptionSafetyGate.enablePaidCheckout,
);
