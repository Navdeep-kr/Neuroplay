/// Application-wide constants.
abstract final class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const games = '/games';
  static const progress = '/progress';
  static const challenges = '/challenges';
  static const profile = '/profile';
}

/// Supabase table names.
abstract final class Tables {
  static const profiles = 'profiles';
  static const games = 'games';
  static const gameSessions = 'game_sessions';
  static const gameScores = 'game_scores';
}
