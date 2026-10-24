-- ============================================================
-- NEUROPLAY Database Migration
-- 20261024000004_subscription_webhooks_and_idempotency.sql
-- Idempotent Webhook Processing, Receipt Ledger & Entitlement Reconciliation
-- ============================================================

-- 1. Webhook Events Table (Guaranteed Deduplication)
CREATE TABLE IF NOT EXISTS public.subscription_webhook_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider TEXT NOT NULL CHECK (provider IN ('apple', 'google', 'stripe', 'revenuecat', 'manual')),
  event_id TEXT NOT NULL,
  event_type TEXT NOT NULL,
  payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  status TEXT NOT NULL DEFAULT 'received' CHECK (status IN ('received', 'processed', 'duplicate', 'failed')),
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  processed_at TIMESTAMPTZ,
  error_message TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT uq_webhook_provider_event UNIQUE (provider, event_id)
);

CREATE INDEX IF NOT EXISTS idx_webhook_events_user ON public.subscription_webhook_events(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_webhook_events_status ON public.subscription_webhook_events(status, created_at DESC);

-- Enable RLS (Service role only; zero client access)
ALTER TABLE public.subscription_webhook_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Deny all client operations on webhook events"
  ON public.subscription_webhook_events FOR ALL
  TO authenticated, anon
  USING (false);

-- ------------------------------------------------------------
-- 2. Idempotent Webhook Processor (SECURITY DEFINER)
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.process_subscription_webhook(
  p_provider TEXT,
  p_event_id TEXT,
  p_event_type TEXT,
  p_user_id UUID,
  p_tier TEXT,
  p_status TEXT,
  p_valid_until TIMESTAMPTZ,
  p_auto_renew BOOLEAN,
  p_external_id TEXT,
  p_payload JSONB DEFAULT '{}'::jsonb
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_existing_event RECORD;
  v_current_entitlement RECORD;
  v_features JSONB;
BEGIN
  -- 1. Idempotency Check: prevent duplicate event processing
  SELECT id, status INTO v_existing_event
  FROM public.subscription_webhook_events
  WHERE provider = p_provider AND event_id = p_event_id;

  IF FOUND THEN
    RETURN jsonb_build_object(
      'status', 'duplicate_ignored',
      'event_id', p_event_id,
      'provider', p_provider,
      'original_status', v_existing_event.status
    );
  END IF;

  -- 2. Determine feature entitlement list based on tier
  IF p_tier = 'pro' THEN
    v_features := '["standard_games", "daily_workout", "cloud_sync", "deep_analytics", "faculty_distribution", "priority_support"]'::jsonb;
  ELSIF p_tier = 'family' OR p_tier = 'lifetime' THEN
    v_features := '["standard_games", "daily_workout", "cloud_sync", "deep_analytics", "faculty_distribution", "priority_support", "family_sharing"]'::jsonb;
  ELSE
    v_features := '["standard_games", "daily_workout"]'::jsonb;
  END IF;

  -- 3. Log incoming webhook event
  INSERT INTO public.subscription_webhook_events (
    provider,
    event_id,
    event_type,
    payload,
    status,
    user_id,
    processed_at
  ) VALUES (
    p_provider,
    p_event_id,
    p_event_type,
    p_payload,
    'processed',
    p_user_id,
    timezone('utc'::text, now())
  );

  -- 4. Reconcile with existing user entitlement
  SELECT tier, status INTO v_current_entitlement
  FROM public.subscription_entitlements
  WHERE user_id = p_user_id;

  -- Upsert entitlement record
  INSERT INTO public.subscription_entitlements (
    user_id,
    tier,
    status,
    features,
    valid_until,
    auto_renew,
    provider,
    external_subscription_id,
    updated_at
  ) VALUES (
    p_user_id,
    p_tier,
    p_status,
    v_features,
    p_valid_until,
    p_auto_renew,
    p_provider,
    p_external_id,
    timezone('utc'::text, now())
  )
  ON CONFLICT (user_id) DO UPDATE SET
    tier = EXCLUDED.tier,
    status = EXCLUDED.status,
    features = EXCLUDED.features,
    valid_until = EXCLUDED.valid_until,
    auto_renew = EXCLUDED.auto_renew,
    provider = EXCLUDED.provider,
    external_subscription_id = EXCLUDED.external_subscription_id,
    updated_at = timezone('utc'::text, now());

  -- 5. Record state transition in subscription_history if tier changed
  IF NOT FOUND OR v_current_entitlement.tier IS DISTINCT FROM p_tier THEN
    INSERT INTO public.subscription_history (
      user_id,
      previous_tier,
      new_tier,
      reason,
      created_at
    ) VALUES (
      p_user_id,
      COALESCE(v_current_entitlement.tier, 'free'),
      p_tier,
      p_event_type || ' via ' || p_provider,
      timezone('utc'::text, now())
    );
  END IF;

  -- 6. Audit event
  INSERT INTO public.admin_audit_events (
    actor_id,
    action,
    target_resource,
    details
  ) VALUES (
    p_user_id,
    'SUBSCRIPTION_WEBHOOK_PROCESSED',
    'subscription_entitlements/' || p_user_id::text,
    jsonb_build_object(
      'provider', p_provider,
      'event_id', p_event_id,
      'event_type', p_event_type,
      'new_tier', p_tier,
      'new_status', p_status
    )
  );

  RETURN jsonb_build_object(
    'status', 'processed',
    'user_id', p_user_id,
    'tier', p_tier,
    'entitlement_status', p_status,
    'valid_until', p_valid_until
  );
END;
$$;

-- ------------------------------------------------------------
-- 3. Restore Purchases & Conflict Reconciliation (SECURITY DEFINER)
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.verify_and_restore_subscription(
  p_provider TEXT,
  p_external_id TEXT,
  p_requesting_user_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_existing_owner UUID;
  v_entitlement RECORD;
BEGIN
  -- Look for an existing account linked to this external subscription
  SELECT user_id, tier, status, valid_until
  INTO v_entitlement
  FROM public.subscription_entitlements
  WHERE provider = p_provider AND external_subscription_id = p_external_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'reason', 'NO_ACTIVE_SUBSCRIPTION_FOUND',
      'message', 'No active subscription was found matching the provided transaction.'
    );
  END IF;

  -- If already owned by requesting user, return success
  IF v_entitlement.user_id = p_requesting_user_id THEN
    RETURN jsonb_build_object(
      'success', true,
      'tier', v_entitlement.tier,
      'status', v_entitlement.status,
      'valid_until', v_entitlement.valid_until,
      'message', 'Subscription restored successfully.'
    );
  END IF;

  -- Transfer conflict check
  IF v_entitlement.status IN ('active', 'trialing') THEN
    RETURN jsonb_build_object(
      'success', false,
      'reason', 'OWNERSHIP_CONFLICT',
      'existing_owner_masked', SUBSTRING(v_entitlement.user_id::text, 1, 8) || '...',
      'message', 'This subscription is already active on another account. Please log in with that account.'
    );
  END IF;

  -- Inactive on previous account -> transfer entitlement to current user
  UPDATE public.subscription_entitlements
  SET user_id = p_requesting_user_id,
      updated_at = timezone('utc'::text, now())
  WHERE provider = p_provider AND external_subscription_id = p_external_id;

  RETURN jsonb_build_object(
    'success', true,
    'tier', v_entitlement.tier,
    'status', v_entitlement.status,
    'valid_until', v_entitlement.valid_until,
    'message', 'Subscription transferred and restored to your account.'
  );
END;
$$;
