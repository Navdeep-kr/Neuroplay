"use client";

import React, { Suspense, useState, useRef } from "react";
import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { GAMES_DATA } from "@/lib/constants";
import { ArrowLeftIcon } from "@/components/Icons";

function PlayGameContent() {
  const searchParams = useSearchParams();
  const gameId = searchParams.get("game");
  const [isFullscreen, setIsFullscreen] = useState(false);
  const [key, setKey] = useState(0);
  const iframeRef = useRef<HTMLIFrameElement>(null);

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

  const reloadGame = () => {
    setKey((prev) => prev + 1);
  };

  return (
    <div className="flex flex-col h-[100dvh] w-screen bg-slate-950 text-white overflow-hidden select-none">
      {/* Responsive Player Navigation Header */}
      <header className="h-13 sm:h-14 bg-slate-900/95 backdrop-blur-sm border-b border-slate-800 px-3 sm:px-6 flex items-center justify-between shrink-0 z-50 pt-[env(safe-area-inset-top)]">
        <div className="flex items-center gap-2 sm:gap-3 min-w-0">
          <Link
            href="/games"
            className="inline-flex items-center gap-1.5 px-2.5 sm:px-3 py-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 active:bg-slate-600 text-slate-300 hover:text-white text-xs font-semibold transition-colors border border-slate-700 shrink-0"
            title="Return to Game Library"
          >
            <ArrowLeftIcon className="w-3.5 h-3.5" />
            <span className="hidden sm:inline">Library</span>
            <span className="sm:hidden text-[11px]">Back</span>
          </Link>

          <Link href="/" className="flex items-center gap-1.5 sm:gap-2 pl-1 sm:pl-2 shrink-0">
            <span className="w-2 h-2 rounded-full bg-blue-500 animate-pulse" />
            <span className="font-extrabold tracking-tight text-white text-xs sm:text-sm">NEUROPLAY</span>
          </Link>

          {activeGame && (
            <div className="flex items-center gap-2 pl-2 sm:pl-3 border-l border-slate-800 min-w-0">
              <span className="text-xs font-bold text-slate-200 truncate max-w-[120px] sm:max-w-[200px] md:max-w-xs">
                {activeGame.title}
              </span>
              <span className="hidden sm:inline-block px-2 py-0.5 rounded text-[10px] font-bold bg-blue-900/60 text-blue-400 border border-blue-800 shrink-0">
                {activeGame.faculty}
              </span>
            </div>
          )}
        </div>

        <div className="flex items-center gap-1.5 sm:gap-2 shrink-0">
          {/* Restart Workout */}
          <button
            onClick={reloadGame}
            className="p-1.5 sm:px-2.5 sm:py-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-300 hover:text-white text-xs font-semibold transition-colors border border-slate-700"
            title="Restart Exercise"
          >
            <svg className="w-3.5 h-3.5 sm:hidden" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
            </svg>
            <span className="hidden sm:inline">Restart</span>
          </button>

          {/* Fullscreen */}
          <button
            onClick={toggleFullscreen}
            className="p-1.5 sm:px-3 sm:py-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-300 hover:text-white text-xs font-semibold transition-colors border border-slate-700"
            title="Toggle Fullscreen"
          >
            <svg className="w-3.5 h-3.5 sm:hidden" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              {isFullscreen ? (
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              ) : (
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 8V4m0 0h4M4 4l5 5m11-1V4m0 0h-4m4 0l-5 5M4 16v4m0 0h4m-4 0l5-5m11 5l-5-5m5 5v-4m0 4h-4" />
              )}
            </svg>
            <span className="hidden sm:inline">{isFullscreen ? "Exit Fullscreen" : "Fullscreen"}</span>
          </button>

          {/* Open standalone */}
          <a
            href={iframeSrc}
            target="_blank"
            rel="noopener noreferrer"
            className="hidden md:inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-blue-600 hover:bg-blue-500 text-white text-xs font-semibold transition-colors"
          >
            <span>Direct Tab</span>
          </a>
        </div>
      </header>

      {/* Embedded Game Canvas Iframe */}
      <main className="flex-1 w-full relative bg-white overflow-hidden pb-[env(safe-area-inset-bottom)] pl-[env(safe-area-inset-left)] pr-[env(safe-area-inset-right)]">
        <iframe
          ref={iframeRef}
          key={key}
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
