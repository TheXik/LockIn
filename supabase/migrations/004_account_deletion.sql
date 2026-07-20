-- Account deletion — required by App Store guideline 5.1.1(v).
-- Deletes the caller's account and ALL associated data in one transaction,
-- handling the RESTRICT foreign keys (pacts.created_by, unlock_requests.*)
-- that a naive auth.users delete would trip over.
--
-- Pact policy:
--   • sole member  → the pact (and its sessions/requests) is deleted
--   • creator + others remain → ownership transfers to the earliest other member
--   • plain member → just removed
--
-- SECURITY DEFINER so it can delete from auth.users. Create it via the Supabase
-- SQL editor (owned by the postgres role, which has the needed privileges). If
-- your project restricts auth.users deletes to the service role, deploy the same
-- cascade as an Edge Function with the service_role key instead and drop the
-- final `delete from auth.users` line here.

create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  uid uuid := auth.uid();
  pact record;
begin
  if uid is null then
    raise exception 'not authenticated';
  end if;

  -- 1. Remove unlock_requests that reference me directly (requester or responder).
  --    These RESTRICT-reference profiles, so they must go before the profile.
  delete from public.unlock_requests
    where requester_id = uid or responder_id = uid;

  -- 2. Detach any remaining unlock_requests that point at MY lock sessions,
  --    so those sessions can be removed (lock_session_id is RESTRICT).
  update public.unlock_requests
    set lock_session_id = null
    where lock_session_id in (
      select id from public.lock_sessions where user_id = uid
    );

  -- 3. Resolve pacts I created (created_by RESTRICT-references profiles).
  for pact in select id from public.pacts where created_by = uid loop
    if exists (
      select 1 from public.pact_members
      where pact_id = pact.id and user_id <> uid
    ) then
      -- Others remain → hand the pact to the earliest-joined other member.
      update public.pacts
        set created_by = (
          select user_id from public.pact_members
          where pact_id = pact.id and user_id <> uid
          order by joined_at asc
          limit 1
        )
      where id = pact.id;
    else
      -- I'm the only member → dissolve the pact.
      -- unlock_requests RESTRICT-reference the pact, so clear them first;
      -- pact_members and lock_sessions cascade on the pact delete.
      delete from public.unlock_requests where pact_id = pact.id;
      delete from public.pacts where id = pact.id;
    end if;
  end loop;

  -- 4. My remaining lock sessions (in pacts I didn't own).
  delete from public.lock_sessions where user_id = uid;

  -- 5. My remaining pact memberships.
  delete from public.pact_members where user_id = uid;

  -- 6. My profile (also cascades from the auth.users delete, but explicit is clearer).
  delete from public.profiles where id = uid;

  -- 7. The auth account itself — this is what makes it a true deletion,
  --    not a deactivation.
  delete from auth.users where id = uid;
end;
$$;

revoke all on function public.delete_my_account() from public;
grant execute on function public.delete_my_account() to authenticated;
