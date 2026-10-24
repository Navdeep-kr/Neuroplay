import 'package:equatable/equatable.dart';

/// User profile record representing identity and onboarding progression.
class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    required this.email,
    this.fullName,
    this.username,
    this.avatarUrl,
    this.onboardingCompleted = false,
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.guest({String id = 'guest-local-user'}) => UserProfile(
        id: id,
        email: 'guest@neuroplay.local',
        fullName: 'Guest Explorer',
        username: 'guest',
        onboardingCompleted: true,
      );

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        email: json['email'] as String? ?? '',
        fullName: json['full_name'] as String?,
        username: json['username'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at'] as String)
            : null,
      );

  final String id;
  final String email;
  final String? fullName;
  final String? username;
  final String? avatarUrl;
  final bool onboardingCompleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get displayName => (fullName?.trim().isNotEmpty ?? false)
      ? fullName!
      : (username ?? email.split('@').first);

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'username': username,
        'avatar_url': avatarUrl,
        'onboarding_completed': onboardingCompleted,
      };

  UserProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    String? username,
    String? avatarUrl,
    bool? onboardingCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      UserProfile(
        id: id ?? this.id,
        email: email ?? this.email,
        fullName: fullName ?? this.fullName,
        username: username ?? this.username,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  List<Object?> get props => [
        id,
        email,
        fullName,
        username,
        avatarUrl,
        onboardingCompleted,
        createdAt,
        updatedAt,
      ];
}

/// User device & sensory preferences.
class UserPreferences extends Equatable {
  const UserPreferences({
    required this.userId,
    this.themeMode = 'system',
    this.soundEnabled = true,
    this.hapticsEnabled = true,
    this.dailyReminderEnabled = false,
    this.reminderTime = '09:00',
    this.preferredDifficulty = 'auto',
    this.reducedMotion = false,
    this.languageCode = 'en',
    this.createdAt,
    this.updatedAt,
  });

  factory UserPreferences.defaultPreferences(String userId) => UserPreferences(
        userId: userId,
      );

  factory UserPreferences.fromJson(Map<String, dynamic> json) =>
      UserPreferences(
        userId: json['user_id'] as String,
        themeMode: json['theme_mode'] as String? ?? 'system',
        soundEnabled: json['sound_enabled'] as bool? ?? true,
        hapticsEnabled: json['haptics_enabled'] as bool? ?? true,
        dailyReminderEnabled: json['daily_reminder_enabled'] as bool? ?? false,
        reminderTime: json['reminder_time'] as String? ?? '09:00',
        preferredDifficulty: json['preferred_difficulty'] as String? ?? 'auto',
        reducedMotion: json['reduced_motion'] as bool? ?? false,
        languageCode: json['language_code'] as String? ?? 'en',
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at'] as String)
            : null,
      );

  final String userId;
  final String themeMode; // 'system', 'light', 'dark'
  final bool soundEnabled;
  final bool hapticsEnabled;
  final bool dailyReminderEnabled;
  final String reminderTime;
  final String
      preferredDifficulty; // 'auto', 'easy', 'medium', 'hard', 'expert'
  final bool reducedMotion;
  final String languageCode; // 'en', 'es', 'fr', 'de', 'ja'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'theme_mode': themeMode,
        'sound_enabled': soundEnabled,
        'haptics_enabled': hapticsEnabled,
        'daily_reminder_enabled': dailyReminderEnabled,
        'reminder_time': reminderTime,
        'preferred_difficulty': preferredDifficulty,
        'reduced_motion': reducedMotion,
        'language_code': languageCode,
      };

  UserPreferences copyWith({
    String? userId,
    String? themeMode,
    bool? soundEnabled,
    bool? hapticsEnabled,
    bool? dailyReminderEnabled,
    String? reminderTime,
    String? preferredDifficulty,
    bool? reducedMotion,
    String? languageCode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      UserPreferences(
        userId: userId ?? this.userId,
        themeMode: themeMode ?? this.themeMode,
        soundEnabled: soundEnabled ?? this.soundEnabled,
        hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
        dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
        reminderTime: reminderTime ?? this.reminderTime,
        preferredDifficulty: preferredDifficulty ?? this.preferredDifficulty,
        reducedMotion: reducedMotion ?? this.reducedMotion,
        languageCode: languageCode ?? this.languageCode,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  List<Object?> get props => [
        userId,
        themeMode,
        soundEnabled,
        hapticsEnabled,
        dailyReminderEnabled,
        reminderTime,
        preferredDifficulty,
        reducedMotion,
        languageCode,
        createdAt,
        updatedAt,
      ];
}
