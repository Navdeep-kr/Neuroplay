-- ============================================================
-- NEUROPLAY — Seed Data for Local Development
-- ============================================================
-- Executed by `supabase db reset` after migrations.
-- ============================================================

-- 1. Games Catalog
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

-- 2. Game Versions
INSERT INTO public.game_versions (game_id, version, engine_version, scoring_rules_version, is_current)
VALUES
  ('memory-matrix', '1.0.0', '1.0.0', '1.0.0', true),
  ('reflex-forge', '1.0.0', '1.0.0', '1.0.0', true),
  ('focus-reactor', '1.0.0', '1.0.0', '1.0.0', true),
  ('logic-labyrinth', '1.0.0', '1.0.0', '1.0.0', true),
  ('number-pulse', '1.0.0', '1.0.0', '1.0.0', true),
  ('word-weaver', '1.0.0', '1.0.0', '1.0.0', true)
ON CONFLICT (game_id, version) DO NOTHING;

-- 3. Core Achievements
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

-- 4. Feature Flags
INSERT INTO public.feature_flags (flag_key, description, is_enabled, rollout_percentage)
VALUES
  ('adaptive_difficulty_v1', 'Enables transparent continuous skill rating adjustments.', true, 100),
  ('social_leaderboards', 'Opt-in weekly cohort comparisons for motivation.', false, 0),
  ('haptic_feedback', 'Tactile haptic pulse on correct pattern matches.', true, 100),
  ('offline_session_cache', 'Permits offline session buffering with idempotency reconciliation.', true, 100)
ON CONFLICT (flag_key) DO UPDATE
SET is_enabled = EXCLUDED.is_enabled;
