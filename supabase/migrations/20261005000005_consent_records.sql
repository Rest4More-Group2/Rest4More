-- Bewijs van toestemming (AVG art. 7.1): per gegeven of ingetrokken
-- toestemming een rij, met de versie van de tekst. Alleen aanvullen: de app
-- past bestaande rijen niet aan, al staat een update toe voor opnieuw
-- uploaden na een accountwissel.

create table public.consent_records (
  id uuid primary key,
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  purpose text not null,
  policy_version text not null,
  status text not null,
  recorded_at timestamptz not null,
  updated_at timestamptz not null,
  deleted_at timestamptz,
  synced_at timestamptz not null default now()
);

alter table public.consent_records enable row level security;

create policy consent_records_select on public.consent_records
  for select to authenticated using (user_id = (select auth.uid()));
create policy consent_records_insert on public.consent_records
  for insert to authenticated with check (user_id = (select auth.uid()));
create policy consent_records_update on public.consent_records
  for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create trigger consent_records_sync
  before insert or update on public.consent_records
  for each row execute function public.sync_before_write();

create index consent_records_synced_at on public.consent_records (user_id, synced_at);

grant select, insert, update on public.consent_records to authenticated;

-- Export en wissen nemen de nieuwe tabel mee.
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
  delete from public.accessories where user_id = uid;
  delete from public.block_profiles where user_id = uid;
  delete from public.consent_records where user_id = uid;
  delete from public.profiles where user_id = uid;
  delete from public.entitlements where user_id = uid;
  delete from auth.users where id = uid;
end;
$$;
