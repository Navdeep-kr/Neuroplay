import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:neuroplay/features/auth/data/auth_repository.dart';
import 'package:neuroplay/features/auth/domain/auth_user.dart';
import 'package:neuroplay/features/subscription/data/local_subscription_repository.dart';
import 'package:neuroplay/features/subscription/domain/entitlement_models.dart';

class MockAuthRepository extends Mock implements IAuthRepository {}

void main() {
  group('LocalSubscriptionRepository Tests', () {
    late MockAuthRepository mockAuthRepo;
    late LocalSubscriptionRepository repository;

    setUp(() {
      mockAuthRepo = MockAuthRepository();
      when(() => mockAuthRepo.currentUser).thenReturn(
        const AuthUser(id: 'usr_test_1', status: AuthStatus.guest),
      );
      when(() => mockAuthRepo.authStateChanges).thenAnswer(
        (_) => Stream.value(
            const AuthUser(id: 'usr_test_1', status: AuthStatus.guest)),
      );
      repository = LocalSubscriptionRepository(authRepo: mockAuthRepo);
    });

    tearDown(() {
      repository.dispose();
    });

    test('Initializes with default Free Community tier for guest user',
        () async {
      final entitlement = await repository.getEntitlement();
      expect(entitlement.tier, SubscriptionTier.free);
      expect(entitlement.isFree, isTrue);
      expect(entitlement.status, SubscriptionStatus.active);
      expect(entitlement.canAccess(SubscriptionFeature.standardGames), isTrue);
      expect(entitlement.canAccess(SubscriptionFeature.cloudSync), isFalse);
    });

    test('Expired simulated entitlement automatically downgrades to Free tier',
        () async {
      final expiredPro = SubscriptionEntitlement(
        userId: 'usr_test_1',
        tier: SubscriptionTier.pro,
        status: SubscriptionStatus.active,
        features: const [
          SubscriptionFeature.standardGames,
          SubscriptionFeature.dailyWorkout,
          SubscriptionFeature.cloudSync,
        ],
        validUntil: DateTime.now().toUtc().subtract(const Duration(minutes: 5)),
      );

      repository.debugSetEntitlement(expiredPro);

      final result = await repository.getEntitlement();
      expect(result.tier, SubscriptionTier.free);
      expect(result.isFree, isTrue);
      expect(result.canAccess(SubscriptionFeature.cloudSync), isFalse);
    });

    test('Available products catalog returns monthly and annual tiers', () {
      final products = repository.getAvailableProducts();
      expect(products.length, 2);
      expect(products.first.id, 'app.neuroplay.plus.monthly');
      expect(products.last.id, 'app.neuroplay.plus.annual');
      expect(products.last.freeTrialDays, 14);
    });

    test('Produces valid subscription management URL', () async {
      final url = await repository.getManagementUrl();
      expect(url.toString(), startsWith('https://'));
    });

    test('Restore purchases returns notFound cleanly in guest mode', () async {
      final result = await repository.restorePurchases();
      expect(result.isSuccess, isFalse);
      expect(result.conflictReason, 'NO_ACTIVE_SUBSCRIPTION_FOUND');
    });
  });
}
