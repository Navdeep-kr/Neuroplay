import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:neuroplay/app/shell.dart';
import 'package:neuroplay/core/constants.dart';
import 'package:neuroplay/features/auth/data/auth_repository.dart';
import 'package:neuroplay/features/auth/presentation/forgot_password_screen.dart';
import 'package:neuroplay/features/auth/presentation/login_screen.dart';
import 'package:neuroplay/features/auth/presentation/onboarding_screen.dart';
import 'package:neuroplay/features/auth/presentation/register_screen.dart';
import 'package:neuroplay/features/challenges/presentation/challenges_screen.dart';
import 'package:neuroplay/features/games/presentation/focus_reactor/focus_reactor_screen.dart';
import 'package:neuroplay/features/games/presentation/games_library_screen.dart';
import 'package:neuroplay/features/games/presentation/logic_labyrinth/logic_labyrinth_screen.dart';
import 'package:neuroplay/features/games/presentation/memory_matrix/memory_matrix_screen.dart';
import 'package:neuroplay/features/games/presentation/number_pulse/number_pulse_screen.dart';
import 'package:neuroplay/features/games/presentation/reflex_forge/reflex_forge_screen.dart';
import 'package:neuroplay/features/games/presentation/word_weaver/word_weaver_screen.dart';
import 'package:neuroplay/features/home/presentation/home_screen.dart';
import 'package:neuroplay/features/profile/presentation/profile_screen.dart';
import 'package:neuroplay/features/progress/presentation/progress_screen.dart';
import 'package:neuroplay/features/subscription/presentation/subscription_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'rootNav');

/// Listenable adapter converting auth stream transitions into GoRouter refresh events.
class AuthRouterListenable extends ChangeNotifier {
  AuthRouterListenable(IAuthRepository repo) {
    _subscription = repo.authStateChanges.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final authRouterListenableProvider = Provider<AuthRouterListenable>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  final listenable = AuthRouterListenable(repo);
  ref.onDispose(listenable.dispose);
  return listenable;
});

final routerProvider = Provider<GoRouter>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  final refreshListenable = ref.watch(authRouterListenableProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.home,
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final user = authRepo.currentUser;
      final location = state.uri.path;

      final isAuthRoute = location == AppRoutes.login ||
          location == AppRoutes.register ||
          location == AppRoutes.forgotPassword;

      // If user is actively authenticated with cloud session and tries to visit login/register,
      // redirect them back into the main app dashboard
      if (user.isAuthenticated && isAuthRoute) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.memoryMatrix,
        name: 'memory-matrix',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MemoryMatrixScreen(),
      ),
      GoRoute(
        path: AppRoutes.reflexForge,
        name: 'reflex-forge',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ReflexForgeScreen(),
      ),
      GoRoute(
        path: AppRoutes.focusReactor,
        name: 'focus-reactor',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const FocusReactorScreen(),
      ),
      GoRoute(
        path: AppRoutes.logicLabyrinth,
        name: 'logic-labyrinth',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LogicLabyrinthScreen(),
      ),
      GoRoute(
        path: AppRoutes.numberPulse,
        name: 'number-pulse',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NumberPulseScreen(),
      ),
      GoRoute(
        path: AppRoutes.wordWeaver,
        name: 'word-weaver',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const WordWeaverScreen(),
      ),
      GoRoute(
        path: AppRoutes.subscription,
        name: 'subscription',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                name: 'home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.games,
                name: 'games',
                builder: (context, state) => const GamesLibraryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.progress,
                name: 'progress',
                builder: (context, state) => const ProgressScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.challenges,
                name: 'challenges',
                builder: (context, state) => const ChallengesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                name: 'profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
