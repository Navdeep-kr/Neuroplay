import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:neuroplay/features/auth/data/auth_repository.dart';
import 'package:neuroplay/features/subscription/data/subscription_repository.dart';
import 'package:neuroplay/features/subscription/domain/entitlement_models.dart';

/// Local in-memory and guest-mode implementation of [ISubscriptionRepository].
///
/// Ensures free access works 100% independently of network connectivity,
/// Supabase credentials, or store accounts.
class LocalSubscriptionRepository implements ISubscriptionRepository {
  LocalSubscriptionRepository({
    required IAuthRepository authRepo,
  }) : _authRepo = authRepo {
    _entitlementController =
        StreamController<SubscriptionEntitlement>.broadcast(
      onListen: () {
        _entitlementController.add(_currentEntitlement);
      },
    );

    // Synchronize entitlement state with auth state changes
    _authSubscription = _authRepo.authStateChanges.listen((user) {
      if (!user.isAuthenticated && !user.isGuest) {
        _currentEntitlement = SubscriptionEntitlement.defaultFree();
      } else {
        _currentEntitlement =
            SubscriptionEntitlement.defaultFree(userId: user.id);
      }
      _entitlementController.add(_currentEntitlement);
    });
  }

  final IAuthRepository _authRepo;
  late final StreamController<SubscriptionEntitlement> _entitlementController;
  StreamSubscription<dynamic>? _authSubscription;

  late SubscriptionEntitlement _currentEntitlement =
      SubscriptionEntitlement.defaultFree(userId: _authRepo.currentUser.id);

  static const List<SubscriptionProduct> _catalog = [
    SubscriptionProduct(
      id: 'app.neuroplay.plus.monthly',
      tier: SubscriptionTier.pro,
      title: 'NEUROPLAY Plus (Monthly)',
      description:
          'Full cloud synchronization, longitudinal analytics, and index distribution.',
      priceString: r'$4.99 / month',
      periodMonths: 1,
    ),
    SubscriptionProduct(
      id: 'app.neuroplay.plus.annual',
      tier: SubscriptionTier.pro,
      title: 'NEUROPLAY Plus (Annual)',
      description:
          'Annual training pass with 14-day free trial and ~33% savings.',
      priceString: r'$39.99 / year',
      periodMonths: 12,
      freeTrialDays: 14,
    ),
  ];

  @override
  Future<SubscriptionEntitlement> getEntitlement({
    bool forceRefresh = false,
  }) async {
    // Check if current cached entitlement has expired
    final now = DateTime.now().toUtc();
    if (_currentEntitlement.isExpiredAt(now)) {
      _currentEntitlement = SubscriptionEntitlement.defaultFree(
        userId: _authRepo.currentUser.id,
      );
      _entitlementController.add(_currentEntitlement);
    }
    return _currentEntitlement;
  }

  @override
  Stream<SubscriptionEntitlement> watchEntitlement() =>
      _entitlementController.stream;

  @override
  Future<RestoreResult> restorePurchases() async => RestoreResult.notFound();

  @override
  Future<Uri> getManagementUrl() async {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return Uri.parse('https://apps.apple.com/account/subscriptions');
      case TargetPlatform.android:
        return Uri.parse(
          'https://play.google.com/store/account/subscriptions?sku=app.neuroplay.plus.monthly&package=com.neuroplay.app',
        );
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return Uri.parse('https://neuroplay.app/subscription-disclosures');
    }
  }

  @override
  List<SubscriptionProduct> getAvailableProducts() => _catalog;

  @override
  Future<void> clearCachedEntitlement() async {
    _currentEntitlement = SubscriptionEntitlement.defaultFree(
      userId: _authRepo.currentUser.id,
    );
    _entitlementController.add(_currentEntitlement);
  }

  /// Testing helper to set simulated entitlement state.
  @visibleForTesting
  void debugSetEntitlement(SubscriptionEntitlement entitlement) {
    _currentEntitlement = entitlement;
    _entitlementController.add(_currentEntitlement);
  }

  void dispose() {
    _authSubscription?.cancel();
    _entitlementController.close();
  }
}
