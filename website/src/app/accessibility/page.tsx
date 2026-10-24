import React from "react";
import type { Metadata } from "next";
import Link from "next/link";
import { SparklesIcon } from "@/components/Icons";

export const metadata: Metadata = {
  title: "Accessibility",
  description:
    "NEUROPLAY's accessibility principles: WCAG 2.1 AA targets, dual non-color distinction, reduced-motion handling, keyboard navigation, and screen reader semantics.",
};

export default function AccessibilityPage() {
  return (
    <div className="py-12 md:py-20 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 space-y-16">
      {/* Header */}
      <div className="max-w-3xl space-y-4">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-md text-xs font-semibold bg-emerald-50 dark:bg-emerald-950/60 text-emerald-700 dark:text-emerald-300 border border-emerald-200 dark:border-emerald-800">
          <SparklesIcon className="w-4 h-4 text-emerald-600 dark:text-emerald-400" />
          <span>Universal Design</span>
        </div>
        <h1 className="text-3xl sm:text-4xl lg:text-5xl font-extrabold text-slate-900 dark:text-white tracking-tight">
          Accessibility Commitment
        </h1>
        <p className="text-base sm:text-lg text-slate-600 dark:text-slate-300 leading-relaxed">
          Cognitive training belongs to everyone. NEUROPLAY is built from the ground up to comply with WCAG 2.1 AA guidelines, offering multi-modal cues, complete keyboard support, and sensory comfort controls.
        </p>
      </div>

      {/* 6 Key Accessibility Pillars */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
        {/* Pillar 1 */}
        <div className="p-8 rounded-3xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 shadow-xs space-y-4">
          <h2 className="text-xl font-bold text-slate-900 dark:text-white">
            Dual Non-Color Cues
          </h2>
          <p className="text-sm text-slate-600 dark:text-slate-400 leading-relaxed">
            No game mechanic relies solely on color identification. Every target, rule switch, and tile pattern features secondary geometric silhouettes, tactile icon glyphs, or explicit textual labels to ensure full accessibility for color-vision variations.
          </p>
        </div>

        {/* Pillar 2 */}
        <div className="p-8 rounded-3xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 shadow-xs space-y-4">
          <h2 className="text-xl font-bold text-slate-900 dark:text-white">
            Reduced Motion & Flash Safety
          </h2>
          <p className="text-sm text-slate-600 dark:text-slate-400 leading-relaxed">
            Respecting both OS-level `prefers-reduced-motion` settings and in-app toggles, NEUROPLAY eliminates rapid oscillations, high-frequency strobing, and disorienting parallax transitions.
          </p>
        </div>

        {/* Pillar 3 */}
        <div className="p-8 rounded-3xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 shadow-xs space-y-4">
          <h2 className="text-xl font-bold text-slate-900 dark:text-white">
            Full Keyboard Navigation
          </h2>
          <p className="text-sm text-slate-600 dark:text-slate-400 leading-relaxed">
            Every interactive control and cognitive game can be played via keyboard. Arrow keys, WASD, Spacebar, Enter, and Numpad keys allow mouse-free interaction with distinct, high-contrast focus rings.
          </p>
        </div>

        {/* Pillar 4 */}
        <div className="p-8 rounded-3xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 shadow-xs space-y-4">
          <h2 className="text-xl font-bold text-slate-900 dark:text-white">
            Screen Reader Semantics
          </h2>
          <p className="text-sm text-slate-600 dark:text-slate-400 leading-relaxed">
            All buttons, dialogs, sliders, and progress charts include descriptive semantic labels and live region announcements (`aria-live`), informing users of phase changes, remaining trial budgets, and score outcomes.
          </p>
        </div>

        {/* Pillar 5 */}
        <div className="p-8 rounded-3xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 shadow-xs space-y-4">
          <h2 className="text-xl font-bold text-slate-900 dark:text-white">
            Accessible Chart Alternatives
          </h2>
          <p className="text-sm text-slate-600 dark:text-slate-400 leading-relaxed">
            Visual timelines and reaction-time charts can be switched with a single click into fully accessible `DataTable` views, allowing tabular exploration of numeric performance history.
          </p>
        </div>

        {/* Pillar 6 */}
        <div className="p-8 rounded-3xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 shadow-xs space-y-4">
          <h2 className="text-xl font-bold text-slate-900 dark:text-white">
            Generous Touch Targets & Contrast
          </h2>
          <p className="text-sm text-slate-600 dark:text-slate-400 leading-relaxed">
            All touch surfaces adhere to minimum 48×48dp dimensions with ample spacing, and text colors satisfy WCAG AAA standards for primary text (7:1) and AA standards for secondary elements (4.5:1).
          </p>
        </div>
      </div>

      {/* Feedback Section */}
      <div className="p-8 rounded-3xl bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-800 space-y-4">
        <h2 className="text-lg font-bold text-slate-900 dark:text-white">
          Encountered an Accessibility Barrier?
        </h2>
        <p className="text-sm text-slate-600 dark:text-slate-400 leading-relaxed max-w-2xl">
          We treat accessibility defects as critical issues. If you experience difficulty operating any feature or game with your assistive technology, please let our engineering team know directly.
        </p>
        <div className="pt-2">
          <Link
            href="/contact"
            className="inline-flex items-center justify-center px-6 py-2.5 rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white font-semibold text-sm transition-colors"
          >
            Contact Accessibility Team
          </Link>
        </div>
      </div>
    </div>
  );
}
