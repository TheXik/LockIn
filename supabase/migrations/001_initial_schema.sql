-- LockIn: Accountability App Schema
-- Run this in your Supabase SQL Editor

-- ─── Profiles ───────────────────────────────────────────
create table if not exists public.profiles (
    id uuid primary key references auth.users(id) on delete cascade,
    display_name text not null default 'User',
    avatar_emoji text not null default '🔥',
    push_token text,
    created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "Users can read any profile"
    on public.profiles for select using (true);

create policy "Users can update their own profile"
    on public.profiles for update using (auth.uid() = id);

create policy "Users can insert their own profile"
    on public.profiles for insert with check (auth.uid() = id);


-- ─── Pacts (accountability groups) ──────────────────────
create table if not exists public.pacts (
    id uuid primary key default gen_random_uuid(),
    name text not null,
    invite_code text unique not null,
    created_by uuid not null references public.profiles(id),
    created_at timestamptz not null default now()
);

alter table public.pacts enable row level security;

create policy "Pact members can read their pacts"
    on public.pacts for select using (
        id in (select pact_id from public.pact_members where user_id = auth.uid())
    );

create policy "Any authenticated user can read pacts by invite code"
    on public.pacts for select using (auth.uid() is not null);

create policy "Authenticated users can create pacts"
    on public.pacts for insert with check (auth.uid() = created_by);


-- ─── Pact Members ───────────────────────────────────────
create table if not exists public.pact_members (
    id uuid primary key default gen_random_uuid(),
    pact_id uuid not null references public.pacts(id) on delete cascade,
    user_id uuid not null references public.profiles(id) on delete cascade,
    joined_at timestamptz not null default now(),
    unique(pact_id, user_id)
);

alter table public.pact_members enable row level security;

create policy "Members can read their pact's members"
    on public.pact_members for select using (
        pact_id in (select pact_id from public.pact_members where user_id = auth.uid())
    );

create policy "Authenticated users can join pacts"
    on public.pact_members for insert with check (auth.uid() = user_id);


-- ─── Lock Sessions ──────────────────────────────────────
create table if not exists public.lock_sessions (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.profiles(id) on delete cascade,
    pact_id uuid not null references public.pacts(id) on delete cascade,
    app_identifiers text[] not null default '{}',
    schedule_start text,          -- "09:00"
    schedule_end text,            -- "17:00"
    schedule_days int[],          -- [1,2,3,4,5]
    daily_limit_minutes int,
    is_active boolean not null default true,
    created_at timestamptz not null default now()
);

alter table public.lock_sessions enable row level security;

create policy "Pact members can read lock sessions"
    on public.lock_sessions for select using (
        pact_id in (select pact_id from public.pact_members where user_id = auth.uid())
    );

create policy "Users can create their own lock sessions"
    on public.lock_sessions for insert with check (auth.uid() = user_id);

create policy "Users can update their own lock sessions"
    on public.lock_sessions for update using (auth.uid() = user_id);


-- ─── Unlock Requests ────────────────────────────────────
create table if not exists public.unlock_requests (
    id uuid primary key default gen_random_uuid(),
    requester_id uuid not null references public.profiles(id),
    pact_id uuid not null references public.pacts(id),
    lock_session_id uuid not null references public.lock_sessions(id),
    app_identifier text not null,
    reason text,
    status text not null default 'pending' check (status in ('pending', 'approved', 'denied')),
    responder_id uuid references public.profiles(id),
    responded_at timestamptz,
    created_at timestamptz not null default now()
);

alter table public.unlock_requests enable row level security;

create policy "Pact members can read unlock requests"
    on public.unlock_requests for select using (
        pact_id in (select pact_id from public.pact_members where user_id = auth.uid())
    );

create policy "Users can create unlock requests"
    on public.unlock_requests for insert with check (auth.uid() = requester_id);

create policy "Pact members can respond to requests"
    on public.unlock_requests for update using (
        pact_id in (select pact_id from public.pact_members where user_id = auth.uid())
        and auth.uid() != requester_id
    );


-- ─── Enable Realtime ────────────────────────────────────
alter publication supabase_realtime add table public.unlock_requests;
alter publication supabase_realtime add table public.pact_members;
