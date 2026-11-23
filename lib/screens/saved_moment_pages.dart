import 'package:rest4more/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rest4more/data/moments/moment_plans.dart';
import 'package:rest4more/data/moments/moment_schedule.dart';
import 'package:rest4more/providers/repository_providers.dart';

import 'evening_screen.dart';
import 'morning_screen.dart';
import 'manual_routine_screen.dart';

import 'package:rest4more/providers/notification_providers.dart';

import 'package:rest4more/data/moments/moment_profiles.dart';

import 'today_screen.dart' show RestPalette;

/// Avondpagina met het bewaarde plan. Opslaan schrijft het plan weg en sluit
/// de pagina; mislukt dat, dan blijft de pagina open met de invoer erin.
class SavedEveningScreen extends ConsumerWidget {
  const SavedEveningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.read(momentPlanStoreProvider);
    final scheduler = ref.read(reminderSchedulerProvider);
    final l10n = AppLocalizations.of(context);
    final isDutch = Localizations.localeOf(context).languageCode == 'nl';

    Future<void> saveEvening(
      EveningPlan plan, {
      DateTime? startingEvening,
    }) async {
      await store.saveEvening(plan);

      final now = DateTime.now();
      final duration = totalMinutes(plan.steps);

      // Yesterday can still be the relevant evening after midnight.
      // Queue the next seven calendar days as well.
      for (var offset = -1; offset < 7; offset++) {
        final date = DateTime(now.year, now.month, now.day + offset);
        final day = plan.days.firstWhere(
          (entry) => entry.weekday == date.weekday,
        );

        if (!day.enabled ||
            plan.steps.isEmpty ||
            DateUtils.isSameDay(date, startingEvening)) {
          await scheduler.cancelEveningReminders(date);
          continue;
        }

        final times = eveningTimes(
          eveningDate: date,
          bedtimeMinutes: day.bedtimeMinutes,
          windDownLeadMinutes: plan.windDownLeadMinutes,
          blockLeadMinutes: duration,
          graceMinutes: plan.secondReminderMinutes,
        );

        final startTime = formatTime(times.blockStart);

        await scheduler.scheduleEveningReminders(
          eveningDate: date,
          startsAt: times.blockStart,
          headsUpAt: times.windDown,
          followUpAt: plan.secondReminderMinutes == 0
              ? null
              : times.reminderIfNotStarted,
          headsUpTitle: isDutch
              ? 'Je avondroutine begint binnenkort'
              : 'Your evening routine starts soon',
          headsUpBody: isDutch
              ? 'Je routine begint om $startTime.'
              : 'Your routine starts at $startTime.',
          followUpTitle: isDutch
              ? 'Klaar voor je avondroutine?'
              : 'Ready to start your evening routine?',
          followUpBody: isDutch
              ? 'Tik om je avondroutine te openen.'
              : 'Tap to open your evening routine.',
        );
      }
    }

    return _SavedPage<EveningPlan>(
      load: () async => await store.loadEvening() ?? EveningPlan.initial(),
      builder: (plan) => EveningScreen(
        initial: plan,
        onSave: (updated) => saveAndClose(
          context,
          l10n.momentEveningTitle,
          () => saveEvening(updated),
        ),
        onStartNow: (updated) async {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final yesterday = DateTime(now.year, now.month, now.day - 1);
          final yesterdayPlan = updated.days.firstWhere(
            (day) => day.weekday == yesterday.weekday,
          );

          // If yesterday's enabled evening extends past midnight and its
          // bedtime is still ahead, Start now belongs to that evening.
          var eveningDate = today;
          if (yesterdayPlan.enabled && yesterdayPlan.bedtimeAfterMidnight) {
            final yesterdayTimes = eveningTimes(
              eveningDate: yesterday,
              bedtimeMinutes: yesterdayPlan.bedtimeMinutes,
              windDownLeadMinutes: updated.windDownLeadMinutes,
              blockLeadMinutes: totalMinutes(updated.steps),
              graceMinutes: updated.secondReminderMinutes,
            );
            if (now.isBefore(yesterdayTimes.bedtime)) {
              eveningDate = yesterday;
            }
          }

          try {
            await saveEvening(updated, startingEvening: eveningDate);
          } on Object {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.couldNotSaveEvening)),
              );
            }
            return;
          }

          if (!context.mounted) return;
          await Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => ManualRoutineScreen(
                kind: MomentKind.evening,
                minutes: totalMinutes(updated.steps),
                strict: updated.end == EveningEnd.atNextScan,
              ),
            ),
          );
        },
      ),
    );
  }
}

class SavedMorningScreen extends ConsumerWidget {
  const SavedMorningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.read(momentPlanStoreProvider);
    return _SavedPage(
      load: () async => await store.loadMorning() ?? MorningPlan.initial(),
      builder: (plan) => MorningScreen(
        initial: plan,
        onSave: (p) => saveAndClose(
          context,
          AppLocalizations.of(context).momentMorningTitle,
          () => store.saveMorning(p),
        ),
        onStartNow: (p) async {
          try {
            await store.saveMorning(p);
          } on Object {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(context).couldNotSaveMorning,
                  ),
                ),
              );
            }
            return;
          }
          if (!context.mounted) return;
          await Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => ManualRoutineScreen(
                kind: MomentKind.morning,
                minutes: totalMinutes(p.steps),
                strict: false,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Bewaart en meldt het resultaat. Toont "saved" pas als het wegschrijven echt
/// gelukt is.
Future<void> saveAndClose(
  BuildContext context,
  String name,
  Future<void> Function() save,
) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);
  try {
    await save();
  } on Object {
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.couldNotSaveMoment(name))),
    );
    return;
  }
  messenger.showSnackBar(SnackBar(content: Text(l10n.momentSaved(name))));
  navigator.pop();
}

class _SavedPage<T> extends StatefulWidget {
  const _SavedPage({required this.load, required this.builder});

  final Future<T> Function() load;
  final Widget Function(T plan) builder;

  @override
  State<_SavedPage<T>> createState() => _SavedPageState<T>();
}

class _SavedPageState<T> extends State<_SavedPage<T>> {
  late Future<T> _future = widget.load();

  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.hasData) return widget.builder(snapshot.data as T);
      return Scaffold(
        backgroundColor: RestPalette.background,
        body: Center(
          child: snapshot.hasError
              ? TextButton(
                  onPressed: () => setState(() => _future = widget.load()),
                  child: Text(AppLocalizations.of(context).couldNotLoad),
                )
              : const CircularProgressIndicator(color: RestPalette.primary),
        ),
      );
    },
  );
}
