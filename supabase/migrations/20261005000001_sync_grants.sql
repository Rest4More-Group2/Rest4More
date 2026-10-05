-- Tabellen die via een migratie worden aangemaakt krijgen geen automatische
-- rechten voor de API-rollen. Row-level security blijft per rij bepalen wat
-- een gebruiker ziet en schrijft. Nooit delete: rijen worden zacht verwijderd.

grant select, insert, update on
  public.profiles,
  public.block_profiles,
  public.routines,
  public.accessories,
  public.focus_sessions,
  public.programme_enrollments,
  public.programme_days
to authenticated;

-- Entitlements: de app mag alleen lezen, de server schrijft.
grant select on public.entitlements to authenticated;
