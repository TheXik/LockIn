// Supabase Edge Function: request-response
// Triggered by a Database Webhook on UPDATE to unlock_requests table.
// Sends APNs push to the requester when their request is approved or denied.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import * as jose from "https://deno.land/x/jose@v4.14.4/index.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

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
    const { type, record, old_record } = body;

    // Only process updates where status changed from 'pending'
    if (type !== "UPDATE" || !record || !old_record) {
      return new Response(JSON.stringify({ ok: true, skipped: true }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }

    if (old_record.status !== "pending" || record.status === "pending") {
      return new Response(JSON.stringify({ ok: true, no_change: true }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }

    const { requester_id, responder_id, status, app_identifier } = record;

    // Validate required fields
    if (!isValidUUID(requester_id) || !isValidUUID(responder_id)) {
      return new Response(JSON.stringify({ error: "Invalid payload" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    // Validate status is one of the expected values
    if (status !== "approved" && status !== "denied") {
      return new Response(JSON.stringify({ error: "Invalid status" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

    // Verify responder is a member of the pact
    if (record.pact_id && isValidUUID(record.pact_id)) {
      const { data: membership } = await supabase
        .from("pact_members")
        .select("id")
        .eq("pact_id", record.pact_id)
        .eq("user_id", responder_id)
        .maybeSingle();

      if (!membership) {
        return new Response(JSON.stringify({ error: "Responder not in pact" }), {
          status: 403,
          headers: { "Content-Type": "application/json" },
        });
      }
    }

    // Get responder's name (sanitized)
    const { data: responder } = await supabase
      .from("profiles")
      .select("display_name, avatar_emoji")
      .eq("id", responder_id)
      .single();

    const responderName = sanitize(responder?.display_name, 100) || "Your pact member";
    const responderEmoji = sanitize(responder?.avatar_emoji, 4) || "💪";

    // Get requester's push token
    const { data: requester } = await supabase
      .from("profiles")
      .select("push_token")
      .eq("id", requester_id)
      .single();

    if (!requester?.push_token) {
      return new Response(JSON.stringify({ ok: true, no_token: true }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }

    const isApproved = status === "approved";
    const title = isApproved ? "Unlock Approved" : "Unlock Denied";
    const alertBody = isApproved
      ? `${responderEmoji} ${responderName} approved your unlock request. Go ahead!`
      : `${responderEmoji} ${responderName} denied your unlock request. Stay focused!`;

    const safeAppId = sanitize(app_identifier, 100);

    const pushPayload = {
      aps: {
        alert: { title, body: alertBody.slice(0, 256) },
        sound: "default",
        badge: 0,
        "mutable-content": 1,
      },
      type: isApproved ? "request_approved" : "request_denied",
      app_identifier: safeAppId,
    };

    const apnsJwt = await generateAPNsToken();
    const success = await sendPush(requester.push_token, apnsJwt, pushPayload);

    return new Response(
      JSON.stringify({ ok: true, sent: success }),
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
