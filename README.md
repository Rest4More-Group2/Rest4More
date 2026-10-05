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

## Leeftijdsgrens en bewijs van toestemming

- **Onder de 16 geen cloudsync** (Nederlandse leeftijd voor digitale toestemming,
  AVG art. 8). Zonder bekende leeftijd ook niet. Dit wordt op drie plaatsen
  afgedwongen: `ProfileRepository.recordCloudSyncConsent` weigert (gooit
  `CloudSyncNotAllowedError`), een leeftijd onder 16 trekt bestaande toestemming
  meteen in, en `SyncEngine` verstuurt niets (`PushResult.skippedAgeGate`). Data
  die al in de cloud staat moet de aanroeper apart laten wissen met
  `CloudDataService.deleteCloudData()`.
- **Bewijs van toestemming**: elke toestemming of intrekking wordt als rij in
  `consent_records` vastgelegd, met de tekstversie
  (`currentCloudSyncPolicyVersion`). Verhoog die versie als de privacytekst
  verandert; `ConsentRepository.needsReconsent` laat dan opnieuw vragen. De
  tabel gaat mee naar de server (`20261005000005_consent_records.sql`).
- Lokaal schema is nu versie 2, met een geteste migratie van v1.

## Versleutelde lokale database en back-ups

- De database is versleuteld met SQLite3 Multiple Ciphers
  (`hooks.user_defines.sqlite3.source: sqlite3mc` in `pubspec.yaml`). De sleutel
  (32 willekeurige bytes) staat in de Keychain (iOS) of Keystore (Android) via
  `flutter_secure_storage`, nooit in de database of in een back-up.
- Een bestaand niet-versleuteld bestand wordt bij het openen ter plekke
  versleuteld. Past de sleutel niet meer bij het bestand (bijvoorbeeld na een
  herstelde back-up zonder sleutel), dan wordt het bestand opnieuw aangemaakt;
  bij synchronisatie komen de gegevens terug van de server.
- Het bestand staat in Application Support. Android: cloudback-up en
  toestel-naar-toestel-overdracht staan uit (`AndroidManifest.xml` en
  `res/xml/data_extraction_rules.xml`). iOS: `AppDelegate` sluit die map uit van
  back-ups. Wissel je van toestel, dan komen de gegevens terug via de cloud (zodra
  de pull er is).
- Eerste build haalt de sqlite3mc-bibliotheek op van GitHub (netwerk nodig).

## Cloud wissen na intrekken, lokaal exporteren en wissen

- Toestemming intrekken of een leeftijd onder 16 laat de cloudgegevens niet
  staan: zolang er geen toestemming is maar wel een bekend serveraccount, wordt
  de cloud gewist. `CloudDataService.withdrawConsent()` doet dit meteen en
  `completePendingErasure()` maakt het af, ook bij het openen van de app
  (`SyncScheduler.beforePush`) en bij een mislukte poging zonder verbinding.
- `LocalDataService.exportAsJson()` geeft alles op het toestel. `wipeEverything()`
  trekt eerst de cloud in en maakt daarna alle tabellen leeg met `VACUUM`. Lukt de
  cloud niet, dan blijft die verwijdering openstaan.

## Pull (gegevens van de server ophalen)

- `PullEngine` haalt per tabel wijzigingen op via `synced_at` (met `id` als
  tiebreaker, en 2 minuten overlap omdat de server de tijd bij het begin van een
  transactie zet). Een nieuwere `updated_at` wint, op de server en lokaal. Opgehaalde
  rijen zijn nooit `dirty`. Rijen die lokaal niet passen worden overgeslagen en
  geteld.
- Een leeg, nieuw aangemaakt lokaal profiel wordt vervangen door dat van de
  server. Een profiel met gegevens blijft staan en wordt als conflict gemeld.
- Rechten komen als volledige lijst en vervangen de lokale.
- De voortgang staat in de tabel `sync_cursors` (schema v3), dus die verdwijnt met
  de gegevens. Een andere account-id, wissen of intrekken zet hem terug.
- De scheduler doet bij het openen: openstaande verwijdering, pull, push, in die
  volgorde, hooguit een keer per dag. Mislukt de pull, dan wordt er niet gepusht.
- Met anoniem inloggen heeft een herinstallatie een nieuw account, dus de pull
  helpt daar niet. Hij helpt bij een opnieuw aangemaakte database terwijl de
  sessie blijft, en straks bij meerdere toestellen met een echt account.
- Proberen op de echte server (alleen debug), na eerst `DEBUG_SYNC=true` te hebben
  gedraaid:

```bash
flutter run --dart-define-from-file=env.json --dart-define=DEBUG_PULL=true
```

  Dit maakt de lokale gegevens leeg (de cloud blijft staan) en haalt alles terug.

## Lege lokale database bij het testen (debug)

Met `DEBUG_RESET=true` wordt de lokale database bij het opstarten leeggemaakt
en vergeet de app de synchronisatiestand, zodat de onboarding weer bij het
begin start. De cloud blijft ongemoeid. Werkt alleen in debugbuilds. Elke
start, ook een hot restart (R), wist opnieuw; een hot reload niet.

```bash
flutter run --dart-define-from-file=env.json --dart-define=DEBUG_RESET=true
```

In Android Studio: Run, Edit Configurations, kies de Flutter-configuratie voor
`main.dart`, en zet bij "Additional run args" (Android Studio-veld voor extra
argumenten):

```
--dart-define-from-file=env.json --dart-define=DEBUG_RESET=true
```

Maak daarvoor het liefst een tweede configuratie ("Fresh start"), naast de
gewone zonder de vlag. Zonder `env.json` laat je het eerste deel weg.
