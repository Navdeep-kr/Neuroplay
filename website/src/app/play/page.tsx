"use client";

import { useEffect } from "react";

export default function PlayPage() {
  useEffect(() => {
    window.location.replace("/app/index.html" + window.location.hash);
  }, []);

  return (
    <div className="min-h-screen flex items-center justify-center bg-white text-slate-800">
      <div className="text-center space-y-4">
        <div className="w-10 h-10 border-4 border-blue-600 border-t-transparent rounded-full animate-spin mx-auto" />
        <p className="text-sm font-semibold text-slate-600">Launching NEUROPLAY...</p>
      </div>
    </div>
  );
}
