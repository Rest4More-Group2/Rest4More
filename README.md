# Rest4More
Group/Industry project for MA-MAD1 Group 2 

## Lokale database (Drift)

De app bewaart gebruikersdata lokaal in SQLite via [Drift](https://drift.simonbinder.eu).
De code staat in `lib/data/`, de providers in `lib/providers/`.

De gegenereerde code (`*.g.dart`) staat niet in git. Genereer die na het
ophalen van de repo en na elke wijziging aan tabellen of converters:

```bash
flutter pub get
dart run build_runner build -d
```

Bij een schemawijziging: verhoog `schemaVersion` in `app_database.dart`, voeg
een migratiestap toe en maak een nieuwe dump, zodat migraties getest kunnen
worden:

```bash
dart run drift_dev schema dump lib/data/database/app_database.dart drift_schemas/
```

Schrijf alleen via de repositories in `lib/data/repositories/`. Maak nooit zelf
een tweede `AppDatabase`, gebruik `databaseProvider`.

```bash
dart run drift_dev schema generate drift_schemas/ test/data/generated/
```

Draai dit na elke nieuwe dump, voor `test/data/migration_test.dart`.
