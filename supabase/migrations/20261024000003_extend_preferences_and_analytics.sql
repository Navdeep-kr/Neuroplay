-- Migration: Extend user preferences and progress analytics support
-- Version: 20261024000003

ALTER TABLE public.user_preferences
  ADD COLUMN IF NOT EXISTS preferred_difficulty TEXT NOT NULL DEFAULT 'auto'
    CHECK (preferred_difficulty IN ('auto', 'easy', 'medium', 'hard', 'expert')),
  ADD COLUMN IF NOT EXISTS reduced_motion BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS language_code TEXT NOT NULL DEFAULT 'en';

-- Index for session history queries by game and user
CREATE INDEX IF NOT EXISTS idx_game_sessions_user_game_created
  ON public.game_sessions(user_id, game_id, created_at DESC);

-- Index for daily activity lookups
CREATE INDEX IF NOT EXISTS idx_user_daily_activity_lookup
  ON public.user_daily_activity(user_id, activity_date DESC);
