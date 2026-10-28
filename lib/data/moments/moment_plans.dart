import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../database/converters.dart' show RoutineStepData;
import '../database/enums.dart' show MomentPlanKind;
import '../repositories/moment_plan_repository.dart';
import 'moment_schedule.dart';

/// Instellingen van de avond.
class EveningPlan {
  const EveningPlan({
    required this.days,
    required this.steps,
    this.windDownLeadMinutes = 30,
    this.secondReminderMinutes = 0,
    this.end = EveningEnd.atBedtime,
  });

  /// Zeven dagen, maandag eerst.
  final List<EveningDay> days;

  /// De stappen van de avond, in volgorde. De bedtijd is het anker: de avond
  /// begint zoveel eerder als de stappen samen duren.
  final List<RoutineStepData> steps;

  /// Hoeveel eerder de herinnering voor de avond komt.
  final int windDownLeadMinutes;

  /// Tweede herinnering als je nog niet bent begonnen; 0 is uit.
  final int secondReminderMinutes;
  final EveningEnd end;

  factory EveningPlan.initial() => EveningPlan(
        days: [for (var d = 1; d <= 7; d++) EveningDay(weekday: d)],
        steps: starterEveningSteps,
      );

  EveningPlan copyWith({
    List<EveningDay>? days,
    List<RoutineStepData>? steps,
    int? windDownLeadMinutes,
    int? secondReminderMinutes,
    EveningEnd? end,
  }) =>
      EveningPlan(
        days: days ?? this.days,
        steps: steps ?? this.steps,
        windDownLeadMinutes: windDownLeadMinutes ?? this.windDownLeadMinutes,
        secondReminderMinutes:
            secondReminderMinutes ?? this.secondReminderMinutes,
        end: end ?? this.end,
      );

  Map<String, Object?> toJson() => {
        'days': [
          for (final d in days)
            {
              'weekday': d.weekday,
              'enabled': d.enabled,
              'bedtime_minutes': d.bedtimeMinutes,
            },
        ],
        'steps': [for (final s in steps) s.toJson()],
        'wind_down_lead_minutes': windDownLeadMinutes,
        'second_reminder_minutes': secondReminderMinutes,
        'end': end.name,
      };

  /// Leest een bewaard plan. Onleesbare of ontbrekende delen krijgen de
  /// beginwaarde, zodat een oud of beschadigd plan nooit de pagina breekt.
  static EveningPlan fromJson(Object? json) {
    final initial = EveningPlan.initial();
    if (json is! Map) return initial;
    final byDay = _daysByWeekday(json['days']);
    return EveningPlan(
      days: [
        for (var d = 1; d <= 7; d++)
          EveningDay(
            weekday: d,
            enabled: byDay[d]?['enabled'] is bool
                ? byDay[d]!['enabled'] as bool
                : true,
            bedtimeMinutes: _minutes(
              byDay[d]?['bedtime_minutes'],
              initial.days.first.bedtimeMinutes,
            ),
          ),
      ],
      steps: _steps(json['steps']) ?? initial.steps,
      windDownLeadMinutes:
          _positive(json['wind_down_lead_minutes'], initial.windDownLeadMinutes),
      secondReminderMinutes: _nonNegative(
          json['second_reminder_minutes'], initial.secondReminderMinutes),
      end: EveningEnd.values.firstWhere(
        (e) => e.name == json['end'],
        orElse: () => initial.end,
      ),
    );
  }
}

/// Instellingen van de ochtend.
class MorningPlan {
  const MorningPlan({required this.days, required this.steps});

  /// Zeven dagen, maandag eerst.
  final List<MorningDay> days;

  /// De stappen van de ochtend, in volgorde. De telefoon komt erna.
  final List<RoutineStepData> steps;

  factory MorningPlan.initial() => MorningPlan(
        days: [for (var d = 1; d <= 7; d++) MorningDay(weekday: d)],
        steps: starterMorningSteps,
      );

  MorningPlan copyWith({
    List<MorningDay>? days,
    List<RoutineStepData>? steps,
  }) =>
      MorningPlan(days: days ?? this.days, steps: steps ?? this.steps);

  Map<String, Object?> toJson() => {
        'days': [
          for (final d in days)
            {
              'weekday': d.weekday,
              'enabled': d.enabled,
              'wake_minutes': d.wakeMinutes,
            },
        ],
        'steps': [for (final s in steps) s.toJson()],
      };

  static MorningPlan fromJson(Object? json) {
    final initial = MorningPlan.initial();
    if (json is! Map) return initial;
    final byDay = _daysByWeekday(json['days']);
    return MorningPlan(
      days: [
        for (var d = 1; d <= 7; d++)
          MorningDay(
            weekday: d,
            enabled: byDay[d]?['enabled'] is bool
                ? byDay[d]!['enabled'] as bool
                : true,
            wakeMinutes:
                _minutes(byDay[d]?['wake_minutes'], initial.days.first.wakeMinutes),
          ),
      ],
      steps: _steps(json['steps']) ?? initial.steps,
    );
  }
}

Map<int, Map> _daysByWeekday(Object? raw) {
  final result = <int, Map>{};
  if (raw is List) {
    for (final item in raw) {
      if (item is Map && item['weekday'] is int) {
        result[item['weekday'] as int] = item;
      }
    }
  }
  return result;
}

/// Minuten sinds middernacht, begrensd op 0 tot 1439.
int _minutes(Object? value, int fallback) =>
    value is int && value >= 0 && value < 1440 ? value : fallback;

int _positive(Object? value, int fallback) =>
    value is int && value > 0 && value <= 600 ? value : fallback;

int _nonNegative(Object? value, int fallback) =>
    value is int && value >= 0 && value <= 600 ? value : fallback;

/// Geeft null als er geen lijst staat. Een bewust lege lijst blijft leeg.
List<RoutineStepData>? _steps(Object? raw) {
  if (raw is! List) return null;
  return [
    for (final item in raw)
      if (RoutineStepData.tryFromJson(item) case final step?)
        RoutineStepData(
          title: step.title,
          durationMin: (step.durationMin ?? defaultStepMinutes)
              .clamp(minStepMinutes, maxStepMinutes),
        ),
  ];
}

/// Bewaart de plannen van Avond en Ochtend. Alleen lokaal.
abstract interface class MomentPlanStore {
  /// Null als er nog niets bewaard is.
  Future<EveningPlan?> loadEvening();
  Future<void> saveEvening(EveningPlan plan);
  Future<MorningPlan?> loadMorning();
  Future<void> saveMorning(MorningPlan plan);
}

/// Bewaart elk plan als één json-tekst in `shared_preferences`. Het formaat
/// heeft een versie, zodat een latere wijziging oude plannen kan herkennen.
class PrefsMomentPlanStore implements MomentPlanStore {
  static const _eveningKey = 'moment_plan_evening';
  static const _morningKey = 'moment_plan_morning';
  static const version = 1;

  Future<Object?> _read(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final text = prefs.getString(key);
    if (text == null) return null;
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map && decoded['version'] == version) {
        return decoded['plan'];
      }
    } on FormatException {
      // Beschadigd: behandel als niet bewaard.
    }
    return null;
  }

  Future<void> _write(String key, Map<String, Object?> plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode({'version': version, 'plan': plan}));
  }

  @override
  Future<EveningPlan?> loadEvening() async {
    final raw = await _read(_eveningKey);
    return raw == null ? null : EveningPlan.fromJson(raw);
  }

  @override
  Future<void> saveEvening(EveningPlan plan) =>
      _write(_eveningKey, plan.toJson());

  @override
  Future<MorningPlan?> loadMorning() async {
    final raw = await _read(_morningKey);
    return raw == null ? null : MorningPlan.fromJson(raw);
  }

  @override
  Future<void> saveMorning(MorningPlan plan) =>
      _write(_morningKey, plan.toJson());
}

/// Bewaart de plannen in de lokale database, zodat ze mee kunnen met de
/// synchronisatie.
///
/// Een plan dat eerder in `shared_preferences` stond ([legacy]) wordt bij het
/// eerste lezen overgenomen: het gaat naar de database en wordt vanaf dan
/// gesynchroniseerd. Zo raakt niemand een bewaard plan kwijt.
class DbMomentPlanStore implements MomentPlanStore {
  DbMomentPlanStore(this._repository, {this.legacy});

  final MomentPlanRepository _repository;
  final MomentPlanStore? legacy;

  static const _version = PrefsMomentPlanStore.version;

  Object? _decode(String? text) {
    if (text == null) return null;
    try {
      final decoded = jsonDecode(text);
      return decoded is Map && decoded['version'] == _version ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  String _encode(Map<String, Object?> plan) =>
      jsonEncode({'version': _version, ...plan});

  @override
  Future<EveningPlan?> loadEvening() async {
    final raw = _decode(await _repository.get(MomentPlanKind.evening));
    if (raw != null) return EveningPlan.fromJson(raw);
    final old = await legacy?.loadEvening();
    if (old != null) await saveEvening(old);
    return old;
  }

  @override
  Future<void> saveEvening(EveningPlan plan) =>
      _repository.save(MomentPlanKind.evening, _encode(plan.toJson()));

  @override
  Future<MorningPlan?> loadMorning() async {
    final raw = _decode(await _repository.get(MomentPlanKind.morning));
    if (raw != null) return MorningPlan.fromJson(raw);
    final old = await legacy?.loadMorning();
    if (old != null) await saveMorning(old);
    return old;
  }

  @override
  Future<void> saveMorning(MorningPlan plan) =>
      _repository.save(MomentPlanKind.morning, _encode(plan.toJson()));
}
