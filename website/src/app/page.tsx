import React from "react";
import Link from "next/link";
import { ArrowRightIcon, BrainIcon, CheckCircleIcon, ShieldCheckIcon, AccessibilityIcon, BoltIcon, AppleIcon, GooglePlayIcon, SparklesIcon } from "@/components/Icons";
import { GAMES_DATA, SITE_CONFIG } from "@/lib/constants";

export default function HomePage() {
  return (
    <div className="space-y-24 md:space-y-32 pb-24">
      {/* Hero Section */}
      <section className="relative pt-12 md:pt-20 lg:pt-28 overflow-hidden">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="max-w-3xl mx-auto text-center space-y-6">
            <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full text-xs font-semibold bg-emerald-50 dark:bg-emerald-950/60 text-emerald-700 dark:text-emerald-300 border border-emerald-200 dark:border-emerald-800">
              <SparklesIcon className="w-4 h-4 text-emerald-600 dark:text-emerald-400" />
              <span>Grounded in Cognitive Science • Zero Hype</span>
            </div>

            <h1 className="text-4xl sm:text-5xl lg:text-6xl font-extrabold tracking-tight text-slate-900 dark:text-white leading-[1.12]">
              Purpose-Built Brain Training for{" "}
              <span className="text-transparent bg-clip-text bg-gradient-to-r from-emerald-600 to-teal-600 dark:from-emerald-400 dark:to-teal-400">
                Mental Agility
              </span>
            </h1>

            <p className="text-lg sm:text-xl text-slate-600 dark:text-slate-300 leading-relaxed font-normal">
              Structured cognitive challenges, transparent adaptive difficulty, and honest progress tracking. No false medical promises, no pseudo-IQ claims, and zero manipulative dark patterns.
            </p>

            {/* CTAs */}
            <div className="pt-4 flex flex-col sm:flex-row items-center justify-center gap-4">
              <a
                href={SITE_CONFIG.appUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="w-full sm:w-auto inline-flex items-center justify-center gap-2.5 px-7 py-3.5 rounded-xl bg-emerald-600 hover:bg-emerald-500 active:bg-emerald-700 text-white font-semibold text-base shadow-sm transition-all focus:outline-none focus-visible:ring-2 focus-visible:ring-emerald-500 focus-visible:ring-offset-2"
              >
                <span>Start Training Now (Free Guest)</span>
                <ArrowRightIcon className="w-4 h-4" />
              </a>
              <Link
                href="/games"
                className="w-full sm:w-auto inline-flex items-center justify-center px-7 py-3.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-900 text-slate-700 dark:text-slate-200 font-semibold text-base hover:bg-slate-50 dark:hover:bg-slate-800 shadow-sm transition-colors"
              >
                Explore Game Library
              </Link>
            </div>

            {/* App download badges */}
            <div className="pt-4 flex flex-wrap items-center justify-center gap-4 text-xs text-slate-500 dark:text-slate-400">
              <div className="inline-flex items-center gap-2 px-3 py-1.5 rounded-lg border border-slate-200 dark:border-slate-800 bg-white/50 dark:bg-slate-900/50">
                <AppleIcon className="w-4 h-4" />
                <span>iOS App (PWA & Native)</span>
              </div>
              <div className="inline-flex items-center gap-2 px-3 py-1.5 rounded-lg border border-slate-200 dark:border-slate-800 bg-white/50 dark:bg-slate-900/50">
                <GooglePlayIcon className="w-4 h-4" />
                <span>Android Ready</span>
              </div>
              <div className="inline-flex items-center gap-2 px-3 py-1.5 rounded-lg border border-slate-200 dark:border-slate-800 bg-white/50 dark:bg-slate-900/50">
                <BrainIcon className="w-4 h-4 text-emerald-500" />
                <span>Instant Web Play</span>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* 3 Core Pillars */}
      <section className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center max-w-2xl mx-auto mb-16 space-y-3">
          <h2 className="text-xs font-bold uppercase tracking-widest text-emerald-600 dark:text-emerald-400">
            Engineered Differently
          </h2>
          <p className="text-3xl font-extrabold text-slate-900 dark:text-white tracking-tight">
            Scientific Rigor Without the Gimmicks
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          {/* Card 1 */}
          <div className="p-8 rounded-2xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 shadow-xs space-y-4">
            <div className="w-12 h-12 rounded-xl bg-blue-50 dark:bg-blue-950/60 text-blue-600 dark:text-blue-400 flex items-center justify-center border border-blue-200 dark:border-blue-900">
              <ShieldCheckIcon className="w-6 h-6" />
            </div>
            <h3 className="text-xl font-bold text-slate-900 dark:text-white">
              Clinical Integrity
            </h3>
            <p className="text-sm text-slate-600 dark:text-slate-400 leading-relaxed">
              Every game adapts verified psychological tasks (spatial span, Stroop-like rule switches, visual target search). We describe game task performance objectively without making fraudulent IQ or anti-aging guarantees.
            </p>
          </div>

          {/* Card 2 */}
          <div className="p-8 rounded-2xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 shadow-xs space-y-4">
            <div className="w-12 h-12 rounded-xl bg-emerald-50 dark:bg-emerald-950/60 text-emerald-600 dark:text-emerald-400 flex items-center justify-center border border-emerald-200 dark:border-emerald-900">
              <BoltIcon className="w-6 h-6" />
            </div>
            <h3 className="text-xl font-bold text-slate-900 dark:text-white">
              Transparent Adaptation
            </h3>
            <p className="text-sm text-slate-600 dark:text-slate-400 leading-relaxed">
              No black-box algorithms deciding your fate. NEUROPLAY uses bounded, versioned difficulty rules with smoothed response latencies and explainable adjustments visible directly in your session telemetry.
            </p>
          </div>

          {/* Card 3 */}
          <div className="p-8 rounded-2xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 shadow-xs space-y-4">
            <div className="w-12 h-12 rounded-xl bg-purple-50 dark:bg-purple-950/60 text-purple-600 dark:text-purple-400 flex items-center justify-center border border-purple-200 dark:border-purple-900">
              <AccessibilityIcon className="w-6 h-6" />
            </div>
            <h3 className="text-xl font-bold text-slate-900 dark:text-white">
              Universal Accessibility
            </h3>
            <p className="text-sm text-slate-600 dark:text-slate-400 leading-relaxed">
              Non-color-only cues, high-contrast borders, tactile keyboard shortcuts (`Space`, `Enter`, arrows, numpad), full screen reader semantics, and dynamic motion dampening built into every exercise.
            </p>
          </div>
        </div>
      </section>

      {/* Six Games Spotlight */}
      <section className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex flex-col md:flex-row md:items-end justify-between mb-12 gap-4">
          <div className="space-y-2">
            <h2 className="text-xs font-bold uppercase tracking-widest text-emerald-600 dark:text-emerald-400">
              The Cognitive Suite
            </h2>
            <p className="text-3xl font-extrabold text-slate-900 dark:text-white tracking-tight">
              Six Original Brain-Training Exercises
            </p>
          </div>
          <Link
            href="/games"
            className="inline-flex items-center gap-1.5 text-sm font-semibold text-emerald-600 dark:text-emerald-400 hover:text-emerald-500"
          >
            <span>View detailed specifications</span>
            <ArrowRightIcon className="w-4 h-4" />
          </Link>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {GAMES_DATA.map((game) => (
            <div
              key={game.id}
              className="p-6 rounded-2xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 flex flex-col justify-between hover:border-slate-300 dark:hover:border-slate-700 transition-all shadow-xs"
            >
              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <span className="px-2.5 py-1 rounded-md text-xs font-semibold bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-300">
                    {game.faculty}
                  </span>
                  <span className="text-xs text-slate-400 font-mono">v{game.version}</span>
                </div>
                <h3 className="text-lg font-bold text-slate-900 dark:text-white">
                  {game.title}
                </h3>
                <p className="text-sm text-slate-600 dark:text-slate-400 leading-relaxed">
                  {game.summary}
                </p>
              </div>

              <div className="pt-6 border-t border-slate-100 dark:border-slate-800/80 mt-6 flex items-center justify-between">
                <span className="text-xs text-slate-500">Accessible & Keyboard Ready</span>
                <Link
                  href={`/games#${game.id}`}
                  className="text-xs font-semibold text-emerald-600 dark:text-emerald-400 hover:underline"
                >
                  Details →
                </Link>
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* Honest Tracking & Data Ownership */}
      <section className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="rounded-3xl bg-slate-900 dark:bg-slate-900/80 text-white p-8 sm:p-12 lg:p-16 border border-slate-800 overflow-hidden relative">
          <div className="max-w-2xl space-y-6 relative z-10">
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-md text-xs font-semibold bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
              <CheckCircleIcon className="w-4 h-4" />
              <span>Full User Sovereignty</span>
            </div>
            <h2 className="text-3xl sm:text-4xl font-extrabold tracking-tight">
              Your Data. Your Telemetry. No Advertising.
            </h2>
            <p className="text-slate-300 text-base leading-relaxed">
              We never sell your cognitive metrics or inject manipulative push notifications. Every session, reaction time measurement, and streak event belongs to you. You can export your data in schema 1.0.0 JSON or purge it completely with a single click.
            </p>
            <div className="pt-2 flex flex-wrap gap-4 text-sm text-slate-300">
              <div className="flex items-center gap-2">
                <CheckCircleIcon className="w-4 h-4 text-emerald-400" />
                <span>Zero third-party trackers</span>
              </div>
              <div className="flex items-center gap-2">
                <CheckCircleIcon className="w-4 h-4 text-emerald-400" />
                <span>One-click JSON export</span>
              </div>
              <div className="flex items-center gap-2">
                <CheckCircleIcon className="w-4 h-4 text-emerald-400" />
                <span>Honest calendar streaks</span>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Call to Action Banner */}
      <section className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 text-center space-y-6">
        <h2 className="text-3xl font-extrabold text-slate-900 dark:text-white tracking-tight">
          Ready for Today&apos;s Workout?
        </h2>
        <p className="text-base text-slate-600 dark:text-slate-400 max-w-xl mx-auto">
          Start a 3-game daily workout in under five minutes. No sign-up required to begin.
        </p>
        <div>
          <a
            href={SITE_CONFIG.appUrl}
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center justify-center gap-2 px-8 py-3.5 rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white font-semibold text-base shadow-sm transition-all"
          >
            <span>Launch NEUROPLAY</span>
            <ArrowRightIcon className="w-4 h-4" />
          </a>
        </div>
      </section>
    </div>
  );
}
