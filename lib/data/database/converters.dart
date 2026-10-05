import 'dart:convert';

import 'package:drift/drift.dart';

import 'enums.dart';

/// Zet een enum om naar tekst en terug. Gooit nooit: een onbekende tekst
/// wordt [fallback], zodat oude rijen leesbaar blijven.
class DbEnumConverter<T extends DbEnum> extends TypeConverter<T, String> {
  const DbEnumConverter(this.values, this.fallback);

  final List<T> values;
  final T fallback;

  @override
  T fromSql(String fromDb) {
    for (final value in values) {
      if (value.id == fromDb) return value;
    }
    return fallback;
  }

  @override
  String toSql(T value) => value.id;
}

T _enumFromId<T extends DbEnum>(List<T> values, T fallback, Object? id) {
  if (id is! String) return fallback;
  for (final value in values) {
    if (value.id == id) return value;
  }
  return fallback;
}

Object? _tryDecode(String source) {
  try {
    return jsonDecode(source);
  } catch (_) {
    return null;
  }
}

/// Een stap in een routine.
class RoutineStepData {
  const RoutineStepData({required this.title, this.durationMin});

  final String title;
  final int? durationMin;

  Map<String, dynamic> toJson() => {
        'title': title,
        'duration_min': durationMin,
      };

  /// Geeft null als de stap onleesbaar is.
  static RoutineStepData? tryFromJson(Object? json) {
    if (json is! Map) return null;
    final title = json['title'];
    if (title is! String) return null;
    final duration = json['duration_min'];
    return RoutineStepData(
      title: title,
      durationMin: duration is int ? duration : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is RoutineStepData &&
      other.title == title &&
      other.durationMin == durationMin;

  @override
  int get hashCode => Object.hash(title, durationMin);
}

/// Een regel in een blokkeerprofiel.
class BlockItemData {
  const BlockItemData({
    required this.kind,
    required this.value,
    this.rule = BlockItemRule.block,
  });

  final BlockItemKind kind;
  final String value;
  final BlockItemRule rule;

  Map<String, dynamic> toJson() => {
        'kind': kind.id,
        'value': value,
        'rule': rule.id,
      };

  /// Geeft null als de regel onleesbaar is. Een onbekende `kind` of `rule`
  /// wordt `unknown`.
  static BlockItemData? tryFromJson(Object? json) {
    if (json is! Map) return null;
    final value = json['value'];
    if (value is! String) return null;
    return BlockItemData(
      kind: _enumFromId(BlockItemKind.values, BlockItemKind.unknown, json['kind']),
      value: value,
      rule: _enumFromId(BlockItemRule.values, BlockItemRule.unknown, json['rule']),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BlockItemData &&
      other.kind == kind &&
      other.value == value &&
      other.rule == rule;

  @override
  int get hashCode => Object.hash(kind, value, rule);
}

/// Een gebeurtenis in het verloop van een focussessie.
class SessionEventData {
  const SessionEventData({
    required this.at,
    required this.event,
    this.fromState,
    this.toState,
    this.errorCode,
  });

  /// Tijdstip, altijd UTC.
  final DateTime at;
  final SessionEventType event;
  final SessionState? fromState;
  final SessionState? toState;
  final String? errorCode;

  Map<String, dynamic> toJson() => {
        'at': at.toUtc().toIso8601String(),
        'event': event.id,
        'from_state': fromState?.id,
        'to_state': toState?.id,
        'error_code': errorCode,
      };

  /// Geeft null als de gebeurtenis onleesbaar is (bijvoorbeeld zonder tijd).
  static SessionEventData? tryFromJson(Object? json) {
    if (json is! Map) return null;
    final atText = json['at'];
    final at = atText is String ? DateTime.tryParse(atText) : null;
    if (at == null) return null;
    SessionState? state(Object? id) => id is String
        ? _enumFromId(SessionState.values, SessionState.unknown, id)
        : null;
    final errorCode = json['error_code'];
    return SessionEventData(
      at: at.toUtc(),
      event: _enumFromId(
          SessionEventType.values, SessionEventType.unknown, json['event']),
      fromState: state(json['from_state']),
      toState: state(json['to_state']),
      errorCode: errorCode is String ? errorCode : null,
    );
  }
}

/// Basis voor jsonb-kolommen die een lijst bewaren. Onleesbare invoer geeft
/// een lege lijst, onleesbare items worden overgeslagen.
abstract class _JsonListConverter<T> extends TypeConverter<List<T>, String> {
  const _JsonListConverter();

  T? parseItem(Object? json);
  Object? encodeItem(T item);

  @override
  List<T> fromSql(String fromDb) {
    final decoded = _tryDecode(fromDb);
    if (decoded is! List) return const [];
    return [
      for (final item in decoded) ?parseItem(item),
    ];
  }

  @override
  String toSql(List<T> value) => jsonEncode([
        for (final item in value) encodeItem(item),
      ]);
}

class RoutineStepsConverter extends _JsonListConverter<RoutineStepData> {
  const RoutineStepsConverter();

  @override
  RoutineStepData? parseItem(Object? json) => RoutineStepData.tryFromJson(json);

  @override
  Object? encodeItem(RoutineStepData item) => item.toJson();
}

class BlockItemsConverter extends _JsonListConverter<BlockItemData> {
  const BlockItemsConverter();

  @override
  BlockItemData? parseItem(Object? json) => BlockItemData.tryFromJson(json);

  @override
  Object? encodeItem(BlockItemData item) => item.toJson();
}

class SessionEventsConverter extends _JsonListConverter<SessionEventData> {
  const SessionEventsConverter();

  @override
  SessionEventData? parseItem(Object? json) =>
      SessionEventData.tryFromJson(json);

  @override
  Object? encodeItem(SessionEventData item) => item.toJson();
}

/// Ongetypeerde jsonb-kolom (bijvoorbeeld `snapshot` en `selection`).
/// Onleesbare invoer geeft een lege map.
class JsonMapConverter extends TypeConverter<Map<String, dynamic>, String> {
  const JsonMapConverter();

  @override
  Map<String, dynamic> fromSql(String fromDb) {
    final decoded = _tryDecode(fromDb);
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return <String, dynamic>{};
  }

  @override
  String toSql(Map<String, dynamic> value) => jsonEncode(value);
}
