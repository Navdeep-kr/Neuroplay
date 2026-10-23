-- ============================================================
-- NEUROPLAY — Phase 4: Game Sessions, Workouts, Streaks & Stats
-- ============================================================
-- Creates tables, RPC functions, and Row-Level Security (RLS)
-- policies for persisting game results, tracking daily workouts,
-- computing consecutive-day streaks, and aggregating cognitive indices.
-- ============================================================

-- 1. Daily Workouts Table
CREATE TABLE IF NOT EXISTS public.daily_workouts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  workout_date DATE NOT NULL,
  title TEXT NOT NULL,
  subtitle TEXT NOT NULL,
  estimated_minutes INTEGER NOT NULL DEFAULT 8,
  game_ids JSONB NOT NULL DEFAULT '[]'::jsonb,
  completed_game_ids JSONB NOT NULL DEFAULT '[]'::jsonb,
  is_completed BOOLEAN NOT NULL DEFAULT FALSE,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT uq_user_workout_date UNIQUE (user_id, workout_date)
);

CREATE INDEX IF NOT EXISTS idx_daily_workouts_user_date ON public.daily_workouts(user_id, workout_date DESC);

-- 2. Game Sessions Table
CREATE TABLE IF NOT EXISTS public.game_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  workout_id UUID REFERENCES public.daily_workouts(id) ON DELETE SET NULL,
  game_id TEXT NOT NULL,
  game_version TEXT NOT NULL,
  score INTEGER NOT NULL CHECK (score >= 0),
  accuracy NUMERIC(5, 4) NOT NULL CHECK (accuracy >= 0 AND accuracy <= 1),
  duration_seconds INTEGER NOT NULL CHECK (duration_seconds >= 0),
  error_count INTEGER NOT NULL DEFAULT 0 CHECK (error_count >= 0),
  is_practice BOOLEAN NOT NULL DEFAULT FALSE,
  metrics JSONB NOT NULL DEFAULT '{}'::jsonb,
  score_breakdown JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_game_sessions_user_created ON public.game_sessions(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_game_sessions_user_game ON public.game_sessions(user_id, game_id);

-- 3. User Streaks Table
CREATE TABLE IF NOT EXISTS public.user_streaks (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  current_streak INTEGER NOT NULL DEFAULT 0 CHECK (current_streak >= 0),
  longest_streak INTEGER NOT NULL DEFAULT 0 CHECK (longest_streak >= 0),
  last_activity_date DATE,
  total_sessions_completed INTEGER NOT NULL DEFAULT 0 CHECK (total_sessions_completed >= 0),
  total_workouts_completed INTEGER NOT NULL DEFAULT 0 CHECK (total_workouts_completed >= 0),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 4. Cognitive Domain Indices Table
CREATE TABLE IF NOT EXISTS public.cognitive_indices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  domain TEXT NOT NULL CHECK (domain IN ('memory', 'attention', 'speed', 'flexibility', 'problemSolving')),
  score_index INTEGER NOT NULL DEFAULT 50 CHECK (score_index >= 0 AND score_index <= 100),
  percentile_rank INTEGER NOT NULL DEFAULT 50 CHECK (percentile_rank >= 1 AND percentile_rank <= 99),
  trend_percentage INTEGER NOT NULL DEFAULT 0,
  sample_count INTEGER NOT NULL DEFAULT 0 CHECK (sample_count >= 0),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT uq_user_domain UNIQUE (user_id, domain)
);

CREATE INDEX IF NOT EXISTS idx_cognitive_indices_user ON public.cognitive_indices(user_id);

-- 5. Updated_at Trigger for daily_workouts and user_streaks
CREATE OR REPLACE TRIGGER tr_daily_workouts_updated_at
  BEFORE UPDATE ON public.daily_workouts
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE OR REPLACE TRIGGER tr_user_streaks_updated_at
  BEFORE UPDATE ON public.user_streaks
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE OR REPLACE TRIGGER tr_cognitive_indices_updated_at
  BEFORE UPDATE ON public.cognitive_indices
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 6. Helper Function: Map Game ID to Cognitive Domain
CREATE OR REPLACE FUNCTION public.get_game_domain(p_game_id TEXT)
RETURNS TEXT AS $$
BEGIN
  CASE p_game_id
    WHEN 'memory-matrix' THEN RETURN 'memory';
    WHEN 'reflex-forge' THEN RETURN 'flexibility';
    WHEN 'focus-reactor' THEN RETURN 'attention';
    WHEN 'reaction-time' THEN RETURN 'speed';
    WHEN 'logic-path' THEN RETURN 'problemSolving';
    ELSE RETURN 'memory';
  END CASE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- 7. Trusted Stored Procedure: record_game_session
-- Inserts session, updates streak, checks workout progress, and updates cognitive index.
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
DECLARE
  v_user_id UUID;
  v_session_id UUID;
  v_today DATE := CURRENT_DATE;
  v_streak RECORD;
  v_new_current INTEGER;
  v_new_longest INTEGER;
  v_workout_completed BOOLEAN := FALSE;
  v_domain TEXT;
  v_new_index INTEGER;
  v_sample_count INTEGER;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required to record game session';
  END IF;

  -- 1. Insert session record
  INSERT INTO public.game_sessions (
    user_id, workout_id, game_id, game_version, score,
    accuracy, duration_seconds, error_count, is_practice,
    metrics, score_breakdown
  ) VALUES (
    v_user_id, p_workout_id, p_game_id, p_game_version, p_score,
    p_accuracy, p_duration_seconds, p_error_count, p_is_practice,
    p_metrics, p_score_breakdown
  ) RETURNING id INTO v_session_id;

  -- 2. If part of a daily workout, update workout progress
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

  -- 3. Update User Streaks (practice sessions count towards total sessions, but standard sessions count for streak)
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
      -- Already trained today, keep current streak
      v_new_current := v_streak.current_streak;
    ELSIF v_streak.last_activity_date = (v_today - INTERVAL '1 day')::DATE THEN
      -- Consecutive day!
      v_new_current := v_streak.current_streak + 1;
    ELSE
      -- Missed at least one calendar day, reset streak to 1
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

  -- 4. Update Cognitive Domain Index (only for non-practice sessions)
  IF NOT p_is_practice THEN
    v_domain := public.get_game_domain(p_game_id);
    -- Calculate normalized score index (0-100) based on accuracy and score
    -- Base index formula: 70% accuracy weight + 30% score scale
    v_new_index := LEAST(100, GREATEST(10, ROUND((p_accuracy * 70) + LEAST(30, p_score / 50))));

    INSERT INTO public.cognitive_indices (user_id, domain, score_index, percentile_rank, trend_percentage, sample_count)
    VALUES (v_user_id, v_domain, v_new_index, LEAST(99, GREATEST(1, v_new_index + 2)), 0, 1)
    ON CONFLICT (user_id, domain) DO UPDATE
    SET score_index = ROUND((cognitive_indices.score_index * 0.7) + (v_new_index * 0.3)),
        sample_count = cognitive_indices.sample_count + 1,
        trend_percentage = ROUND(v_new_index - cognitive_indices.score_index),
        percentile_rank = LEAST(99, GREATEST(1, ROUND((cognitive_indices.score_index * 0.7) + (v_new_index * 0.3)) + 2));
  END IF;

  RETURN jsonb_build_object(
    'session_id', v_session_id,
    'current_streak', v_new_current,
    'longest_streak', v_new_longest,
    'workout_completed', v_workout_completed
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ============================================================
-- 8. Row-Level Security (RLS) Policies
-- ============================================================

ALTER TABLE public.daily_workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.game_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_streaks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cognitive_indices ENABLE ROW LEVEL SECURITY;

-- DAILY WORKOUTS POLICIES
CREATE POLICY "Users can view own daily workouts"
  ON public.daily_workouts FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create own daily workouts"
  ON public.daily_workouts FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own daily workouts"
  ON public.daily_workouts FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Deny client delete on daily workouts"
  ON public.daily_workouts FOR DELETE
  TO authenticated
  USING (false);

-- GAME SESSIONS POLICIES
CREATE POLICY "Users can view own game sessions"
  ON public.game_sessions FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own game sessions"
  ON public.game_sessions FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Deny client update on game sessions"
  ON public.game_sessions FOR UPDATE
  TO authenticated
  USING (false);

CREATE POLICY "Deny client delete on game sessions"
  ON public.game_sessions FOR DELETE
  TO authenticated
  USING (false);

-- USER STREAKS POLICIES
CREATE POLICY "Users can view own streaks"
  ON public.user_streaks FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Deny direct client insert on streaks"
  ON public.user_streaks FOR INSERT
  TO authenticated
  WITH CHECK (false);

CREATE POLICY "Deny direct client update on streaks"
  ON public.user_streaks FOR UPDATE
  TO authenticated
  USING (false);

CREATE POLICY "Deny direct client delete on streaks"
  ON public.user_streaks FOR DELETE
  TO authenticated
  USING (false);

-- COGNITIVE INDICES POLICIES
CREATE POLICY "Users can view own cognitive indices"
  ON public.cognitive_indices FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Deny direct client modification on cognitive indices"
  ON public.cognitive_indices FOR ALL
  TO authenticated
  USING (false);
