import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:neuroplay/features/auth/data/auth_repository.dart';
import 'package:neuroplay/features/auth/domain/auth_user.dart';
import 'package:neuroplay/features/subscription/data/subscription_repository.dart';
import 'package:neuroplay/features/subscription/domain/entitlement_models.dart';
import 'package:neuroplay/features/subscription/presentation/subscription_screen.dart';

class MockSubscriptionRepository extends Mock
    implements ISubscriptionRepository {}

class MockAuthRepository extends Mock implements IAuthRepository {}

void main() {
  group('SubscriptionScreen Widget Tests', () {
    late MockSubscriptionRepository mockSubRepo;
    late MockAuthRepository mockAuthRepo;

    setUp(() {
      mockSubRepo = MockSubscriptionRepository();
      mockAuthRepo = MockAuthRepository();

      when(() => mockAuthRepo.currentUser).thenReturn(
        const AuthUser(id: 'usr_screen_test', status: AuthStatus.guest),
      );
      when(() => mockAuthRepo.authStateChanges).thenAnswer(
        (_) => Stream.value(
          const AuthUser(id: 'usr_screen_test', status: AuthStatus.guest),
        ),
      );

      when(
        () => mockSubRepo.getEntitlement(
          forceRefresh: any(named: 'forceRefresh'),
        ),
      ).thenAnswer((_) async => SubscriptionEntitlement.defaultFree());

      when(() => mockSubRepo.watchEntitlement()).thenAnswer(
        (_) => Stream.value(SubscriptionEntitlement.defaultFree()),
      );

      when(() => mockSubRepo.getAvailableProducts()).thenReturn(const [
        SubscriptionProduct(
          id: 'app.neuroplay.plus.monthly',
          tier: SubscriptionTier.pro,
          title: 'NEUROPLAY Plus (Monthly)',
          description: 'Full cloud synchronization and deep analytics.',
          priceString: r'$4.99 / month',
          periodMonths: 1,
        ),
      ]);

      when(() => mockSubRepo.getManagementUrl()).thenAnswer(
        (_) async => Uri.parse('https://apps.apple.com/account/subscriptions'),
      );

      when(() => mockSubRepo.restorePurchases()).thenAnswer(
        (_) async => RestoreResult.notFound(),
      );
    });

    Widget createTestWidget() => ProviderScope(
          overrides: [
            subscriptionRepositoryProvider.overrideWithValue(mockSubRepo),
            authRepositoryProvider.overrideWithValue(mockAuthRepo),
          ],
          child: const MaterialApp(
            home: SubscriptionScreen(),
          ),
        );

    testWidgets(
        'Renders subscription screen headers, pre-release banner, and feature matrix',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Subscription & Entitlements'), findsOneWidget);
      expect(find.text('ACTIVE ENTITLEMENT'), findsOneWidget);
      expect(find.text('Free Community'), findsOneWidget);

      // Verify Pre-Release Banner
      expect(
        find.text('Monetization Status: Pre-Release Free Access'),
        findsOneWidget,
      );

      // Verify Product Card
      expect(find.text('NEUROPLAY Plus (Monthly)'), findsOneWidget);
      expect(
        find.text('Locked'),
        findsOneWidget,
      ); // Because paid checkout is disabled

      // Verify Feature Matrix
      expect(find.text('Entitlement Access Matrix'), findsOneWidget);
      expect(
        find.text('Access to all 6 core cognitive exercises'),
        findsOneWidget,
      );
      expect(find.text('Cross-device cloud synchronization'), findsOneWidget);

      // Verify Action Buttons
      expect(find.text('Restore Purchases'), findsOneWidget);
      expect(find.text('Manage Billing'), findsOneWidget);
    });

    testWidgets('Tapping Manage Billing opens platform instructions dialog',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final manageButton = find.text('Manage Billing');
      expect(manageButton, findsOneWidget);
      await tester.tap(manageButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Manage Subscription'), findsOneWidget);
      expect(
        find.textContaining('https://apps.apple.com/account/subscriptions'),
        findsOneWidget,
      );

      final closeButton = find.text('Close');
      await tester.tap(closeButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Manage Subscription'), findsNothing);
    });

    testWidgets(
        'Tapping Restore Purchases triggers restore action and displays feedback',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final restoreButton = find.text('Restore Purchases');
      expect(restoreButton, findsOneWidget);
      await tester.tap(restoreButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockSubRepo.restorePurchases()).called(1);
      expect(
        find.text('No active subscription was found for this store account.'),
        findsOneWidget,
      );
    });
  });
}
