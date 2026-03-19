// Supabase Edge Function: push-notification
// Triggered by a Database Webhook on INSERT to unlock_requests table.
// Sends APNs push notifications to all pact members (except the requester).

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import * as jose from "https://deno.land/x/jose@v4.14.4/index.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

// APNs configuration — set these in Supabase Edge Function secrets
const APNS_KEY_ID = Deno.env.get("APNS_KEY_ID")!;         // Your Apple Key ID
const APNS_TEAM_ID = Deno.env.get("APNS_TEAM_ID")!;       // Your Apple Team ID
const APNS_BUNDLE_ID = Deno.env.get("APNS_BUNDLE_ID") || "com.lockin.app";
const APNS_KEY_P8 = Deno.env.get("APNS_KEY_P8")!;         // .p8 private key contents
const APNS_ENV = Deno.env.get("APNS_ENV") || "development"; // "production" for App Store

const APNS_HOST = APNS_ENV === "production"
  ? "https://api.push.apple.com"
  : "https://api.sandbox.push.apple.com";

// ── Generate APNs JWT ──────────────────────────────────
async function generateAPNsToken(): Promise<string> {
  const privateKey = await jose.importPKCS8(APNS_KEY_P8, "ES256");

  const jwt = await new jose.SignJWT({})
    .setProtectedHeader({ alg: "ES256", kid: APNS_KEY_ID })
    .setIssuer(APNS_TEAM_ID)
    .setIssuedAt()
    .setExpirationTime("1h")
    .sign(privateKey);

  return jwt;
}

// ── Send a single APNs push ───────────────────────────
async function sendPush(
  token: string,
  apnsJwt: string,
  payload: Record<string, unknown>
): Promise<boolean> {
  try {
    const res = await fetch(`${APNS_HOST}/3/device/${token}`, {
      method: "POST",
      headers: {
        authorization: `bearer ${apnsJwt}`,
        "apns-topic": APNS_BUNDLE_ID,
        "apns-push-type": "alert",
        "apns-priority": "10",
        "content-type": "application/json",
      },
      body: JSON.stringify(payload),
    });

    if (!res.ok) {
      const errorBody = await res.text();
      console.error(`APNs error (${res.status}): ${errorBody}`);
      return false;
    }
    return true;
  } catch (err) {
    console.error("APNs fetch error:", err);
    return false;
  }
}

// ── Main handler ──────────────────────────────────────
serve(async (req: Request) => {
  try {
    const body = await req.json();

    // Database webhook sends: { type: "INSERT", table: "unlock_requests", record: {...} }
    const { type, record } = body;

    if (type !== "INSERT" || !record) {
      return new Response(JSON.stringify({ ok: true, skipped: true }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }

    const { requester_id, pact_id, app_identifier, reason } = record;

    // Create admin Supabase client (bypasses RLS)
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

    // 1. Get requester's display name
    const { data: requester } = await supabase
      .from("profiles")
      .select("display_name, avatar_emoji")
      .eq("id", requester_id)
      .single();

    const requesterName = requester?.display_name || "Someone";
    const requesterEmoji = requester?.avatar_emoji || "🔥";

    // 2. Get all pact members (except requester)
    const { data: members } = await supabase
      .from("pact_members")
      .select("user_id")
      .eq("pact_id", pact_id)
      .neq("user_id", requester_id);

    if (!members || members.length === 0) {
      return new Response(JSON.stringify({ ok: true, no_members: true }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }

    // 3. Get push tokens for those members
    const memberIds = members.map((m: { user_id: string }) => m.user_id);
    const { data: profiles } = await supabase
      .from("profiles")
      .select("id, push_token")
      .in("id", memberIds)
      .not("push_token", "is", null);

    if (!profiles || profiles.length === 0) {
      return new Response(JSON.stringify({ ok: true, no_tokens: true }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }

    // 4. Build push payload
    const alertBody = reason
      ? `${requesterEmoji} ${requesterName} wants to unlock an app: "${reason}"`
      : `${requesterEmoji} ${requesterName} is requesting to unlock an app`;

    const pushPayload = {
      aps: {
        alert: {
          title: "🔓 Unlock Request",
          body: alertBody,
        },
        sound: "default",
        badge: 1,
        "mutable-content": 1,
      },
      // Custom data for deep linking
      type: "unlock_request",
      pact_id: pact_id,
      requester_id: requester_id,
      app_identifier: app_identifier,
    };

    // 5. Generate APNs JWT and send to all members
    const apnsJwt = await generateAPNsToken();
    const results = await Promise.allSettled(
      profiles
        .filter((p: { push_token: string | null }) => p.push_token)
        .map((p: { push_token: string }) =>
          sendPush(p.push_token, apnsJwt, pushPayload)
        )
    );

    const sent = results.filter(
      (r) => r.status === "fulfilled" && r.value === true
    ).length;

    console.log(`Sent ${sent}/${profiles.length} push notifications for unlock request`);

    return new Response(
      JSON.stringify({ ok: true, sent, total: profiles.length }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (err) {
    console.error("Edge function error:", err);
    return new Response(
      JSON.stringify({ error: (err as Error).message }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
