// Supabase Edge Function: push-notification
// Triggered by a Database Webhook on INSERT to unlock_requests table.
// Sends APNs push notifications to all pact members (except the requester).

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import * as jose from "https://deno.land/x/jose@v4.14.4/index.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

// APNs configuration — set these in Supabase Edge Function secrets
const APNS_KEY_ID = Deno.env.get("APNS_KEY_ID")!;
const APNS_TEAM_ID = Deno.env.get("APNS_TEAM_ID")!;
const APNS_BUNDLE_ID = Deno.env.get("APNS_BUNDLE_ID") || "com.lukashellesch.lockin";
const APNS_KEY_P8 = Deno.env.get("APNS_KEY_P8")!;
const APNS_ENV = Deno.env.get("APNS_ENV") || "development";

const APNS_HOST = APNS_ENV === "production"
  ? "https://api.push.apple.com"
  : "https://api.sandbox.push.apple.com";

// ── Webhook verification ─────────────────────────────
function verifyWebhookAuth(req: Request): boolean {
  const authHeader = req.headers.get("authorization");
  if (!authHeader) return false;
  const token = authHeader.replace(/^Bearer\s+/i, "");
  return token === SUPABASE_SERVICE_KEY;
}

// ── Input sanitization ───────────────────────────────
function sanitize(input: unknown, maxLength: number): string {
  if (typeof input !== "string") return "";
  return input.slice(0, maxLength).replace(/[\x00-\x1F]/g, "");
}

function isValidUUID(input: unknown): boolean {
  if (typeof input !== "string") return false;
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(input);
}

// ── Generate APNs JWT ────────────────────────────────
async function generateAPNsToken(): Promise<string> {
  const privateKey = await jose.importPKCS8(APNS_KEY_P8, "ES256");

  return new jose.SignJWT({})
    .setProtectedHeader({ alg: "ES256", kid: APNS_KEY_ID })
    .setIssuer(APNS_TEAM_ID)
    .setIssuedAt()
    .setExpirationTime("1h")
    .sign(privateKey);
}

// ── Send a single APNs push (with timeout) ───────────
async function sendPush(
  token: string,
  apnsJwt: string,
  payload: Record<string, unknown>
): Promise<boolean> {
  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 5000);

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
      signal: controller.signal,
    });

    clearTimeout(timeout);

    if (!res.ok) {
      console.error(`APNs error: status ${res.status}`);
      return false;
    }
    return true;
  } catch (err) {
    if ((err as Error).name === "AbortError") {
      console.error("APNs request timed out");
    } else {
      console.error("APNs fetch error");
    }
    return false;
  }
}

// ── Main handler ─────────────────────────────────────
serve(async (req: Request) => {
  try {
    // Verify webhook authenticity
    if (!verifyWebhookAuth(req)) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }

    const body = await req.json();
    const { type, record } = body;

    if (type !== "INSERT" || !record) {
      return new Response(JSON.stringify({ ok: true, skipped: true }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }

    // Validate required fields
    const { requester_id, pact_id, app_identifier, reason } = record;

    if (!isValidUUID(requester_id) || !isValidUUID(pact_id)) {
      return new Response(JSON.stringify({ error: "Invalid payload" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    // Sanitize user-supplied content
    const safeAppId = sanitize(app_identifier, 100);
    const safeReason = sanitize(reason, 500);

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

    // 1. Verify requester is actually a member of this pact
    const { data: membership } = await supabase
      .from("pact_members")
      .select("id")
      .eq("pact_id", pact_id)
      .eq("user_id", requester_id)
      .maybeSingle();

    if (!membership) {
      return new Response(JSON.stringify({ error: "Requester not in pact" }), {
        status: 403,
        headers: { "Content-Type": "application/json" },
      });
    }

    // 2. Get requester's display name
    const { data: requester } = await supabase
      .from("profiles")
      .select("display_name, avatar_emoji")
      .eq("id", requester_id)
      .single();

    const requesterName = sanitize(requester?.display_name, 100) || "Someone";
    const requesterEmoji = sanitize(requester?.avatar_emoji, 4) || "🔥";

    // 3. Get all pact members (except requester)
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

    // 4. Get push tokens for those members
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

    // 5. Build push payload (sanitized content)
    const alertBody = safeReason
      ? `${requesterEmoji} ${requesterName} wants to unlock ${safeAppId}`
      : `${requesterEmoji} ${requesterName} is requesting to unlock an app`;

    const pushPayload = {
      aps: {
        alert: {
          title: "Unlock Request",
          body: alertBody.slice(0, 256),
        },
        sound: "default",
        badge: 1,
        "mutable-content": 1,
      },
      type: "unlock_request",
      pact_id: pact_id,
      requester_id: requester_id,
      app_identifier: safeAppId,
    };

    // 6. Generate APNs JWT and send to all members
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

    return new Response(
      JSON.stringify({ ok: true, sent, total: profiles.length }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (err) {
    console.error("Edge function error:", (err as Error).message);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
