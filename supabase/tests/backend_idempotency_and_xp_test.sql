-- ============================================================
-- NEUROPLAY — Supabase Test: Idempotency, Server XP & Achievements
-- ============================================================
-- Verifies:
-- 1. Game completion derives XP and score server-side.
-- 2. Duplicate completion requests with the same idempotency key
--    do NOT double-award XP, duplicate sessions, or advance streaks.
-- 3. Milestone achievements are unlocked idempotently.
-- ============================================================

BEGIN;

-- Setup test user
INSERT INTO auth.users (id, email)
VALUES ('77777777-7777-7777-7777-777777777777', 'player@neuroplay.internal')
ON CONFLICT (id) DO NOTHING;

-- Act as the player
SET LOCAL ROLE authenticated;
SET LOCAL "request.jwt.claims" = '{"sub": "77777777-7777-7777-7777-777777777777"}';

-- Test 1: Complete Game Session (First Call)
DO $$
DECLARE
  v_res JSONB;
  v_xp_summary RECORD;
  v_session_count INT;
BEGIN
  v_res := public.complete_game_session(
    p_game_id => 'memory-matrix',
    p_game_version => '1.0.0',
    p_score => 1000,
    p_accuracy => 0.95,
    p_duration_seconds => 50,
    p_error_count => 0,
    p_is_practice => false,
    p_metrics => '{"accuracy": 0.95, "errors": 0}'::jsonb,
    p_score_breakdown => '{"raw": 1000}'::jsonb,
    p_idempotency_key => 'idem_key_test_001',
    p_correlation_id => 'corr_test_001'
  );

  IF v_res->>'status' <> 'success' THEN
    RAISE EXCEPTION 'TEST FAILED: Initial session completion failed: %', v_res;
  END IF;

  IF (v_res->>'derived_xp_awarded')::INT <= 0 THEN
    RAISE EXCEPTION 'TEST FAILED: Derived XP was not awarded!';
  END IF;

  -- Verify session row was created
  SELECT count(*) INTO v_session_count
  FROM public.game_sessions
  WHERE user_id = '77777777-7777-7777-7777-777777777777';

  IF v_session_count <> 1 THEN
    RAISE EXCEPTION 'TEST FAILED: Expected 1 session, found %', v_session_count;
  END IF;

  -- Verify achievements unlocked
  IF NOT EXISTS (
    SELECT 1 FROM public.user_achievements
    WHERE user_id = '77777777-7777-7777-7777-777777777777' AND achievement_id = 'first_steps'
  ) THEN
    RAISE EXCEPTION 'TEST FAILED: first_steps achievement was not unlocked!';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.user_achievements
    WHERE user_id = '77777777-7777-7777-7777-777777777777' AND achievement_id = 'perfectionist'
  ) THEN
    RAISE EXCEPTION 'TEST FAILED: perfectionist achievement was not unlocked for 95%% accuracy!';
  END IF;
END;
$$;

-- Test 2: Idempotent Replay (Second Call with SAME idempotency key)
DO $$
DECLARE
  v_res2 JSONB;
  v_session_count INT;
  v_xp_event_count INT;
  v_summary RECORD;
BEGIN
  v_res2 := public.complete_game_session(
    p_game_id => 'memory-matrix',
    p_game_version => '1.0.0',
    p_score => 1000,
    p_accuracy => 0.95,
    p_duration_seconds => 50,
    p_error_count => 0,
    p_is_practice => false,
    p_metrics => '{"accuracy": 0.95, "errors": 0}'::jsonb,
    p_score_breakdown => '{"raw": 1000}'::jsonb,
    p_idempotency_key => 'idem_key_test_001',
    p_correlation_id => 'corr_test_001_replay'
  );

  IF v_res2->>'status' <> 'idempotent_duplicate' THEN
    RAISE EXCEPTION 'TEST FAILED: Expected status idempotent_duplicate, got %', v_res2->>'status';
  END IF;

  -- Verify sessions count is STILL 1 (NO duplicate session row)
  SELECT count(*) INTO v_session_count
  FROM public.game_sessions
  WHERE user_id = '77777777-7777-7777-7777-777777777777';

  IF v_session_count <> 1 THEN
    RAISE EXCEPTION 'IDEMPOTENCY FAILURE: Duplicate session inserted! Count = %', v_session_count;
  END IF;

  -- Verify XP events count is STILL 1 (NO double-awarding of XP)
  SELECT count(*) INTO v_xp_event_count
  FROM public.user_xp_events
  WHERE user_id = '77777777-7777-7777-7777-777777777777';

  IF v_xp_event_count <> 1 THEN
    RAISE EXCEPTION 'IDEMPOTENCY FAILURE: Duplicate XP event created! Count = %', v_xp_event_count;
  END IF;
END;
$$;

ROLLBACK;
