/// Application-wide constants.
abstract final class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const games = '/games';
  static const memoryMatrix = '/games/memory-matrix';
  static const reflexForge = '/games/reflex-forge';
  static const focusReactor = '/games/focus-reactor';
  static const logicLabyrinth = '/games/logic-labyrinth';
  static const numberPulse = '/games/number-pulse';
  static const wordWeaver = '/games/word-weaver';
  static const progress = '/progress';
  static const challenges = '/challenges';
  static const profile = '/profile';
  static const subscription = '/subscription';
}

/// Supabase table names.
abstract final class Tables {
  static const profiles = 'profiles';
  static const userPreferences = 'user_preferences';
  static const games = 'games';
  static const gameSessions = 'game_sessions';
  static const gameScores = 'game_scores';
  static const dailyWorkouts = 'daily_workouts';
  static const userStreaks = 'user_streaks';
  static const cognitiveIndices = 'cognitive_indices';
  static const userGameSkills = 'user_game_skills';
  static const difficultyAdjustments = 'difficulty_adjustments';
  static const gameVersions = 'game_versions';
  static const workoutPlans = 'workout_plans';
  static const userXpEvents = 'user_xp_events';
  static const userXpSummary = 'user_xp_summary';
  static const achievements = 'achievements';
  static const userAchievements = 'user_achievements';
  static const userDailyActivity = 'user_daily_activity';
  static const subscriptionEntitlements = 'subscription_entitlements';
  static const subscriptionHistory = 'subscription_history';
  static const featureFlags = 'feature_flags';
  static const userFeatureOverrides = 'user_feature_overrides';
  static const adminRoles = 'admin_roles';
  static const adminAuditEvents = 'admin_audit_events';
}
