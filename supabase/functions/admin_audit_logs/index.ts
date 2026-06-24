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
    console.error("admin_audit_logs admin lookup error", adminErr);
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

  const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);
  const { data: logs, error: logsErr } = await admin
    .from("admin_audit_logs_with_targets")
    .select()
    .order("created_at", { ascending: false });

  if (logsErr) {
    console.error("admin_audit_logs read error", logsErr);
    return json({ error: "Audit log lookup failed" }, 500);
  }

  return json({ logs: logs ?? [] }, 200);
});
