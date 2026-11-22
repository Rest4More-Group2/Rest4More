import 'dart:io' as io;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/enums.dart';
import '../data/moments/strict_night_log.dart';
import '../data/progress/moment_records.dart';
import '../data/progress/progress_analytics.dart';
import '../data/progress/progress_settings.dart';
import '../data/repositories/session_end_reason_repository.dart';
import 'database_providers.dart';
import 'repository_providers.dart';

/// De klok van Progress. Tests zetten hier een vaste tijd in.
final progressClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

final progressSettingsStoreProvider = Provider((ref) => ProgressSettingsStore());

/// Avondstart, eerste dag van de week en het weggeklikte inzicht.
final progressSettingsProvider =
    NotifierProvider<ProgressSettingsNotifier, ProgressSettings>(
      ProgressSettingsNotifier.new,
    );

class ProgressSettingsNotifier extends Notifier<ProgressSettings> {
  @override
  ProgressSettings build() {
    _load();
    return const ProgressSettings();
  }

  Future<void> _load() async {
    try {
      state = await ref.read(progressSettingsStoreProvider).load();
    } on Object {
      // Zonder opslag gelden de standaardwaarden.
    }
  }

  Future<void> _set(ProgressSettings next) async {
    state = next;
    try {
      await ref.read(progressSettingsStoreProvider).save(next);
    } on Object {
      // Alleen deze keer: de keuze blijft tot de app sluit.
    }
  }

  Future<void> setEveningStart(int minutes) =>
      _set(state.copyWith(eveningStartMinutes: minutes));

  Future<void> setWeekStart(int weekday) =>
      _set(state.copyWith(weekStart: weekday));

  Future<void> dismissInsight(String signature) =>
      _set(state.copyWith(dismissedInsight: signature));
}

final sessionEndReasonRepositoryProvider = Provider(
  (ref) => SessionEndReasonRepository(ref.watch(databaseProvider)),
);

final endReasonsProvider = StreamProvider<Map<String, EndReason>>(
  (ref) => ref.watch(sessionEndReasonRepositoryProvider).watchAll(),
);

final strictNightLogProvider = Provider(
  (ref) => StrictNightLog(
    ref.watch(focusSessionRepositoryProvider),
    PrefsStrictNightStash(),
    platform: io.Platform.isIOS
        ? SessionPlatform.ios
        : io.Platform.isAndroid
        ? SessionPlatform.android
        : SessionPlatform.unknown,
  ),
);

/// Het rekenwerk over alle afgeronde momenten, met de huidige instellingen.
final progressAnalyticsProvider = Provider<AsyncValue<ProgressAnalytics>>((
  ref,
) {
  final sessions = ref.watch(sessionHistoryProvider);
  final reasons = ref.watch(endReasonsProvider);
  final settings = ref.watch(progressSettingsProvider);
  for (final part in <AsyncValue<Object>>[sessions, reasons]) {
    if (part.hasError) {
      return AsyncValue.error(part.error!, part.stackTrace ?? StackTrace.empty);
    }
  }
  if (!sessions.hasValue || !reasons.hasValue) {
    return const AsyncValue.loading();
  }
  return AsyncValue.data(
    ProgressAnalytics(
      records: momentRecords(sessions.value!, reasons.value!),
      now: ref.watch(progressClockProvider)(),
      eveningStartMinutes: settings.eveningStartMinutes,
      weekStart: settings.weekStart,
    ),
  );
});
