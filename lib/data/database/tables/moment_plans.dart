import 'package:drift/drift.dart';

import '../converters.dart';
import '../enums.dart';
import '../sync_columns.dart';

/// Het plan van een moment (avond of ochtend): weekschema, stappen en
/// instellingen als één json-document. Per soort geldt de nieuwste levende
/// rij; twee toestellen kunnen elk een rij aanmaken, dus er is bewust geen
/// unieke index. De repository ruimt dubbelen op bij het bewaren.
class MomentPlans extends Table with SyncColumns {
  TextColumn get kind => text().map(
      const DbEnumConverter(MomentPlanKind.values, MomentPlanKind.unknown))();

  /// Json-tekst van het plan, met een `version`.
  TextColumn get plan => text()();
}
