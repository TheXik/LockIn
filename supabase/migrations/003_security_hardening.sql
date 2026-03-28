-- LockIn: Security Hardening Migration
-- Fixes: RLS policies, race conditions, input validation, rate limiting
-- Run this after 002_push_notifications.sql

-- ════════════════════════════════════════════════════════
-- 1. FIX PROFILES RLS — restrict reads to co-pact-members + self
-- ════════════════════════════════════════════════════════

-- Drop the overly permissive policy that exposes ALL profiles
drop policy if exists "Users can read any profile" on public.profiles;

-- Users can read their own profile
create policy "Users can read own profile"
    on public.profiles for select using (auth.uid() = id);

-- Users can read profiles of people in the same pact
create policy "Users can read co-member profiles"
    on public.profiles for select using (
        id in (
            select distinct pm.user_id
            from public.pact_members pm
            where pm.pact_id in (
                select pact_id from public.pact_members where user_id = auth.uid()
            )
        )
    );

-- ════════════════════════════════════════════════════════
-- 2. FIX PACTS RLS — remove blanket read, add invite code lookup
-- ════════════════════════════════════════════════════════

-- Drop the overly permissive policy
drop policy if exists "Any authenticated user can read pacts by invite code" on public.pacts;

-- Keep existing member-read policy (already correct):
-- "Pact members can read their pacts" — already exists from 001

-- For joining: allow reading a SINGLE pact by exact invite code match.
-- This uses a Postgres function to safely expose only code-based lookups.
create or replace function public.lookup_pact_by_invite_code(code text)
returns setof public.pacts
language sql
security definer
set search_path = public
as $$
    select * from public.pacts where invite_code = upper(code) limit 1;
$$;

-- ════════════════════════════════════════════════════════
-- 3. FIX UNLOCK REQUESTS RLS — require pact membership for INSERT
-- ════════════════════════════════════════════════════════

drop policy if exists "Users can create unlock requests" on public.unlock_requests;

create policy "Pact members can create unlock requests"
    on public.unlock_requests for insert with check (
        auth.uid() = requester_id
        and pact_id in (select pact_id from public.pact_members where user_id = auth.uid())
    );

-- ════════════════════════════════════════════════════════
-- 4. FIX LOCK SESSIONS RLS — require pact membership for INSERT
-- ════════════════════════════════════════════════════════

drop policy if exists "Users can create their own lock sessions" on public.lock_sessions;

create policy "Users can create lock sessions in their pacts"
    on public.lock_sessions for insert with check (
        auth.uid() = user_id
        and pact_id in (select pact_id from public.pact_members where user_id = auth.uid())
    );

-- ════════════════════════════════════════════════════════
-- 5. PREVENT RACE CONDITION: Pact member limit (max 4)
-- ════════════════════════════════════════════════════════

create or replace function public.check_pact_member_limit()
returns trigger
language plpgsql
security definer
as $$
declare
    member_count int;
begin
    select count(*) into member_count
    from public.pact_members
    where pact_id = NEW.pact_id;

    if member_count >= 4 then
        raise exception 'Pact is full (max 4 members)';
    end if;

    return NEW;
end;
$$;

drop trigger if exists enforce_pact_member_limit on public.pact_members;
create trigger enforce_pact_member_limit
    before insert on public.pact_members
    for each row
    execute function public.check_pact_member_limit();

-- ════════════════════════════════════════════════════════
-- 6. PREVENT RACE CONDITION: Optimistic locking on unlock request responses
-- Only allow UPDATE if status is still 'pending'
-- ════════════════════════════════════════════════════════

-- Drop old policy and replace with stricter one
drop policy if exists "Pact members can respond to requests" on public.unlock_requests;

create policy "Pact members can respond to pending requests"
    on public.unlock_requests for update using (
        status = 'pending'
        and pact_id in (select pact_id from public.pact_members where user_id = auth.uid())
        and auth.uid() != requester_id
    );

-- ════════════════════════════════════════════════════════
-- 7. RATE LIMITING: Max 5 pending unlock requests per user per pact
-- ════════════════════════════════════════════════════════

create or replace function public.check_unlock_request_rate_limit()
returns trigger
language plpgsql
security definer
as $$
declare
    pending_count int;
begin
    select count(*) into pending_count
    from public.unlock_requests
    where requester_id = NEW.requester_id
      and pact_id = NEW.pact_id
      and status = 'pending';

    if pending_count >= 5 then
        raise exception 'Too many pending requests (max 5 per pact). Wait for responses.';
    end if;

    return NEW;
end;
$$;

drop trigger if exists enforce_unlock_request_rate_limit on public.unlock_requests;
create trigger enforce_unlock_request_rate_limit
    before insert on public.unlock_requests
    for each row
    execute function public.check_unlock_request_rate_limit();

-- ════════════════════════════════════════════════════════
-- 8. INPUT VALIDATION: Display name length limit
-- ════════════════════════════════════════════════════════

alter table public.profiles
    add constraint profiles_display_name_length check (char_length(display_name) <= 100);

-- ════════════════════════════════════════════════════════
-- 9. INPUT VALIDATION: App identifier and reason length limits
-- ════════════════════════════════════════════════════════

alter table public.unlock_requests
    add constraint unlock_requests_app_identifier_length check (char_length(app_identifier) <= 100);

alter table public.unlock_requests
    add constraint unlock_requests_reason_length check (char_length(reason) <= 500);

-- ════════════════════════════════════════════════════════
-- 10. INPUT VALIDATION: Pact name length limit
-- ════════════════════════════════════════════════════════

alter table public.pacts
    add constraint pacts_name_length check (char_length(name) <= 100);

-- ════════════════════════════════════════════════════════
-- 11. PREVENT CREATOR ABANDONMENT: Creator can't leave their own pact
-- ════════════════════════════════════════════════════════

create or replace function public.prevent_creator_leave()
returns trigger
language plpgsql
security definer
as $$
declare
    pact_creator uuid;
begin
    select created_by into pact_creator
    from public.pacts
    where id = OLD.pact_id;

    if OLD.user_id = pact_creator then
        raise exception 'Pact creator cannot leave. Transfer ownership or delete the pact.';
    end if;

    return OLD;
end;
$$;

drop trigger if exists prevent_creator_leave on public.pact_members;
create trigger prevent_creator_leave
    before delete on public.pact_members
    for each row
    execute function public.prevent_creator_leave();

-- ════════════════════════════════════════════════════════
-- 12. INVITE CODE: Ensure uniqueness constraint exists
-- ════════════════════════════════════════════════════════

-- Already has UNIQUE in schema (line 29 of 001), but add index for lookups
create index if not exists idx_pacts_invite_code on public.pacts (invite_code);

-- ════════════════════════════════════════════════════════
-- 13. LOCK SESSION: Validate created_at is not in the future
-- ════════════════════════════════════════════════════════

create or replace function public.validate_lock_session_timestamp()
returns trigger
language plpgsql
security definer
as $$
begin
    -- Don't allow sessions more than 1 minute in the future (clock skew tolerance)
    if NEW.created_at > now() + interval '1 minute' then
        raise exception 'Lock session timestamp cannot be in the future';
    end if;

    return NEW;
end;
$$;

drop trigger if exists validate_lock_session_timestamp on public.lock_sessions;
create trigger validate_lock_session_timestamp
    before insert on public.lock_sessions
    for each row
    execute function public.validate_lock_session_timestamp();

-- ════════════════════════════════════════════════════════
-- 14. CASCADE: Cancel pending requests when member leaves pact
-- ════════════════════════════════════════════════════════

create or replace function public.cancel_requests_on_leave()
returns trigger
language plpgsql
security definer
as $$
begin
    -- Cancel pending requests by the leaving member for this pact
    update public.unlock_requests
    set status = 'denied',
        responded_at = now()
    where requester_id = OLD.user_id
      and pact_id = OLD.pact_id
      and status = 'pending';

    return OLD;
end;
$$;

drop trigger if exists cancel_requests_on_member_leave on public.pact_members;
create trigger cancel_requests_on_member_leave
    after delete on public.pact_members
    for each row
    execute function public.cancel_requests_on_leave();

-- ════════════════════════════════════════════════════════
-- 15. PACT DELETION: Allow creator to delete pact
-- ════════════════════════════════════════════════════════

create policy "Creator can delete their pact"
    on public.pacts for delete using (auth.uid() = created_by);

-- ════════════════════════════════════════════════════════
-- 16. HIDE PUSH TOKEN: Create a view without push_token for member lookups
-- ════════════════════════════════════════════════════════

create or replace view public.profiles_safe as
select id, display_name, avatar_emoji, created_at
from public.profiles;
