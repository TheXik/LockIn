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
const APNS_BUNDLE_ID = Deno.env.get("APNS_BUNDLE_ID") || "com.lockin.app";
const APNS_KEY_P8 = Deno.env.get("APNS_KEY_P8")!;
const APNS_ENV = Deno.env.get("APNS_ENV") || "development";

const APNS_HOST = APNS_ENV === "production"
  ? "https://api.push.apple.com"
  : "https://api.sandbox.push.apple.com";

async function generateAPNsToken(): Promise<string> {
  const privateKey = await jose.importPKCS8(APNS_KEY_P8, "ES256");
  return new jose.SignJWT({})
    .setProtectedHeader({ alg: "ES256", kid: APNS_KEY_ID })
    .setIssuer(APNS_TEAM_ID)
    .setIssuedAt()
    .setExpirationTime("1h")
    .sign(privateKey);
}

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
      console.error(`APNs error: ${res.status} ${await res.text()}`);
      return false;
    }
    return true;
  } catch (err) {
    console.error("APNs fetch error:", err);
    return false;
  }
}

serve(async (req: Request) => {
  try {
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

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

    // Get responder's name
    const { data: responder } = await supabase
      .from("profiles")
      .select("display_name, avatar_emoji")
      .eq("id", responder_id)
      .single();

    const responderName = responder?.display_name || "Your pact member";
    const responderEmoji = responder?.avatar_emoji || "💪";

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
    const title = isApproved ? "✅ Unlock Approved!" : "❌ Unlock Denied";
    const alertBody = isApproved
      ? `${responderEmoji} ${responderName} approved your unlock request. Go ahead!`
      : `${responderEmoji} ${responderName} denied your unlock request. Stay focused! 💪`;

    const pushPayload = {
      aps: {
        alert: { title, body: alertBody },
        sound: "default",
        badge: 0,
        "mutable-content": 1,
      },
      type: isApproved ? "request_approved" : "request_denied",
      app_identifier,
    };

    const apnsJwt = await generateAPNsToken();
    const success = await sendPush(requester.push_token, apnsJwt, pushPayload);

    return new Response(
      JSON.stringify({ ok: true, sent: success }),
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
