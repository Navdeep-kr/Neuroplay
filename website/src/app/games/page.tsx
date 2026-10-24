import React from "react";
import type { Metadata } from "next";
import { ArrowRightIcon, CheckCircleIcon, SparklesIcon } from "@/components/Icons";
import { GAMES_DATA, SITE_CONFIG } from "@/lib/constants";

export const metadata: Metadata = {
  title: "Game Library",
  description:
    "Explore NEUROPLAY's six original cognitive exercises across Memory, Cognitive Flexibility, Attention, Problem Solving, Calculation, and Language.",
};

export default function GamesPage() {
  return (
    <div className="py-12 md:py-20 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 space-y-16">
      {/* Header */}
      <div className="max-w-3xl space-y-4">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-md text-xs font-semibold bg-emerald-50 dark:bg-emerald-950/60 text-emerald-700 dark:text-emerald-300 border border-emerald-200 dark:border-emerald-800">
          <SparklesIcon className="w-4 h-4 text-emerald-600 dark:text-emerald-400" />
          <span>The Six Cognitive Domains</span>
        </div>
        <h1 className="text-3xl sm:text-4xl lg:text-5xl font-extrabold text-slate-900 dark:text-white tracking-tight">
          NEUROPLAY Game Library
        </h1>
        <p className="text-base sm:text-lg text-slate-600 dark:text-slate-300 leading-relaxed">
          Six original exercises built on established psychological paradigms. Each game features reproducible seeded levels, bounded adaptive difficulty, keyboard controls, and transparent telemetry.
        </p>
      </div>

      {/* Game Cards */}
      <div className="space-y-12">
        {GAMES_DATA.map((game, idx) => (
          <article
            key={game.id}
            id={game.id}
            className="p-8 sm:p-10 rounded-3xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 shadow-xs space-y-8 scroll-mt-24"
          >
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-6 border-b border-slate-100 dark:border-slate-800">
              <div className="flex items-center gap-4">
                <span className="w-10 h-10 rounded-xl bg-slate-100 dark:bg-slate-800 flex items-center justify-center font-bold text-slate-700 dark:text-slate-300 text-sm">
                  0{idx + 1}
                </span>
                <div>
                  <h2 className="text-2xl font-bold text-slate-900 dark:text-white">
                    {game.title}
                  </h2>
                  <div className="flex items-center gap-2 mt-1">
                    <span className="text-xs font-semibold text-emerald-600 dark:text-emerald-400">
                      {game.faculty}
                    </span>
                    <span className="text-slate-300 dark:text-slate-700">•</span>
                    <span className="text-xs text-slate-500 font-mono">Engine Version: {game.version}</span>
                  </div>
                </div>
              </div>

              <div>
                <a
                  href={`${SITE_CONFIG.appUrl}#/${game.id}`}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center gap-2 px-4 py-2 rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white font-semibold text-xs transition-colors shadow-xs"
                >
                  <span>Play {game.title}</span>
                  <ArrowRightIcon className="w-3.5 h-3.5" />
                </a>
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
              {/* Mechanics */}
              <div className="space-y-2">
                <h3 className="text-xs font-bold uppercase tracking-wider text-slate-400 dark:text-slate-500">
                  Gameplay Mechanics
                </h3>
                <p className="text-sm text-slate-600 dark:text-slate-300 leading-relaxed">
                  {game.mechanics}
                </p>
              </div>

              {/* Scoring */}
              <div className="space-y-2">
                <h3 className="text-xs font-bold uppercase tracking-wider text-slate-400 dark:text-slate-500">
                  Scoring & Metrics
                </h3>
                <p className="text-sm text-slate-600 dark:text-slate-300 leading-relaxed">
                  {game.scoring}
                </p>
              </div>

              {/* Accessibility */}
              <div className="space-y-2">
                <h3 className="text-xs font-bold uppercase tracking-wider text-slate-400 dark:text-slate-500">
                  Accessibility & Controls
                </h3>
                <p className="text-sm text-slate-600 dark:text-slate-300 leading-relaxed">
                  {game.accessibility}
                </p>
              </div>
            </div>

            <div className="flex flex-wrap items-center gap-4 text-xs text-slate-500 dark:text-slate-400 pt-2">
              <span className="inline-flex items-center gap-1.5">
                <CheckCircleIcon className="w-4 h-4 text-emerald-500" />
                Practice Mode included
              </span>
              <span className="inline-flex items-center gap-1.5">
                <CheckCircleIcon className="w-4 h-4 text-emerald-500" />
                Seeded deterministic runs
              </span>
              <span className="inline-flex items-center gap-1.5">
                <CheckCircleIcon className="w-4 h-4 text-emerald-500" />
                Offline operable
              </span>
            </div>
          </article>
        ))}
      </div>

      {/* Task Performance vs Transfer Disclaimer */}
      <div className="p-6 rounded-2xl bg-slate-100 dark:bg-slate-900 border border-slate-200 dark:border-slate-800 text-xs text-slate-600 dark:text-slate-400 leading-relaxed">
        <strong className="font-semibold text-slate-900 dark:text-white">Scientific Scope & Non-Medical Notice:</strong> High scores and latency improvements in NEUROPLAY reflect task-specific practice and perceptual strategies. NEUROPLAY exercises are not a medical device, do not diagnose neurological conditions or cognitive impairments, and do not imply generalized IQ increases.
      </div>
    </div>
  );
}
