import React from "react";
import type { Metadata } from "next";
import Link from "next/link";
import { SparklesIcon } from "@/components/Icons";

export const metadata: Metadata = {
  title: "About",
  description:
    "Learn about NEUROPLAY's mission to build ethical, scientifically grounded cognitive training software with zero false promises and complete user data sovereignty.",
};

export default function AboutPage() {
  return (
    <div className="py-12 md:py-20 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 space-y-20">
      {/* Header */}
      <div className="max-w-3xl space-y-4">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-md text-xs font-semibold bg-emerald-50 dark:bg-emerald-950/60 text-emerald-700 dark:text-emerald-300 border border-emerald-200 dark:border-emerald-800">
          <SparklesIcon className="w-4 h-4 text-emerald-600 dark:text-emerald-400" />
          <span>Our Mission & Principles</span>
        </div>
        <h1 className="text-3xl sm:text-4xl lg:text-5xl font-extrabold text-slate-900 dark:text-white tracking-tight">
          Ethical Brain Training, Reimagined
        </h1>
        <p className="text-base sm:text-lg text-slate-600 dark:text-slate-300 leading-relaxed">
          NEUROPLAY was founded as a direct response to an industry crowded with pseudo-scientific claims, predatory subscription traps, and manipulative engagement algorithms. We believe brain training should be calm, rigorous, and honest.
        </p>
      </div>

      {/* Core Values Manifesto */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
        <div className="p-8 rounded-3xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 shadow-xs space-y-4">
          <h2 className="text-xl font-bold text-slate-900 dark:text-white">
            1. Scientific Honesty
          </h2>
          <p className="text-sm text-slate-600 dark:text-slate-400 leading-relaxed">
            We will never market NEUROPLAY as an IQ booster, dementia prevention tool, or clinical diagnostic mechanism. NEUROPLAY exercises are not a medical device and do not diagnose neurological illness. We treat cognitive tasks as engaging mental workouts that improve specific task execution, and we explain the boundaries of that transfer clearly.
          </p>
        </div>

        <div className="p-8 rounded-3xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 shadow-xs space-y-4">
          <h2 className="text-xl font-bold text-slate-900 dark:text-white">
            2. Zero Exploitation
          </h2>
          <p className="text-sm text-slate-600 dark:text-slate-400 leading-relaxed">
            No countdown anxiety timers, no artificial &ldquo;streak freeze&rdquo; microtransactions, and no shame-based notifications. When you train, you do so on your terms, with honest UTC calendar-day streak tracking.
          </p>
        </div>

        <div className="p-8 rounded-3xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 shadow-xs space-y-4">
          <h2 className="text-xl font-bold text-slate-900 dark:text-white">
            3. Absolute Data Sovereignty
          </h2>
          <p className="text-sm text-slate-600 dark:text-slate-400 leading-relaxed">
            Your performance curves, accuracy timelines, and response latencies are your property. We have zero advertising trackers, and you can export or permanently delete your complete telemetry record at any time.
          </p>
        </div>
      </div>

      {/* The 6 Cognitive Faculties Taxonomy */}
      <div className="p-8 sm:p-12 rounded-3xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 shadow-xs space-y-8">
        <div className="max-w-2xl space-y-2">
          <h2 className="text-xs font-bold uppercase tracking-widest text-emerald-600 dark:text-emerald-400">
            Cognitive Taxonomy
          </h2>
          <p className="text-2xl sm:text-3xl font-extrabold text-slate-900 dark:text-white tracking-tight">
            How We Structure Mental Agility
          </p>
          <p className="text-sm text-slate-600 dark:text-slate-400">
            Our library targets six distinct psychological domains, each represented by a dedicated exercise:
          </p>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
          <div className="p-5 rounded-2xl bg-slate-50 dark:bg-slate-950/50 border border-slate-200 dark:border-slate-800 space-y-1.5">
            <span className="text-xs font-bold text-emerald-600 dark:text-emerald-400">Memory Matrix</span>
            <h3 className="font-bold text-slate-900 dark:text-white">Spatial Working Memory</h3>
            <p className="text-xs text-slate-600 dark:text-slate-400 leading-relaxed">
              Short-term visual representation maintenance and precision spatial recall.
            </p>
          </div>

          <div className="p-5 rounded-2xl bg-slate-50 dark:bg-slate-950/50 border border-slate-200 dark:border-slate-800 space-y-1.5">
            <span className="text-xs font-bold text-emerald-600 dark:text-emerald-400">Reflex Forge</span>
            <h3 className="font-bold text-slate-900 dark:text-white">Cognitive Flexibility</h3>
            <p className="text-xs text-slate-600 dark:text-slate-400 leading-relaxed">
              Rapid rule switching, cognitive set shifting, and inhibitory control.
            </p>
          </div>

          <div className="p-5 rounded-2xl bg-slate-50 dark:bg-slate-950/50 border border-slate-200 dark:border-slate-800 space-y-1.5">
            <span className="text-xs font-bold text-emerald-600 dark:text-emerald-400">Focus Reactor</span>
            <h3 className="font-bold text-slate-900 dark:text-white">Selective Attention</h3>
            <p className="text-xs text-slate-600 dark:text-slate-400 leading-relaxed">
              Perceptual target discrimination, distractor suppression, and sustained vigilance.
            </p>
          </div>

          <div className="p-5 rounded-2xl bg-slate-50 dark:bg-slate-950/50 border border-slate-200 dark:border-slate-800 space-y-1.5">
            <span className="text-xs font-bold text-emerald-600 dark:text-emerald-400">Logic Labyrinth</span>
            <h3 className="font-bold text-slate-900 dark:text-white">Problem Solving</h3>
            <p className="text-xs text-slate-600 dark:text-slate-400 leading-relaxed">
              Topological path planning, multi-step constraint evaluation, and deduction.
            </p>
          </div>

          <div className="p-5 rounded-2xl bg-slate-50 dark:bg-slate-950/50 border border-slate-200 dark:border-slate-800 space-y-1.5">
            <span className="text-xs font-bold text-emerald-600 dark:text-emerald-400">Number Pulse</span>
            <h3 className="font-bold text-slate-900 dark:text-white">Numerical Reasoning</h3>
            <p className="text-xs text-slate-600 dark:text-slate-400 leading-relaxed">
              Mental arithmetic sequencing, computational speed, and formula extrapolation.
            </p>
          </div>

          <div className="p-5 rounded-2xl bg-slate-50 dark:bg-slate-950/50 border border-slate-200 dark:border-slate-800 space-y-1.5">
            <span className="text-xs font-bold text-emerald-600 dark:text-emerald-400">Word Weaver</span>
            <h3 className="font-bold text-slate-900 dark:text-white">Verbal Fluency</h3>
            <p className="text-xs text-slate-600 dark:text-slate-400 leading-relaxed">
              Lexical retrieval, semantic association distance, and anagram resolution.
            </p>
          </div>
        </div>
      </div>

      {/* Team & Verification */}
      <div className="p-8 rounded-3xl bg-slate-100 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 space-y-4">
        <h2 className="text-lg font-bold text-slate-900 dark:text-white">
          Open Architecture & Auditable Rules
        </h2>
        <p className="text-sm text-slate-600 dark:text-slate-400 leading-relaxed">
          NEUROPLAY&apos;s game engine is decoupled from presentation and covered by comprehensive deterministic test suites. Every level generation seed, scoring calculation, and difficulty transition is verifiably reproducible.
        </p>
        <div className="pt-2">
          <Link
            href="/contact"
            className="text-sm font-semibold text-emerald-600 dark:text-emerald-400 hover:underline"
          >
            Have a research inquiry? Reach out to us →
          </Link>
        </div>
      </div>
    </div>
  );
}
