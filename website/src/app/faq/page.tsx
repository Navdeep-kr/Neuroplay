"use client";

import React, { useState } from "react";
import Link from "next/link";
import { FAQ_ITEMS } from "@/lib/constants";
import { FaqJsonLd } from "@/components/StructuredData";
import { SparklesIcon, ArrowRightIcon } from "@/components/Icons";

export default function FaqPage() {
  const [openIndex, setOpenIndex] = useState<number | null>(0);

  const toggle = (idx: number) => {
    setOpenIndex(openIndex === idx ? null : idx);
  };

  return (
    <>
      <FaqJsonLd />
      <div className="py-12 md:py-20 max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 space-y-16">
        {/* Header */}
        <div className="text-center space-y-4 max-w-2xl mx-auto">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-md text-xs font-semibold bg-emerald-50 text-emerald-700 border border-emerald-200">
            <SparklesIcon className="w-4 h-4 text-emerald-600" />
            <span>Got Questions?</span>
          </div>
          <h1 className="text-3xl sm:text-4xl lg:text-5xl font-extrabold text-slate-900 tracking-tight">
            Frequently Asked Questions
          </h1>
          <p className="text-base sm:text-lg text-slate-600 leading-relaxed">
            Everything you need to know about NEUROPLAY&apos;s games, scientific foundations, data privacy, and adaptive algorithms.
          </p>
        </div>

        {/* FAQ Accordion */}
        <div className="space-y-4">
          {FAQ_ITEMS.map((item, idx) => {
            const isOpen = openIndex === idx;
            return (
              <div
                key={item.question}
                className="rounded-2xl bg-white border border-slate-200 shadow-xs overflow-hidden transition-all"
              >
                <button
                  type="button"
                  onClick={() => toggle(idx)}
                  className="w-full text-left p-6 sm:p-7 flex items-center justify-between gap-4 focus:outline-none focus-visible:ring-2 focus-visible:ring-emerald-500 rounded-2xl"
                  aria-expanded={isOpen}
                  aria-controls={`faq-answer-${idx}`}
                  id={`faq-question-${idx}`}
                >
                  <span className="font-bold text-base sm:text-lg text-slate-900">
                    {item.question}
                  </span>
                  <span
                    className={`transform transition-transform text-slate-400 flex-shrink-0 ${
                      isOpen ? "rotate-180 text-emerald-600" : ""
                    }`}
                  >
                    <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
                    </svg>
                  </span>
                </button>

                {isOpen && (
                  <div
                    id={`faq-answer-${idx}`}
                    role="region"
                    aria-labelledby={`faq-question-${idx}`}
                    className="px-6 pb-6 sm:px-7 sm:pb-7 text-sm sm:text-base text-slate-600 leading-relaxed border-t border-slate-100 pt-4"
                  >
                    {item.answer}
                  </div>
                )}
              </div>
            );
          })}
        </div>

        {/* Still have questions */}
        <div className="p-8 rounded-3xl bg-slate-100 border border-slate-200 text-center space-y-4">
          <h2 className="text-xl font-bold text-slate-900">
            Have a question that isn&apos;t answered here?
          </h2>
          <p className="text-sm text-slate-600 max-w-md mx-auto">
            Our support and research teams are always available to help with questions about accessibility, data privacy, or game mechanics.
          </p>
          <div className="pt-2">
            <Link
              href="/contact"
              className="inline-flex items-center gap-2 px-6 py-2.5 rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white font-semibold text-sm transition-colors"
            >
              <span>Contact Support</span>
              <ArrowRightIcon className="w-4 h-4" />
            </Link>
          </div>
        </div>
      </div>
    </>
  );
}
