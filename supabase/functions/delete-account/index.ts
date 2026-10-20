// Deletes the signed-in user's account.
//
// The caller's JWT (sent automatically by supabase_flutter as the
// Authorization header) is verified first, so a user can only delete
// themselves. Deleting the auth user removes their profiles,
// user_documents and essays rows through "on delete cascade".
//
// The service role key is read from this function's environment only
// (SUPABASE_SERVICE_ROLE_KEY is provided by Supabase). It must never be in
// the app or the repo.
//
// Deploy: supabase functions deploy delete-account

import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: Record<string, unknown>, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json({ error: "method_not_allowed" }, 405);
  }

  const authorization = req.headers.get("Authorization");
  if (!authorization?.startsWith("Bearer ")) {
    return json({ error: "not_authenticated" }, 401);
  }

  const url = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !serviceRoleKey) {
    return json({ error: "server_not_configured" }, 500);
  }
  const admin = createClient(url, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  // Who is calling? Supabase Auth verifies the JWT (signature and expiry).
  const token = authorization.slice("Bearer ".length);
  const { data, error: userError } = await admin.auth.getUser(token);
  const user = data?.user;
  if (userError || !user) {
    return json({ error: "not_authenticated" }, 401);
  }

  // Only the service role can delete auth users.
  const { error: deleteError } = await admin.auth.admin.deleteUser(user.id);
  if (deleteError) {
    console.error("delete-account failed", user.id, deleteError.message);
    return json({ error: "delete_failed" }, 500);
  }

  return json({ deleted: true }, 200);
});
