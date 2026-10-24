-- ============================================================
-- NEUROPLAY — Supabase Test: Validation, Rate Limits & Workouts
-- ============================================================
-- Verifies:
-- 1. Malformed inputs (negative duration, accuracy > 1.0) are rejected.
-- 2. Rate limiter enforces sliding-window threshold on abusive calls.
-- 3. get_or_create_daily_workout deterministically generates and caches workouts.
-- ============================================================

BEGIN;

-- Setup test user
INSERT INTO auth.users (id, email)
VALUES ('88888888-8888-8888-8888-888888888888', 'tester@neuroplay.internal')
ON CONFLICT (id) DO NOTHING;

-- Act as user
SET LOCAL ROLE authenticated;
SET LOCAL "request.jwt.claims" = '{"sub": "88888888-8888-8888-8888-888888888888"}';

-- Test 1: Reject accuracy > 1.0
DO $$
BEGIN
  BEGIN
    PERFORM public.complete_game_session(
      p_game_id => 'memory-matrix',
      p_game_version => '1.0.0',
      p_score => 800,
      p_accuracy => 1.5, -- INVALID ACCURACY (> 1.0)
      p_duration_seconds => 45,
      p_error_count => 0,
      p_is_practice => false,
      p_metrics => '{}'::jsonb,
      p_score_breakdown => '{}'::jsonb,
      p_idempotency_key => 'bad_acc_test'
    );
    RAISE EXCEPTION 'TEST FAILED: Invalid accuracy > 1.0 was accepted!';
  EXCEPTION WHEN numeric_value_out_of_range THEN
    -- Expected rejection
    NULL;
  END;
END;
$$;

-- Test 2: Reject negative duration
DO $$
BEGIN
  BEGIN
    PERFORM public.complete_game_session(
      p_game_id => 'memory-matrix',
      p_game_version => '1.0.0',
      p_score => 800,
      p_accuracy => 0.8,
      p_duration_seconds => -10, -- INVALID DURATION (< 0)
      p_error_count => 0,
      p_is_practice => false,
      p_metrics => '{}'::jsonb,
      p_score_breakdown => '{}'::jsonb,
      p_idempotency_key => 'bad_dur_test'
    );
    RAISE EXCEPTION 'TEST FAILED: Negative duration was accepted!';
  EXCEPTION WHEN numeric_value_out_of_range THEN
    -- Expected rejection
    NULL;
  END;
END;
$$;

-- Test 3: Rate Limiter enforcement
DO $$
DECLARE
  v_res BOOLEAN;
  v_i INT;
  v_blocked BOOLEAN := FALSE;
BEGIN
  -- Bucket with limit of 3 requests in 60s
  FOR v_i IN 1..5 LOOP
    v_res := public.check_rate_limit('test_rate_bucket', 3, 60);
    IF NOT v_res THEN
      v_blocked := TRUE;
      EXIT;
    END IF;
  END LOOP;

  IF NOT v_blocked THEN
    RAISE EXCEPTION 'TEST FAILED: Rate limiter failed to block requests exceeding threshold!';
  END IF;
END;
$$;

-- Test 4: Deterministic daily workout generation RPC
DO $$
DECLARE
  v_workout1 JSONB;
  v_workout2 JSONB;
BEGIN
  v_workout1 := public.get_or_create_daily_workout(CURRENT_DATE, 'corr_workout_01');

  IF (v_workout1->>'is_fresh')::BOOLEAN <> TRUE THEN
    RAISE EXCEPTION 'TEST FAILED: First call should generate fresh workout!';
  END IF;

  IF jsonb_array_length(v_workout1->'game_ids') <> 3 THEN
    RAISE EXCEPTION 'TEST FAILED: Expected 3 games in playlist, got %', jsonb_array_length(v_workout1->'game_ids');
  END IF;

  -- Second call on same date should return cached workout
  v_workout2 := public.get_or_create_daily_workout(CURRENT_DATE, 'corr_workout_02');

  IF (v_workout2->>'is_fresh')::BOOLEAN <> FALSE THEN
    RAISE EXCEPTION 'TEST FAILED: Second call should return cached workout (is_fresh = false)!';
  END IF;

  IF v_workout1->>'id' <> v_workout2->>'id' THEN
    RAISE EXCEPTION 'TEST FAILED: Workout IDs do not match between calls!';
  END IF;
END;
$$;

ROLLBACK;
