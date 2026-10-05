import 'dart:convert';

/// De inhoud van het programma (`assets/programme/programme_content.json`).
class ContentCatalog {
  ContentCatalog._(this.version, this.goals, this.obstacleActions, this._days);

  /// Bijvoorbeeld `1.0-en`.
  final String version;

  /// Doel-sleutel naar leesbare naam.
  final Map<String, String> goals;

  /// Belemmering-sleutel naar de actie.
  final Map<String, String> obstacleActions;
  final List<Map<String, Object?>> _days;

  factory ContentCatalog.parse(String json) {
    final data = jsonDecode(json) as Map<String, Object?>;
    return ContentCatalog._(
      data['version'] as String,
      Map<String, String>.from(data['goals'] as Map),
      Map<String, String>.from(data['obstacle_actions'] as Map),
      [
        for (final day in data['days'] as List)
          Map<String, Object?>.from(day as Map),
      ],
    );
  }

  /// De dagen van een doel, op volgorde.
  List<Map<String, Object?>> daysFor(String goal) => [
        for (final day in _days)
          if (day['goal'] == goal) day,
      ]..sort((a, b) => (a['day'] as int).compareTo(b['day'] as int));
}
