import 'package:drift/drift.dart';

import '../converters.dart';
import '../enums.dart';
import '../sync_columns.dart';

/// Bewijs van toestemming: een rij per gegeven of ingetrokken toestemming, met
/// de versie van de tekst waar de gebruiker mee instemde. Rijen worden alleen
/// toegevoegd, nooit aangepast.
class ConsentRecords extends Table with SyncColumns {
  TextColumn get purpose => text().map(
      const DbEnumConverter(ConsentPurpose.values, ConsentPurpose.unknown))();

  /// Versie van de privacytekst die de gebruiker zag.
  TextColumn get policyVersion => text()();
  TextColumn get status => text().map(
      const DbEnumConverter(ConsentStatus.values, ConsentStatus.unknown))();

  /// Moment van instemmen of intrekken, UTC.
  DateTimeColumn get recordedAt => dateTime()();
}
