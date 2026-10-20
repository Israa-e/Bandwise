-- Bandwise: accounts and sync.
-- Run once in the Supabase SQL editor (Dashboard > SQL Editor > New query).
-- Every table has Row Level Security on: a signed-in user can only read and
-- write rows where user_id = auth.uid(). The anon role gets no access.

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

-- One row per synced document: 'onboarding' (the study plan), 'progress'
-- (lessons, XP, streak, mistakes, review schedules) and 'settings'.
-- The app compares updated_at to keep the newest copy (last write wins).
create table if not exists public.user_documents (
  user_id uuid not null references auth.users (id) on delete cascade,
  key text not null,
  data jsonb not null,
  updated_at timestamptz not null default now(),
  primary key (user_id, key)
);

-- Submitted essays, one row each. The AI review backend will read these
-- later. The last four columns let another device restore an essay
-- exactly (revisions, timed mode).
create table if not exists public.essays (
  id text primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  task_id text not null,
  text text not null,
  result jsonb,
  submitted_at timestamptz not null,
  revision_of text,
  mode text not null default 'learning',
  time_used_seconds integer not null default 0,
  time_up boolean not null default false
);

create index if not exists essays_user_id_idx on public.essays (user_id);

create table if not exists public.profiles (
  user_id uuid primary key references auth.users (id) on delete cascade,
  display_name text
);

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------

alter table public.user_documents enable row level security;
alter table public.essays enable row level security;
alter table public.profiles enable row level security;

-- user_documents
drop policy if exists "user_documents: select own" on public.user_documents;
create policy "user_documents: select own" on public.user_documents
  for select to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "user_documents: insert own" on public.user_documents;
create policy "user_documents: insert own" on public.user_documents
  for insert to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists "user_documents: update own" on public.user_documents;
create policy "user_documents: update own" on public.user_documents
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "user_documents: delete own" on public.user_documents;
create policy "user_documents: delete own" on public.user_documents
  for delete to authenticated
  using ((select auth.uid()) = user_id);

-- essays
drop policy if exists "essays: select own" on public.essays;
create policy "essays: select own" on public.essays
  for select to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "essays: insert own" on public.essays;
create policy "essays: insert own" on public.essays
  for insert to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists "essays: update own" on public.essays;
create policy "essays: update own" on public.essays
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "essays: delete own" on public.essays;
create policy "essays: delete own" on public.essays
  for delete to authenticated
  using ((select auth.uid()) = user_id);

-- profiles
drop policy if exists "profiles: select own" on public.profiles;
create policy "profiles: select own" on public.profiles
  for select to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "profiles: insert own" on public.profiles;
create policy "profiles: insert own" on public.profiles
  for insert to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists "profiles: update own" on public.profiles;
create policy "profiles: update own" on public.profiles
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "profiles: delete own" on public.profiles;
create policy "profiles: delete own" on public.profiles
  for delete to authenticated
  using ((select auth.uid()) = user_id);

-- ---------------------------------------------------------------------------
-- A profile row for every new account, with the name given at sign-up
-- (the app sends it as user metadata 'display_name'). Runs as the table
-- owner, so it works before the email is confirmed.
-- ---------------------------------------------------------------------------

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (user_id, display_name)
  values (
    new.id,
    nullif(left(trim(new.raw_user_meta_data ->> 'display_name'), 60), '')
  )
  on conflict (user_id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
