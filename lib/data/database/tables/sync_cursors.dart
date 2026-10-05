import 'package:drift/drift.dart';

/// Alleen lokaal: hoe ver de pull per tabel is. Staat bewust in de database
/// zelf, zodat de voortgang samen met de gegevens verdwijnt. Wordt de database
/// opnieuw aangemaakt of gewist, dan begint de pull weer van voren af aan.
class SyncCursors extends Table {
  TextColumn get targetTable => text()();

  /// `synced_at` van de laatst opgehaalde rij van de server, zoals de server
  /// die teruggaf.
  TextColumn get cursor => text()();

  @override
  Set<Column> get primaryKey => {targetTable};
}
