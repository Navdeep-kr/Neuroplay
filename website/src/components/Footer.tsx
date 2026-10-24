import React from "react";
import Link from "next/link";
import { BrainIcon } from "./Icons";
import { SITE_CONFIG } from "@/lib/constants";

export function Footer() {
  return (
    <footer className="border-t border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-950 text-slate-600 dark:text-slate-400">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12 md:py-16">
        <div className="grid grid-cols-1 md:grid-cols-5 gap-8 lg:gap-12">
          {/* Brand Info */}
          <div className="md:col-span-2 space-y-4">
            <Link
              href="/"
              className="inline-flex items-center gap-2.5 font-bold text-xl tracking-tight text-slate-900 dark:text-white"
            >
              <span className="p-1.5 rounded-lg bg-emerald-500/10 text-emerald-600 dark:text-emerald-400">
                <BrainIcon className="w-5 h-5" />
              </span>
              <span className="font-extrabold tracking-wider">NEUROPLAY</span>
            </Link>
            <p className="text-sm text-slate-600 dark:text-slate-400 leading-relaxed max-w-sm">
              Purpose-built brain training engineered with clinical integrity, transparent adaptive difficulty, and zero manipulative engagement gimmicks.
            </p>
            <div className="flex items-center gap-2 text-xs text-slate-500">
              <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
              <span>All systems operational • v1.0.0</span>
            </div>
          </div>

          {/* Navigation Column 1: Product */}
          <div>
            <h2 className="text-xs font-semibold uppercase tracking-wider text-slate-900 dark:text-white mb-4">
              Product
            </h2>
            <ul className="space-y-2.5 text-sm">
              <li>
                <Link href="/games" className="hover:text-emerald-600 dark:hover:text-emerald-400 transition-colors">
                  Game Library
                </Link>
              </li>
              <li>
                <Link href="/how-it-works" className="hover:text-emerald-600 dark:hover:text-emerald-400 transition-colors">
                  How It Works
                </Link>
              </li>
              <li>
                <a
                  href={SITE_CONFIG.appUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="hover:text-emerald-600 dark:hover:text-emerald-400 transition-colors"
                >
                  Web App
                </a>
              </li>
              <li>
                <Link href="/accessibility" className="hover:text-emerald-600 dark:hover:text-emerald-400 transition-colors">
                  Accessibility
                </Link>
              </li>
            </ul>
          </div>

          {/* Navigation Column 2: Resources & Company */}
          <div>
            <h2 className="text-xs font-semibold uppercase tracking-wider text-slate-900 dark:text-white mb-4">
              Company
            </h2>
            <ul className="space-y-2.5 text-sm">
              <li>
                <Link href="/about" className="hover:text-emerald-600 dark:hover:text-emerald-400 transition-colors">
                  About Us
                </Link>
              </li>
              <li>
                <Link href="/faq" className="hover:text-emerald-600 dark:hover:text-emerald-400 transition-colors">
                  FAQ
                </Link>
              </li>
              <li>
                <Link href="/contact" className="hover:text-emerald-600 dark:hover:text-emerald-400 transition-colors">
                  Contact & Support
                </Link>
              </li>
              <li>
                <Link href="/admin/login" className="hover:text-emerald-600 dark:hover:text-emerald-400 transition-colors">
                  Admin Console
                </Link>
              </li>
            </ul>
          </div>

          {/* Navigation Column 3: Legal & Trust */}
          <div>
            <h2 className="text-xs font-semibold uppercase tracking-wider text-slate-900 dark:text-white mb-4">
              Legal & Trust
            </h2>
            <ul className="space-y-2.5 text-sm">
              <li>
                <Link href="/privacy" className="hover:text-emerald-600 dark:hover:text-emerald-400 transition-colors">
                  Privacy Policy
                </Link>
              </li>
              <li>
                <Link href="/terms" className="hover:text-emerald-600 dark:hover:text-emerald-400 transition-colors">
                  Terms of Service
                </Link>
              </li>
              <li>
                <Link href="/subscription-disclosures" className="hover:text-emerald-600 dark:hover:text-emerald-400 transition-colors">
                  Subscription Terms
                </Link>
              </li>
            </ul>
          </div>
        </div>

        {/* Essential Science & Medical Scope Disclaimer */}
        <div className="mt-12 pt-8 border-t border-slate-200/80 dark:border-slate-800/80">
          <div className="p-4 rounded-xl bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 text-xs text-slate-500 dark:text-slate-400 leading-relaxed">
            <strong className="font-semibold text-slate-700 dark:text-slate-300">Scientific Scope & Non-Medical Notice:</strong>{" "}
            NEUROPLAY training exercises are digital games created for recreation, habit formation, and mental stimulation across core cognitive domains. NEUROPLAY is not a medical device, diagnostic instrument, or clinical therapy. NEUROPLAY does not diagnose, treat, prevent, or reverse dementia, Alzheimer&apos;s disease, or any neurological illness, nor does it guarantee general intelligence (IQ) increase or real-world cognitive transfer.
          </div>
          <div className="mt-6 flex flex-col sm:flex-row items-center justify-between text-xs text-slate-500 gap-4">
            <p>© 2026 NEUROPLAY. All rights reserved.</p>
            <p>Designed with clinical integrity & transparent algorithms.</p>
          </div>
        </div>
      </div>
    </footer>
  );
}
