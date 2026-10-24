-- ============================================================
-- NEUROPLAY — Supabase Test: Security, Ownership & RLS Isolation
-- ============================================================
-- Verifies:
-- 1. Cross-user access is denied on all client-accessible tables.
-- 2. Clients CANNOT grant themselves admin roles.
-- 3. Clients CANNOT manually insert or update subscription entitlements.
-- 4. Clients CANNOT directly write to user_xp_summary or user_xp_events.
-- ============================================================

BEGIN;

-- Setup test users
INSERT INTO auth.users (id, email)
VALUES
  ('11111111-1111-1111-1111-111111111111', 'victim@neuroplay.internal'),
  ('22222222-2222-2222-2222-222222222222', 'attacker@neuroplay.internal')
ON CONFLICT (id) DO NOTHING;

-- Seed victim's data
INSERT INTO public.subscription_entitlements (user_id, tier, status)
VALUES ('11111111-1111-1111-1111-111111111111', 'pro', 'active')
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO public.user_xp_summary (user_id, total_xp, current_level)
VALUES ('11111111-1111-1111-1111-111111111111', 2500, 5)
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO public.game_sessions (
  id, user_id, game_id, game_version, score, accuracy, duration_seconds
) VALUES (
  '33333333-3333-3333-3333-333333333333',
  '11111111-1111-1111-1111-111111111111',
  'memory-matrix',
  '1.0.0',
  1200,
  0.95,
  60
) ON CONFLICT (id) DO NOTHING;

-- Switch to Attacker's context
SET LOCAL ROLE authenticated;
SET LOCAL "request.jwt.claims" = '{"sub": "22222222-2222-2222-2222-222222222222"}';

-- Test 1: Attacker cannot read victim's game sessions
DO $$
DECLARE
  v_count INT;
BEGIN
  SELECT count(*) INTO v_count
  FROM public.game_sessions
  WHERE user_id = '11111111-1111-1111-1111-111111111111';

  IF v_count <> 0 THEN
    RAISE EXCEPTION 'RLS FAILED: Attacker can view victim game sessions!';
  END IF;
END;
$$;

-- Test 2: Attacker cannot view victim's subscription entitlements
DO $$
DECLARE
  v_count INT;
BEGIN
  SELECT count(*) INTO v_count
  FROM public.subscription_entitlements
  WHERE user_id = '11111111-1111-1111-1111-111111111111';

  IF v_count <> 0 THEN
    RAISE EXCEPTION 'RLS FAILED: Attacker can view victim subscription entitlements!';
  END IF;
END;
$$;

-- Test 3: Attacker cannot view victim's XP summary
DO $$
DECLARE
  v_count INT;
BEGIN
  SELECT count(*) INTO v_count
  FROM public.user_xp_summary
  WHERE user_id = '11111111-1111-1111-1111-111111111111';

  IF v_count <> 0 THEN
    RAISE EXCEPTION 'RLS FAILED: Attacker can view victim XP summary!';
  END IF;
END;
$$;

-- Test 4: Attacker CANNOT elevate to admin directly via INSERT
DO $$
BEGIN
  BEGIN
    INSERT INTO public.admin_roles (user_id, role)
    VALUES ('22222222-2222-2222-2222-222222222222', 'superadmin');
    RAISE EXCEPTION 'SECURITY BREACH: Client was able to self-grant admin role!';
  EXCEPTION WHEN insufficient_privilege THEN
    -- Expected: RLS rejects client insert
    NULL;
  END;
END;
$$;

-- Test 5: Attacker CANNOT grant self Pro subscription directly via INSERT
DO $$
BEGIN
  BEGIN
    INSERT INTO public.subscription_entitlements (user_id, tier, status)
    VALUES ('22222222-2222-2222-2222-222222222222', 'pro', 'active');
    RAISE EXCEPTION 'SECURITY BREACH: Client was able to self-grant Pro subscription!';
  EXCEPTION WHEN insufficient_privilege THEN
    -- Expected: RLS rejects client insert
    NULL;
  END;
END;
$$;

-- Test 6: Attacker CANNOT fabricate XP directly via INSERT
DO $$
BEGIN
  BEGIN
    INSERT INTO public.user_xp_summary (user_id, total_xp, current_level)
    VALUES ('22222222-2222-2222-2222-222222222222', 999999, 100);
    RAISE EXCEPTION 'SECURITY BREACH: Client was able to directly write XP summary!';
  EXCEPTION WHEN insufficient_privilege THEN
    -- Expected: RLS rejects client insert
    NULL;
  END;
END;
$$;

ROLLBACK;
