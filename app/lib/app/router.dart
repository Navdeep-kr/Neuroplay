import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:neuroplay/app/shell.dart';
import 'package:neuroplay/core/constants.dart';
import 'package:neuroplay/features/auth/presentation/login_screen.dart';
import 'package:neuroplay/features/auth/presentation/register_screen.dart';
import 'package:neuroplay/features/challenges/presentation/challenges_screen.dart';
import 'package:neuroplay/features/games/presentation/games_library_screen.dart';
import 'package:neuroplay/features/home/presentation/home_screen.dart';
import 'package:neuroplay/features/profile/presentation/profile_screen.dart';
import 'package:neuroplay/features/progress/presentation/progress_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'rootNav');

final routerProvider = Provider<GoRouter>(
  (ref) => GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.home,
    routes: [
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
  ),
);
