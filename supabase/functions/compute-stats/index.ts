// ============================================================
// NEUROPLAY — Supabase Edge Function: compute-stats
// ============================================================
// Aggregates user cognitive performance, computes domain scores,
// streaks, and weekly score trends server-side.
//
// Security Constraints:
// - Validates JWT of the requesting user.
// - Returns only the authenticated user's aggregated data.
// ============================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, GET, OPTIONS",
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");

    if (!supabaseUrl || !supabaseAnonKey) {
      return new Response(
        JSON.stringify({ error: "Server configuration missing required environment keys." }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing Authorization header." }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Client scoped to user token
    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: "Invalid or expired session token." }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 1. Fetch Streak
    const { data: streakData } = await supabase
      .from("user_streaks")
      .select("*")
      .eq("user_id", user.id)
      .maybeSingle();

    // 2. Fetch Cognitive Domain Indices
    const { data: domainData } = await supabase
      .from("cognitive_indices")
      .select("*")
      .eq("user_id", user.id);

    // 3. Fetch past 7 days of non-practice game sessions
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

    const { data: recentSessions } = await supabase
      .from("game_sessions")
      .select("score, accuracy, duration_seconds, game_id, created_at, is_practice")
      .eq("user_id", user.id)
      .gte("created_at", sevenDaysAgo.toISOString())
      .order("created_at", { ascending: true });

    // 4. Build weekly trend (past 7 days)
    const dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
    const weeklyTrend = [];
    const today = new Date();

    for (let i = 6; i >= 0; i--) {
      const d = new Date(today);
      d.setDate(d.getDate() - i);
      const dateStr = d.toISOString().split("T")[0];
      const dayLabel = dayNames[d.getDay()];

      // Sessions on this calendar day
      const daySessions = (recentSessions || []).filter(s =>
        s.created_at.startsWith(dateStr) && !s.is_practice
      );

      let dayScore = 0;
      const isCompleted = daySessions.length > 0;
      if (isCompleted) {
        const avgScore = daySessions.reduce((acc, curr) => acc + curr.score, 0) / daySessions.length;
        // Normalize to 0-100 scale for trend
        dayScore = Math.min(100, Math.round(avgScore / 20));
      } else {
        dayScore = 0;
      }

      weeklyTrend.push({
        day_label: dayLabel,
        date: dateStr,
        score_index: dayScore,
        is_completed_day: isCompleted,
      });
    }

    // 5. Build domain scores response with defaults
    const domainKeys = ["memory", "attention", "speed", "flexibility", "problemSolving"];
    const domainScores = domainKeys.map(k => {
      const existing = (domainData || []).find(d => d.domain === k);
      return {
        domain: k,
        score_index: existing ? existing.score_index : 50,
        percentile_rank: existing ? existing.percentile_rank : 50,
        trend_percentage: existing ? existing.trend_percentage : 0,
        sample_count: existing ? existing.sample_count : 0,
      };
    });

    const activeIndices = domainScores.filter(d => d.sample_count > 0);
    const overallBrainIndex = activeIndices.length > 0
      ? Math.round(activeIndices.reduce((acc, d) => acc + d.score_index, 0) / activeIndices.length)
      : 50;

    const responsePayload = {
      user_id: user.id,
      overall_brain_index: overallBrainIndex,
      current_streak: streakData ? streakData.current_streak : 0,
      longest_streak: streakData ? streakData.longest_streak : 0,
      total_sessions_completed: streakData ? streakData.total_sessions_completed : 0,
      total_workouts_completed: streakData ? streakData.total_workouts_completed : 0,
      domain_scores: domainScores,
      weekly_trend: weeklyTrend,
    };

    return new Response(JSON.stringify(responsePayload), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : "Internal server error";
    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
