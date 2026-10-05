import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/programme/content_catalog.dart';
import '../data/programme/plan_service.dart';
import '../data/programme/today_plan.dart';
import 'database_providers.dart';
import 'repository_providers.dart';

/// Laadt de inhoud van het programma. Tests vervangen dit.
final contentCatalogLoaderProvider = Provider<Future<ContentCatalog> Function()>(
  (ref) => () async => ContentCatalog.parse(
        await rootBundle.loadString('assets/programme/programme_content.json'),
      ),
);

final planServiceProvider = Provider(
  (ref) => PlanService(
    ref.watch(databaseProvider),
    ref.watch(contentCatalogLoaderProvider),
  ),
);

/// De huidige dag voor het Today-scherm. Null als er (nog) geen plan is.
final todayPlanProvider = Provider<AsyncValue<TodayPlan?>>((ref) {
  final days = ref.watch(programmeDaysProvider);
  return days.whenData((list) => pickToday(list, DateTime.now()));
});
