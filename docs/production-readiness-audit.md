# NEUROPLAY Production-Readiness Audit & Release Runbook

**Audit Date**: October 24, 2026  
**Auditor**: Antigravity Quality & Infrastructure Engine  
**Target Release Platforms**: Web (PWA), Google Play Store (Android), Apple App Store (iOS)  
**Readiness Status**: ⚠️ **Pre-Release Ready / Blocked on Production Credentials & External Human Approval**

---

## 1. Release-Readiness Checklist (14 Audit Domains)

### Domain 1: Code Quality, Static Analysis & Automated Testing
- [x] **Static Analysis (Game Engine)**: `dart analyze --fatal-infos` passes with 0 warnings/errors.
- [x] **Static Analysis (Flutter App)**: `flutter analyze --fatal-infos` passes with 0 issues across 105 source files.
- [x] **Code Formatting**: `dart format --output=none --set-exit-if-changed .` passes cleanly with 0 diffs.
- [x] **Game Engine Unit Tests**: 67/67 deterministic tests passing (game loop, BFS maze solver, seeded RNG, score breakdown).
- [x] **App Unit & Widget Tests**: 122/122 tests passing (auth flows, daily workouts, adaptive difficulty, all 6 game screens, subscription entitlements).
- [x] **Website Automated Tests**: 7/7 checks passing (`scripts/run-checks.ts`), ESLint passing, Next.js static build passing.
- [x] **Continuous Integration**: `.github/workflows/ci.yml` configured to enforce formatting, analyzer, unit/widget tests, migration validation, and release web bundle generation on every pull request.

### Domain 2: Dependency Vulnerabilities & Open Source Licenses
- [x] **Web Dependencies**: `pnpm audit` reports **0 known vulnerabilities**.
- [x] **Flutter Package Licenses**: All direct and transitive dependencies analyzed. All use permissive commercial licenses:
  - MIT: `flutter_riverpod`, `riverpod_annotation`, `supabase_flutter`, `fl_chart`, `equatable`, `uuid`.
  - BSD-3-Clause: `flutter_secure_storage`, `intl`, `go_router`, `flutter_lints`.
  - Apache-2.0: `google_fonts`.
  - **No copyleft (GPL / AGPL / LGPL) dependencies found.**
- [x] **Word Weaver Wordbank**: Curated word associations verified as internal intellectual property; no copyrighted third-party puzzle banks used.

### Domain 3: Authentication, Authorization, RLS & Secret Handling
- [x] **Row-Level Security (RLS)**: Enforced across all client-facing Supabase tables (`profiles`, `game_sessions`, `game_scores`, `user_streaks`, `subscription_entitlements`, `subscription_history`, `subscription_webhook_events`).
- [x] **Client Isolation**: Client apps only access their own user records (`auth.uid() = user_id`).
- [x] **Untrusted Client Inputs**: Game XP, derived cognitive indices, and subscription statuses are computed exclusively via server-side RPCs (`record_completed_game_session`, `process_subscription_webhook`).
- [x] **Secret Isolation**: Zero secrets stored in client code. `SUPABASE_SERVICE_ROLE_KEY` and webhook signing secrets are isolated to serverless functions / database migrations.
- [x] **Zero-Trust Subscriptions**: Client-side store receipts are never treated as proof of entitlement. Server-side idempotency table `subscription_webhook_events` prevents replay attacks and race conditions.

### Domain 4: Account Deletion, Privacy Disclosures & Data Export
- [x] **Account Deletion Flow**: In-app two-factor confirmation dialog triggers cascading deletion (`auth.users`, profiles, workouts, session history).
- [x] **Data Export Flow**: One-click JSON data export compliant with GDPR Article 20 and CCPA.
- [x] **Privacy Policy & Terms**: Public marketing pages (`/privacy`, `/terms`, `/subscription-disclosures`) explain data retention, anonymized telemetry, and explicit health disclaimers.
- [x] **Zero Diagnostic / Medical Claims**: All user-facing copy and charts explicitly state that scores measure task-specific performance and do NOT represent clinical cognitive health or IQ.

### Domain 5: Interruption, Offline Resilience, Session Retries & Sync
- [x] **Offline-First Playability**: All 6 core games, practice modes, and daily workouts run 100% offline via local seeded generators without network roundtrips.
- [x] **App Interruption**: Monotonic pausable clock (`PausableMonotonicClock`) freezes gameplay during app backgrounding, system modals, or phone calls.
- [x] **Workout Resume**: `WorkoutSessionNotifier` seamlessly resumes interrupted multi-game playlists at the exact uncompleted exercise index.
- [x] **Sync Conflict Resolution**: Last-write-wins with monotonically increasing timestamp tracking; pending sessions queue locally in offline storage.

### Domain 6: Accessibility & Localization
- [x] **Accessible Target Differentiation**: Games use shape, symbol, and pattern distinctions in addition to color to accommodate color-blind users (deuteranopia, protanopia, tritanopia).
- [x] **Reduced Motion**: Respects `MediaQuery.of(context).disableAnimations` and user preference toggle. Flashing and rapid transitions are eliminated.
- [x] **Screen Readers & ARIA**: Widget tree annotated with `Semantics` widgets; web pages provide ARIA headings, skip-to-content links, and semantic landmark roles.
- [x] **Alternative Data Views**: Interactive performance charts provide accessible tabular data alternatives for screen readers.
- [x] **Localization Infrastructure**: `app_en.arb` and `l10n.yaml` configured; number and date formatting adapt via `intl`.

### Domain 7: Performance on Low-End Hardware & Desktop
- [x] **Memory & CPU Footprint**: Lightweight canvas painting without heavy shader passes; target 60 FPS maintained on low-tier mobile devices.
- [x] **Font & Asset Tree-Shaking**: Font assets tree-shaken during release build (`MaterialIcons` reduced by 98.6%, `CupertinoIcons` reduced by 99.4%).
- [x] **Adaptive Viewport**: Responsive layout shifts between mobile bottom navigation bar and desktop `NavigationRail` above 800px width.

### Domain 8: Crash & Error Monitoring
- [x] **Structured Logging**: `AppLogger` provides contextual debug/info/warning/error tagging.
- [ ] **Release Crash Reporting**: Production crash SDK (e.g., Sentry / Datadog) configuration pending environment DSN injection (Blocked on human account).

### Domain 9: Database Backups & Restore Drills
- [x] **Database Schema Versioning**: 6 incremental migrations versioned with timestamps in `supabase/migrations/`.
- [x] **Automated Migration Check**: `scripts/verify-migrations.py` verifies sequence, syntax, and credential cleanliness.
- [ ] **Automated Daily Backups & Point-in-Time Recovery (PITR)**: Requires Supabase Pro/Enterprise tier enabled on production project (Blocked on human billing approval).

### Domain 10: Production / Staging Separation
- [x] **Environment Variable Isolation**: Separate configurations for local (`http://127.0.0.1:8080`), staging, and production in `.env.example`.
- [x] **Branching Model**: Pull request checks isolate `main` from untested feature branches.

### Domain 11: Build Signing & Release Credentials
- [x] **Android Keystore Architecture**: `build.gradle.kts` configured to load `key.properties` for release signing, falling back to debug keys for local verification.
- [x] **iOS Privacy Manifest**: `app/ios/Runner/PrivacyInfo.xcprivacy` created declaring required reasons (`CA92.1`, `C617.1`) and disabling tracking.
- [ ] **Production Keystore & Apple Certificates**: Keystore generation and Apple Provisioning Profile assignment pending human developer credentials.

### Domain 12: Store Listing Assets & Policy Disclosures
- [x] **App Display Name**: Standardized as `NEUROPLAY` across Web, Android (`AndroidManifest.xml`), and iOS (`Info.plist`).
- [x] **Web App Manifest**: `manifest.json` configured with standalone PWA support, brand colors (`#0B0F19`, `#6750A4`), and maskable icons.
- [ ] **Store Screenshots & Feature Graphic**: High-resolution marketing screenshots (1242x2688 for iOS, 1080x1920 for Android, 1024x500 Feature Graphic) required prior to store submission.

### Domain 13: Rollback Procedures & Incident Response
- [x] **Web Rollback**: Static web bundle hosting supports zero-downtime atomic rollback to previous git commit sha.
- [x] **Database Rollback Strategy**: Forward-compatible additive migrations; emergency downgrade scripts documented.
- [x] **Safety Gates**: `SubscriptionSafetyGate.enablePaidCheckout` locks paid monetization switches if store issues emerge.

### Domain 14: Analytics Event Validation & Privacy Controls
- [x] **Minimal Data Collection**: Records only session duration, accuracy, error counts, and seed required for scoring. No location, biometric, or contact data captured.
- [x] **Consent & Telemetry Toggles**: User preferences in Profile screen allow disabling telemetry and personalized workout recommendations.

---

## 2. Verified Test Results

| Test Category | Suite / Scope | Tools / Commands | Expected | Verified Result | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Cognitive Framework** | Logic, RNG determinism, scoring rules, BFS solver | `cd packages/game_engine; dart test` | 67 tests | **67 / 67 passed** (1.0s) | ✅ PASS |
| **Dart Static Analysis** | Monorepo app analysis | `cd app; flutter analyze --fatal-infos` | 0 issues | **0 issues found** (7.4s) | ✅ PASS |
| **Dart Formatting** | Monorepo formatting standard | `cd app; dart format --output=none --set-exit-if-changed .` | 0 diffs | **105 files clean** (0.46s) | ✅ PASS |
| **Flutter Test Suite** | Unit tests, widget tests, navigation, workouts, entitlements | `cd app; flutter test` | 122 tests | **122 / 122 passed** (56.0s) | ✅ PASS |
| **Database Migrations** | File naming, timestamp order, syntax integrity | `python scripts/verify-migrations.py` | 6 migrations | **6 / 6 verified** (0.5s) | ✅ PASS |
| **Marketing Website** | Routes, schemas, legal disclaimers, admin gate | `cd website; pnpm test` | 7 checks | **7 / 7 passed** (0.8s) | ✅ PASS |
| **Website Security Audit**| Dependency vulnerability scan | `cd website; pnpm audit` | 0 vulnerabilities | **0 vulnerabilities** | ✅ PASS |
| **Website Static Build** | Production Next.js 16 build | `cd website; pnpm build` | All static routes | **18 / 18 routes compiled** | ✅ PASS |
| **Web Release Bundle** | Web assembly & JS optimization | `cd app; flutter build web --release` | Zero compile errors | **Built build\web** (240s) | ✅ PASS |

---

## 3. Outstanding Blockers (Human Approval & Credentials Required)

Before releasing to the public, the following external items must be completed by an authorized administrator:

1. **Apple Developer Program Enrollment ($99/year)**:
   - Need App Store Connect team access.
   - Requires generating Distribution Certificate (`.p12`) and App Store Provisioning Profile.
2. **Google Play Console Developer Account ($25 one-time)**:
   - Need Play Console developer access.
   - Requires generating production release keystore (`neuroplay-release.jks`) and creating `app/android/key.properties`.
3. **Production Supabase Project**:
   - Provision production project in Supabase dashboard.
   - Apply migrations `20261023000001` through `20261024000004`.
   - Configure custom domain, SSL certificate, and production SMTP provider for auth emails.
4. **Crash & Telemetry Service DSN**:
   - Obtain Sentry or Datadog DSN for Flutter and Next.js.
5. **Marketing Assets**:
   - Capture device screenshots for 6.7" iPhone, 12.9" iPad, and 6.5" Android phones.
   - Prepare 512x512 app icons and 1024x500 Google Play feature graphic.

---

## 4. Deployment and Rollback Instructions

### A. Web Application (PWA) Deployment
```bash
# 1. Build production release bundle
cd app
flutter build web --release --pwa-strategy=offline-first

# 2. Deploy to CDN / Cloudflare Pages / Vercel
# (e.g., using Cloudflare Wrangler or Vercel CLI)
wrangler pages deploy build/web --project-name=neuroplay-app
```
**Rollback**:
- In the Cloudflare Pages or Vercel dashboard, click "Rollback" to instantly switch the active deployment alias back to the previous stable release.

### B. Marketing Website Deployment
```bash
cd website
pnpm install --frozen-lockfile
pnpm build
# Deploy to Vercel / Next.js hosting
vercel deploy --prod
```
**Rollback**:
- Instant instant rollback via Vercel dashboard or `vercel rollback [deploymentId]`.

### C. Database Migration Deployment
```bash
# Verify migrations locally first
python scripts/verify-migrations.py

# Push migrations to production database via Supabase CLI
supabase db push --linked
```
**Emergency Database Rollback**:
- If an issue occurs, execute the specific reverse SQL script or restore from the latest automated PITR snapshot via the Supabase dashboard.

---

## 5. Exact Store-Submission Steps

### Google Play Store (Android)
1. **Create Keystore** (Execute once and store securely in password manager):
   ```bash
   keytool -genkey -v -keystore neuroplay-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias neuroplay-release
   ```
2. **Configure `key.properties`**:
   Copy `app/android/key.properties.example` to `app/android/key.properties` and fill in credentials.
3. **Build Android AppBundle**:
   ```bash
   cd app
   flutter build appbundle --release
   # Output: build/app/outputs/bundle/release/app-release.aab
   ```
4. **Upload to Google Play Console**:
   - Open [Google Play Console](https://play.google.com/console).
   - Select `app.neuroplay.brain`.
   - Go to **Testing > Internal testing > Create new release**.
   - Upload `app-release.aab`.
   - Complete the **App Content questionnaires**: Data Safety (declare User ID for App Functionality, declare no data sold/shared with third parties), Privacy Policy URL (`https://neuroplay.app/privacy`), and Content Rating (Everyone / Age 3+).
   - Promote from Internal Testing to Closed Testing -> Open Testing -> Production after QA verification.

### Apple App Store (iOS)
1. **Prepare Signing Assets**:
   - In Apple Developer portal, create App ID: `app.neuroplay.brain`.
   - Create iOS Distribution Certificate and App Store Provisioning Profile.
2. **Build iOS Archive**:
   ```bash
   cd app
   flutter build ipa --release
   # Output: build/ios/archive/Runner.xcarchive
   ```
3. **Upload via Transporter or Xcode**:
   ```bash
   xcrun altool --upload-app --type ios --file build/ios/ipa/*.ipa --apiKey [KEY_ID] --apiIssuer [ISSUER_ID]
   ```
4. **App Store Connect Setup**:
   - Complete **App Privacy** nutrition label (matches `PrivacyInfo.xcprivacy`: User ID linked to user for app functionality; Diagnostics not linked).
   - Add App Store screenshots, description, keywords, and support URL (`https://neuroplay.app/contact`).
   - Submit for App Store Review.

---

## 6. Post-Launch Monitoring Plan

| Monitoring Tier | Tool / Dashboard | Metrics / Thresholds | Alerting Channel | Response SLA |
| :--- | :--- | :--- | :--- | :--- |
| **Crash Rate** | Sentry / Firebase Crashlytics | Crash-free sessions < 99.5% | PagerDuty / Slack `#alerts` | P0 (< 30 min) |
| **App Uptime** | BetterUptime / Checkly | Synthetic health ping to `neuroplay.app` fails (> 3 min) | SMS / Slack `#ops` | P0 (< 15 min) |
| **API Errors** | Supabase Dashboard / Grafana | 5xx error rate > 0.5% over 5 minutes | Slack `#alerts-backend` | P1 (< 1 hour) |
| **DB Performance**| Supabase Postgres Metrics | CPU > 80% or Connection pool > 80% | Slack `#ops-database` | P1 (< 2 hours) |
| **Entitlement Sync**| Supabase Webhook Logs | Webhook processing failure rate > 0% | Slack `#billing-alerts` | P0 (< 1 hour) |
| **Review Feedback** | App Store Connect & Play Console | 1-star review spikes or repeating crash reports | Weekly Tri-department sync | P2 (< 24 hours) |
