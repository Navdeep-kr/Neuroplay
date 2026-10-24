-- ============================================================
-- NEUROPLAY — Phase 5: Backend Core, Entitlements, XP & Admin
-- ============================================================
-- Comprehensive migrations for:
-- 1. Games and game versions catalog
-- 2. Workout plans and extended sessions
-- 3. Versioned idempotency and request correlation
-- 4. Server-side session completion & derived score validation
-- 5. Idempotent XP events, leveling & achievements engine
-- 6. User daily activity aggregates
-- 7. Subscription entitlements & history (zero-trust client)
-- 8. Feature flags & rollout engine
-- 9. Administrative authorization & immutable audit events
-- 10. Sliding-window rate limiter
-- 11. Initial seed data for games, achievements, and flags
-- ============================================================

-- ------------------------------------------------------------
-- 1. Games Catalog & Versions Table
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.games (
  id TEXT PRIMARY KEY,
  slug TEXT UNIQUE NOT NULL,
  title TEXT NOT NULL,
  domain TEXT NOT NULL CHECK (domain IN ('memory', 'attention', 'speed', 'flexibility', 'problemSolving')),
  description TEXT NOT NULL,
  instructions TEXT NOT NULL,
  duration_minutes INTEGER NOT NULL DEFAULT 3 CHECK (duration_minutes > 0),
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE TABLE IF NOT EXISTS public.game_versions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  game_id TEXT NOT NULL REFERENCES public.games(id) ON DELETE CASCADE,
  version TEXT NOT NULL,
  engine_version TEXT NOT NULL DEFAULT '1.0.0',
  scoring_rules_version TEXT NOT NULL DEFAULT '1.0.0',
  config_schema JSONB NOT NULL DEFAULT '{}'::jsonb,
  scoring_rules JSONB NOT NULL DEFAULT '{}'::jsonb,
  is_current BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT uq_game_version UNIQUE(game_id, version)
);

CREATE INDEX IF NOT EXISTS idx_game_versions_lookup ON public.game_versions(game_id, version);

-- Trigger for games updated_at
CREATE OR REPLACE TRIGGER tr_games_updated_at
  BEFORE UPDATE ON public.games
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ------------------------------------------------------------
-- 2. Enhancements to game_sessions: Idempotency & Correlation
-- ------------------------------------------------------------
ALTER TABLE public.game_sessions
  ADD COLUMN IF NOT EXISTS idempotency_key TEXT UNIQUE,
  ADD COLUMN IF NOT EXISTS correlation_id TEXT,
  ADD COLUMN IF NOT EXISTS validated_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS derived_xp_awarded INTEGER NOT NULL DEFAULT 0 CHECK (derived_xp_awarded >= 0);

CREATE INDEX IF NOT EXISTS idx_game_sessions_idempotency ON public.game_sessions(idempotency_key);
CREATE INDEX IF NOT EXISTS idx_game_sessions_correlation ON public.game_sessions(correlation_id);

-- ------------------------------------------------------------
-- 3. Workout Plans Table
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.workout_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  focus_domains JSONB NOT NULL DEFAULT '[]'::jsonb,
  target_days_per_week INTEGER NOT NULL DEFAULT 5 CHECK (target_days_per_week >= 1 AND target_days_per_week <= 7),
  target_minutes_per_day INTEGER NOT NULL DEFAULT 9 CHECK (target_minutes_per_day >= 3 AND target_minutes_per_day <= 60),
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_workout_plans_user ON public.workout_plans(user_id);

CREATE OR REPLACE TRIGGER tr_workout_plans_updated_at
  BEFORE UPDATE ON public.workout_plans
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Add plan_id reference to daily_workouts
ALTER TABLE public.daily_workouts
  ADD COLUMN IF NOT EXISTS plan_id UUID REFERENCES public.workout_plans(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS correlation_id TEXT;

-- ------------------------------------------------------------
-- 4. XP Events, Summary & Achievements
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_xp_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL CHECK (event_type IN (
    'game_completion',
    'daily_workout_completion',
    'streak_milestone',
    'achievement_unlock',
    'challenge_completion'
  )),
  xp_amount INTEGER NOT NULL CHECK (xp_amount > 0 AND xp_amount <= 5000),
  source_id TEXT,
  idempotency_key TEXT NOT NULL UNIQUE,
  correlation_id TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_user_xp_events_user_created ON public.user_xp_events(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_xp_events_idempotency ON public.user_xp_events(idempotency_key);

CREATE TABLE IF NOT EXISTS public.user_xp_summary (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  total_xp INTEGER NOT NULL DEFAULT 0 CHECK (total_xp >= 0),
  current_level INTEGER NOT NULL DEFAULT 1 CHECK (current_level >= 1),
  xp_to_next_level INTEGER NOT NULL DEFAULT 1000 CHECK (xp_to_next_level > 0),
  last_awarded_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE TABLE IF NOT EXISTS public.achievements (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  category TEXT NOT NULL CHECK (category IN ('streak', 'accuracy', 'mastery', 'exploration', 'speed')),
  badge_icon TEXT NOT NULL,
  xp_reward INTEGER NOT NULL DEFAULT 100 CHECK (xp_reward >= 0),
  criteria JSONB NOT NULL DEFAULT '{}'::jsonb,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE TABLE IF NOT EXISTS public.user_achievements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  achievement_id TEXT NOT NULL REFERENCES public.achievements(id) ON DELETE CASCADE,
  unlocked_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  idempotency_key TEXT UNIQUE,
  CONSTRAINT uq_user_achievement UNIQUE(user_id, achievement_id)
);

CREATE INDEX IF NOT EXISTS idx_user_achievements_user ON public.user_achievements(user_id);

-- ------------------------------------------------------------
-- 5. User Daily Activity Tracking
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_daily_activity (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  activity_date DATE NOT NULL,
  sessions_count INTEGER NOT NULL DEFAULT 0 CHECK (sessions_count >= 0),
  total_duration_seconds INTEGER NOT NULL DEFAULT 0 CHECK (total_duration_seconds >= 0),
  total_xp_earned INTEGER NOT NULL DEFAULT 0 CHECK (total_xp_earned >= 0),
  workout_completed BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT uq_user_daily_activity UNIQUE(user_id, activity_date)
);

CREATE INDEX IF NOT EXISTS idx_user_daily_activity_lookup ON public.user_daily_activity(user_id, activity_date DESC);

-- ------------------------------------------------------------
-- 6. Subscription Entitlements (Zero-Trust Client Access)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.subscription_entitlements (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  tier TEXT NOT NULL DEFAULT 'free' CHECK (tier IN ('free', 'pro', 'family', 'lifetime')),
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'trialing', 'past_due', 'canceled', 'expired')),
  features JSONB NOT NULL DEFAULT '["standard_games", "daily_workout"]'::jsonb,
  valid_until TIMESTAMPTZ,
  auto_renew BOOLEAN NOT NULL DEFAULT FALSE,
  provider TEXT NOT NULL DEFAULT 'manual',
  external_subscription_id TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE TABLE IF NOT EXISTS public.subscription_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  previous_tier TEXT NOT NULL,
  new_tier TEXT NOT NULL,
  reason TEXT NOT NULL,
  changed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  correlation_id TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_subscription_history_user ON public.subscription_history(user_id, created_at DESC);

-- ------------------------------------------------------------
-- 7. Feature Flags & Overrides
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.feature_flags (
  flag_key TEXT PRIMARY KEY,
  description TEXT,
  is_enabled BOOLEAN NOT NULL DEFAULT FALSE,
  rollout_percentage INTEGER NOT NULL DEFAULT 0 CHECK (rollout_percentage >= 0 AND rollout_percentage <= 100),
  minimum_app_version TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE TABLE IF NOT EXISTS public.user_feature_overrides (
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  flag_key TEXT NOT NULL REFERENCES public.feature_flags(flag_key) ON DELETE CASCADE,
  is_enabled BOOLEAN NOT NULL,
  reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  PRIMARY KEY (user_id, flag_key)
);

-- ------------------------------------------------------------
-- 8. Administrative Authorization & Audit Events
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.admin_roles (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('superadmin', 'admin', 'moderator', 'support')),
  granted_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  granted_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE TABLE IF NOT EXISTS public.admin_audit_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  target_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  entity_type TEXT NOT NULL,
  entity_id TEXT,
  previous_state JSONB,
  new_state JSONB,
  correlation_id TEXT,
  ip_address TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_admin_audit_events_created ON public.admin_audit_events(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_admin_audit_events_actor ON public.admin_audit_events(actor_id);

-- Helper to verify admin status (Never trust client metadata)
CREATE OR REPLACE FUNCTION public.is_admin(p_user_id UUID DEFAULT auth.uid())
RETURNS BOOLEAN AS $$
BEGIN
  IF p_user_id IS NULL THEN
    RETURN FALSE;
  END IF;
  RETURN EXISTS (
    SELECT 1 FROM public.admin_roles WHERE user_id = p_user_id
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

-- ------------------------------------------------------------
-- 9. Sliding-Window Rate Limiter
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.rate_limit_buckets (
  key TEXT PRIMARY KEY,
  request_count INTEGER NOT NULL DEFAULT 1,
  window_start TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE OR REPLACE FUNCTION public.check_rate_limit(
  p_key TEXT,
  p_max_requests INTEGER,
  p_window_seconds INTEGER
)
RETURNS BOOLEAN AS $$
DECLARE
  v_bucket RECORD;
  v_now TIMESTAMPTZ := timezone('utc'::text, now());
BEGIN
  SELECT * INTO v_bucket FROM public.rate_limit_buckets WHERE key = p_key FOR UPDATE;

  IF NOT FOUND THEN
    INSERT INTO public.rate_limit_buckets (key, request_count, window_start)
    VALUES (p_key, 1, v_now);
    RETURN TRUE;
  END IF;

  IF v_now >= v_bucket.window_start + (p_window_seconds || ' seconds')::INTERVAL THEN
    -- Window expired, reset bucket
    UPDATE public.rate_limit_buckets
    SET request_count = 1, window_start = v_now
    WHERE key = p_key;
    RETURN TRUE;
  END IF;

  IF v_bucket.request_count < p_max_requests THEN
    UPDATE public.rate_limit_buckets
    SET request_count = v_bucket.request_count + 1
    WHERE key = p_key;
    RETURN TRUE;
  END IF;

  -- Rate limit exceeded
  RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ------------------------------------------------------------
-- 10. Server-Side Idempotent XP Issuance & Leveling Engine
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.award_xp(
  p_user_id UUID,
  p_event_type TEXT,
  p_amount INTEGER,
  p_idempotency_key TEXT,
  p_source_id TEXT DEFAULT NULL,
  p_correlation_id TEXT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_existing_event RECORD;
  v_summary RECORD;
  v_new_total INTEGER;
  v_new_level INTEGER;
  v_xp_for_next INTEGER;
BEGIN
  -- Idempotency check: return existing state if duplicate request
  SELECT * INTO v_existing_event
  FROM public.user_xp_events
  WHERE idempotency_key = p_idempotency_key;

  IF FOUND THEN
    SELECT * INTO v_summary FROM public.user_xp_summary WHERE user_id = p_user_id;
    RETURN jsonb_build_object(
      'status', 'idempotent_duplicate',
      'xp_awarded', 0,
      'total_xp', COALESCE(v_summary.total_xp, 0),
      'current_level', COALESCE(v_summary.current_level, 1),
      'idempotency_key', p_idempotency_key
    );
  END IF;

  -- Insert event record
  INSERT INTO public.user_xp_events (
    user_id, event_type, xp_amount, source_id, idempotency_key, correlation_id
  ) VALUES (
    p_user_id, p_event_type, p_amount, p_source_id, p_idempotency_key, p_correlation_id
  );

  -- Upsert summary
  SELECT * INTO v_summary FROM public.user_xp_summary WHERE user_id = p_user_id FOR UPDATE;

  IF NOT FOUND THEN
    v_new_total := p_amount;
    v_new_level := GREATEST(1, FLOOR(SQRT(v_new_total / 100.0))::INTEGER + 1);
    v_xp_for_next := (v_new_level * v_new_level * 100);

    INSERT INTO public.user_xp_summary (
      user_id, total_xp, current_level, xp_to_next_level, last_awarded_at
    ) VALUES (
      p_user_id, v_new_total, v_new_level, v_xp_for_next, timezone('utc'::text, now())
    );
  ELSE
    v_new_total := v_summary.total_xp + p_amount;
    v_new_level := GREATEST(1, FLOOR(SQRT(v_new_total / 100.0))::INTEGER + 1);
    v_xp_for_next := (v_new_level * v_new_level * 100);

    UPDATE public.user_xp_summary
    SET total_xp = v_new_total,
        current_level = v_new_level,
        xp_to_next_level = v_xp_for_next,
        last_awarded_at = timezone('utc'::text, now()),
        updated_at = timezone('utc'::text, now())
    WHERE user_id = p_user_id;
  END IF;

  RETURN jsonb_build_object(
    'status', 'success',
    'xp_awarded', p_amount,
    'total_xp', v_new_total,
    'current_level', v_new_level,
    'xp_to_next_level', v_xp_for_next,
    'idempotency_key', p_idempotency_key
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ------------------------------------------------------------
-- 11. Complete Game Session (Server-Validated & Idempotent)
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.complete_game_session(
  p_game_id TEXT,
  p_game_version TEXT,
  p_score INTEGER,
  p_accuracy NUMERIC,
  p_duration_seconds INTEGER,
  p_error_count INTEGER,
  p_is_practice BOOLEAN,
  p_metrics JSONB,
  p_score_breakdown JSONB,
  p_idempotency_key TEXT,
  p_workout_id UUID DEFAULT NULL,
  p_correlation_id TEXT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_session_id UUID;
  v_existing_session RECORD;
  v_today DATE := CURRENT_DATE;
  v_streak RECORD;
  v_new_current INTEGER := 1;
  v_new_longest INTEGER := 1;
  v_workout_completed BOOLEAN := FALSE;
  v_domain TEXT;
  v_new_index INTEGER;
  v_derived_xp INTEGER := 0;
  v_xp_res JSONB;
  v_unlocked_achievements JSONB := '[]'::jsonb;
  v_rate_ok BOOLEAN;
BEGIN
  -- 1. Security Check
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION '{"code": "UNAUTHENTICATED", "message": "Authentication required to complete game session"}'
      USING ERRCODE = '28000';
  END IF;

  -- 2. Abuse Prevention: Rate Limit (max 60 completion calls per minute per user)
  v_rate_ok := public.check_rate_limit('complete_session:' || v_user_id::TEXT, 60, 60);
  IF NOT v_rate_ok THEN
    RAISE EXCEPTION '{"code": "RATE_LIMIT_EXCEEDED", "message": "Too many session completion requests. Please wait."}'
      USING ERRCODE = 'P0001';
  END IF;

  -- 3. Idempotency Check: prevent duplicate rewards or state mutations
  IF p_idempotency_key IS NOT NULL AND p_idempotency_key <> '' THEN
    SELECT * INTO v_existing_session
    FROM public.game_sessions
    WHERE idempotency_key = p_idempotency_key;

    IF FOUND THEN
      SELECT * INTO v_streak FROM public.user_streaks WHERE user_id = v_user_id;
      RETURN jsonb_build_object(
        'status', 'idempotent_duplicate',
        'session_id', v_existing_session.id,
        'derived_xp_awarded', v_existing_session.derived_xp_awarded,
        'current_streak', COALESCE(v_streak.current_streak, 1),
        'longest_streak', COALESCE(v_streak.longest_streak, 1),
        'workout_completed', FALSE,
        'correlation_id', p_correlation_id
      );
    END IF;
  END IF;

  -- 4. Server-Side Input Validation
  IF p_accuracy < 0.0 OR p_accuracy > 1.0 THEN
    RAISE EXCEPTION '{"code": "INVALID_INPUT", "message": "Accuracy must be between 0.0 and 1.0"}'
      USING ERRCODE = '22003';
  END IF;

  IF p_duration_seconds < 0 OR p_duration_seconds > 7200 THEN
    RAISE EXCEPTION '{"code": "INVALID_INPUT", "message": "Duration seconds out of allowable bounds (0-7200s)"}'
      USING ERRCODE = '22003';
  END IF;

  IF p_score < 0 OR p_score > 500000 THEN
    RAISE EXCEPTION '{"code": "INVALID_INPUT", "message": "Score out of allowable bounds"}'
      USING ERRCODE = '22003';
  END IF;

  IF p_error_count < 0 THEN
    RAISE EXCEPTION '{"code": "INVALID_INPUT", "message": "Error count cannot be negative"}'
      USING ERRCODE = '22003';
  END IF;

  -- 5. Calculate Server-Side Derived XP (Never trust client-submitted XP)
  IF NOT p_is_practice THEN
    v_derived_xp := ROUND(
      LEAST(150, p_score / 20.0) +
      (p_accuracy * 50.0) +
      (CASE WHEN p_error_count = 0 THEN 25 ELSE 0 END)
    )::INTEGER;
  ELSE
    v_derived_xp := 10; -- Nominal practice reward
  END IF;

  -- 6. Insert Verified Game Session
  INSERT INTO public.game_sessions (
    user_id, workout_id, game_id, game_version, score,
    accuracy, duration_seconds, error_count, is_practice,
    metrics, score_breakdown, idempotency_key, correlation_id,
    validated_at, derived_xp_awarded
  ) VALUES (
    v_user_id, p_workout_id, p_game_id, p_game_version, p_score,
    p_accuracy, p_duration_seconds, p_error_count, p_is_practice,
    p_metrics, p_score_breakdown, p_idempotency_key, p_correlation_id,
    timezone('utc'::text, now()), v_derived_xp
  ) RETURNING id INTO v_session_id;

  -- 7. If linked to workout, update workout progress
  IF p_workout_id IS NOT NULL THEN
    UPDATE public.daily_workouts
    SET completed_game_ids = (
      SELECT jsonb_agg(DISTINCT elem)
      FROM jsonb_array_elements_text(completed_game_ids || jsonb_build_array(p_game_id)) AS elem
    ),
    is_completed = (
      SELECT COUNT(DISTINCT target_elem) = COUNT(DISTINCT comp_elem)
      FROM jsonb_array_elements_text(game_ids) AS target_elem
      FULL OUTER JOIN jsonb_array_elements_text(completed_game_ids || jsonb_build_array(p_game_id)) AS comp_elem
        ON target_elem = comp_elem
    ),
    completed_at = CASE
      WHEN is_completed = FALSE AND (
        SELECT COUNT(DISTINCT target_elem) = COUNT(DISTINCT comp_elem)
        FROM jsonb_array_elements_text(game_ids) AS target_elem
        FULL OUTER JOIN jsonb_array_elements_text(completed_game_ids || jsonb_build_array(p_game_id)) AS comp_elem
          ON target_elem = comp_elem
      ) THEN timezone('utc'::text, now())
      ELSE completed_at
    END
    WHERE id = p_workout_id AND user_id = v_user_id
    RETURNING is_completed INTO v_workout_completed;
  END IF;

  -- 8. Update Streak
  SELECT * INTO v_streak FROM public.user_streaks WHERE user_id = v_user_id;
  IF NOT FOUND THEN
    v_new_current := 1;
    v_new_longest := 1;
    INSERT INTO public.user_streaks (
      user_id, current_streak, longest_streak, last_activity_date,
      total_sessions_completed, total_workouts_completed
    ) VALUES (
      v_user_id, v_new_current, v_new_longest, v_today,
      1, CASE WHEN v_workout_completed THEN 1 ELSE 0 END
    );
  ELSE
    IF v_streak.last_activity_date IS NULL THEN
      v_new_current := 1;
    ELSIF v_streak.last_activity_date = v_today THEN
      v_new_current := v_streak.current_streak;
    ELSIF v_streak.last_activity_date = (v_today - INTERVAL '1 day')::DATE THEN
      v_new_current := v_streak.current_streak + 1;
    ELSE
      v_new_current := 1;
    END IF;

    v_new_longest := GREATEST(v_streak.longest_streak, v_new_current);

    UPDATE public.user_streaks
    SET current_streak = v_new_current,
        longest_streak = v_new_longest,
        last_activity_date = v_today,
        total_sessions_completed = v_streak.total_sessions_completed + 1,
        total_workouts_completed = v_streak.total_workouts_completed + CASE WHEN v_workout_completed THEN 1 ELSE 0 END
    WHERE user_id = v_user_id;
  END IF;

  -- 9. Update Cognitive Indices
  IF NOT p_is_practice THEN
    v_domain := public.get_game_domain(p_game_id);
    v_new_index := LEAST(100, GREATEST(10, ROUND((p_accuracy * 70.0) + LEAST(30.0, p_score / 50.0))))::INTEGER;

    INSERT INTO public.cognitive_indices (user_id, domain, score_index, percentile_rank, trend_percentage, sample_count)
    VALUES (v_user_id, v_domain, v_new_index, LEAST(99, GREATEST(1, v_new_index + 2)), 0, 1)
    ON CONFLICT (user_id, domain) DO UPDATE
    SET score_index = ROUND((cognitive_indices.score_index * 0.7) + (v_new_index * 0.3))::INTEGER,
        sample_count = cognitive_indices.sample_count + 1,
        trend_percentage = ROUND(v_new_index - cognitive_indices.score_index)::INTEGER,
        percentile_rank = LEAST(99, GREATEST(1, ROUND((cognitive_indices.score_index * 0.7) + (v_new_index * 0.3)) + 2))::INTEGER;
  END IF;

  -- 10. Award XP
  v_xp_res := public.award_xp(
    v_user_id,
    'game_completion',
    v_derived_xp,
    'xp_session_' || v_session_id::TEXT,
    v_session_id::TEXT,
    p_correlation_id
  );

  -- 11. Check and Unlock Milestone Achievements
  -- Achievement: First steps (completed first session)
  INSERT INTO public.user_achievements (user_id, achievement_id, idempotency_key)
  VALUES (v_user_id, 'first_steps', 'ach_first_steps_' || v_user_id::TEXT)
  ON CONFLICT (user_id, achievement_id) DO NOTHING;

  IF p_accuracy >= 0.95 THEN
    INSERT INTO public.user_achievements (user_id, achievement_id, idempotency_key)
    VALUES (v_user_id, 'perfectionist', 'ach_perf_' || v_session_id::TEXT)
    ON CONFLICT (user_id, achievement_id) DO NOTHING;
  END IF;

  IF v_new_current >= 3 THEN
    INSERT INTO public.user_achievements (user_id, achievement_id, idempotency_key)
    VALUES (v_user_id, 'streak_starter', 'ach_streak_3_' || v_user_id::TEXT)
    ON CONFLICT (user_id, achievement_id) DO NOTHING;
  END IF;

  IF v_new_current >= 7 THEN
    INSERT INTO public.user_achievements (user_id, achievement_id, idempotency_key)
    VALUES (v_user_id, 'streak_warrior', 'ach_streak_7_' || v_user_id::TEXT)
    ON CONFLICT (user_id, achievement_id) DO NOTHING;
  END IF;

  -- 12. Aggregate Daily Activity
  INSERT INTO public.user_daily_activity (
    user_id, activity_date, sessions_count, total_duration_seconds, total_xp_earned, workout_completed
  ) VALUES (
    v_user_id, v_today, 1, p_duration_seconds, v_derived_xp, v_workout_completed
  ) ON CONFLICT (user_id, activity_date) DO UPDATE
  SET sessions_count = user_daily_activity.sessions_count + 1,
      total_duration_seconds = user_daily_activity.total_duration_seconds + p_duration_seconds,
      total_xp_earned = user_daily_activity.total_xp_earned + v_derived_xp,
      workout_completed = user_daily_activity.workout_completed OR v_workout_completed,
      updated_at = timezone('utc'::text, now());

  RETURN jsonb_build_object(
    'status', 'success',
    'session_id', v_session_id,
    'derived_xp_awarded', v_derived_xp,
    'total_xp', v_xp_res->'total_xp',
    'current_level', v_xp_res->'current_level',
    'current_streak', v_new_current,
    'longest_streak', v_new_longest,
    'workout_completed', v_workout_completed,
    'correlation_id', p_correlation_id
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Keep backward compatibility: redirect record_game_session to complete_game_session
CREATE OR REPLACE FUNCTION public.record_game_session(
  p_game_id TEXT,
  p_game_version TEXT,
  p_score INTEGER,
  p_accuracy NUMERIC,
  p_duration_seconds INTEGER,
  p_error_count INTEGER,
  p_is_practice BOOLEAN,
  p_metrics JSONB,
  p_score_breakdown JSONB,
  p_workout_id UUID DEFAULT NULL
)
RETURNS JSONB AS $$
BEGIN
  RETURN public.complete_game_session(
    p_game_id => p_game_id,
    p_game_version => p_game_version,
    p_score => p_score,
    p_accuracy => p_accuracy,
    p_duration_seconds => p_duration_seconds,
    p_error_count => p_error_count,
    p_is_practice => p_is_practice,
    p_metrics => p_metrics,
    p_score_breakdown => p_score_breakdown,
    p_idempotency_key => NULL,
    p_workout_id => p_workout_id,
    p_correlation_id => NULL
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ------------------------------------------------------------
-- 12. Server-Side Deterministic Daily Workout Generator
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_or_create_daily_workout(
  p_workout_date DATE DEFAULT CURRENT_DATE,
  p_correlation_id TEXT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_workout RECORD;
  v_day_seed INTEGER;
  v_selected_game_ids JSONB;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION '{"code": "UNAUTHENTICATED", "message": "Authentication required to generate daily workout"}'
      USING ERRCODE = '28000';
  END IF;

  -- 1. Check existing workout for user & date
  SELECT * INTO v_workout
  FROM public.daily_workouts
  WHERE user_id = v_user_id AND workout_date = p_workout_date;

  IF FOUND THEN
    RETURN jsonb_build_object(
      'id', v_workout.id,
      'workout_date', v_workout.workout_date,
      'title', v_workout.title,
      'subtitle', v_workout.subtitle,
      'estimated_minutes', v_workout.estimated_minutes,
      'game_ids', v_workout.game_ids,
      'completed_game_ids', v_workout.completed_game_ids,
      'is_completed', v_workout.is_completed,
      'is_fresh', FALSE
    );
  END IF;

  -- 2. Deterministic 3-game playlist generation
  v_day_seed := (EXTRACT(YEAR FROM p_workout_date)::INTEGER * 10000) +
                (EXTRACT(MONTH FROM p_workout_date)::INTEGER * 100) +
                (EXTRACT(DAY FROM p_workout_date)::INTEGER);

  CASE (v_day_seed % 3)
    WHEN 0 THEN
      v_selected_game_ids := '["memory-matrix", "reflex-forge", "focus-reactor"]'::jsonb;
    WHEN 1 THEN
      v_selected_game_ids := '["focus-reactor", "logic-labyrinth", "memory-matrix"]'::jsonb;
    ELSE
      v_selected_game_ids := '["number-pulse", "word-weaver", "reflex-forge"]'::jsonb;
  END CASE;

  INSERT INTO public.daily_workouts (
    user_id, workout_date, title, subtitle, estimated_minutes, game_ids, completed_game_ids, correlation_id
  ) VALUES (
    v_user_id,
    p_workout_date,
    'Cognitive Agility Circuit',
    'Targeting spatial pattern recall, executive control, and distractor suppression.',
    9,
    v_selected_game_ids,
    '[]'::jsonb,
    p_correlation_id
  ) RETURNING * INTO v_workout;

  RETURN jsonb_build_object(
    'id', v_workout.id,
    'workout_date', v_workout.workout_date,
    'title', v_workout.title,
    'subtitle', v_workout.subtitle,
    'estimated_minutes', v_workout.estimated_minutes,
    'game_ids', v_workout.game_ids,
    'completed_game_ids', v_workout.completed_game_ids,
    'is_completed', v_workout.is_completed,
    'is_fresh', TRUE
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ------------------------------------------------------------
-- 13. Row-Level Security (RLS) on All Tables
-- ------------------------------------------------------------
ALTER TABLE public.games ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.game_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_xp_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_xp_summary ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_daily_activity ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_entitlements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feature_flags ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_feature_overrides ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_audit_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rate_limit_buckets ENABLE ROW LEVEL SECURITY;

-- Games Catalog: Readable by anyone (public/authenticated), Writable only by superadmins
CREATE POLICY "Public read games catalog"
  ON public.games FOR SELECT
  USING (true);

CREATE POLICY "Admin write games catalog"
  ON public.games FOR ALL
  TO authenticated
  USING (public.is_admin());

-- Game Versions: Readable by anyone, Writable only by superadmins
CREATE POLICY "Public read game versions"
  ON public.game_versions FOR SELECT
  USING (true);

CREATE POLICY "Admin write game versions"
  ON public.game_versions FOR ALL
  TO authenticated
  USING (public.is_admin());

-- Workout Plans: User private
CREATE POLICY "Users view own workout plans"
  ON public.workout_plans FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users modify own workout plans"
  ON public.workout_plans FOR ALL
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- XP Events & Summary: Readable by owner; Client direct inserts/updates DENIED (only RPC)
CREATE POLICY "Users view own xp events"
  ON public.user_xp_events FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Deny client write on xp events"
  ON public.user_xp_events FOR INSERT
  TO authenticated
  WITH CHECK (false);

CREATE POLICY "Users view own xp summary"
  ON public.user_xp_summary FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Deny client write on xp summary"
  ON public.user_xp_summary FOR ALL
  TO authenticated
  USING (false);

-- Achievements: Public read; User Achievements: User read only (unlocked via RPC)
CREATE POLICY "Public read achievements"
  ON public.achievements FOR SELECT
  USING (true);

CREATE POLICY "Admin write achievements"
  ON public.achievements FOR ALL
  TO authenticated
  USING (public.is_admin());

CREATE POLICY "Users view own achievements"
  ON public.user_achievements FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Deny client write on user achievements"
  ON public.user_achievements FOR INSERT
  TO authenticated
  WITH CHECK (false);

-- User Daily Activity: User read only
CREATE POLICY "Users view own daily activity"
  ON public.user_daily_activity FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Deny client write on daily activity"
  ON public.user_daily_activity FOR ALL
  TO authenticated
  USING (false);

-- Subscription Entitlements: User read only (Never trust client for writes/upgrades)
CREATE POLICY "Users view own subscription entitlement"
  ON public.subscription_entitlements FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Deny client write on subscription entitlements"
  ON public.subscription_entitlements FOR ALL
  TO authenticated
  USING (false);

CREATE POLICY "Users view own subscription history"
  ON public.subscription_history FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Deny client write on subscription history"
  ON public.subscription_history FOR ALL
  TO authenticated
  USING (false);

-- Feature Flags: Public read; Overrides: User read only
CREATE POLICY "Public read feature flags"
  ON public.feature_flags FOR SELECT
  USING (true);

CREATE POLICY "Admin write feature flags"
  ON public.feature_flags FOR ALL
  TO authenticated
  USING (public.is_admin());

CREATE POLICY "Users view own feature overrides"
  ON public.user_feature_overrides FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Deny client write on feature overrides"
  ON public.user_feature_overrides FOR ALL
  TO authenticated
  USING (false);

-- Administrative Tables: Strictly Admin only
CREATE POLICY "Admins view admin roles"
  ON public.admin_roles FOR SELECT
  TO authenticated
  USING (public.is_admin());

CREATE POLICY "Deny client write on admin roles"
  ON public.admin_roles FOR ALL
  TO authenticated
  USING (false);

CREATE POLICY "Admins view audit events"
  ON public.admin_audit_events FOR SELECT
  TO authenticated
  USING (public.is_admin());

CREATE POLICY "Deny client write on admin audit events"
  ON public.admin_audit_events FOR ALL
  TO authenticated
  USING (false);

-- Rate Limit Buckets: Internal use only
CREATE POLICY "Deny public select on rate limit buckets"
  ON public.rate_limit_buckets FOR ALL
  USING (false);

-- ------------------------------------------------------------
-- 14. Seed Data for Games, Achievements, and Feature Flags
-- ------------------------------------------------------------
INSERT INTO public.games (id, slug, title, domain, description, instructions, duration_minutes, is_active)
VALUES
  (
    'memory-matrix',
    'memory-matrix',
    'Memory Matrix',
    'memory',
    'Memorize briefly illuminated spatial grid patterns and reproduce their positions.',
    'Observe the illuminated tiles on the grid. Reproduce the exact positions after the pattern clears.',
    3,
    true
  ),
  (
    'reflex-forge',
    'reflex-forge',
    'Reflex Forge',
    'flexibility',
    'Match geometric symbols to dynamically shifting rules with speed and precision.',
    'Match symbols by shape or pattern depending on the active rule. Adapt swiftly when the rule shifts.',
    3,
    true
  ),
  (
    'focus-reactor',
    'focus-reactor',
    'Focus Reactor',
    'attention',
    'Identify designated target symbols amidst visual distractors or signal absence.',
    'Scan the array for the target item. Select the matching slot or declare absence when missing.',
    3,
    true
  ),
  (
    'logic-labyrinth',
    'logic-labyrinth',
    'Logic Labyrinth',
    'problemSolving',
    'Plan and navigate optimal paths through spatial mazes with obstacles and checkpoints.',
    'Determine the shortest route to the exit. Collect the key checkpoint if present and reach the goal.',
    3,
    true
  ),
  (
    'number-pulse',
    'number-pulse',
    'Number Pulse',
    'speed',
    'Rapid mental arithmetic and numerical sequence recognition under time pressure.',
    'Observe the numerical sequence. Calculate the missing number and choose the correct answer swiftly.',
    3,
    true
  ),
  (
    'word-weaver',
    'word-weaver',
    'Word Weaver',
    'memory',
    'Rapid semantic association and vocabulary organization under cognitive load.',
    'Inspect the anchor word. Identify the matching term from the same conceptual category.',
    3,
    true
  )
ON CONFLICT (id) DO UPDATE
SET title = EXCLUDED.title,
    domain = EXCLUDED.domain,
    description = EXCLUDED.description,
    instructions = EXCLUDED.instructions,
    updated_at = timezone('utc'::text, now());

-- Seed Initial Versions (1.0.0)
INSERT INTO public.game_versions (game_id, version, engine_version, scoring_rules_version, is_current)
VALUES
  ('memory-matrix', '1.0.0', '1.0.0', '1.0.0', true),
  ('reflex-forge', '1.0.0', '1.0.0', '1.0.0', true),
  ('focus-reactor', '1.0.0', '1.0.0', '1.0.0', true),
  ('logic-labyrinth', '1.0.0', '1.0.0', '1.0.0', true),
  ('number-pulse', '1.0.0', '1.0.0', '1.0.0', true),
  ('word-weaver', '1.0.0', '1.0.0', '1.0.0', true)
ON CONFLICT (game_id, version) DO NOTHING;

-- Seed Achievements
INSERT INTO public.achievements (id, title, description, category, badge_icon, xp_reward, criteria)
VALUES
  ('first_steps', 'First Steps', 'Complete your very first cognitive exercise.', 'exploration', 'flag', 100, '{"sessions_required": 1}'::jsonb),
  ('perfectionist', 'Perfectionist', 'Attain 95% or higher accuracy in any standard game session.', 'accuracy', 'sparkles', 250, '{"min_accuracy": 0.95}'::jsonb),
  ('streak_starter', 'Consistent Mind', 'Train on 3 consecutive days to build a habit.', 'streak', 'fire', 200, '{"streak_days": 3}'::jsonb),
  ('streak_warrior', 'Unstoppable Momentum', 'Maintain a consecutive 7-day daily workout streak.', 'streak', 'zap', 500, '{"streak_days": 7}'::jsonb),
  ('polymath', 'Cognitive Polymath', 'Complete sessions across all five core cognitive domains.', 'mastery', 'globe', 400, '{"domains_required": 5}'::jsonb),
  ('speed_demon', 'Neural Velocity', 'Complete a session with an average reaction time under 400ms.', 'speed', 'gauge', 300, '{"max_median_rt_ms": 400}'::jsonb)
ON CONFLICT (id) DO UPDATE
SET title = EXCLUDED.title,
    description = EXCLUDED.description,
    xp_reward = EXCLUDED.xp_reward;

-- Seed Default Feature Flags
INSERT INTO public.feature_flags (flag_key, description, is_enabled, rollout_percentage)
VALUES
  ('adaptive_difficulty_v1', 'Enables transparent continuous skill rating adjustments.', true, 100),
  ('social_leaderboards', 'Opt-in weekly cohort comparisons for motivation.', false, 0),
  ('haptic_feedback', 'Tactile haptic pulse on correct pattern matches.', true, 100),
  ('offline_session_cache', 'Permits offline session buffering with idempotency reconciliation.', true, 100)
ON CONFLICT (flag_key) DO UPDATE
SET is_enabled = EXCLUDED.is_enabled;
