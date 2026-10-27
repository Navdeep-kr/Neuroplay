"use client";

import React, { Suspense, useState } from "react";
import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { GAMES_DATA } from "@/lib/constants";
import { ArrowLeftIcon } from "@/components/Icons";

function PlayGameContent() {
  const searchParams = useSearchParams();
  const gameId = searchParams.get("game");
  const [isFullscreen, setIsFullscreen] = useState(false);

  // Derived values directly from query parameter
  const activeGame = gameId ? GAMES_DATA.find((g) => g.id === gameId) ?? null : null;
  const iframeSrc = gameId ? `/app/index.html#/games/${gameId}` : "/app/index.html#/home";

  const toggleFullscreen = () => {
    if (!document.fullscreenElement) {
      document.documentElement.requestFullscreen().then(() => setIsFullscreen(true)).catch(() => {});
    } else {
      document.exitFullscreen().then(() => setIsFullscreen(false)).catch(() => {});
    }
  };

  return (
    <div className="flex flex-col h-[100dvh] w-screen bg-slate-950 text-white overflow-hidden select-none">
      {/* Player Navigation Header */}
      <header className="h-14 bg-slate-900 border-b border-slate-800 px-4 sm:px-6 flex items-center justify-between shrink-0 z-50">
        <div className="flex items-center gap-3">
          <Link
            href="/games"
            className="inline-flex items-center gap-2 px-3 py-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-300 hover:text-white text-xs font-semibold transition-colors border border-slate-700"
          >
            <ArrowLeftIcon className="w-3.5 h-3.5" />
            <span className="hidden sm:inline">Game Library</span>
            <span className="sm:hidden">Back</span>
          </Link>

          <Link href="/" className="flex items-center gap-2 pl-2">
            <span className="w-2 h-2 rounded-full bg-blue-500 animate-pulse" />
            <span className="font-extrabold tracking-tight text-white text-sm">NEUROPLAY</span>
          </Link>

          {activeGame && (
            <div className="hidden md:flex items-center gap-2 pl-3 border-l border-slate-800">
              <span className="text-xs font-bold text-slate-200">{activeGame.title}</span>
              <span className="px-2 py-0.5 rounded text-[10px] font-bold bg-blue-900/60 text-blue-400 border border-blue-800">
                {activeGame.faculty}
              </span>
            </div>
          )}
        </div>

        <div className="flex items-center gap-2">
          {activeGame && (
            <div className="flex sm:hidden items-center gap-1.5 text-xs font-bold text-slate-300">
              <span>{activeGame.title}</span>
            </div>
          )}

          <button
            onClick={toggleFullscreen}
            className="px-3 py-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-300 hover:text-white text-xs font-semibold transition-colors border border-slate-700"
            title="Toggle Fullscreen"
          >
            {isFullscreen ? "Exit Fullscreen" : "Fullscreen"}
          </button>

          <a
            href={iframeSrc}
            target="_blank"
            rel="noopener noreferrer"
            className="hidden sm:inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-blue-600 hover:bg-blue-500 text-white text-xs font-semibold transition-colors"
          >
            <span>Open in Tab</span>
          </a>
        </div>
      </header>

      {/* Embedded Game Canvas Iframe */}
      <main className="flex-1 w-full relative bg-white">
        <iframe
          key={iframeSrc}
          src={iframeSrc}
          title="NEUROPLAY Cognitive Workout"
          className="w-full h-full border-0 absolute inset-0 bg-white"
          allow="autoplay; fullscreen"
        />
      </main>
    </div>
  );
}

export default function PlayPage() {
  return (
    <Suspense
      fallback={
        <div className="h-screen w-screen flex items-center justify-center bg-white text-slate-800">
          <div className="text-center space-y-4">
            <div className="w-10 h-10 border-4 border-blue-600 border-t-transparent rounded-full animate-spin mx-auto" />
            <p className="text-sm font-semibold text-slate-600">Launching NEUROPLAY...</p>
          </div>
        </div>
      }
    >
      <PlayGameContent />
    </Suspense>
  );
}
