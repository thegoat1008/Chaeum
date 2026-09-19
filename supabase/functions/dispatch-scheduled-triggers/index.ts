// Invoked every minute by pg_cron (see migrations/20260919000002_cron_dispatch.sql).
// Finds due mission triggers, sends the FCM push, and records the outcome so the
// mission push still arrives even while the app is closed.
import { corsHeaders } from "../_shared/cors.ts";
import { getServiceClient } from "../_shared/supabaseClient.ts";
import { sendFcmPush } from "../_shared/fcm.ts";

const CRON_SECRET = Deno.env.get("CRON_SECRET")!;
const BATCH_SIZE = 100;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.headers.get("x-cron-secret") !== CRON_SECRET) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const supabase = getServiceClient();

  const { data: dueTriggers, error: fetchError } = await supabase
    .from("mission_triggers")
    .select("id, mission_id, user_id, scheduled_at, missions(title, description)")
    .eq("status", "scheduled")
    .lte("scheduled_at", new Date().toISOString())
    .order("scheduled_at", { ascending: true })
    .limit(BATCH_SIZE);

  if (fetchError) {
    return new Response(JSON.stringify({ error: fetchError.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  let sent = 0;
  let failed = 0;

  for (const trigger of dueTriggers ?? []) {
    const mission = Array.isArray(trigger.missions) ? trigger.missions[0] : trigger.missions;

    const { data: tokenRows } = await supabase
      .from("push_tokens")
      .select("token")
      .eq("user_id", trigger.user_id);

    const tokens = (tokenRows ?? []).map((r) => r.token);

    if (tokens.length === 0) {
      await markTrigger(supabase, trigger.id, "failed", "no_token");
      await logExecution(supabase, trigger.id, trigger.user_id, "skipped", {
        reason: "no_push_token",
      });
      failed++;
      continue;
    }

    try {
      const results = await sendFcmPush(
        tokens,
        {
          title: mission?.title ?? "미션 알림",
          body: mission?.description ?? "예약된 미션을 확인해보세요.",
        },
        {
          type: "mission_trigger",
          mission_id: trigger.mission_id,
          trigger_id: trigger.id,
        },
      );

      const invalidTokens = results.filter((r) => r.invalidToken).map((r) => r.token);
      if (invalidTokens.length > 0) {
        await supabase
          .from("push_tokens")
          .delete()
          .eq("user_id", trigger.user_id)
          .in("token", invalidTokens);
      }

      const anySent = results.some((r) => r.ok);
      if (anySent) {
        await markTrigger(supabase, trigger.id, "sent");
        await supabase
          .from("missions")
          .update({ push_sent: true })
          .eq("id", trigger.mission_id);
        await logExecution(supabase, trigger.id, trigger.user_id, "sent", { results });
        sent++;
      } else {
        await markTrigger(supabase, trigger.id, "failed");
        await logExecution(supabase, trigger.id, trigger.user_id, "failed", { results });
        failed++;
      }
    } catch (err) {
      await markTrigger(supabase, trigger.id, "failed");
      await logExecution(supabase, trigger.id, trigger.user_id, "failed", {
        error: err instanceof Error ? err.message : String(err),
      });
      failed++;
    }
  }

  return new Response(
    JSON.stringify({ processed: dueTriggers?.length ?? 0, sent, failed }),
    { headers: { ...corsHeaders, "Content-Type": "application/json" } },
  );
});

async function markTrigger(
  supabase: ReturnType<typeof getServiceClient>,
  triggerId: string,
  status: "sent" | "failed",
  _reason?: string,
) {
  await supabase
    .from("mission_triggers")
    .update({ status, attempted_at: new Date().toISOString() })
    .eq("id", triggerId);
}

async function logExecution(
  supabase: ReturnType<typeof getServiceClient>,
  triggerId: string,
  userId: string,
  status: "sent" | "failed" | "skipped",
  detail: Record<string, unknown>,
) {
  await supabase.from("trigger_executions").insert({
    trigger_id: triggerId,
    user_id: userId,
    status,
    detail,
  });
}
