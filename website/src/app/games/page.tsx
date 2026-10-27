import React from "react";
import type { Metadata } from "next";
import Link from "next/link";
import { ArrowRightIcon, CheckCircleIcon, SparklesIcon } from "@/components/Icons";
import { GAMES_DATA } from "@/lib/constants";

export const metadata: Metadata = {
  title: "Game Library",
  description:
    "Explore NEUROPLAY's six original cognitive exercises across Memory, Cognitive Flexibility, Attention, Problem Solving, Calculation, and Language.",
};

export default function GamesPage() {
  return (
    <div className="py-12 md:py-20 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 space-y-16 bg-white text-slate-900">
      {/* Header */}
      <div className="max-w-3xl space-y-4">
        <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-md text-xs font-semibold bg-blue-50 text-blue-700 border border-blue-200">
          <SparklesIcon className="w-4 h-4 text-blue-600" />
          <span>The Six Cognitive Domains</span>
        </div>
        <h1 className="text-3xl sm:text-4xl lg:text-5xl font-extrabold text-slate-900 tracking-tight">
          NEUROPLAY Game Library
        </h1>
        <p className="text-base sm:text-lg text-slate-600 leading-relaxed font-normal">
          Six original exercises built on established psychological paradigms. Each game features reproducible seeded levels, bounded adaptive difficulty, keyboard controls, and transparent telemetry.
        </p>
      </div>

      {/* Game Cards */}
      <div className="space-y-12">
        {GAMES_DATA.map((game, idx) => (
          <article
            key={game.id}
            id={game.id}
            className="p-5 sm:p-8 md:p-10 rounded-2xl sm:rounded-3xl bg-white border border-slate-200 shadow-xs hover:shadow-md transition-all space-y-6 sm:space-y-8 scroll-mt-24"
          >
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-5 sm:pb-6 border-b border-slate-100">
              <div className="flex items-center gap-3.5 sm:gap-4">
                <span className="w-9 h-9 sm:w-10 sm:h-10 rounded-xl bg-slate-100 flex items-center justify-center font-bold text-slate-800 text-xs sm:text-sm shrink-0">
                  {idx + 1 < 10 ? `0${idx + 1}` : idx + 1}
                </span>
                <div>
                  <h2 className="text-xl sm:text-2xl font-bold text-slate-900">
                    {game.title}
                  </h2>
                  <div className="flex items-center gap-2 mt-1">
                    <span className="text-xs font-bold text-blue-600">
                      {game.faculty}
                    </span>
                    <span className="text-slate-300">•</span>
                    <span className="text-xs font-semibold text-slate-500 font-mono">v{game.version}</span>
                  </div>
                </div>
              </div>

              <div>
                <Link
                  href={`/play?game=${game.id}`}
                  className="w-full sm:w-auto inline-flex items-center justify-center gap-2 px-5 py-3 rounded-xl bg-blue-600 hover:bg-blue-500 active:bg-blue-700 text-white font-semibold text-xs sm:text-sm transition-all shadow-xs"
                >
                  <span>Play {game.title}</span>
                  <ArrowRightIcon className="w-3.5 h-3.5" />
                </Link>
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
              {/* Mechanics */}
              <div className="space-y-2">
                <h3 className="text-xs font-bold uppercase tracking-wider text-slate-500">
                  Gameplay Mechanics
                </h3>
                <p className="text-sm text-slate-600 leading-relaxed font-normal">
                  {game.mechanics}
                </p>
              </div>

              {/* Scoring */}
              <div className="space-y-2">
                <h3 className="text-xs font-bold uppercase tracking-wider text-slate-500">
                  Scoring & Metrics
                </h3>
                <p className="text-sm text-slate-600 leading-relaxed font-normal">
                  {game.scoring}
                </p>
              </div>

              {/* Accessibility */}
              <div className="space-y-2">
                <h3 className="text-xs font-bold uppercase tracking-wider text-slate-500">
                  Accessibility & Controls
                </h3>
                <p className="text-sm text-slate-600 leading-relaxed font-normal">
                  {game.accessibility}
                </p>
              </div>
            </div>

            <div className="flex flex-wrap items-center gap-4 text-xs font-medium text-slate-600 pt-2">
              <span className="inline-flex items-center gap-1.5">
                <CheckCircleIcon className="w-4 h-4 text-emerald-600" />
                Practice Mode included
              </span>
              <span className="inline-flex items-center gap-1.5">
                <CheckCircleIcon className="w-4 h-4 text-emerald-600" />
                Seeded deterministic runs
              </span>
              <span className="inline-flex items-center gap-1.5">
                <CheckCircleIcon className="w-4 h-4 text-emerald-600" />
                Offline operable
              </span>
            </div>
          </article>
        ))}
      </div>

      {/* Task Performance vs Transfer Disclaimer */}
      <div className="p-6 rounded-2xl bg-slate-50 border border-slate-200 text-xs text-slate-600 leading-relaxed">
        <strong className="font-semibold text-slate-900">Scientific Scope & Non-Medical Notice:</strong> High scores and latency improvements in NEUROPLAY reflect task-specific practice and perceptual strategies. NEUROPLAY exercises are not a medical device, do not diagnose neurological conditions or cognitive impairments, and do not imply generalized IQ increases.
      </div>
    </div>
  );
}
