import React from "react";
import type { Metadata } from "next";
import { SparklesIcon, CheckCircleIcon } from "@/components/Icons";

export const metadata: Metadata = {
  title: "Subscription Disclosures",
  description:
    "NEUROPLAY Subscription Disclosures: clear pricing, free tier features, auto-renewal terms, cancellation rules, and refund policy.",
};

export default function SubscriptionDisclosuresPage() {
  return (
    <div className="py-12 md:py-20 max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 space-y-12">
      <div className="space-y-4">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-md text-xs font-semibold bg-emerald-50 dark:bg-emerald-950/60 text-emerald-700 dark:text-emerald-300 border border-emerald-200 dark:border-emerald-800">
          <SparklesIcon className="w-4 h-4 text-emerald-600 dark:text-emerald-400" />
          <span>Pricing Transparency</span>
        </div>
        <h1 className="text-3xl sm:text-4xl lg:text-5xl font-extrabold text-slate-900 dark:text-white tracking-tight">
          Subscription & Billing Disclosures
        </h1>
        <p className="text-sm text-slate-500 font-mono">
          Last Updated: October 2026 • Policy Version 1.0.0
        </p>
      </div>

      <div className="space-y-8 text-sm sm:text-base text-slate-600 dark:text-slate-300 leading-relaxed">
        {/* Free vs Premium Grid */}
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-6 pt-4">
          <div className="p-6 rounded-2xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 space-y-4">
            <h2 className="text-lg font-bold text-slate-900 dark:text-white">
              Free Community Tier
            </h2>
            <p className="text-2xl font-extrabold text-slate-900 dark:text-white">$0</p>
            <ul className="space-y-2 text-sm text-slate-600 dark:text-slate-400">
              <li className="flex items-center gap-2">
                <CheckCircleIcon className="w-4 h-4 text-emerald-500" />
                Full guest mode without registration
              </li>
              <li className="flex items-center gap-2">
                <CheckCircleIcon className="w-4 h-4 text-emerald-500" />
                Access to all 6 original exercises
              </li>
              <li className="flex items-center gap-2">
                <CheckCircleIcon className="w-4 h-4 text-emerald-500" />
                Daily 3-game workout generation
              </li>
              <li className="flex items-center gap-2">
                <CheckCircleIcon className="w-4 h-4 text-emerald-500" />
                Local personal bests and history
              </li>
            </ul>
          </div>

          <div className="p-6 rounded-2xl bg-emerald-50/50 dark:bg-emerald-950/20 border border-emerald-200 dark:border-emerald-800/60 space-y-4">
            <h2 className="text-lg font-bold text-slate-900 dark:text-white">
              NEUROPLAY Plus
            </h2>
            <p className="text-2xl font-extrabold text-slate-900 dark:text-white">
              $4.99 <span className="text-xs font-normal text-slate-500">/ month or $39.99 / year</span>
            </p>
            <ul className="space-y-2 text-sm text-slate-600 dark:text-slate-400">
              <li className="flex items-center gap-2">
                <CheckCircleIcon className="w-4 h-4 text-emerald-500" />
                Cloud sync across unlimited devices
              </li>
              <li className="flex items-center gap-2">
                <CheckCircleIcon className="w-4 h-4 text-emerald-500" />
                Extended multi-year response latency analytics
              </li>
              <li className="flex items-center gap-2">
                <CheckCircleIcon className="w-4 h-4 text-emerald-500" />
                Detailed faculty balance distributions
              </li>
              <li className="flex items-center gap-2">
                <CheckCircleIcon className="w-4 h-4 text-emerald-500" />
                Priority customer and accessibility support
              </li>
            </ul>
          </div>
        </div>

        <section className="space-y-3 pt-6 border-t border-slate-200 dark:border-slate-800">
          <h2 className="text-xl font-bold text-slate-900 dark:text-white">
            1. Clear Auto-Renewal Policy
          </h2>
          <p>
            Subscriptions automatically renew at the end of each billing cycle (monthly or annually) unless canceled at least 24 hours before the renewal date. We will send an email reminder 7 days prior to any annual renewal.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-bold text-slate-900 dark:text-white">
            2. Simple One-Click Cancellation
          </h2>
          <p>
            You can cancel your subscription at any time directly through the app settings, Google Play Store, or Apple App Store depending on where you subscribed. When canceled, you retain full Plus access through the end of your current paid billing period with zero cancellation penalties.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-bold text-slate-900 dark:text-white">
            3. 14-Day Refund Guarantee
          </h2>
          <p>
            If you are unsatisfied with NEUROPLAY Plus for any reason within the first 14 days of your initial purchase, contact support@neuroplay.app for a full, no-questions-asked refund.
          </p>
        </section>
      </div>
    </div>
  );
}
