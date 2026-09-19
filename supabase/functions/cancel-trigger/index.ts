// POST { trigger_id } -> cancels a scheduled mission trigger owned by the caller.
import { corsHeaders } from "../_shared/cors.ts";
import { getUserClient } from "../_shared/supabaseClient.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return new Response("Method Not Allowed", { status: 405, headers: corsHeaders });
  }

  const supabase = getUserClient(req);
  const { data: userData, error: userError } = await supabase.auth.getUser();
  if (userError || !userData.user) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const { trigger_id } = await req.json();
  if (!trigger_id) {
    return new Response(JSON.stringify({ error: "trigger_id is required" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  // RLS scopes this update to the caller's own rows; only a still-scheduled trigger can be cancelled.
  const { data, error } = await supabase
    .from("mission_triggers")
    .update({ status: "cancelled" })
    .eq("id", trigger_id)
    .eq("status", "scheduled")
    .select()
    .maybeSingle();

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  if (!data) {
    return new Response(
      JSON.stringify({ error: "Trigger not found or already dispatched/cancelled" }),
      { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  return new Response(JSON.stringify({ data }), {
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});
