import React from "react";
import Link from "next/link";
import { BrainIcon } from "./Icons";
import { SITE_CONFIG } from "@/lib/constants";

export function Footer() {
  return (
    <footer className="border-t border-slate-200 bg-white text-slate-600">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12 md:py-16">
        <div className="grid grid-cols-1 md:grid-cols-5 gap-8 lg:gap-12">
          {/* Brand Info */}
          <div className="md:col-span-2 space-y-4">
            <Link
              href="/"
              className="inline-flex items-center gap-2.5 font-bold text-xl tracking-tight text-slate-900"
            >
              <span className="p-1.5 rounded-lg bg-blue-50 text-blue-600 border border-blue-100">
                <BrainIcon className="w-5 h-5" />
              </span>
              <span className="font-extrabold tracking-wider">NEUROPLAY</span>
            </Link>
            <p className="text-sm text-slate-600 leading-relaxed max-w-sm">
              Purpose-built brain training engineered with clinical integrity, transparent adaptive difficulty, and zero manipulative engagement gimmicks.
            </p>
            <div className="flex items-center gap-2 text-xs text-slate-500">
              <span className="w-2 h-2 rounded-full bg-blue-600 animate-pulse" />
              <span>All systems operational • v1.0.0</span>
            </div>
          </div>

          {/* Navigation Column 1: Product */}
          <div>
            <h2 className="text-xs font-semibold uppercase tracking-wider text-slate-900 mb-4">
              Product
            </h2>
            <ul className="space-y-2.5 text-sm">
              <li>
                <Link href="/games" className="hover:text-blue-600 transition-colors">
                  Game Library
                </Link>
              </li>
              <li>
                <Link href="/how-it-works" className="hover:text-blue-600 transition-colors">
                  How It Works
                </Link>
              </li>
              <li>
                <Link href="/play" className="hover:text-blue-600 transition-colors">
                  Web App
                </Link>
              </li>
              <li>
                <Link href="/accessibility" className="hover:text-blue-600 transition-colors">
                  Accessibility
                </Link>
              </li>
            </ul>
          </div>

          {/* Navigation Column 2: Resources & Company */}
          <div>
            <h2 className="text-xs font-semibold uppercase tracking-wider text-slate-900 mb-4">
              Company
            </h2>
            <ul className="space-y-2.5 text-sm">
              <li>
                <Link href="/about" className="hover:text-blue-600 transition-colors">
                  About Us
                </Link>
              </li>
              <li>
                <Link href="/faq" className="hover:text-blue-600 transition-colors">
                  FAQ
                </Link>
              </li>
              <li>
                <Link href="/contact" className="hover:text-blue-600 transition-colors">
                  Contact & Support
                </Link>
              </li>
              <li>
                <Link href="/admin/login" className="hover:text-blue-600 transition-colors">
                  Admin Console
                </Link>
              </li>
            </ul>
          </div>

          {/* Navigation Column 3: Legal & Trust */}
          <div>
            <h2 className="text-xs font-semibold uppercase tracking-wider text-slate-900 mb-4">
              Legal & Trust
            </h2>
            <ul className="space-y-2.5 text-sm">
              <li>
                <Link href="/privacy" className="hover:text-blue-600 transition-colors">
                  Privacy Policy
                </Link>
              </li>
              <li>
                <Link href="/terms" className="hover:text-blue-600 transition-colors">
                  Terms of Service
                </Link>
              </li>
              <li>
                <Link href="/subscription-disclosures" className="hover:text-blue-600 transition-colors">
                  Subscription Terms
                </Link>
              </li>
            </ul>
          </div>
        </div>

        {/* Essential Science & Medical Scope Disclaimer */}
        <div className="mt-12 pt-8 border-t border-slate-200">
          <div className="p-4 rounded-xl bg-slate-50 border border-slate-200 text-xs text-slate-500 leading-relaxed">
            <strong className="font-semibold text-slate-700">Scientific Scope & Non-Medical Notice:</strong>{" "}
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
