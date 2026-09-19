import { GoogleAuth } from "npm:google-auth-library@9";

const FCM_PROJECT_ID = Deno.env.get("FCM_PROJECT_ID")!;
const FCM_SERVICE_ACCOUNT_JSON = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON")!;

let cachedAuth: GoogleAuth | null = null;

function getAuth(): GoogleAuth {
  if (!cachedAuth) {
    cachedAuth = new GoogleAuth({
      credentials: JSON.parse(FCM_SERVICE_ACCOUNT_JSON),
      scopes: ["https://www.googleapis.com/auth/firebase.messaging"],
    });
  }
  return cachedAuth;
}

async function getAccessToken(): Promise<string> {
  const client = await getAuth().getClient();
  const { token } = await client.getAccessToken();
  if (!token) throw new Error("Failed to obtain FCM access token");
  return token;
}

export type FcmSendResult = {
  token: string;
  ok: boolean;
  /** set when FCM reports the token is no longer valid, so the caller can prune it */
  invalidToken?: boolean;
  error?: string;
};

/** Sends one FCM (HTTP v1) push per token, so a single bad token doesn't fail the batch. */
export async function sendFcmPush(
  tokens: string[],
  notification: { title: string; body: string },
  data: Record<string, string>,
): Promise<FcmSendResult[]> {
  if (tokens.length === 0) return [];
  const accessToken = await getAccessToken();
  const url =
    `https://fcm.googleapis.com/v1/projects/${FCM_PROJECT_ID}/messages:send`;

  const results: FcmSendResult[] = [];
  for (const token of tokens) {
    const res = await fetch(url, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token,
          notification,
          data,
          android: { priority: "high" },
          apns: { headers: { "apns-priority": "10" } },
        },
      }),
    });

    if (res.ok) {
      results.push({ token, ok: true });
      continue;
    }

    const body = await res.json().catch(() => ({}));
    const errorStatus = body?.error?.status ?? "";
    results.push({
      token,
      ok: false,
      invalidToken: errorStatus === "UNREGISTERED" ||
        errorStatus === "NOT_FOUND" ||
        errorStatus === "INVALID_ARGUMENT",
      error: body?.error?.message ?? `HTTP ${res.status}`,
    });
  }
  return results;
}
