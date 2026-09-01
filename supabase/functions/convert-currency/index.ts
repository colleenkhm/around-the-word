// Forin: currency conversion — Edge Function
//
// Why this exists as an Edge Function at all (per the architecture doc):
// ExchangeRate-API needs a key, and any key shipped inside the Flutter
// binary is extractable. So the app calls THIS function, which holds the
// key server-side, and this function calls ExchangeRate-API.
//
// Rates are cached in the exchange_rate_cache table for CACHE_TTL_HOURS.
// ExchangeRate-API's free tier only updates once a day anyway, so caching
// for a few hours costs nothing in freshness and keeps us well under the
// free tier's monthly request cap even with real traffic.
//
// Setup (one-time):
//   1. Sign up free at https://www.exchangerate-api.com/ (free tier: all
//      world currencies, daily updates, no commercial-use restriction —
//      per the architecture doc's own note on this).
//   2. Set the key as a Supabase secret (NOT in this file):
//        supabase secrets set EXCHANGERATE_API_KEY=your_key_here
//   3. Deploy: supabase functions deploy convert-currency
//
// Call it like:
//   GET https://<project-ref>.functions.supabase.co/convert-currency?to=EUR
//   -> { "currencyCode": "EUR", "rateFromUsd": 0.92, "fetchedAt": "..." }
//
// (Base is always USD, matching ExchangeRate class in the architecture doc.)

import { createClient } from "npm:@supabase/supabase-js@2";

const CACHE_TTL_HOURS = 6;
const API_KEY = Deno.env.get("EXCHANGERATE_API_KEY");

// Edge Functions don't get CORS headers for free the way the main
// Supabase REST/PostgREST gateway does — without these, a browser client
// (e.g. `flutter run -d chrome`) blocks the request at the preflight and
// this function never even runs. Every response below must carry these.
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  // x-client-info: the Supabase client SDK stamps this on every request
  // (its own version string) — omitting it here is what actually broke
  // this on web (confirmed 2026-08-20): the preflight rejects the real
  // request before it's ever sent, whole browser call fails as CORS.
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Content-Type": "application/json",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );

  const url = new URL(req.url);
  const currencyCode = url.searchParams.get("to")?.toUpperCase();

  if (!currencyCode) {
    return new Response(
      JSON.stringify({ error: "Missing required query param: to (e.g. ?to=EUR)" }),
      { status: 400, headers: corsHeaders }
    );
  }

  if (!API_KEY) {
    return new Response(
      JSON.stringify({ error: "EXCHANGERATE_API_KEY not configured — run `supabase secrets set EXCHANGERATE_API_KEY=...`" }),
      { status: 500, headers: corsHeaders }
    );
  }

  // 1. Check cache
  const { data: cached } = await supabase
    .from("exchange_rate_cache")
    .select("rate_from_usd, fetched_at")
    .eq("currency_code", currencyCode)
    .maybeSingle();

  if (cached) {
    const ageHours = (Date.now() - new Date(cached.fetched_at).getTime()) / (1000 * 60 * 60);
    if (ageHours < CACHE_TTL_HOURS) {
      return new Response(
        JSON.stringify({
          currencyCode,
          rateFromUsd: cached.rate_from_usd,
          fetchedAt: cached.fetched_at,
          source: "cache",
        }),
        { headers: corsHeaders }
      );
    }
  }

  // 2. Cache miss or stale — fetch fresh from ExchangeRate-API
  try {
    const res = await fetch(`https://v6.exchangerate-api.com/v6/${API_KEY}/latest/USD`);
    if (!res.ok) throw new Error(`ExchangeRate-API returned ${res.status}`);
    const data = await res.json();

    if (data.result !== "success") {
      throw new Error(data["error-type"] ?? "ExchangeRate-API error");
    }

    const rate = data.conversion_rates?.[currencyCode];
    if (rate == null) {
      return new Response(
        JSON.stringify({ error: `Unknown currency code: ${currencyCode}` }),
        { status: 400, headers: corsHeaders }
      );
    }

    const fetchedAt = new Date().toISOString();

    // Update cache for this currency (and opportunistically cache others
    // from the same response, since the API returns all currencies at once
    // for the same cost as one — no extra quota spent).
    const allRates = Object.entries(data.conversion_rates).map(([code, r]) => ({
      currency_code: code,
      rate_from_usd: r,
      fetched_at: fetchedAt,
    }));
    await supabase.from("exchange_rate_cache").upsert(allRates, { onConflict: "currency_code" });

    return new Response(
      JSON.stringify({ currencyCode, rateFromUsd: rate, fetchedAt, source: "live" }),
      { headers: corsHeaders }
    );
  } catch (err) {
    // If the live fetch fails but we have ANY cached value (even stale),
    // serve it rather than showing nothing — a slightly-stale rate is
    // better than a broken currency display.
    if (cached) {
      return new Response(
        JSON.stringify({
          currencyCode,
          rateFromUsd: cached.rate_from_usd,
          fetchedAt: cached.fetched_at,
          source: "stale_cache_fallback",
        }),
        { headers: corsHeaders }
      );
    }
    return new Response(
      JSON.stringify({ error: (err as Error).message }),
      { status: 502, headers: corsHeaders }
    );
  }
});