import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/programme/content_catalog.dart';
import '../data/programme/plan_input.dart';
import '../data/programme/plan_preview.dart';
import '../data/programme/plan_selector.dart';
import '../data/programme/plan_service.dart';
import '../data/programme/today_plan.dart';
import 'database_providers.dart';
import 'locale_providers.dart';
import 'repository_providers.dart';

/// Laadt de inhoud van het programma in de gekozen taal. Tests vervangen dit.
final contentCatalogLoaderProvider = Provider<Future<ContentCatalog> Function()>(
  (ref) => () async {
    final language = ref.read(l10nProvider).localeName;
    final file = language == 'en'
        ? 'programme_content.json'
        : 'programme_content_$language.json';
    return ContentCatalog.parse(
      await rootBundle.loadString('assets/programme/$file'),
    );
  },
);

final planServiceProvider = Provider(
  (ref) => PlanService(
    ref.watch(databaseProvider),
    ref.watch(contentCatalogLoaderProvider),
    l10n: () => ref.read(l10nProvider),
  ),
);

/// Het voorbeeldplan op basis van de antwoorden tot nu toe. Null als er nog
/// geen doel is gekozen. Wordt elke keer opnieuw berekend, zodat een gewijzigd
/// antwoord meteen zichtbaar is.
final planPreviewProvider = FutureProvider.autoDispose<PlanPreview?>((ref) async {
  final l10n = ref.watch(l10nProvider);
  final profile = await ref.watch(profileRepositoryProvider).get();
  final input = PlanInput.fromProfile(profile, l10n: l10n);
  if (input == null) return null;
  final catalog = await ref.watch(contentCatalogLoaderProvider)();
  return PlanPreview.build(input, catalog, l10n: l10n);
});

/// De huidige dag voor het Today-scherm. Null als er (nog) geen plan is.
final todayPlanProvider = Provider<AsyncValue<TodayPlan?>>((ref) {
  final days = ref.watch(programmeDaysProvider);
  // Tot de vertaling klaar is, staat de bewaarde tekst er gewoon.
  final localized = ref.watch(localizedPlanDaysProvider).value ?? const {};
  return days
      .whenData((list) => pickToday(list, DateTime.now(), localized: localized));
});

/// De taal waarin een bewaarde dag is geschreven, uit `content_version`
/// (bijvoorbeeld `1.0-nl`). Null als dat er niet in staat.
String? _snapshotLanguage(Map<String, Object?> snapshot) {
  final version = snapshot['content_version'];
  if (version is! String || !version.contains('-')) return null;
  return version.split('-').last;
}

/// De dagen van het lopende plan in de huidige taal, per dagnummer. Leeg zolang
/// de bewaarde tekst al in die taal is. Er wordt niets in de database veranderd:
/// het bewaarde plan blijft zoals de gebruiker het kreeg, en de tekst wordt bij
/// het tonen opnieuw opgebouwd uit de inhoud en de antwoorden.
final localizedPlanDaysProvider =
    FutureProvider.autoDispose<Map<int, Map<String, Object?>>>((ref) async {
  final l10n = ref.watch(l10nProvider);
  final days = await ref.watch(programmeDaysProvider.future);
  final stale = [
    for (final d in days)
      if (d.deletedAt == null &&
          _snapshotLanguage(d.snapshot) != null &&
          _snapshotLanguage(d.snapshot) != l10n.localeName)
        d,
  ];
  if (stale.isEmpty) return const {};
  try {
    final profile = await ref.watch(profileRepositoryProvider).get();
    final input = PlanInput.fromProfile(profile, l10n: l10n);
    if (input == null) return const {};
    final catalog = await ref.watch(contentCatalogLoaderProvider)();
    return {
      for (final day in selectPlan(input, catalog, l10n: l10n))
        day['day'] as int: day,
    };
  } on Object {
    // Lukt het niet, dan blijft de bewaarde tekst staan.
    return const {};
  }
});
