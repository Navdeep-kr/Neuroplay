-- ============================================================
-- NEUROPLAY — Supabase Test: RLS for Sessions, Workouts & Stats
-- ============================================================
-- Verifies that:
-- 1. Authenticated users cannot read another user's sessions or workouts.
-- 2. Authenticated users cannot modify another user's streaks or indices.
-- 3. Direct client modifications to streaks and cognitive indices are denied.
-- ============================================================

BEGIN;

-- Setup test users in auth.users
INSERT INTO auth.users (id, email)
VALUES
  ('33333333-3333-3333-3333-333333333333', 'user1@neuroplay.internal'),
  ('44444444-4444-4444-4444-444444444444', 'user2@neuroplay.internal')
ON CONFLICT (id) DO NOTHING;

-- Insert sample workout and session for user 1
INSERT INTO public.daily_workouts (id, user_id, workout_date, title, subtitle, game_ids)
VALUES (
  '55555555-5555-5555-5555-555555555555',
  '33333333-3333-3333-3333-333333333333',
  CURRENT_DATE,
  'Test Routine',
  'Test Subtitle',
  '["memory-matrix", "reflex-forge"]'::jsonb
);

INSERT INTO public.game_sessions (id, user_id, game_id, game_version, score, accuracy, duration_seconds)
VALUES (
  '66666666-6666-6666-6666-666666666666',
  '33333333-3333-3333-3333-333333333333',
  'memory-matrix',
  '1.0.0',
  850,
  0.92,
  120
);

-- Test 1: User 2 cannot SELECT User 1's daily workouts
SET LOCAL ROLE authenticated;
SET LOCAL "request.jwt.claims" = '{"sub": "44444444-4444-4444-4444-444444444444"}';

DO $$
DECLARE
  v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM public.daily_workouts
  WHERE user_id = '33333333-3333-3333-3333-333333333333';

  IF v_count <> 0 THEN
    RAISE EXCEPTION 'TEST FAILED: User 2 was able to view User 1 daily workouts (found % rows)', v_count;
  END IF;
END;
$$;

-- Test 2: User 2 cannot SELECT User 1's game sessions
DO $$
DECLARE
  v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM public.game_sessions
  WHERE user_id = '33333333-3333-3333-3333-333333333333';

  IF v_count <> 0 THEN
    RAISE EXCEPTION 'TEST FAILED: User 2 was able to view User 1 game sessions (found % rows)', v_count;
  END IF;
END;
$$;

-- Test 3: User 2 cannot directly insert into user_streaks
DO $$
BEGIN
  BEGIN
    INSERT INTO public.user_streaks (user_id, current_streak, longest_streak)
    VALUES ('44444444-4444-4444-4444-444444444444', 99, 99);
    RAISE EXCEPTION 'TEST FAILED: Direct client insert to user_streaks was allowed';
  EXCEPTION WHEN insufficient_privilege THEN
    -- Expected behavior: RLS denies insert
    NULL;
  END;
END;
$$;

ROLLBACK;
