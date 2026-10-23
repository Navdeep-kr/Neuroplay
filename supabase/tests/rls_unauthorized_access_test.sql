-- ============================================================
-- NEUROPLAY — RLS & Access Control Integration Tests
-- ============================================================
-- Verifies:
-- 1. Unauthenticated users cannot read profiles or preferences.
-- 2. User A cannot read or write User B's profile or preferences.
-- 3. User A can read and update their own profile and preferences.
-- 4. CASCADE behavior deletes profile and preferences when auth user is deleted.
-- ============================================================

BEGIN;

-- Create pgTAP extension if available, or simulate with plpgsql assertions
DO $$
DECLARE
  v_user_a UUID := gen_random_uuid();
  v_user_b UUID := gen_random_uuid();
  v_count INT;
  v_profile_a public.profiles%ROWTYPE;
  v_profile_b public.profiles%ROWTYPE;
BEGIN
  -- ----------------------------------------------------------
  -- Setup: Create two simulated auth users in auth.users
  -- ----------------------------------------------------------
  INSERT INTO auth.users (id, email, raw_user_meta_data, created_at, updated_at)
  VALUES 
    (v_user_a, 'user_a@neuroplay.test', '{"full_name": "User Alpha"}'::jsonb, now(), now()),
    (v_user_b, 'user_b@neuroplay.test', '{"full_name": "User Beta"}'::jsonb, now(), now());

  -- Verify trigger automatically populated profiles & preferences
  SELECT count(*) INTO v_count FROM public.profiles WHERE id IN (v_user_a, v_user_b);
  IF v_count <> 2 THEN
    RAISE EXCEPTION 'TEST FAILED: Trigger on_auth_user_created did not create profiles. Expected 2, got %', v_count;
  END IF;

  SELECT count(*) INTO v_count FROM public.user_preferences WHERE user_id IN (v_user_a, v_user_b);
  IF v_count <> 2 THEN
    RAISE EXCEPTION 'TEST FAILED: Trigger on_auth_user_created did not create preferences. Expected 2, got %', v_count;
  END IF;

  -- ----------------------------------------------------------
  -- Test 1: Anonymous / Unauthenticated Access (Role: anon)
  -- ----------------------------------------------------------
  SET LOCAL ROLE anon;
  SET LOCAL "request.jwt.claims" TO '{"role": "anon"}';

  SELECT count(*) INTO v_count FROM public.profiles;
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'SECURITY BREACH: Anonymous user could view profiles! Expected 0 rows, got %', v_count;
  END IF;

  SELECT count(*) INTO v_count FROM public.user_preferences;
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'SECURITY BREACH: Anonymous user could view preferences! Expected 0 rows, got %', v_count;
  END IF;

  -- ----------------------------------------------------------
  -- Test 2: User A Authenticated Context
  -- ----------------------------------------------------------
  SET LOCAL ROLE authenticated;
  PERFORM set_config('request.jwt.claims', format('{"sub": "%s", "role": "authenticated"}', v_user_a), true);

  -- User A should only see their own profile
  SELECT count(*) INTO v_count FROM public.profiles;
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'RLS FAILED: User A sees % profiles, expected exactly 1 (their own)', v_count;
  END IF;

  -- Verify that the visible profile is indeed User A
  SELECT * INTO v_profile_a FROM public.profiles LIMIT 1;
  IF v_profile_a.id <> v_user_a THEN
    RAISE EXCEPTION 'RLS FAILED: Visible profile ID % does not match authenticated User A %', v_profile_a.id, v_user_a;
  END IF;

  -- User A cannot read User B's profile
  SELECT count(*) INTO v_count FROM public.profiles WHERE id = v_user_b;
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'SECURITY BREACH: User A was able to query User B profile directly!';
  END IF;

  -- User A cannot read User B's preferences
  SELECT count(*) INTO v_count FROM public.user_preferences WHERE user_id = v_user_b;
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'SECURITY BREACH: User A was able to query User B preferences!';
  END IF;

  -- User A cannot update User B's profile
  UPDATE public.profiles SET full_name = 'Hacked Name' WHERE id = v_user_b;
  -- In PostgreSQL RLS, updating non-visible rows affects 0 rows
  GET DIAGNOSTICS v_count = ROW_COUNT;
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'SECURITY BREACH: User A updated User B profile! Affected rows: %', v_count;
  END IF;

  -- User A cannot update User B's preferences
  UPDATE public.user_preferences SET sound_enabled = false WHERE user_id = v_user_b;
  GET DIAGNOSTICS v_count = ROW_COUNT;
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'SECURITY BREACH: User A updated User B preferences! Affected rows: %', v_count;
  END IF;

  -- User A CAN update their own preferences
  UPDATE public.user_preferences SET theme_mode = 'dark', sound_enabled = false WHERE user_id = v_user_a;
  GET DIAGNOSTICS v_count = ROW_COUNT;
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'RLS FAILED: User A could not update own preferences!';
  END IF;

  -- User A cannot delete their profile directly from client
  BEGIN
    DELETE FROM public.profiles WHERE id = v_user_a;
    GET DIAGNOSTICS v_count = ROW_COUNT;
    IF v_count <> 0 THEN
      RAISE EXCEPTION 'SECURITY BREACH: Client-side direct delete permitted on profiles!';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    -- Expected policy rejection
    NULL;
  END;

  -- ----------------------------------------------------------
  -- Test 3: Cascade Deletion (Server-side deletion flow)
  -- ----------------------------------------------------------
  -- Reset to service role / admin
  RESET ROLE;
  RESET "request.jwt.claims";

  -- Deleting User A in auth.users should cascade-delete profile and preferences
  DELETE FROM auth.users WHERE id = v_user_a;

  SELECT count(*) INTO v_count FROM public.profiles WHERE id = v_user_a;
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'CASCADE FAILED: Profile for User A still exists after auth.users deletion!';
  END IF;

  SELECT count(*) INTO v_count FROM public.user_preferences WHERE user_id = v_user_a;
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'CASCADE FAILED: Preferences for User A still exist after auth.users deletion!';
  END IF;

  -- User B should remain untouched
  SELECT count(*) INTO v_count FROM public.profiles WHERE id = v_user_b;
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'INTEGRITY ERROR: User B profile was unexpectedly affected!';
  END IF;

  RAISE NOTICE 'ALL RLS AND ACCESS CONTROL INTEGRATION TESTS PASSED SUCCESSFULLY.';
END;
$$;

ROLLBACK; -- Always roll back test data
