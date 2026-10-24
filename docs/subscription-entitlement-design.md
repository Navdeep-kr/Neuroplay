# NEUROPLAY Subscription & Entitlement Architecture

This document defines the architecture, security contracts, lifecycle transitions, and platform integration requirements for NEUROPLAY's subscription entitlement engine.

---

## 1. Executive Summary & Zero-Trust Philosophy

NEUROPLAY operates under a **Zero-Trust Client Access** model for all monetization and billing logic:
1. **Zero Client Authority:** The client application (Flutter or Web) is never trusted as proof of payment or entitlement status. Client-side callbacks from StoreKit, Google Play Billing, or Stripe are treated solely as intent indicators. Durable access is granted exclusively after server-side cryptographic receipt/token validation.
2. **Free-First Guarantee:** Core cognitive training exercises, practice modes, daily workout playlist generation, and local performance tracking are completely decoupled from billing and work 100% offline without payment or subscriptions.
3. **Pre-Release Production Safety Lock:** Paid checkout is disabled by default via compile-time and feature-flag gates (`ENABLE_PAID_CHECKOUT = false`) until Apple App Store, Google Play Console, and merchant agreements are officially verified and production secrets are securely provisioned.
4. **Transparent Engagement:** No trial traps, no obfuscated auto-renewals, and immediate one-click cancellation deep-links for all supported platforms.

---

## 2. Feature Access Matrix

| Feature / Capability | Free Community Tier | NEUROPLAY Plus Tier (`pro`) |
| :--- | :---: | :---: |
| **All 6 Original Games** (Memory Matrix, Reflex Forge, Focus Reactor, Logic Labyrinth, Number Pulse, Word Weaver) | Full Access | Full Access |
| **Practice Mode & Seeded Levels** | Unlimited | Unlimited |
| **Daily 3-Game Workout Playlist** | 1 Routine / Day | Unlimited / On-Demand Generation |
| **Local Performance History & PBs** | Unlimited Local Storage | Unlimited Local Storage |
| **Cross-Device Cloud Sync** | Basic Cloud Backup | Instant Multi-Device Sync |
| **Adaptive Difficulty Engine** | Fully Enabled (Bounded) | Fully Enabled (Bounded) |
| **Historical Latency & Accuracy Trends** | Recent 30 Days | Multi-Year Longitudinal Trends |
| **Cognitive Faculty Distribution Breakdown** | Summary Balance | Deep Domain Index Decomposition |
| **Self-Service JSON Data Export (Schema 1.0.0)** | Full Access | Full Access |
| **Account Deletion & Data Erasure** | Immediate 1-Click | Immediate 1-Click |

---

## 3. Product IDs & Subscription States

### 3.1 Standard Product Identifiers
- **Monthly Subscription:** `app.neuroplay.plus.monthly`
  - Billing Cycle: 1 Month
  - Target Price: \$4.99 USD
  - Grace Period: 16 Days (Apple) / 7 Days (Google)
- **Annual Subscription:** `app.neuroplay.plus.annual`
  - Billing Cycle: 1 Year
  - Target Price: \$39.99 USD (~33% savings)
  - Introductory Offer: 14-day free trial (where permitted)
  - Renewal Reminder: Automated notification 7 days prior to renewal

### 3.2 Subscription Lifecycle States
```
               [Purchase / Trial]
                       │
                       ▼
                 ┌───────────┐
                 │ trialing  │
                 └─────┬─────┘
                       │ Trial Converted
                       ▼
 ┌───────────────►┌───────────┐◄────────────────┐
 │ Renewed        │  active   │                 │
 │                └─────┬─────┘                 │
 │                      │ Payment Failed        │ Recovered
 │                      ▼                       │
 │               ┌─────────────┐                │
 │               │  past_due   │────────────────┘
 │               └──────┬──────┘
 │                      │ Grace Period Ended
 │                      ▼
 │               ┌─────────────┐
 │               │   expired   │
 │               └─────────────┘
 │
 │ User Initiated Cancellation
 └───────────────►┌───────────┐
                  │ canceled  │ (Active until `valid_until`)
                  └─────┬─────┘
                        │ Reached Expiration
                        ▼
                  ┌───────────┐
                  │  expired  │
                  └───────────┘
```

1. **`active`**: Paid subscription in good standing. All premium features unlocked.
2. **`trialing`**: User is in a valid introductory promotional period. All premium features unlocked.
3. **`past_due`**: Provider payment renewal failed. Enters platform-enforced grace period (up to 16 days on iOS, 7-14 days on Google Play). Features remain provisioned while retry billing executes.
4. **`canceled`**: User cancelled auto-renewal. Premium access remains intact until `valid_until` timestamp, then automatically transitions to `expired`.
5. **`expired`**: Subscription term has ended without renewal. Features revert cleanly to Free Community Tier without deleting any user performance history.

---

## 4. Architectural Comparison of Payment Providers

We evaluated three potential billing architectures:

| Evaluation Dimension | Option A: Direct Native IAPs (StoreKit 2 + Google Play Billing 7) | Option B: Direct Web-Only (Stripe Billing) | Option C: Unified Purchase Manager (e.g. RevenueCat) |
| :--- | :--- | :--- | :--- |
| **App Store Compliance** | 100% compliant with Apple App Store Review Guideline 3.1.1 and Google Play Billing Policy for digital content. | Strictly prohibited by Apple/Google for unlocking digital features inside native mobile apps (violates anti-steering guidelines). | Fully compliant; wraps native SDKs under compliant StoreKit 2 and Google Play APIs. |
| **Receipt Verification Complexity** | High. Requires maintaining App Store Server API (JWS verification, ECDSA P-256) + Google Play Developer API (service account, OAuth 2.0, RTDN Pub/Sub). | Moderate. Clean webhooks (`customer.subscription.*`), but cannot be used in native iOS/Android builds. | Low. Managed server handles receipt verification, JWS decoding, and store-specific nuances. |
| **Cross-Platform Synchronization** | High developer overhead. Backend must reconcile Apple `original_transaction_id`, Google `purchaseToken`, and web customer IDs. | Trivial for web; non-viable for native stores without account linking. | Built-in cross-platform identity mapping (`app_user_id` mapped to Supabase Auth UUID). |
| **Webhook Deduplication & Edge Cases** | Requires building custom idempotency tables, grace period handlers, billing retries, and store notification parsers. | Clean standard webhooks with signature headers (`stripe-signature`). | Standardized webhook payload covering all stores with single normalized event schema. |
| **Cost & Dependencies** | 15% (Small Business Program) / 30% store fees; \$0 software vendor fee. | 2.9% + \$0.30 per transaction; restricted to web platform. | Free tier up to \$2.5k MTR, then 1% of tracked revenue; reduces hundreds of hours of maintenance. |

### Final Selected Strategy
- **Architectural Abstraction:** Implement an internal `ISubscriptionRepository` and `SubscriptionProvider` abstraction in Flutter, backed by a unified server-side table (`subscription_entitlements`, `subscription_history`, `subscription_webhook_events`).
- **Phase 1 (Current Milestone):** The unified entitlement model is completely wired, tested, and active with a strict **Pre-Release Free Gate**. The app operates in Free mode with full access to core features.
- **Phase 2 (Production Store Release):** Enable native StoreKit 2 and Google Play Billing via RevenueCat/server-side verification once Apple Developer and Google Play Merchant accounts are verified.

---

## 5. Server-Side Entitlement Updates & Idempotent Webhook Processing

### 5.1 Idempotency Guarantee
Network retries from App Store Server Notifications v2, Google Cloud Pub/Sub, or Stripe can deliver duplicate notifications. To prevent race conditions and duplicate history entries:
1. Every incoming webhook is recorded in `subscription_webhook_events` with a unique composite key on `(provider, event_id)`.
2. If `(provider, event_id)` already exists, the transaction returns HTTP 200 immediately with `{ "status": "duplicate_ignored" }`.
3. Event processing is wrapped in a PostgreSQL transaction executing `process_subscription_webhook()`.

### 5.2 Server Security Rules
- `subscription_entitlements` has Row Level Security (RLS) enabled.
- Authenticated clients have `SELECT` permission only where `auth.uid() = user_id`.
- Client `INSERT`, `UPDATE`, and `DELETE` queries are denied (`USING (false)`).
- Entitlements can only be modified by the service-role or trusted SECURITY DEFINER database functions.

---

## 6. Offline Caching & Expiration Handling

1. **Secure Local Caching:**
   - Active entitlements are cached locally using `FlutterSecureStorage` with a signed cache timestamp.
   - Cache payload: `{ tier, status, features, validUntil, cachedAt, cacheSignature }`.
2. **Offline Grace Window:**
   - If the user is offline, the cached entitlement remains valid until `validUntil`.
   - If `validUntil` is exceeded while offline, the client gracefully downgrades features to the Free Community Tier without blocking access to any local gameplay.
3. **Re-synchronization:**
   - Upon network restoration, the repository fetches the server entitlement and reconciles any state changes.

---

## 7. Restore Purchases & Account Switching

### 7.1 Restore Purchases Flow
1. User taps **"Restore Purchases"** in Settings or Paywall.
2. The platform queries the native store (Apple StoreKit 2 / Google Play Billing) for existing active transactions.
3. The store receipt/JWS transaction is submitted to the backend validation endpoint with the current authenticated `auth.uid()`.
4. If the transaction was previously linked to a *different* user account:
   - If the previous account is inactive or deleted, ownership transfers to the new account.
   - If the previous account is currently active, an explicit `OwnershipConflict` is returned: *"This subscription is already linked to another NEUROPLAY account. Please sign in with that account or contact support."*

---

## 8. Management Deep-Links

NEUROPLAY provides direct platform-native management links:
- **iOS:** `https://apps.apple.com/account/subscriptions` (or `itms-apps://apps.apple.com/account/subscriptions`)
- **Android:** `https://play.google.com/store/account/subscriptions?sku={sku}&package={package_name}`
- **Web:** Hosted customer billing portal.
