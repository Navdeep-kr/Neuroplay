import React from "react";
import Link from "next/link";
import { ArrowRightIcon, BrainIcon, CheckCircleIcon, ShieldCheckIcon, AccessibilityIcon, BoltIcon, AppleIcon, GooglePlayIcon, SparklesIcon } from "@/components/Icons";
import { GAMES_DATA, SITE_CONFIG } from "@/lib/constants";

export default function HomePage() {
  return (
    <div className="space-y-24 md:space-y-32 pb-24 bg-white text-slate-900">
      {/* Hero Section */}
      <section className="relative pt-12 md:pt-20 lg:pt-24 overflow-hidden">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="max-w-3xl mx-auto text-center space-y-6">
            <div className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full text-xs font-semibold bg-blue-50 text-blue-700 border border-blue-200 shadow-xs">
              <SparklesIcon className="w-4 h-4 text-blue-600" />
              <span>Grounded in Cognitive Science • Zero Hype</span>
            </div>

            <h1 className="text-4xl sm:text-5xl lg:text-6xl font-extrabold tracking-tight text-slate-900 leading-[1.14]">
              Purpose-Built Brain Training for{" "}
              <span className="text-transparent bg-clip-text bg-gradient-to-r from-blue-600 to-indigo-600">
                Mental Agility
              </span>
            </h1>

            <p className="text-lg sm:text-xl text-slate-600 leading-relaxed font-normal max-w-2xl mx-auto">
              Structured cognitive challenges, transparent adaptive difficulty, and honest progress tracking. No false medical promises, no pseudo-IQ claims, and zero manipulative dark patterns.
            </p>

            {/* CTAs */}
            <div className="pt-4 flex flex-col sm:flex-row items-center justify-center gap-4">
              <Link
                href="/app"
                className="w-full sm:w-auto inline-flex items-center justify-center gap-2.5 px-7 py-3.5 rounded-xl bg-blue-600 hover:bg-blue-500 active:bg-blue-700 text-white font-semibold text-base shadow-sm transition-all focus:outline-none focus-visible:ring-2 focus-visible:ring-blue-500 focus-visible:ring-offset-2 hover:translate-y-[-1px]"
              >
                <span>Start Training Now (Free Guest)</span>
                <ArrowRightIcon className="w-4 h-4" />
              </Link>
              <Link
                href="/games"
                className="w-full sm:w-auto inline-flex items-center justify-center px-7 py-3.5 rounded-xl border border-slate-300 bg-white text-slate-700 font-semibold text-base hover:bg-slate-50 hover:border-slate-400 shadow-xs transition-all"
              >
                Explore Game Library
              </Link>
            </div>

            {/* App platform badges */}
            <div className="pt-4 flex flex-wrap items-center justify-center gap-4 text-xs font-medium text-slate-600">
              <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-lg border border-slate-200 bg-white shadow-xs">
                <AppleIcon className="w-4 h-4 text-slate-700" />
                <span>iOS App (PWA & Native)</span>
              </div>
              <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-lg border border-slate-200 bg-white shadow-xs">
                <GooglePlayIcon className="w-4 h-4 text-slate-700" />
                <span>Android Ready</span>
              </div>
              <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-lg border border-slate-200 bg-white shadow-xs">
                <BrainIcon className="w-4 h-4 text-blue-600" />
                <span>Instant Web Play</span>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* 3 Core Pillars */}
      <section className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center max-w-2xl mx-auto mb-16 space-y-3">
          <h2 className="text-xs font-bold uppercase tracking-widest text-blue-600">
            Engineered Differently
          </h2>
          <p className="text-3xl sm:text-4xl font-extrabold text-slate-900 tracking-tight">
            Scientific Rigor Without the Gimmicks
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          {/* Card 1 */}
          <div className="p-8 rounded-2xl bg-white border border-slate-200/90 shadow-sm hover:shadow-md transition-shadow space-y-4">
            <div className="w-12 h-12 rounded-xl bg-blue-50 text-blue-600 flex items-center justify-center border border-blue-200">
              <ShieldCheckIcon className="w-6 h-6" />
            </div>
            <h3 className="text-xl font-bold text-slate-900">
              Clinical Integrity
            </h3>
            <p className="text-sm text-slate-600 leading-relaxed font-normal">
              Every game adapts verified psychological tasks (spatial span, Stroop-like rule switches, visual target search). We describe game task performance objectively without making fraudulent IQ or anti-aging guarantees.
            </p>
          </div>

          {/* Card 2 */}
          <div className="p-8 rounded-2xl bg-white border border-slate-200/90 shadow-sm hover:shadow-md transition-shadow space-y-4">
            <div className="w-12 h-12 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center border border-emerald-200">
              <BoltIcon className="w-6 h-6" />
            </div>
            <h3 className="text-xl font-bold text-slate-900">
              Transparent Adaptation
            </h3>
            <p className="text-sm text-slate-600 leading-relaxed font-normal">
              No black-box algorithms deciding your fate. NEUROPLAY uses bounded, versioned difficulty rules with smoothed response latencies and explainable adjustments visible directly in your session telemetry.
            </p>
          </div>

          {/* Card 3 */}
          <div className="p-8 rounded-2xl bg-white border border-slate-200/90 shadow-sm hover:shadow-md transition-shadow space-y-4">
            <div className="w-12 h-12 rounded-xl bg-indigo-50 text-indigo-600 flex items-center justify-center border border-indigo-200">
              <AccessibilityIcon className="w-6 h-6" />
            </div>
            <h3 className="text-xl font-bold text-slate-900">
              Universal Accessibility
            </h3>
            <p className="text-sm text-slate-600 leading-relaxed font-normal">
              Non-color-only cues, high-contrast borders, tactile keyboard shortcuts (Space, Enter, arrows, numpad), full screen reader semantics, and dynamic motion dampening built into every exercise.
            </p>
          </div>
        </div>
      </section>

      {/* Six Games Spotlight */}
      <section className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex flex-col md:flex-row md:items-end justify-between mb-12 gap-4">
          <div className="space-y-2">
            <h2 className="text-xs font-bold uppercase tracking-widest text-blue-600">
              The Cognitive Suite
            </h2>
            <p className="text-3xl font-extrabold text-slate-900 tracking-tight">
              Six Original Brain-Training Exercises
            </p>
          </div>
          <Link
            href="/games"
            className="inline-flex items-center gap-1.5 text-sm font-semibold text-blue-600 hover:text-blue-700"
          >
            <span>View detailed specifications</span>
            <ArrowRightIcon className="w-4 h-4" />
          </Link>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {GAMES_DATA.map((game) => (
            <div
              key={game.id}
              className="p-7 rounded-2xl bg-white border border-slate-200 hover:border-blue-400 hover:shadow-lg transition-all shadow-xs flex flex-col justify-between group"
            >
              <div className="space-y-4">
                <div className="flex items-center justify-between">
                  <span className="px-3 py-1 rounded-md text-xs font-bold bg-blue-50 text-blue-700 border border-blue-200">
                    {game.faculty}
                  </span>
                  <span className="text-xs font-semibold text-slate-400 font-mono">v{game.version}</span>
                </div>
                <h3 className="text-xl font-bold text-slate-900 group-hover:text-blue-600 transition-colors">
                  {game.title}
                </h3>
                <p className="text-sm text-slate-600 leading-relaxed">
                  {game.summary}
                </p>
              </div>

              <div className="pt-6 border-t border-slate-100 mt-6 flex items-center justify-between gap-3">
                <a
                  href={`/app/index.html#/games/${game.id}`}
                  className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-blue-600 hover:bg-blue-500 active:bg-blue-700 text-white text-xs font-bold shadow-xs transition-all hover:translate-y-[-1px]"
                >
                  <span>Play {game.title}</span>
                  <ArrowRightIcon className="w-3.5 h-3.5" />
                </a>
                <Link
                  href={`/games#${game.id}`}
                  className="text-xs font-bold text-slate-500 hover:text-blue-600 hover:underline transition-colors"
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
        <div className="rounded-3xl bg-slate-50 border border-slate-200 p-8 sm:p-12 lg:p-16 overflow-hidden relative shadow-xs">
          <div className="max-w-2xl space-y-6 relative z-10">
            <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-md text-xs font-bold bg-emerald-50 text-emerald-700 border border-emerald-200">
              <CheckCircleIcon className="w-4 h-4 text-emerald-600" />
              <span>Full User Sovereignty</span>
            </div>
            <h2 className="text-3xl sm:text-4xl font-extrabold tracking-tight text-slate-900">
              Your Data. Your Telemetry. No Advertising.
            </h2>
            <p className="text-slate-600 text-base leading-relaxed">
              We never sell your cognitive metrics or inject manipulative push notifications. Every session, reaction time measurement, and streak event belongs to you. You can export your data in schema 1.0.0 JSON or purge it completely with a single click.
            </p>
            <div className="pt-2 flex flex-wrap gap-5 text-sm font-semibold text-slate-700">
              <div className="flex items-center gap-2">
                <CheckCircleIcon className="w-4 h-4 text-emerald-600" />
                <span>Zero third-party trackers</span>
              </div>
              <div className="flex items-center gap-2">
                <CheckCircleIcon className="w-4 h-4 text-emerald-600" />
                <span>One-click JSON export</span>
              </div>
              <div className="flex items-center gap-2">
                <CheckCircleIcon className="w-4 h-4 text-emerald-600" />
                <span>Honest calendar streaks</span>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Call to Action Banner */}
      <section className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 text-center space-y-6">
        <h2 className="text-3xl sm:text-4xl font-extrabold text-slate-900 tracking-tight">
          Ready for Today&apos;s Workout?
        </h2>
        <p className="text-base sm:text-lg text-slate-600 max-w-xl mx-auto">
          Start a 3-game daily workout in under five minutes. No sign-up required to begin.
        </p>
        <div>
          <Link
            href="/app"
            className="inline-flex items-center justify-center gap-2 px-8 py-3.5 rounded-xl bg-blue-600 hover:bg-blue-500 active:bg-blue-700 text-white font-semibold text-base shadow-sm transition-all hover:translate-y-[-1px]"
          >
            <span>Launch NEUROPLAY</span>
            <ArrowRightIcon className="w-4 h-4" />
          </Link>
        </div>
      </section>
    </div>
  );
}
