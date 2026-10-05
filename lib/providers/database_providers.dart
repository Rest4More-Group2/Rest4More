import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/app_database.dart';

/// De enige `AppDatabase` van de app. Nog een instantie ergens anders opent
/// een tweede verbinding met hetzelfde bestand.
final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});
