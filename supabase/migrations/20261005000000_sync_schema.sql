-- Serverkant van de lokale Drift-database. De app pusht rijen met `dirty`;
-- die kolom en de lokale-only tabellen (ios_selections, local_notifications)
-- bestaan hier niet. `user_id` wordt door de server uit de sessie gevuld.
--
-- Last-writer-wins op `updated_at`: een oudere schrijfactie wordt stil
-- genegeerd. Rijen worden nooit verwijderd, alleen `deleted_at` wordt gezet.

create table public.profiles (
  id uuid primary key,
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  display_name text,
  age_band text,
  primary_goal text,
  obstacle text,
  rhythm text,
  putaway_minutes int,
  step_size text,
  preferred_activity text,
  anchor_text text,
  activity_material text,
  owns_restnest boolean not null default false,
  owns_card boolean not null default false,
  bedtime_minutes int check (bedtime_minutes between 0 and 1439),
  phone_away_minutes int,
  timezone text not null default 'UTC',
  notify_programme boolean not null default false,
  notify_time_minutes int check (notify_time_minutes between 0 and 1439),
  cloud_sync_consent_at timestamptz,
  intake_step int not null default 0,
  intake_completed_at timestamptz,
  updated_at timestamptz not null,
  deleted_at timestamptz,
  synced_at timestamptz not null default now()
);
create unique index profiles_one_per_user on public.profiles (user_id);

create table public.block_profiles (
  id uuid primary key,
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  name text not null,
  context text,
  items jsonb not null default '[]',
  updated_at timestamptz not null,
  deleted_at timestamptz,
  synced_at timestamptz not null default now()
);

create table public.routines (
  id uuid primary key,
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  block_profile_id uuid references public.block_profiles (id) on delete set null,
  mode text not null,
  name text not null,
  end_rule text not null default 'manual',
  default_minutes int,
  days_mask int not null default 0 check (days_mask between 0 and 127),
  start_minutes int check (start_minutes between 0 and 1439),
  auto_start boolean not null default false,
  enabled boolean not null default true,
  steps jsonb,
  updated_at timestamptz not null,
  deleted_at timestamptz,
  synced_at timestamptz not null default now()
);

create table public.accessories (
  id uuid primary key,
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  kind text not null,
  token_hash text,
  label text not null,
  status text not null default 'active',
  paired_at timestamptz,
  updated_at timestamptz not null,
  deleted_at timestamptz,
  synced_at timestamptz not null default now()
);
create unique index accessories_token_hash_per_user
  on public.accessories (user_id, token_hash) where token_hash is not null;

create table public.focus_sessions (
  id uuid primary key,
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  routine_id uuid references public.routines (id) on delete set null,
  block_profile_id uuid references public.block_profiles (id) on delete set null,
  accessory_id uuid references public.accessories (id) on delete set null,
  mode text not null,
  source text not null,
  platform text not null,
  state text not null,
  started_at timestamptz not null,
  local_date date not null,
  planned_seconds int,
  ended_at timestamptz,
  outcome text,
  blocking_confirmed_at timestamptz,
  blocking_released_at timestamptz,
  feeling text,
  events jsonb not null default '[]',
  updated_at timestamptz not null,
  deleted_at timestamptz,
  synced_at timestamptz not null default now()
);
create index focus_sessions_started_at on public.focus_sessions (user_id, started_at);

create table public.programme_enrollments (
  id uuid primary key,
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  profile_id uuid not null references public.profiles (id),
  content_version text not null,
  status text not null default 'active',
  started_on date not null,
  selection jsonb not null default '{}',
  direction text,
  completed_at timestamptz,
  updated_at timestamptz not null,
  deleted_at timestamptz,
  synced_at timestamptz not null default now()
);

create table public.programme_days (
  id uuid primary key,
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  enrollment_id uuid not null references public.programme_enrollments (id) on delete cascade,
  day_number int not null check (day_number between 1 and 14),
  content_id text not null,
  status text not null default 'planned',
  size text not null default 'standard',
  scheduled_for date not null,
  offered_at timestamptz,
  opened_at timestamptz,
  completed_at timestamptz,
  snapshot jsonb not null default '{}',
  fit text,
  blocker text,
  protected text,
  rested_score int check (rested_score between 1 and 5),
  updated_at timestamptz not null,
  deleted_at timestamptz,
  synced_at timestamptz not null default now(),
  unique (enrollment_id, day_number)
);
create index programme_days_scheduled_for on public.programme_days (user_id, scheduled_for);

-- Alleen de server schrijft hier (service role). De app leest en pusht nooit.
create table public.entitlements (
  id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  feature text not null,
  source text not null,
  status text not null,
  starts_at timestamptz not null,
  ends_at timestamptz,
  updated_at timestamptz not null,
  deleted_at timestamptz,
  synced_at timestamptz not null default now()
);

-- Houdt `synced_at` bij (cursor voor de latere pull), negeert verouderde
-- schrijfacties en laat `user_id` nooit veranderen.
create function public.sync_before_write()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'UPDATE' then
    if new.updated_at < old.updated_at then
      return null;
    end if;
    new.user_id := old.user_id;
  end if;
  new.synced_at := now();
  return new;
end;
$$;

do $$
declare
  t text;
begin
  foreach t in array array[
    'profiles', 'block_profiles', 'routines', 'accessories',
    'focus_sessions', 'programme_enrollments', 'programme_days', 'entitlements'
  ]
  loop
    execute format('alter table public.%I enable row level security', t);
    execute format(
      'create policy %I on public.%I for select to authenticated using (user_id = (select auth.uid()))',
      t || '_select', t);
    execute format(
      'create trigger %I before insert or update on public.%I for each row execute function public.sync_before_write()',
      t || '_sync', t);
    execute format('create index %I on public.%I (user_id, synced_at)', t || '_synced_at', t);
  end loop;

  -- Schrijfrechten voor de app: alles behalve entitlements. Nooit delete.
  foreach t in array array[
    'profiles', 'block_profiles', 'routines', 'accessories',
    'focus_sessions', 'programme_enrollments', 'programme_days'
  ]
  loop
    execute format(
      'create policy %I on public.%I for insert to authenticated with check (user_id = (select auth.uid()))',
      t || '_insert', t);
    execute format(
      'create policy %I on public.%I for update to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()))',
      t || '_update', t);
  end loop;
end;
$$;
