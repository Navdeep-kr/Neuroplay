import 'package:supabase_flutter/supabase_flutter.dart';

/// Initializes and exposes the Supabase client singleton.
abstract final class SupabaseConfig {
  /// Call once in `main()` before `runApp()`.
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: const String.fromEnvironment('SUPABASE_URL'),
      publishableKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
    );
  }

  /// Convenience accessor for the Supabase client instance.
  static SupabaseClient get client => Supabase.instance.client;
}
