-- Verlaten anonieme accounts: na 12 maanden zonder activiteit worden de
-- gegevens en het account gewist (opslagbeperking, AVG art. 5.1.e).
--
-- Activiteit is de laatste van: aanmaken, laatste aanmelding, laatste sessie
-- en `profiles.synced_at`. De app raakt dat laatste punt dagelijks aan via
-- `record_activity()`, ook als er niets te uploaden valt.

-- Wist alle gegevens van een gebruiker en daarna het account. Wordt gebruikt
-- door `delete_my_data()` en door de opschoonroutine hieronder, en is zelf
-- voor niemand aanroepbaar behalve de database-eigenaar.
create function public.erase_user_data(uid uuid)
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
  delete from public.profiles where user_id = uid;
  delete from public.entitlements where user_id = uid;
  delete from auth.users where id = uid;
end;
$$;
revoke all on function public.erase_user_data(uuid) from public, anon, authenticated;

create or replace function public.delete_my_data()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'niet aangemeld' using errcode = '28000';
  end if;
  perform public.erase_user_data(uid);
end;
$$;

-- Hartslag: laat de server zien dat dit account nog in gebruik is. De
-- trigger op profiles zet `synced_at`.
create function public.record_activity()
returns void
language sql
security invoker
set search_path = ''
as $$
  update public.profiles set id = id where user_id = auth.uid();
$$;
revoke all on function public.record_activity() from public, anon;
grant execute on function public.record_activity() to authenticated;

create function public.purge_abandoned_anonymous_users()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  cutoff timestamptz := now() - interval '12 months';
  victim uuid;
  removed integer := 0;
begin
  for victim in
    select u.id
    from auth.users u
    where u.is_anonymous
      and greatest(
        u.created_at,
        coalesce(u.last_sign_in_at, u.created_at),
        coalesce((select max(s.updated_at) from auth.sessions s where s.user_id = u.id), u.created_at),
        coalesce((select max(p.synced_at) from public.profiles p where p.user_id = u.id), u.created_at)
      ) < cutoff
  loop
    perform public.erase_user_data(victim);
    removed := removed + 1;
  end loop;
  return removed;
end;
$$;
revoke all on function public.purge_abandoned_anonymous_users() from public, anon, authenticated;

select cron.schedule(
  'purge-abandoned-anonymous-users',
  '47 3 * * *',
  $$select public.purge_abandoned_anonymous_users()$$
);
