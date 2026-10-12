-- Plannen van Avond en Ochtend: weekschema, stappen en instellingen als een
-- json-document per soort. Lokaal staat dit in `moment_plans`.
--
-- Bewust geen unieke index op (user_id, kind): twee toestellen kunnen elk een
-- rij aanmaken voordat ze elkaar gezien hebben. De app gebruikt per soort de
-- nieuwste levende rij en verwijdert dubbelen zacht bij het bewaren.

create table public.moment_plans (
  id uuid primary key,
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  kind text not null,
  plan jsonb not null,
  updated_at timestamptz not null,
  deleted_at timestamptz,
  synced_at timestamptz not null default now()
);

alter table public.moment_plans enable row level security;

create policy moment_plans_select on public.moment_plans
  for select to authenticated using (user_id = (select auth.uid()));
create policy moment_plans_insert on public.moment_plans
  for insert to authenticated with check (user_id = (select auth.uid()));
create policy moment_plans_update on public.moment_plans
  for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create trigger moment_plans_sync
  before insert or update on public.moment_plans
  for each row execute function public.sync_before_write();

create index moment_plans_synced_at on public.moment_plans (user_id, synced_at);

-- Nooit delete: rijen worden zacht verwijderd.
grant select, insert, update on public.moment_plans to authenticated;

-- Export, wissen en bewaartermijn nemen de nieuwe tabel mee.
create or replace function public.export_my_data()
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  select jsonb_build_object(
    'exported_at', now(),
    'user_id', auth.uid(),
    'profiles', coalesce((select jsonb_agg(to_jsonb(t)) from public.profiles t), '[]'::jsonb),
    'consent_records', coalesce((select jsonb_agg(to_jsonb(t)) from public.consent_records t), '[]'::jsonb),
    'block_profiles', coalesce((select jsonb_agg(to_jsonb(t)) from public.block_profiles t), '[]'::jsonb),
    'routines', coalesce((select jsonb_agg(to_jsonb(t)) from public.routines t), '[]'::jsonb),
    'moment_plans', coalesce((select jsonb_agg(to_jsonb(t)) from public.moment_plans t), '[]'::jsonb),
    'accessories', coalesce((select jsonb_agg(to_jsonb(t)) from public.accessories t), '[]'::jsonb),
    'focus_sessions', coalesce((select jsonb_agg(to_jsonb(t)) from public.focus_sessions t), '[]'::jsonb),
    'programme_enrollments', coalesce((select jsonb_agg(to_jsonb(t)) from public.programme_enrollments t), '[]'::jsonb),
    'programme_days', coalesce((select jsonb_agg(to_jsonb(t)) from public.programme_days t), '[]'::jsonb),
    'entitlements', coalesce((select jsonb_agg(to_jsonb(t)) from public.entitlements t), '[]'::jsonb)
  );
$$;

create or replace function public.erase_user_data(uid uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  delete from public.programme_days where user_id = uid;
  delete from public.programme_enrollments where user_id = uid;
  delete from public.focus_sessions where user_id = uid;
  delete from public.routines where user_id = uid;
  delete from public.moment_plans where user_id = uid;
  delete from public.accessories where user_id = uid;
  delete from public.block_profiles where user_id = uid;
  delete from public.consent_records where user_id = uid;
  delete from public.profiles where user_id = uid;
  delete from public.entitlements where user_id = uid;
  delete from auth.users where id = uid;
end;
$$;

create or replace function public.purge_old_tombstones()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  cutoff timestamptz := now() - interval '2 years';
begin
  delete from public.programme_days where deleted_at < cutoff;
  delete from public.programme_enrollments where deleted_at < cutoff;
  delete from public.focus_sessions where deleted_at < cutoff;
  delete from public.routines where deleted_at < cutoff;
  delete from public.moment_plans where deleted_at < cutoff;
  delete from public.accessories where deleted_at < cutoff;
  delete from public.block_profiles where deleted_at < cutoff;
  delete from public.entitlements where deleted_at < cutoff;
  delete from public.profiles p
    where p.deleted_at < cutoff
      and not exists (
        select 1 from public.programme_enrollments e where e.profile_id = p.id
      );
end;
$$;
