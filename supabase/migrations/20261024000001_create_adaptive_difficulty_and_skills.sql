-- ============================================================
-- NEUROPLAY — Adaptive Difficulty Engine & Skill Ratings
-- ============================================================
-- Creates tables and RLS policies for tracking continuous skill
-- estimates (0-100), bounded difficulty tiers (easy/medium/hard/expert),
-- and adjustment audit histories with versioned rationale.
-- ============================================================

-- 1. User Game Skills Table (Continuous Skill Estimates)
CREATE TABLE IF NOT EXISTS public.user_game_skills (
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  game_id TEXT NOT NULL,
  continuous_rating NUMERIC(5, 2) NOT NULL DEFAULT 50.00
    CHECK (continuous_rating >= 0.0 AND continuous_rating <= 100.0),
  recommended_difficulty TEXT NOT NULL DEFAULT 'medium'
    CHECK (recommended_difficulty IN ('easy', 'medium', 'hard', 'expert')),
  sample_count INTEGER NOT NULL DEFAULT 0 CHECK (sample_count >= 0),
  consecutive_strong_sessions INTEGER NOT NULL DEFAULT 0 CHECK (consecutive_strong_sessions >= 0),
  consecutive_weak_sessions INTEGER NOT NULL DEFAULT 0 CHECK (consecutive_weak_sessions >= 0),
  last_adjustment_reason TEXT,
  algorithm_version TEXT NOT NULL DEFAULT '1.0.0',
  last_updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  PRIMARY KEY (user_id, game_id)
);

CREATE INDEX IF NOT EXISTS idx_user_game_skills_user ON public.user_game_skills(user_id);

-- 2. Difficulty Adjustments Audit Log Table
CREATE TABLE IF NOT EXISTS public.difficulty_adjustments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  game_id TEXT NOT NULL,
  previous_difficulty TEXT NOT NULL CHECK (previous_difficulty IN ('easy', 'medium', 'hard', 'expert')),
  new_difficulty TEXT NOT NULL CHECK (new_difficulty IN ('easy', 'medium', 'hard', 'expert')),
  previous_rating NUMERIC(5, 2) NOT NULL,
  new_rating NUMERIC(5, 2) NOT NULL,
  rating_delta NUMERIC(5, 2) NOT NULL,
  is_damped BOOLEAN NOT NULL DEFAULT FALSE,
  reason TEXT NOT NULL,
  algorithm_version TEXT NOT NULL DEFAULT '1.0.0',
  metrics_snapshot JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_difficulty_adjustments_user_game
  ON public.difficulty_adjustments(user_id, game_id, created_at DESC);

-- 3. Row-Level Security (RLS) Policies
ALTER TABLE public.user_game_skills ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.difficulty_adjustments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can select own skill estimates"
  ON public.user_game_skills FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own skill estimates"
  ON public.user_game_skills FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own skill estimates"
  ON public.user_game_skills FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own skill estimates"
  ON public.user_game_skills FOR DELETE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can select own difficulty adjustments"
  ON public.difficulty_adjustments FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own difficulty adjustments"
  ON public.difficulty_adjustments FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- 4. Update Game Domain Mapping to include all 6 original games
CREATE OR REPLACE FUNCTION public.get_game_domain(p_game_id TEXT)
RETURNS TEXT AS $$
BEGIN
  CASE p_game_id
    WHEN 'memory-matrix' THEN RETURN 'memory';
    WHEN 'reflex-forge' THEN RETURN 'flexibility';
    WHEN 'focus-reactor' THEN RETURN 'attention';
    WHEN 'logic-labyrinth' THEN RETURN 'problemSolving';
    WHEN 'number-pulse' THEN RETURN 'speed';
    WHEN 'word-weaver' THEN RETURN 'memory';
    ELSE RETURN 'memory';
  END CASE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;
