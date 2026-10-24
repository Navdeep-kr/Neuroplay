# NEUROPLAY — Supabase Backend & Database Architecture Guide

This document outlines the complete Supabase backend architecture, migration setup, security constraints, and operational procedures for NEUROPLAY.

---

## 1. Architecture Overview

The NEUROPLAY backend uses Supabase (PostgreSQL 15, Auth, Storage, and Edge Functions) designed with a strict **Zero-Trust Client Principle**:
- **Zero Client Trust**: The client never calculates or awards durable XP, unlocks achievements, grants subscription tiers, or self-elevates administrative privileges.
- **Idempotent Mutation Pipeline**: All game completions, XP issuances, and achievement unlocks use idempotency keys to ensure duplicate or replayed network requests never double-award points, duplicate records, or distort streaks.
- **Strict Row-Level Security (RLS)**: Every client-accessible table enforces granular RLS policies ensuring users can only read their own data, and administrative tables completely deny direct client write operations.
- **Deterministic Workout Selection Policy**: Server stored procedure `get_or_create_daily_workout` generates balanced, varied multi-domain workouts backed by deterministic seeding and anti-repetition guards.

---

## 2. Database Migration Pipeline

All database schema migrations are version-controlled and located in `supabase/migrations/`:

| Migration File | Description |
|---|---|
| [`20261023000001_create_profiles_and_preferences.sql`](file:///d:/Neuroplay/supabase/migrations/20261023000001_create_profiles_and_preferences.sql) | Profiles, preferences, auth triggers, and cascade deletion. |
| [`20261023000002_create_game_sessions_workouts_and_stats.sql`](file:///d:/Neuroplay/supabase/migrations/20261023000002_create_game_sessions_workouts_and_stats.sql) | Game sessions, daily workouts, user streaks, and domain indices. |
| [`20261024000001_create_adaptive_difficulty_and_skills.sql`](file:///d:/Neuroplay/supabase/migrations/20261024000001_create_adaptive_difficulty_and_skills.sql) | Continuous skill ratings (0–100), bounded tiers, and hysteresis audit logs. |
| [`20261024000002_create_backend_core_and_entitlements.sql`](file:///d:/Neuroplay/supabase/migrations/20261024000002_create_backend_core_and_entitlements.sql) | Games catalog, versions, XP leveling engine, achievements, daily activity, subscription entitlements, feature flags, admin roles & audit, rate limiter, and session completion RPCs. |

---

## 3. Local Setup Instructions

### Prerequisites
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (running)
- Node.js 18+ or 20+
- [Supabase CLI](https://supabase.com/docs/guides/cli) (`npm install -g supabase` or `npx supabase`)

### Initializing and Starting Local Supabase
```bash
# 1. Start local Supabase containers (Postgres, Auth, Storage, Studio, Kong)
npx supabase start

# 2. Reset database and run all migrations in sequence + execute seed.sql
npx supabase db reset

# 3. View local Supabase Studio dashboard
# Open in browser: http://127.0.0.1:54323
```

### Running Backend Integration Tests
The test suites verify ownership, RLS denial, idempotency guarantees, rate limits, and server-side validation:
```bash
# Run all pgTAP / SQL integration test suites
npx supabase test db
```

Or run individual test files:
```bash
# Security & RLS Isolation tests
npx supabase test db --file supabase/tests/backend_security_and_rls_test.sql

# Idempotency & Server XP tests
npx supabase test db --file supabase/tests/backend_idempotency_and_xp_test.sql

# Input validation & Rate Limit tests
npx supabase test db --file supabase/tests/backend_validation_and_rate_limit_test.sql
```

---

## 4. Environment Variables Documentation

Set in `.env` (or via `npx supabase secrets set` in production):

| Variable | Scope | Description | Never Commit |
|---|---|---|---|
| `SUPABASE_URL` | Client & Functions | API endpoint URL (e.g. `http://127.0.0.1:54321` or `https://<ref>.supabase.co`). | Yes (safe to distribute) |
| `SUPABASE_ANON_KEY` | Client & Functions | Public anonymous key for client requests subjected to RLS. | Yes (safe to distribute) |
| `SUPABASE_SERVICE_ROLE_KEY` | Server & Functions only | Privileged service key bypassing RLS. Used exclusively in trusted Edge Functions. | **NEVER COMMIT TO GIT** |
| `SUPABASE_DB_URL` | Server & CI only | Direct PostgreSQL connection string. | **NEVER COMMIT TO GIT** |

---

## 5. Security Review Checklist

- [x] **Client-Side Authorization Isolation**:
  - `admin_roles` cannot be modified by authenticated clients; RLS strictly denies client INSERT/UPDATE/DELETE.
  - `subscription_entitlements` cannot be granted or upgraded by clients; only readable via RLS and updated via service-role webhooks (e.g. Stripe/App Store).
- [x] **Durable XP & Leveling Integrity**:
  - Direct client writes to `user_xp_summary` and `user_xp_events` are blocked by RLS.
  - XP is derived on the server by `complete_game_session` using verified scores, accuracy, and error counts.
  - Level formula is enforced on the database: $\text{level} = \lfloor\sqrt{\text{total\_xp} / 100}\rfloor + 1$.
- [x] **Idempotency Protection**:
  - Every game completion requires `p_idempotency_key`. Duplicate requests return the cached outcome with `status: idempotent_duplicate` and 0 additional XP, preventing double-awarding and replay attacks.
- [x] **Input Bounds Validation**:
  - Durations $<0$ or $>7200\text{ s}$ are rejected with `INVALID_INPUT`.
  - Accuracy $<0.0$ or $>1.0$ is rejected with `INVALID_INPUT`.
  - Negative error counts and anomalous scores are strictly blocked.
- [x] **Rate Limiting**:
  - Sliding-window rate limiter (`check_rate_limit`) restricts session completion calls to $\le 60\text{ requests/min}$ per user.
- [x] **Distributed Tracing & Correlation**:
  - `correlation_id` is propagated through `game_sessions`, `admin_audit_events`, and RPC responses without logging sensitive PII or credentials.
- [x] **Non-Clinical Boundary**:
  - Explicit disclaimer `SkillEstimate.nonClinicalDisclaimer` is embedded in skill records, UI schemas, and audit logs.
