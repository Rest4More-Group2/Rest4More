-- Bewaartermijn: zacht verwijderde rijen (`deleted_at`) worden na 2 jaar echt
-- gewist. De app doet hetzelfde lokaal met dezelfde regel.
--
-- Kinderen eerst. Een profiel blijft staan zolang er nog een deelname naar
-- verwijst. Verwijderingen via de foreign keys (set null, cascade) gedragen
-- zich op de server en in de app hetzelfde.

create function public.purge_old_tombstones()
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

-- Alleen de database zelf (pg_cron) draait dit, nooit een app-gebruiker.
revoke all on function public.purge_old_tombstones() from public, anon, authenticated;

-- Dagelijks, 's nachts. Vereist de extensie pg_cron.
create extension if not exists pg_cron with schema pg_catalog;

select cron.schedule(
  'purge-old-tombstones',
  '17 3 * * *',
  $$select public.purge_old_tombstones()$$
);
