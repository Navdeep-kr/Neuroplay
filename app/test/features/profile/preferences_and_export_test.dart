import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neuroplay/features/profile/domain/profile_models.dart';
import 'package:neuroplay/features/profile/presentation/profile_screen.dart';
import 'package:neuroplay/features/training/data/local_training_repository.dart';

void main() {
  group('UserPreferences Domain and Repository Tests', () {
    test(
        'default preferences initializes with standard accessibility and language settings',
        () {
      final prefs = UserPreferences.defaultPreferences('test-user');

      expect(prefs.userId, equals('test-user'));
      expect(prefs.themeMode, equals('system'));
      expect(prefs.soundEnabled, isTrue);
      expect(prefs.hapticsEnabled, isTrue);
      expect(prefs.dailyReminderEnabled, isFalse);
      expect(prefs.reminderTime, equals('09:00'));
      expect(prefs.preferredDifficulty, equals('auto'));
      expect(prefs.reducedMotion, isFalse);
      expect(prefs.languageCode, equals('en'));
    });

    test('UserPreferences JSON serialization roundtrip', () {
      const prefs = UserPreferences(
        userId: 'u-1',
        themeMode: 'dark',
        soundEnabled: false,
        dailyReminderEnabled: true,
        reminderTime: '08:15',
        preferredDifficulty: 'hard',
        reducedMotion: true,
        languageCode: 'ja',
      );

      final json = prefs.toJson();
      expect(json['user_id'], equals('u-1'));
      expect(json['theme_mode'], equals('dark'));
      expect(json['sound_enabled'], isFalse);
      expect(json['daily_reminder_enabled'], isTrue);
      expect(json['reminder_time'], equals('08:15'));
      expect(json['preferred_difficulty'], equals('hard'));
      expect(json['reduced_motion'], isTrue);
      expect(json['language_code'], equals('ja'));

      final restored = UserPreferences.fromJson(json);
      expect(restored.themeMode, equals('dark'));
      expect(restored.preferredDifficulty, equals('hard'));
      expect(restored.reducedMotion, isTrue);
      expect(restored.languageCode, equals('ja'));
    });

    test(
        'LocalTrainingRepository exportUserDataJson produces complete schema v1.0.0 payload',
        () async {
      final repo = LocalTrainingRepository();
      final export = await repo.exportUserDataJson();

      expect(export['export_schema_version'], equals('1.0.0'));
      expect(export['exported_at'], isNotNull);
      expect(export['mode'], equals('guest_local_storage'));

      // Check required sections
      expect(export.containsKey('streak'), isTrue);
      expect(export.containsKey('xp_progression'), isTrue);
      expect(export.containsKey('achievements'), isTrue);
      expect(export.containsKey('cognitive_indices'), isTrue);
      expect(export.containsKey('skill_estimates'), isTrue);
      expect(export.containsKey('game_sessions'), isTrue);
      expect(export.containsKey('workout_history'), isTrue);

      final sessions = export['game_sessions'] as List;
      expect(sessions, isNotEmpty);
      final firstSession = sessions.first as Map<String, dynamic>;
      expect(firstSession.containsKey('score'), isTrue);
      expect(firstSession.containsKey('accuracy'), isTrue);

      // Verify zero security keys or passwords present
      expect(export.containsKey('password'), isFalse);
      expect(export.containsKey('service_role'), isFalse);
      expect(export.containsKey('secret'), isFalse);
    });
  });

  group('ProfileScreen Preferences & Export Widget Tests', () {
    Future<void> pumpTransition(WidgetTester tester) async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 350));
    }

    testWidgets(
        'renders all preference controls: difficulty, reduced motion, reminders, and language',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );

      await pumpTransition(tester);

      // Appearance Section
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Interface Theme'), findsOneWidget);

      // Sensory & Feedback Section
      expect(find.text('Sensory & Feedback'), findsOneWidget);
      expect(find.text('Auditory Feedback'), findsOneWidget);
      expect(find.text('Tactile Vibrations'), findsOneWidget);
      expect(find.text('Reduced Motion'), findsOneWidget);

      // Training Routine & Language Section
      expect(find.text('Training Routine & Language'), findsOneWidget);
      expect(find.text('Daily Routine Reminder'), findsOneWidget);
      expect(find.text('Target Difficulty Mode'), findsOneWidget);
      expect(find.text('Content Language'), findsOneWidget);

      // Verify Difficulty Segments
      expect(find.text('Auto'), findsOneWidget);
      expect(find.text('Easy'), findsOneWidget);
      expect(find.text('Med'), findsOneWidget);
      expect(find.text('Hard'), findsOneWidget);
      expect(find.text('Exp'), findsOneWidget);

      // Data & Privacy Section
      expect(find.text('Data & Privacy'), findsOneWidget);
      expect(find.text('Export Data (JSON)'), findsOneWidget);
    });

    testWidgets(
        'tapping Export Data (JSON) opens interactive export preview dialog',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );

      await pumpTransition(tester);

      // Scroll to and tap Export Data (JSON)
      final exportBtn = find.text('Export Data (JSON)');
      expect(exportBtn, findsOneWidget);
      await tester.ensureVisible(exportBtn);
      await tester.tap(exportBtn);
      await tester.pumpAndSettle();

      // Verify Export Dialog opens
      expect(find.text('Export Data Archive'), findsOneWidget);
      expect(find.textContaining('Schema Version 1.0.0'), findsOneWidget);
      expect(find.text('Copy to Clipboard'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.text('Export Data Archive'), findsNothing);
    });
  });
}
