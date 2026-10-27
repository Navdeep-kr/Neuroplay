import React from "react";
import type { Metadata } from "next";
import { ArrowRightIcon, SparklesIcon } from "@/components/Icons";
import { SITE_CONFIG } from "@/lib/constants";

export const metadata: Metadata = {
  title: "How Personalization Works",
  description:
    "Learn about NEUROPLAY's transparent adaptive difficulty engine, daily multi-game playlist generation, and honest habit mechanics.",
};

export default function HowItWorksPage() {
  return (
    <div className="py-12 md:py-20 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 space-y-20">
      {/* Header */}
      <div className="max-w-3xl space-y-4">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-md text-xs font-semibold bg-emerald-50 text-emerald-700 border border-emerald-200">
          <SparklesIcon className="w-4 h-4 text-emerald-600" />
          <span>Transparent Systems Architecture</span>
        </div>
        <h1 className="text-3xl sm:text-4xl lg:text-5xl font-extrabold text-slate-900 tracking-tight">
          How Personalization Works
        </h1>
        <p className="text-base sm:text-lg text-slate-600 leading-relaxed">
          NEUROPLAY rejects black-box AI and manipulative retention tricks. Our adaptive difficulty, playlist generation, and habit systems are deterministic, versioned, and completely transparent to the player.
        </p>
      </div>

      {/* 3 Step Interactive Explanation */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
        {/* Step 1 */}
        <div className="p-8 rounded-3xl bg-white border border-slate-200 shadow-xs space-y-4">
          <div className="w-10 h-10 rounded-xl bg-emerald-100 text-emerald-700 font-bold flex items-center justify-center text-sm border border-emerald-300">
            01
          </div>
          <h2 className="text-xl font-bold text-slate-900">
            Daily Workout Engine
          </h2>
          <p className="text-sm text-slate-600 leading-relaxed">
            Every day, the system generates a balanced 3-game playlist targeting complementary cognitive domains (e.g., Memory + Flexibility + Calculation). The algorithm rotates games deterministically based on your recent activity, ensuring variety without repetitive pairings.
          </p>
        </div>

        {/* Step 2 */}
        <div className="p-8 rounded-3xl bg-white border border-slate-200 shadow-xs space-y-4">
          <div className="w-10 h-10 rounded-xl bg-emerald-100 text-emerald-700 font-bold flex items-center justify-center text-sm border border-emerald-300">
            02
          </div>
          <h2 className="text-xl font-bold text-slate-900">
            Bounded Adaptive Scaling
          </h2>
          <p className="text-sm text-slate-600 leading-relaxed">
            As you train, game difficulty scales within verified minimum and maximum bounds. We use exponential smoothing on accuracy and median reaction times. A single distracted trial will never crash your difficulty rating, nor will a lucky guess produce an unplayable spike.
          </p>
        </div>

        {/* Step 3 */}
        <div className="p-8 rounded-3xl bg-white border border-slate-200 shadow-xs space-y-4">
          <div className="w-10 h-10 rounded-xl bg-emerald-100 text-emerald-700 font-bold flex items-center justify-center text-sm border border-emerald-300">
            03
          </div>
          <h2 className="text-xl font-bold text-slate-900">
            Auditable Telemetry
          </h2>
          <p className="text-sm text-slate-600 leading-relaxed">
            Every score adjustment records the exact algorithm version, adjustment reason (e.g., &ldquo;high accuracy plateau&rdquo;), and timestamp. We maintain a clean architectural separation between raw game telemetry and derived skill estimates.
          </p>
        </div>
      </div>

      {/* Honest Streaks vs Manipulative Mechanics */}
      <div className="p-8 sm:p-12 rounded-3xl bg-white border border-slate-200 shadow-xs space-y-8">
        <div className="max-w-2xl space-y-3">
          <h2 className="text-xs font-bold uppercase tracking-widest text-emerald-600">
            Ethical Engagement
          </h2>
          <p className="text-2xl sm:text-3xl font-extrabold text-slate-900 tracking-tight">
            Honest Streaks Without Guilt-Tripping
          </p>
          <p className="text-sm text-slate-600 leading-relaxed">
            Many gaming and learning platforms monetize anxiety through artificial &ldquo;streak freezes&rdquo; and aggressive notifications. NEUROPLAY takes a fundamentally respectful approach:
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="p-6 rounded-2xl bg-slate-50 border border-slate-200 space-y-3">
            <h3 className="font-bold text-slate-900 text-base">
              Explicit Calendar Day Boundaries
            </h3>
            <p className="text-sm text-slate-600 leading-relaxed">
              Streaks are anchored to real UTC calendar dates. Training twice on Tuesday and skipping Wednesday accurately reflects a missed day. We do not manufacture false continuity.
            </p>
          </div>

          <div className="p-6 rounded-2xl bg-slate-50 border border-slate-200 space-y-3">
            <h3 className="font-bold text-slate-900 text-base">
              Zero Dark Patterns
            </h3>
            <p className="text-sm text-slate-600 leading-relaxed">
              No countdown timers threatening streak forfeiture, no paid &ldquo;repair&rdquo; tokens, and no guilt-inducing alerts. Training should fit into your life calmly and sustainably.
            </p>
          </div>
        </div>
      </div>

      {/* Medical Scope Banner */}
      <div className="p-8 rounded-3xl bg-slate-100 border border-slate-200 space-y-4">
        <h2 className="text-lg font-bold text-slate-900">
          Our Explicit Scope Commitment
        </h2>
        <p className="text-sm text-slate-600 leading-relaxed">
          While cognitive exercises engage attention and working memory networks, performance metrics reflect task proficiency and game strategy. NEUROPLAY does not diagnose neurological health, assess clinical impairment, or alter genetic intelligence. We believe ethical software starts with honest communication.
        </p>
        <div>
          <a
            href={SITE_CONFIG.appUrl}
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-2 text-sm font-semibold text-emerald-600 hover:text-emerald-500"
          >
            <span>Try the adaptive workout in app</span>
            <ArrowRightIcon className="w-4 h-4" />
          </a>
        </div>
      </div>
    </div>
  );
}
