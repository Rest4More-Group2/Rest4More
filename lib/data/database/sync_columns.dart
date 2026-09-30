import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// Gedeelde kolommen voor tabellen die later met de server worden
/// gesynchroniseerd. `user_id` staat hier bewust niet in: de server vult
/// die vanuit de sessie.
mixin SyncColumns on Table {
  /// Client-side UUID, zodat rijen offline aangemaakt kunnen worden.
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();

  /// Laatste wijziging, altijd UTC.
  DateTimeColumn get updatedAt => dateTime()();

  /// Zachte verwijdering. Rijen worden nooit echt gewist.
  DateTimeColumn get deletedAt => dateTime().nullable()();

  /// True zolang de wijziging nog niet naar de server is gestuurd.
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
