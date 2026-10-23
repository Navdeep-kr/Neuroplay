import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neuroplay/app/providers.dart';
import 'package:neuroplay/app/router.dart';
import 'package:neuroplay/core/theme/app_theme.dart';

/// Root application widget.
class NeuroplayApp extends ConsumerWidget {
  const NeuroplayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'NEUROPLAY',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}

/// Backward compatibility alias.
typedef NeuroplaApp = NeuroplayApp;
