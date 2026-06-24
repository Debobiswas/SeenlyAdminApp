// @ts-ignore
import { serve } from "https://deno.land/std@0.192.0/http/server.ts";
// @ts-ignore
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4";

declare const Deno: {
  env: { get(key: string): string | undefined };
};

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

function json(body: Record<string, unknown>, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
  });
}

async function getAdminUserId(req: Request): Promise<string | Response> {
  const authHeader = req.headers.get("Authorization") ?? "";
  const token = authHeader.replace(/^Bearer\s+/i, "");
  if (!token) return json({ error: "Missing bearer token" }, 401);

  const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);
  const { data: userData, error: userErr } = await admin.auth.getUser(token);
  if (userErr || !userData?.user?.id) {
    return json({ error: "Not authenticated" }, 401);
  }

  const userId = userData.user.id;
  const { data: adminRow, error: adminErr } = await admin
    .from("admins")
    .select("id")
    .eq("id", userId)
    .eq("is_admin", true)
    .eq("role", "admin")
    .maybeSingle();

  if (adminErr) {
    console.error("admin_reject_profile admin lookup error", adminErr);
    return json({ error: "Admin lookup failed" }, 500);
  }
  if (!adminRow) return json({ error: "Admin privileges required" }, 403);

  return userId;
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }
  if (!SUPABASE_URL || !SERVICE_ROLE_KEY) {
    return json({ error: "Server misconfigured" }, 500);
  }

  const adminUserId = await getAdminUserId(req);
  if (adminUserId instanceof Response) return adminUserId;

  let payload: { target_user_id?: unknown; rejection_reason?: unknown };
  try {
    payload = await req.json();
  } catch {
    return json({ error: "Invalid JSON body" }, 400);
  }

  if (typeof payload.target_user_id !== "string" || payload.target_user_id.length === 0) {
    return json({ error: "target_user_id is required" }, 400);
  }

  const reason = typeof payload.rejection_reason === "string"
    ? payload.rejection_reason.trim()
    : "";

  const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);
  const { error: updateErr } = await admin
    .from("profiles")
    .update({ status: "rejected" })
    .eq("id", payload.target_user_id);

  if (updateErr) {
    console.error("admin_reject_profile update error", updateErr);
    return json({ error: "Profile rejection failed" }, 500);
  }

  const { error: logErr } = await admin.from("admin_audit_logs").insert({
    admin_user_id: adminUserId,
    target_user_id: payload.target_user_id,
    action: "rejected",
    reason,
  });

  if (logErr) {
    console.error("admin_reject_profile audit log error", logErr);
    return json({ error: "Audit log write failed" }, 500);
  }

  return json({ ok: true }, 200);
});
