# Rest4More
Group/Industry project for MA-MAD1 Group 2 

## Lokale database (Drift)

De app bewaart gebruikersdata lokaal in SQLite via [Drift](https://drift.simonbinder.eu).
De code staat in `lib/data/`, de providers in `lib/providers/`.

De gegenereerde code (`*.g.dart`) staat niet in git. Genereer die na het
ophalen van de repo en na elke wijziging aan tabellen of converters:

```bash
flutter pub get
flutter pub run build_runner build -d
```

Bij een schemawijziging: verhoog `schemaVersion` in `app_database.dart`, voeg
een migratiestap toe en maak een nieuwe dump, zodat migraties getest kunnen
worden:

```bash
flutter pub run drift_dev schema dump lib/data/database/app_database.dart drift_schemas/
flutter pub run drift_dev schema generate drift_schemas/ test/data/generated/
```

De tweede opdracht maakt de hulpbestanden voor `test/data/migration_test.dart`.
De gedeeltelijke unieke indexen staan niet in de dump en worden apart getest
in `test/data/partial_indexes_test.dart`.

Schrijf alleen via de repositories in `lib/data/repositories/`. Maak nooit zelf
een tweede `AppDatabase`, gebruik `databaseProvider`.

### Test op een toestel

De integratietest opent het echte databasebestand, sluit het en opent het
opnieuw. Draai hem op een toestel of emulator:

```bash
flutter test integration_test -d <device>
```

## Synchronisatie met Supabase (alleen push)

- De serverkant staat in `supabase/migrations/`. Pas die zelf toe na review:
  `supabase db push`. Zet ook anonieme aanmelding aan in het Supabase
  dashboard (Authentication > Sign In / Providers), of gebruik
  `supabase config push`.
- `lib/data/sync/sync_engine.dart` stuurt rijen met `dirty = 1` naar de server,
  ouders eerst, en markeert ze pas schoon na een gelukte upload. Er wordt niets
  verstuurd zonder `cloud_sync_consent_at` in het profiel.
- `lib/main.dart` start Supabase met `SUPABASE_URL` en
  `SUPABASE_PUBLISHABLE_KEY` (of `SUPABASE_ANON_KEY`). Start de app daarom met:
  `flutter run --dart-define-from-file=env.json`. Zonder die waarden werkt de
  app lokaal verder en wordt er niets gesynchroniseerd.
- `SyncScheduler` pusht hooguit een keer per dag: bij het openen van de app en
  als de app weer naar voren komt, zolang het vandaag nog niet is gelukt. Bij
  een fout probeert hij het elke 30 minuten opnieuw zolang de app open is. De
  dag van de laatste gelukte push staat in `shared_preferences`.
- Er is nog geen pull.

### Synchronisatie testen zonder toestemmingsscherm

Start een debugbuild met de testvlag. Die geeft toestemming en wist de
"vandaag al gepusht"-markering, zodat er direct wordt gepusht:

```bash
flutter run --dart-define-from-file=env.json --dart-define=DEBUG_SYNC=true
```

De vlag maakt ook een keer voorbeelddata aan in elke gesynchroniseerde tabel
(profiel, blokkeerprofiel, routine, kaart, focussessie, programma met 14
dagen). In de console verschijnt een regel `[sync] ok=... pushed=...`. Controleer daarna
in de Supabase table editor of `profiles` een rij heeft met een `user_id`. De
vlag werkt alleen in debugbuilds.

## AVG: cloudgegevens exporteren en verwijderen

- Serverkant: `supabase/migrations/20261005000002_gdpr_functions.sql` met
  `export_my_data()` (alle rijen van de gebruiker als json) en
  `delete_my_data()` (wist alle rijen echt en daarna het account). Pas toe met
  `supabase db push`.
- App: `CloudDataService` (`cloudDataServiceProvider`) heeft `exportAsJson()` en
  `deleteCloudData()`. Verwijderen zet synchronisatie uit en laat de lokale
  gegevens staan, gemarkeerd als nog te uploaden voor een nieuw account.
- Er is nog geen scherm voor. Back-ups van Supabase kunnen gewiste gegevens nog
  een tijd bevatten, neem dat op in de privacyverklaring.

### Export en verwijdering proberen op de echte server

Alleen debugbuilds. Combineer met `DEBUG_SYNC=true`, zodat er data en
toestemming zijn:

```bash
flutter run --dart-define-from-file=env.json --dart-define=DEBUG_SYNC=true --dart-define=DEBUG_GDPR=export
```

Met `DEBUG_GDPR=delete` wordt daarna ook alles in de cloud gewist. Zonder
`DEBUG_GDPR` gebeurt er niets. In de console verschijnen regels met `[gdpr]`,
nooit de inhoud van de gegevens.

## Bewaartermijn: verwijderde rijen na 2 jaar wissen

- Lokaal: `RetentionService` wist bij het opstarten zacht verwijderde rijen
  ouder dan 2 jaar. Een verwijdering die nog niet naar de server is gestuurd
  blijft staan zolang er toestemming voor synchronisatie is.
- Server: `supabase/migrations/20261005000003_purge_old_tombstones.sql` maakt
  `purge_old_tombstones()` en plant die dagelijks om 03:17 met `pg_cron`. Zet
  de extensie `pg_cron` zo nodig eerst aan in het dashboard (Integrations).

## Verlaten anonieme accounts

- `supabase/migrations/20261005000004_abandoned_anonymous_accounts.sql` wist
  dagelijks (03:47, `pg_cron`) anonieme accounts zonder activiteit in 12
  maanden, met al hun gegevens. Activiteit is de laatste van aanmaken, laatste
  aanmelding, laatste sessie en `profiles.synced_at`.
- De app raakt `profiles.synced_at` dagelijks aan via `record_activity()` na
  een gelukte push, ook als er niets te uploaden valt. Zonder toestemming voor
  synchronisatie is er geen servercopy en dus ook geen account om op te ruimen.
- Komt een opgeruimde gebruiker terug, dan maakt de app een nieuw anoniem
  account en stuurt alle lokale gegevens opnieuw mee (`SyncEngine` onthoudt
  het laatste account-id).
