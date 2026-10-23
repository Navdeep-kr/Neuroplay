import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neuroplay/core/exceptions/app_exception.dart';
import 'package:neuroplay/core/network/supabase_client.dart';
import 'package:neuroplay/core/utils/logger.dart';
import 'package:neuroplay/features/auth/data/auth_repository.dart';
import 'package:neuroplay/features/profile/domain/profile_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Contract for profile and preferences data operations.
abstract interface class IProfileRepository {
  Future<UserProfile> getProfile(String userId);
  Future<UserProfile> updateProfile(UserProfile profile);
  Future<void> completeOnboarding(String userId);
  Future<UserPreferences> getPreferences(String userId);
  Future<UserPreferences> updatePreferences(UserPreferences preferences);
}

/// Supabase-backed implementation of [IProfileRepository].
class SupabaseProfileRepository implements IProfileRepository {
  const SupabaseProfileRepository({sb.SupabaseClient? client})
      : _client = client;

  final sb.SupabaseClient? _client;

  @override
  Future<UserProfile> getProfile(String userId) async {
    if (userId.startsWith('guest') || _client == null) {
      return UserProfile.guest(id: userId);
    }

    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data == null) {
        // Fallback default if trigger has not completed or mock user
        return UserProfile(
          id: userId,
          email: _client.auth.currentUser?.email ?? '',
          fullName:
              _client.auth.currentUser?.userMetadata?['full_name'] as String?,
        );
      }

      return UserProfile.fromJson(data);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('PostgrestException fetching profile: ${e.message}');
      throw NetworkException('Failed to fetch user profile: ${e.message}', e);
    } catch (e, st) {
      AppLogger.error(
        'Unexpected error fetching profile',
        error: e,
        stackTrace: st,
      );
      throw NetworkException('Could not load profile.', e);
    }
  }

  @override
  Future<UserProfile> updateProfile(UserProfile profile) async {
    if (profile.id.startsWith('guest') || _client == null) {
      return profile;
    }

    try {
      final updated = await _client
          .from('profiles')
          .update(profile.toJson())
          .eq('id', profile.id)
          .select()
          .single();

      return UserProfile.fromJson(updated);
    } on sb.PostgrestException catch (e) {
      throw NetworkException('Failed to update profile: ${e.message}', e);
    } on Object catch (e) {
      throw NetworkException('Could not save profile updates.', e);
    }
  }

  @override
  Future<void> completeOnboarding(String userId) async {
    if (userId.startsWith('guest') || _client == null) return;

    try {
      await _client
          .from('profiles')
          .update({'onboarding_completed': true}).eq('id', userId);
    } on Object catch (e) {
      AppLogger.warning('Failed to persist onboarding status: $e');
    }
  }

  @override
  Future<UserPreferences> getPreferences(String userId) async {
    if (userId.startsWith('guest') || _client == null) {
      return UserPreferences.defaultPreferences(userId);
    }

    try {
      final data = await _client
          .from('user_preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (data == null) {
        return UserPreferences.defaultPreferences(userId);
      }

      return UserPreferences.fromJson(data);
    } on sb.PostgrestException catch (e) {
      AppLogger.warning('Postgrest error fetching preferences: ${e.message}');
      return UserPreferences.defaultPreferences(userId);
    } on Object catch (_) {
      return UserPreferences.defaultPreferences(userId);
    }
  }

  @override
  Future<UserPreferences> updatePreferences(UserPreferences preferences) async {
    if (preferences.userId.startsWith('guest') || _client == null) {
      return preferences;
    }

    try {
      final data = await _client
          .from('user_preferences')
          .upsert(preferences.toJson())
          .select()
          .single();

      return UserPreferences.fromJson(data);
    } on sb.PostgrestException catch (e) {
      throw NetworkException('Failed to save preferences: ${e.message}', e);
    } on Object catch (e) {
      throw NetworkException('Could not update preferences.', e);
    }
  }
}

/// Provider for the profile repository.
final profileRepositoryProvider = Provider<IProfileRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseProfileRepository(client: client);
});

/// Profile provider for the current user.
final userProfileProvider = FutureProvider<UserProfile>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (!user.isAuthenticated && !user.isGuest) {
    return UserProfile.guest();
  }
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getProfile(user.id);
});

/// Preferences provider for the current user.
final userPreferencesProvider = FutureProvider<UserPreferences>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (!user.isAuthenticated && !user.isGuest) {
    return UserPreferences.defaultPreferences('unauthenticated');
  }
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getPreferences(user.id);
});
