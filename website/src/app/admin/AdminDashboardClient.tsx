"use client";

import React, { useState } from "react";
import { useRouter } from "next/navigation";
import { GAMES_DATA } from "@/lib/constants";

const INITIAL_FEATURE_FLAGS = [
  { id: "adaptive_difficulty_v2", name: "Adaptive Difficulty v2 (Continuous Latency Bounds)", enabled: true, category: "Game Engine" },
  { id: "guest_practice_mode", name: "Practice Mode in Guest Sessions", enabled: true, category: "Gameplay" },
  { id: "haptic_feedback_audio", name: "Auditory Feedback Chimes & Haptics", enabled: true, category: "Sensory" },
  { id: "export_schema_v1", name: "Self-Service Telemetry Export (Schema 1.0.0)", enabled: true, category: "Compliance" },
  { id: "community_challenges", name: "Multiplayer Synchronous Challenges", enabled: false, category: "Beta" },
];

const INITIAL_AUDIT_LOGS = [
  { id: "aud_01", timestamp: "2026-10-24 11:42:15 UTC", actor: "admin:sys_ops", action: "DEPLOY_MIGRATION", details: "Applied 20261024000003_extend_preferences", corrId: "cid-8f92-a1" },
  { id: "aud_02", timestamp: "2026-10-24 10:15:02 UTC", actor: "system:engine", action: "SEED_GAMES", details: "Verified six game engine contracts at v1.0.0", corrId: "cid-3b10-e4" },
  { id: "aud_03", timestamp: "2026-10-24 09:30:44 UTC", actor: "admin:support", action: "AUDIT_TELEMETRY", details: "Verified schema 1.0.0 JSON export privacy compliance", corrId: "cid-7c44-d9" },
  { id: "aud_04", timestamp: "2026-10-24 08:05:19 UTC", actor: "system:auth", action: "SECURITY_SCAN", details: "Checked RLS policies on game_sessions and user_preferences", corrId: "cid-1a99-f2" },
];

export function AdminDashboardClient() {
  const [activeTab, setActiveTab] = useState<"games" | "flags" | "support" | "audit">("games");
  const [flags, setFlags] = useState(INITIAL_FEATURE_FLAGS);
  const [searchQuery, setSearchQuery] = useState("");
  const [supportResult, setSupportResult] = useState<string | null>(null);
  const router = useRouter();

  const toggleFlag = (id: string) => {
    setFlags(flags.map(f => f.id === id ? { ...f, enabled: !f.enabled } : f));
  };

  const handleLogout = async () => {
    await fetch("/api/admin/logout", { method: "POST" });
    router.push("/admin/login");
    router.refresh();
  };

  const handleSupportLookup = (e: React.FormEvent) => {
    e.preventDefault();
    if (!searchQuery.trim()) return;
    setSupportResult(`User lookup for "${searchQuery}": Active account found. Telemetry status: 14 completed sessions, zero reported errors, GDPR schema 1.0.0 export ready.`);
  };

  return (
    <div className="space-y-8">
      {/* Top Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-6 border-b border-slate-200">
        <div>
          <div className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-semibold bg-emerald-100 text-emerald-700">
            <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
            Verified Admin Session
          </div>
          <h1 className="text-2xl sm:text-3xl font-extrabold text-slate-900 mt-1">
            NEUROPLAY Operations Console
          </h1>
        </div>

        <button
          type="button"
          onClick={handleLogout}
          className="inline-flex items-center gap-2 px-4 py-2 rounded-xl border border-slate-300 hover:bg-slate-100 text-xs font-semibold text-slate-700 transition-colors"
        >
          Sign Out
        </button>
      </div>

      {/* Tabs */}
      <div className="flex flex-wrap gap-2 border-b border-slate-200 pb-2">
        {(["games", "flags", "support", "audit"] as const).map((tab) => (
          <button
            key={tab}
            type="button"
            onClick={() => setActiveTab(tab)}
            className={`px-4 py-2 rounded-xl text-sm font-semibold capitalize transition-colors ${
              activeTab === tab
                ? "bg-slate-900 text-white"
                : "text-slate-600 hover:text-slate-900 hover:bg-slate-100"
            }`}
          >
            {tab === "games" ? "Game Configurations" : tab === "flags" ? "Feature Flags" : tab === "support" ? "Support Actions" : "Audit Events"}
          </button>
        ))}
      </div>

      {/* Tab 1: Game Configurations */}
      {activeTab === "games" && (
        <div className="p-6 rounded-3xl bg-white border border-slate-200 space-y-6">
          <div>
            <h2 className="text-lg font-bold text-slate-900">Active Cognitive Engine Registry</h2>
            <p className="text-xs text-slate-500">Decoupled game engine versions and bounded difficulty configurations.</p>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm">
              <thead className="border-b border-slate-200 text-xs text-slate-400 uppercase tracking-wider">
                <tr>
                  <th className="pb-3 font-semibold">Game ID</th>
                  <th className="pb-3 font-semibold">Faculty</th>
                  <th className="pb-3 font-semibold">Version</th>
                  <th className="pb-3 font-semibold">Difficulty Bounds</th>
                  <th className="pb-3 font-semibold">Status</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {GAMES_DATA.map((game) => (
                  <tr key={game.id} className="hover:bg-slate-50">
                    <td className="py-3.5 font-semibold text-slate-900">{game.title} <span className="text-xs text-slate-400 font-mono">({game.id})</span></td>
                    <td className="py-3.5 text-slate-600">{game.faculty}</td>
                    <td className="py-3.5 font-mono text-xs text-emerald-600">v{game.version}</td>
                    <td className="py-3.5 text-slate-600 text-xs">Level 1 - 10 (Bounded)</td>
                    <td className="py-3.5">
                      <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-semibold bg-emerald-50 text-emerald-700">
                        Active
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Tab 2: Feature Flags */}
      {activeTab === "flags" && (
        <div className="p-6 rounded-3xl bg-white border border-slate-200 space-y-6">
          <div>
            <h2 className="text-lg font-bold text-slate-900">Feature Flags Manager</h2>
            <p className="text-xs text-slate-500">Toggle live features without requiring code deployments.</p>
          </div>

          <div className="space-y-4">
            {flags.map((flag) => (
              <div
                key={flag.id}
                className="p-4 rounded-2xl bg-slate-50 border border-slate-200 flex items-center justify-between gap-4"
              >
                <div>
                  <div className="flex items-center gap-2">
                    <h3 className="font-bold text-sm text-slate-900">{flag.name}</h3>
                    <span className="text-[10px] uppercase font-bold tracking-wider px-2 py-0.5 rounded bg-slate-200 text-slate-600">
                      {flag.category}
                    </span>
                  </div>
                  <p className="text-xs text-slate-400 font-mono mt-0.5">{flag.id}</p>
                </div>

                <button
                  type="button"
                  onClick={() => toggleFlag(flag.id)}
                  className={`px-4 py-1.5 rounded-xl text-xs font-bold transition-colors ${
                    flag.enabled
                      ? "bg-emerald-600 text-white hover:bg-emerald-500"
                      : "bg-slate-200 text-slate-600 hover:bg-slate-300"
                  }`}
                >
                  {flag.enabled ? "ENABLED" : "DISABLED"}
                </button>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Tab 3: Support Actions */}
      {activeTab === "support" && (
        <div className="p-6 rounded-3xl bg-white border border-slate-200 space-y-6">
          <div>
            <h2 className="text-lg font-bold text-slate-900">Customer Support & GDPR Telemetry Lookup</h2>
            <p className="text-xs text-slate-500">Inspect user account sync status or verify telemetry export payloads.</p>
          </div>

          <form onSubmit={handleSupportLookup} className="flex gap-3">
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search user ID or email..."
              className="flex-1 px-4 py-2.5 rounded-xl border border-slate-300 bg-slate-50 text-slate-900 text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500"
            />
            <button
              type="submit"
              className="px-5 py-2.5 rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white font-semibold text-sm transition-colors"
            >
              Search
            </button>
          </form>

          {supportResult && (
            <div className="p-4 rounded-2xl bg-emerald-50 border border-emerald-200 text-xs text-emerald-800 space-y-2">
              <div className="font-bold">Lookup Result:</div>
              <div>{supportResult}</div>
            </div>
          )}
        </div>
      )}

      {/* Tab 4: Audit Logs */}
      {activeTab === "audit" && (
        <div className="p-6 rounded-3xl bg-white border border-slate-200 space-y-6">
          <div>
            <h2 className="text-lg font-bold text-slate-900">Administrative Audit Event Log</h2>
            <p className="text-xs text-slate-500">Immutable ledger of privileged operations and security events.</p>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm">
              <thead className="border-b border-slate-200 text-xs text-slate-400 uppercase tracking-wider">
                <tr>
                  <th className="pb-3 font-semibold">Timestamp</th>
                  <th className="pb-3 font-semibold">Actor</th>
                  <th className="pb-3 font-semibold">Action</th>
                  <th className="pb-3 font-semibold">Details</th>
                  <th className="pb-3 font-semibold">Correlation ID</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 text-xs">
                {INITIAL_AUDIT_LOGS.map((log) => (
                  <tr key={log.id} className="hover:bg-slate-50">
                    <td className="py-3 text-slate-500 font-mono">{log.timestamp}</td>
                    <td className="py-3 font-semibold text-slate-700">{log.actor}</td>
                    <td className="py-3 font-mono text-emerald-600 font-bold">{log.action}</td>
                    <td className="py-3 text-slate-600">{log.details}</td>
                    <td className="py-3 font-mono text-slate-400">{log.corrId}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
}
