import 'package:drift/drift.dart';

import '../converters.dart';
import '../enums.dart';
import 'focus_sessions.dart';

/// Alleen lokaal: waarom een moment eerder stopte. Staat los van
/// `focus_sessions`, omdat de sync alle kolommen van die tabel naar de server
/// stuurt en deze reden het toestel niet mag verlaten. Geen synckolommen.
class SessionEndReasons extends Table {
  TextColumn get sessionId => text()
      .references(FocusSessions, #id, onDelete: KeyAction.cascade)();
  TextColumn get reason => text()
      .map(const DbEnumConverter(EndReason.values, EndReason.unknown))();
  DateTimeColumn get recordedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {sessionId};
}
