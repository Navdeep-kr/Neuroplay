import React from "react";
import type { Metadata } from "next";
import { SparklesIcon } from "@/components/Icons";
import { SITE_CONFIG } from "@/lib/constants";

export const metadata: Metadata = {
  title: "Privacy Policy",
  description:
    "NEUROPLAY Privacy Policy: user data sovereignty, zero advertising trackers, transparent telemetry retention, and one-click JSON data export and account deletion.",
};

export default function PrivacyPage() {
  return (
    <div className="py-12 md:py-20 max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 space-y-12">
      <div className="space-y-4">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-md text-xs font-semibold bg-emerald-50 dark:bg-emerald-950/60 text-emerald-700 dark:text-emerald-300 border border-emerald-200 dark:border-emerald-800">
          <SparklesIcon className="w-4 h-4 text-emerald-600 dark:text-emerald-400" />
          <span>Data Sovereignty & Privacy</span>
        </div>
        <h1 className="text-3xl sm:text-4xl lg:text-5xl font-extrabold text-slate-900 dark:text-white tracking-tight">
          Privacy Policy
        </h1>
        <p className="text-sm text-slate-500 font-mono">
          Last Updated: October 2026 • Policy Version 1.0.0
        </p>
      </div>

      <div className="prose dark:prose-invert max-w-none space-y-8 text-sm sm:text-base text-slate-600 dark:text-slate-300 leading-relaxed">
        <section className="space-y-3">
          <h2 className="text-xl font-bold text-slate-900 dark:text-white">
            1. Core Principles
          </h2>
          <p>
            NEUROPLAY operates on a strict principle of user data ownership. We believe cognitive metrics reflect sensitive personal engagement. We do not sell user data, license behavioral patterns to brokers, or deploy third-party advertising tracking software.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-bold text-slate-900 dark:text-white">
            2. Data We Collect
          </h2>
          <ul className="list-disc pl-6 space-y-2">
            <li>
              <strong>Guest Mode Users:</strong> All session records, personal bests, and preferences remain solely in your browser or local device storage. No account identifiers or personal telemetry are transmitted to our servers.
            </li>
            <li>
              <strong>Registered Accounts:</strong> When creating a synchronized account, we store your email address, profile handle, preferences (theme, audio, reduced motion, difficulty), and validated game session records (accuracy, duration, error counts, median reaction times).
            </li>
            <li>
              <strong>Security & Auth Secrets:</strong> Passwords are never stored as plaintext; authentication is processed using standard PKCE cryptographic protocols. We never store credit card or payment card details on our application servers.
            </li>
          </ul>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-bold text-slate-900 dark:text-white">
            3. How We Use Cognitive Telemetry
          </h2>
          <p>
            Game results are used exclusively to:
          </p>
          <ul className="list-disc pl-6 space-y-2">
            <li>Generate your personal accuracy and response-time performance charts.</li>
            <li>Power the transparent, bounded adaptive-difficulty engine.</li>
            <li>Calculate honest calendar-day streaks and unlock achievements.</li>
          </ul>
          <p>
            Telemetry is never used for algorithmic profiling outside the context of your self-directed training workouts.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-bold text-slate-900 dark:text-white">
            4. Self-Service Data Export & Account Deletion
          </h2>
          <p>
            Under GDPR, CCPA, and our own architectural standards, you maintain absolute control over your records:
          </p>
          <ul className="list-disc pl-6 space-y-2">
            <li>
              <strong>Schema 1.0.0 JSON Export:</strong> You can export your full profile, preferences, daily activity, and completed session history directly from the Profile screen at any time with zero administrative hurdles.
            </li>
            <li>
              <strong>Permanent Deletion:</strong> You can request account deletion in app or via our API. All user-associated data, session logs, and personal bests are permanently eradicated within 30 days.
            </li>
          </ul>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-bold text-slate-900 dark:text-white">
            5. Contact Information
          </h2>
          <p>
            For privacy inquiries, reach our Data Protection Officer directly at{" "}
            <a href={`mailto:${SITE_CONFIG.links.privacyEmail}`} className="text-emerald-600 dark:text-emerald-400 font-semibold hover:underline">
              {SITE_CONFIG.links.privacyEmail}
            </a>.
          </p>
        </section>
      </div>
    </div>
  );
}
