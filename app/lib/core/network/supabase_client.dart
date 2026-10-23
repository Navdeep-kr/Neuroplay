import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neuroplay/core/utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Initializes and exposes the Supabase client singleton.
abstract final class SupabaseConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Indicates whether actual Supabase production or staging credentials
  /// have been supplied at compile-time via `--dart-define`.
  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;

  /// Call once in `main()` before `runApp()`.
  static Future<void> initialize() async {
    if (!isConfigured) {
      AppLogger.warning(
        'SUPABASE_URL or SUPABASE_ANON_KEY not supplied. Application will operate with isolated local guest mode.',
        tag: 'SupabaseConfig',
      );
      return;
    }

    try {
      await Supabase.initialize(
        url: url,
        // ignore: deprecated_member_use
        anonKey: anonKey,
      );
      AppLogger.info('Supabase initialized successfully (PKCE flow active).');
    } on Object catch (e, st) {
      AppLogger.error(
        'Failed to initialize Supabase client: $e',
        tag: 'SupabaseConfig',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Safe accessor returning `SupabaseClient?` if initialized.
  static SupabaseClient? get clientOrNull {
    if (!isConfigured) return null;
    try {
      return Supabase.instance.client;
    } on Object {
      return null;
    }
  }

  /// Convenience accessor. Throws StateError if called when not configured.
  static SupabaseClient get client {
    final c = clientOrNull;
    if (c == null) {
      throw StateError(
        'Supabase is not configured. Provide SUPABASE_URL and SUPABASE_ANON_KEY.',
      );
    }
    return c;
  }
}

/// Provider for the SupabaseClient instance (nullable if not configured).
final supabaseClientProvider =
    Provider<SupabaseClient?>((ref) => SupabaseConfig.clientOrNull);
