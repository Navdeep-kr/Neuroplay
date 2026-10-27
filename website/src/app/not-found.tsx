import React from "react";
import Link from "next/link";
import { ArrowRightIcon } from "@/components/Icons";

export default function NotFound() {
  return (
    <div className="min-h-[70vh] flex items-center justify-center px-4 sm:px-6 lg:px-8 py-16">
      <div className="max-w-md w-full text-center space-y-6">
        <div className="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-emerald-50 text-emerald-600 font-bold text-2xl border border-emerald-200">
          404
        </div>
        <div className="space-y-2">
          <h1 className="text-3xl font-extrabold text-slate-900 tracking-tight">
            Page Not Found
          </h1>
          <p className="text-slate-600 text-sm leading-relaxed">
            The page you are looking for doesn&apos;t exist or has been moved. Explore our cognitive library or return to the dashboard.
          </p>
        </div>
        <div className="pt-4 flex flex-col sm:flex-row items-center justify-center gap-3">
          <Link
            href="/"
            className="w-full sm:w-auto inline-flex items-center justify-center gap-2 px-6 py-2.5 rounded-xl bg-emerald-600 text-white font-semibold text-sm hover:bg-emerald-500 shadow-sm transition-colors"
          >
            <span>Return Home</span>
            <ArrowRightIcon className="w-4 h-4" />
          </Link>
          <Link
            href="/games"
            className="w-full sm:w-auto inline-flex items-center justify-center px-6 py-2.5 rounded-xl border border-slate-300 bg-white text-slate-700 font-semibold text-sm hover:bg-slate-50 transition-colors"
          >
            Browse Games
          </Link>
        </div>
      </div>
    </div>
  );
}
