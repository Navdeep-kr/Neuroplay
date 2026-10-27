import React from "react";
import type { Metadata } from "next";
import { SparklesIcon } from "@/components/Icons";

export const metadata: Metadata = {
  title: "Terms of Service",
  description:
    "NEUROPLAY Terms of Service: user rights, permitted use, intellectual property, and non-medical training disclosures.",
};

export default function TermsPage() {
  return (
    <div className="py-12 md:py-20 max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 space-y-12">
      <div className="space-y-4">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-md text-xs font-semibold bg-emerald-50 text-emerald-700 border border-emerald-200">
          <SparklesIcon className="w-4 h-4 text-emerald-600" />
          <span>Legal Agreement</span>
        </div>
        <h1 className="text-3xl sm:text-4xl lg:text-5xl font-extrabold text-slate-900 tracking-tight">
          Terms of Service
        </h1>
        <p className="text-sm text-slate-500 font-mono">
          Last Updated: October 2026 • Version 1.0.0
        </p>
      </div>

      <div className="prose max-w-none space-y-8 text-sm sm:text-base text-slate-600 leading-relaxed">
        <section className="space-y-3">
          <h2 className="text-xl font-bold text-slate-900">
            1. Acceptance of Terms
          </h2>
          <p>
            By accessing or playing NEUROPLAY (via web, desktop, or mobile applications), you agree to be bound by these Terms of Service. If you do not agree to these terms, you may discontinue use or delete your account at any time.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-bold text-slate-900">
            2. Medical & Clinical Disclaimer
          </h2>
          <div className="p-4 rounded-xl bg-slate-100 border border-slate-200 text-sm">
            NEUROPLAY exercises are recreational mental training games. They are not intended, designed, or licensed for the diagnosis, cure, mitigation, treatment, or prevention of disease, neurological conditions, cognitive decline, or mental illness. Always consult a qualified medical professional for health concerns.
          </div>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-bold text-slate-900">
            3. Permitted Use & Account Integrity
          </h2>
          <p>
            You agree not to reverse engineer the application, submit fraudulent or automated bot session results, or attempt to circumvent authentication or role-based access controls on the backend.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-bold text-slate-900">
            4. Intellectual Property
          </h2>
          <p>
            All original games (Memory Matrix, Reflex Forge, Focus Reactor, Logic Labyrinth, Number Pulse, Word Weaver), visual interfaces, sound effects, brand assets, and custom code are proprietary to NEUROPLAY. You may not reproduce, redistribute, or create derivative commercial brain-training products using our copyrighted assets.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-bold text-slate-900">
            5. Limitation of Liability
          </h2>
          <p>
            NEUROPLAY is provided on an &ldquo;as is&rdquo; and &ldquo;as available&rdquo; basis. To the maximum extent permitted by applicable law, NEUROPLAY disclaims all warranties, express or implied, regarding reliability, fitness for a particular purpose, or cognitive outcome guarantees.
          </p>
        </section>
      </div>
    </div>
  );
}
