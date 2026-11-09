import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/programme/plan_adjustment.dart';
import '../data/programme/plan_explanation.dart';
import '../data/programme/plan_input.dart';
import 'database_providers.dart';
import 'locale_providers.dart';
import 'plan_providers.dart';
import 'repository_providers.dart';

final planAdjustmentServiceProvider = Provider(
  (ref) => PlanAdjustmentService(
    ref.watch(databaseProvider),
    ref.watch(contentCatalogLoaderProvider),
    l10n: () => ref.read(l10nProvider),
  ),
);

/// "Why we chose this for you" bij het huidige plan. Null zonder doel.
final planExplanationProvider =
    FutureProvider.autoDispose<PlanExplanation?>((ref) async {
  final l10n = ref.watch(l10nProvider);
  final profile = await ref.watch(profileRepositoryProvider).get();
  final input = PlanInput.fromProfile(profile, l10n: l10n);
  if (input == null) return null;
  final catalog = await ref.watch(contentCatalogLoaderProvider)();
  return PlanExplanation.build(input, catalog,
      windDownStartMinutes: profile.bedtimeMinutes, l10n: l10n);
});
