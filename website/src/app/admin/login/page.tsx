"use client";

import React, { useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { ShieldCheckIcon, ArrowRightIcon } from "@/components/Icons";

export default function AdminLoginPage() {
  const [passkey, setPasskey] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const router = useRouter();

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!passkey) {
      setError("Please enter the admin passkey.");
      return;
    }

    setIsLoading(true);
    setError(null);

    try {
      const res = await fetch("/api/admin/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ passkey }),
      });

      const data = await res.json();
      if (!res.ok) {
        setError(data.error || "Authentication failed.");
      } else {
        router.push("/admin");
        router.refresh();
      }
    } catch {
      setError("Network or server connection error.");
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-[70vh] flex items-center justify-center px-4 sm:px-6 lg:px-8 py-16">
      <div className="max-w-md w-full p-8 rounded-3xl bg-white border border-slate-200 shadow-sm space-y-6">
        <div className="text-center space-y-2">
          <div className="w-12 h-12 rounded-xl bg-slate-100 text-slate-700 flex items-center justify-center mx-auto">
            <ShieldCheckIcon className="w-6 h-6 text-emerald-600" />
          </div>
          <h1 className="text-2xl font-extrabold text-slate-900 tracking-tight">
            NEUROPLAY Admin Console
          </h1>
          <p className="text-xs text-slate-500">
            Protected internal console for game configurations, feature flags, and audit telemetry.
          </p>
        </div>

        {error && (
          <div className="p-3.5 rounded-xl bg-rose-50 border border-rose-200 text-xs text-rose-600 font-medium">
            {error}
          </div>
        )}

        <form onSubmit={handleLogin} className="space-y-4">
          <div className="space-y-1.5">
            <label htmlFor="admin-passkey" className="block text-xs font-semibold uppercase tracking-wider text-slate-700">
              Admin Passkey
            </label>
            <input
              id="admin-passkey"
              type="password"
              required
              value={passkey}
              onChange={(e) => setPasskey(e.target.value)}
              placeholder="Enter secure admin passkey"
              className="w-full px-4 py-2.5 rounded-xl border border-slate-300 bg-slate-50 text-slate-900 text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500"
            />
          </div>

          <button
            type="submit"
            disabled={isLoading}
            className="w-full inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white font-semibold text-sm transition-colors shadow-xs disabled:opacity-50"
          >
            {isLoading ? <span>Authenticating...</span> : (
              <>
                <span>Authenticate Session</span>
                <ArrowRightIcon className="w-4 h-4" />
              </>
            )}
          </button>
        </form>

        <div className="text-center pt-2 border-t border-slate-100">
          <Link href="/" className="text-xs text-slate-400 hover:text-slate-600">
            ← Return to public website
          </Link>
        </div>
      </div>
    </div>
  );
}
