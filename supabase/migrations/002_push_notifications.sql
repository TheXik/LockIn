-- LockIn: Push Notification Infrastructure
-- Run this after 001_initial_schema.sql

-- ─── Index for push token lookups ──────────────────────
create index if not exists idx_profiles_push_token
    on public.profiles (push_token)
    where push_token is not null;

-- ─── Database Webhooks ─────────────────────────────────
-- Note: Supabase Database Webhooks are configured in the Dashboard, not in SQL.
-- Configure these webhooks in Supabase Dashboard → Database → Webhooks:
--
-- 1. Webhook: "push-notification-on-unlock-request"
--    Table: public.unlock_requests
--    Events: INSERT
--    URL: <your-project-url>/functions/v1/push-notification
--    Headers: Authorization: Bearer <service_role_key>
--
-- 2. Webhook: "push-notification-on-request-response"
--    Table: public.unlock_requests
--    Events: UPDATE
--    URL: <your-project-url>/functions/v1/request-response
--    Headers: Authorization: Bearer <service_role_key>

-- ─── Notification preferences (future) ────────────────
-- Placeholder for per-user notification preferences
alter table public.profiles
    add column if not exists notifications_enabled boolean not null default true;

-- ─── Lock session indexes for streak computation ──────
create index if not exists idx_lock_sessions_user_created
    on public.lock_sessions (user_id, created_at desc);

create index if not exists idx_lock_sessions_active
    on public.lock_sessions (pact_id, is_active)
    where is_active = true;
