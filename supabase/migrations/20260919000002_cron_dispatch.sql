-- Schedules dispatch-scheduled-triggers to run every minute via pg_cron + pg_net.
-- NOTE: pg_cron may need to be enabled first from the Supabase Dashboard
-- (Database → Extensions) if this migration fails on a fresh project.

create extension if not exists pg_cron;
create extension if not exists pg_net;

-- Project URL / secret are stored in Vault so they aren't hardcoded in the migration.
-- After `supabase link`, set them once with:
--   select vault.create_secret('https://<project-ref>.supabase.co/functions/v1/dispatch-scheduled-triggers', 'chaeum_dispatch_url');
--   select vault.create_secret('<CRON_SECRET value>', 'chaeum_cron_secret');
-- (CRON_SECRET must match the Edge Function secret set via `supabase secrets set CRON_SECRET=...`.)

select cron.schedule(
  'chaeum-dispatch-scheduled-triggers',
  '* * * * *',
  $$
  select net.http_post(
    url := (select decrypted_secret from vault.decrypted_secrets where name = 'chaeum_dispatch_url'),
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-cron-secret', (select decrypted_secret from vault.decrypted_secrets where name = 'chaeum_cron_secret')
    ),
    body := '{}'::jsonb
  );
  $$
);
