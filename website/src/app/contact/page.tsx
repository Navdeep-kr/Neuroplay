"use client";

import React, { useState } from "react";
import { SparklesIcon, CheckCircleIcon, ArrowRightIcon } from "@/components/Icons";
import { SITE_CONFIG } from "@/lib/constants";

export default function ContactPage() {
  const [formState, setFormState] = useState({
    name: "",
    email: "",
    category: "general",
    message: "",
  });

  const [submitted, setSubmitted] = useState(false);
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [isSubmitting, setIsSubmitting] = useState(false);

  const validate = () => {
    const errs: Record<string, string> = {};
    if (!formState.name.trim()) errs.name = "Name is required.";
    if (!formState.email.trim()) {
      errs.email = "Email is required.";
    } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formState.email.trim())) {
      errs.email = "Please enter a valid email address.";
    }
    if (!formState.message.trim() || formState.message.trim().length < 10) {
      errs.message = "Message must be at least 10 characters long.";
    }
    setErrors(errs);
    return Object.keys(errs).length === 0;
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!validate()) return;

    setIsSubmitting(true);
    // Simulate accessible async submission without external API secrets
    setTimeout(() => {
      setIsSubmitting(false);
      setSubmitted(true);
      setFormState({ name: "", email: "", category: "general", message: "" });
    }, 700);
  };

  return (
    <div className="py-12 md:py-20 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 space-y-16">
      {/* Header */}
      <div className="max-w-3xl space-y-4">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-md text-xs font-semibold bg-emerald-50 dark:bg-emerald-950/60 text-emerald-700 dark:text-emerald-300 border border-emerald-200 dark:border-emerald-800">
          <SparklesIcon className="w-4 h-4 text-emerald-600 dark:text-emerald-400" />
          <span>Support & Inquiries</span>
        </div>
        <h1 className="text-3xl sm:text-4xl lg:text-5xl font-extrabold text-slate-900 dark:text-white tracking-tight">
          Contact NEUROPLAY
        </h1>
        <p className="text-base sm:text-lg text-slate-600 dark:text-slate-300 leading-relaxed">
          Need assistance with your account, encountered an accessibility issue, or have a question about cognitive metrics? Our dedicated team is here to help.
        </p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-12">
        {/* Contact Form */}
        <div className="lg:col-span-2 p-8 sm:p-10 rounded-3xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 shadow-xs">
          {submitted ? (
            <div className="py-12 text-center space-y-4">
              <div className="w-16 h-16 rounded-full bg-emerald-100 dark:bg-emerald-950/60 text-emerald-600 dark:text-emerald-400 flex items-center justify-center mx-auto border border-emerald-300 dark:border-emerald-800">
                <CheckCircleIcon className="w-8 h-8" />
              </div>
              <h2 className="text-2xl font-bold text-slate-900 dark:text-white">
                Message Received
              </h2>
              <p className="text-slate-600 dark:text-slate-400 text-sm max-w-md mx-auto">
                Thank you for reaching out. We will review your message and reply via email within one business day.
              </p>
              <button
                type="button"
                onClick={() => setSubmitted(false)}
                className="mt-4 px-6 py-2.5 rounded-xl bg-slate-100 dark:bg-slate-800 hover:bg-slate-200 dark:hover:bg-slate-700 text-slate-700 dark:text-slate-200 text-sm font-semibold transition-colors"
              >
                Send Another Message
              </button>
            </div>
          ) : (
            <form onSubmit={handleSubmit} noValidate className="space-y-6">
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
                {/* Name */}
                <div className="space-y-2">
                  <label htmlFor="contact-name" className="block text-sm font-semibold text-slate-800 dark:text-slate-200">
                    Your Name <span className="text-rose-500">*</span>
                  </label>
                  <input
                    id="contact-name"
                    type="text"
                    required
                    value={formState.name}
                    onChange={(e) => setFormState({ ...formState, name: e.target.value })}
                    aria-invalid={!!errors.name}
                    aria-describedby={errors.name ? "name-error" : undefined}
                    placeholder="Alex Morgan"
                    className="w-full px-4 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-slate-50 dark:bg-slate-950 text-slate-900 dark:text-white text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500"
                  />
                  {errors.name && (
                    <p id="name-error" className="text-xs text-rose-500">
                      {errors.name}
                    </p>
                  )}
                </div>

                {/* Email */}
                <div className="space-y-2">
                  <label htmlFor="contact-email" className="block text-sm font-semibold text-slate-800 dark:text-slate-200">
                    Email Address <span className="text-rose-500">*</span>
                  </label>
                  <input
                    id="contact-email"
                    type="email"
                    required
                    value={formState.email}
                    onChange={(e) => setFormState({ ...formState, email: e.target.value })}
                    aria-invalid={!!errors.email}
                    aria-describedby={errors.email ? "email-error" : undefined}
                    placeholder="alex@example.com"
                    className="w-full px-4 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-slate-50 dark:bg-slate-950 text-slate-900 dark:text-white text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500"
                  />
                  {errors.email && (
                    <p id="email-error" className="text-xs text-rose-500">
                      {errors.email}
                    </p>
                  )}
                </div>
              </div>

              {/* Inquiry Category */}
              <div className="space-y-2">
                <label htmlFor="contact-category" className="block text-sm font-semibold text-slate-800 dark:text-slate-200">
                  Topic / Category
                </label>
                <select
                  id="contact-category"
                  value={formState.category}
                  onChange={(e) => setFormState({ ...formState, category: e.target.value })}
                  className="w-full px-4 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-slate-50 dark:bg-slate-950 text-slate-900 dark:text-white text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500"
                >
                  <option value="general">General Inquiries & Feedback</option>
                  <option value="accessibility">Accessibility Barrier or Suggestion</option>
                  <option value="bug">Bug Report / Technical Support</option>
                  <option value="privacy">Data Privacy & Account Deletion Request</option>
                  <option value="research">Academic or Clinical Research Inquiry</option>
                </select>
              </div>

              {/* Message */}
              <div className="space-y-2">
                <label htmlFor="contact-message" className="block text-sm font-semibold text-slate-800 dark:text-slate-200">
                  Message <span className="text-rose-500">*</span>
                </label>
                <textarea
                  id="contact-message"
                  required
                  rows={5}
                  value={formState.message}
                  onChange={(e) => setFormState({ ...formState, message: e.target.value })}
                  aria-invalid={!!errors.message}
                  aria-describedby={errors.message ? "message-error" : undefined}
                  placeholder="How can we assist you with NEUROPLAY?"
                  className="w-full px-4 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-slate-50 dark:bg-slate-950 text-slate-900 dark:text-white text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500"
                />
                {errors.message && (
                  <p id="message-error" className="text-xs text-rose-500">
                    {errors.message}
                  </p>
                )}
              </div>

              <button
                type="submit"
                disabled={isSubmitting}
                className="inline-flex items-center justify-center gap-2 px-7 py-3 rounded-xl bg-emerald-600 hover:bg-emerald-500 active:bg-emerald-700 text-white font-semibold text-sm shadow-sm transition-all disabled:opacity-50"
              >
                {isSubmitting ? (
                  <span>Sending message...</span>
                ) : (
                  <>
                    <span>Submit Inquiry</span>
                    <ArrowRightIcon className="w-4 h-4" />
                  </>
                )}
              </button>
            </form>
          )}
        </div>

        {/* Channels Sidebar */}
        <div className="space-y-8">
          <div className="p-6 rounded-2xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 shadow-xs space-y-4">
            <h2 className="text-base font-bold text-slate-900 dark:text-white">
              Direct Inquiries
            </h2>
            <div className="space-y-3 text-sm">
              <div>
                <p className="text-xs font-semibold uppercase tracking-wider text-slate-400">Support Email</p>
                <a href={`mailto:${SITE_CONFIG.links.supportEmail}`} className="text-emerald-600 dark:text-emerald-400 hover:underline">
                  {SITE_CONFIG.links.supportEmail}
                </a>
              </div>
              <div>
                <p className="text-xs font-semibold uppercase tracking-wider text-slate-400">Privacy & Data Requests</p>
                <a href={`mailto:${SITE_CONFIG.links.privacyEmail}`} className="text-emerald-600 dark:text-emerald-400 hover:underline">
                  {SITE_CONFIG.links.privacyEmail}
                </a>
              </div>
            </div>
          </div>

          <div className="p-6 rounded-2xl bg-slate-100 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 space-y-3">
            <h2 className="text-base font-bold text-slate-900 dark:text-white">
              Self-Service Privacy Actions
            </h2>
            <p className="text-xs text-slate-600 dark:text-slate-400 leading-relaxed">
              You do not need to contact support to export your data or delete your account. You can trigger schema 1.0.0 JSON exports and immediate account removal directly from the Profile screen in the NEUROPLAY application.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
