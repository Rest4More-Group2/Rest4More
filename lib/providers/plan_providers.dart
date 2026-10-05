import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/programme/content_catalog.dart';
import '../data/programme/plan_input.dart';
import '../data/programme/plan_preview.dart';
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

/// Het voorbeeldplan op basis van de antwoorden tot nu toe. Null als er nog
/// geen doel is gekozen. Wordt elke keer opnieuw berekend, zodat een gewijzigd
/// antwoord meteen zichtbaar is.
final planPreviewProvider = FutureProvider.autoDispose<PlanPreview?>((ref) async {
  final profile = await ref.watch(profileRepositoryProvider).get();
  final input = PlanInput.fromProfile(profile);
  if (input == null) return null;
  final catalog = await ref.watch(contentCatalogLoaderProvider)();
  return PlanPreview.build(input, catalog);
});

/// De huidige dag voor het Today-scherm. Null als er (nog) geen plan is.
final todayPlanProvider = Provider<AsyncValue<TodayPlan?>>((ref) {
  final days = ref.watch(programmeDaysProvider);
  return days.whenData((list) => pickToday(list, DateTime.now()));
});
