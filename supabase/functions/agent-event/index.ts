// POST { agent_type, event_type, payload, user_id? } -> logs an Agent Controller event.
// Called either as the end-user (JWT), or server-to-server by the Agent Controller
// using the service-role key, in which case user_id must be supplied explicitly.
import { corsHeaders } from "../_shared/cors.ts";
import {
  getServiceClient,
  getUserClient,
  isServiceRoleRequest,
} from "../_shared/supabaseClient.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return new Response("Method Not Allowed", { status: 405, headers: corsHeaders });
  }

  const body = await req.json();
  const { agent_type, event_type, payload, user_id } = body ?? {};

  if (!agent_type || !event_type) {
    return new Response(
      JSON.stringify({ error: "agent_type and event_type are required" }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  if (isServiceRoleRequest(req)) {
    if (!user_id) {
      return new Response(
        JSON.stringify({ error: "user_id is required for service-role calls" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }
    const service = getServiceClient();
    const { data, error } = await service
      .from("agent_events")
      .insert({ user_id, agent_type, event_type, payload })
      .select()
      .single();

    if (error) {
      return new Response(JSON.stringify({ error: error.message }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }
    return new Response(JSON.stringify({ data }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const supabase = getUserClient(req);
  const { data: userData, error: userError } = await supabase.auth.getUser();
  if (userError || !userData.user) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const { data, error } = await supabase
    .from("agent_events")
    .insert({ user_id: userData.user.id, agent_type, event_type, payload })
    .select()
    .single();

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  return new Response(JSON.stringify({ data }), {
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});
