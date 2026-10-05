-- Rechten van betrokkenen (AVG): inzage/export en verwijdering van de
-- cloudgegevens van de ingelogde gebruiker. Alleen `authenticated` mag ze
-- aanroepen, en elke functie werkt alleen op `auth.uid()`.

-- Export: alle rijen van de gebruiker, inclusief zacht verwijderde. Draait als
-- de aanroeper, dus row-level security beperkt het tot eigen rijen.
create function public.export_my_data()
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
    'block_profiles', coalesce((select jsonb_agg(to_jsonb(t)) from public.block_profiles t), '[]'::jsonb),
    'routines', coalesce((select jsonb_agg(to_jsonb(t)) from public.routines t), '[]'::jsonb),
    'accessories', coalesce((select jsonb_agg(to_jsonb(t)) from public.accessories t), '[]'::jsonb),
    'focus_sessions', coalesce((select jsonb_agg(to_jsonb(t)) from public.focus_sessions t), '[]'::jsonb),
    'programme_enrollments', coalesce((select jsonb_agg(to_jsonb(t)) from public.programme_enrollments t), '[]'::jsonb),
    'programme_days', coalesce((select jsonb_agg(to_jsonb(t)) from public.programme_days t), '[]'::jsonb),
    'entitlements', coalesce((select jsonb_agg(to_jsonb(t)) from public.entitlements t), '[]'::jsonb)
  );
$$;

-- Verwijdering: wist echt alle rijen van de gebruiker en daarna het account.
-- Draait als eigenaar, want de app heeft geen delete-rechten op de tabellen.
-- Kinderen eerst, zodat geen enkele verwijzing in de weg zit.
create function public.delete_my_data()
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

revoke all on function public.export_my_data() from public, anon;
revoke all on function public.delete_my_data() from public, anon;
grant execute on function public.export_my_data() to authenticated;
grant execute on function public.delete_my_data() to authenticated;
