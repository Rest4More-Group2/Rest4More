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
