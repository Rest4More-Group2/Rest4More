import 'package:shared_preferences/shared_preferences.dart';

/// Instellingen voor Progress. Alleen lokaal, net als de taalkeuze.
class ProgressSettings {
  const ProgressSettings({
    this.eveningStartMinutes = defaultEveningStart,
    this.weekStart = DateTime.monday,
    this.dismissedInsight,
  });

  /// 21:00.
  static const defaultEveningStart = 21 * 60;

  /// Minuten sinds middernacht (0 tot 1439).
  final int eveningStartMinutes;

  /// `DateTime.weekday` van de eerste dag van de week.
  final int weekStart;

  /// Het laatst weggeklikte inzicht (zie `EarlyStopInsight.signature`).
  final String? dismissedInsight;

  ProgressSettings copyWith({
    int? eveningStartMinutes,
    int? weekStart,
    String? dismissedInsight,
  }) => ProgressSettings(
    eveningStartMinutes: eveningStartMinutes ?? this.eveningStartMinutes,
    weekStart: weekStart ?? this.weekStart,
    dismissedInsight: dismissedInsight ?? this.dismissedInsight,
  );
}

/// Bewaart [ProgressSettings] in SharedPreferences.
class ProgressSettingsStore {
  static const _eveningStartKey = 'progress_evening_start_minutes';
  static const _weekStartKey = 'progress_week_start';
  static const _dismissedKey = 'progress_dismissed_insight';

  Future<ProgressSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final evening = prefs.getInt(_eveningStartKey);
    final week = prefs.getInt(_weekStartKey);
    return ProgressSettings(
      eveningStartMinutes: evening != null && evening >= 0 && evening < 1440
          ? evening
          : ProgressSettings.defaultEveningStart,
      weekStart: week != null && week >= 1 && week <= 7
          ? week
          : DateTime.monday,
      dismissedInsight: prefs.getString(_dismissedKey),
    );
  }

  Future<void> save(ProgressSettings s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_eveningStartKey, s.eveningStartMinutes);
    await prefs.setInt(_weekStartKey, s.weekStart);
    final dismissed = s.dismissedInsight;
    if (dismissed == null) {
      await prefs.remove(_dismissedKey);
    } else {
      await prefs.setString(_dismissedKey, dismissed);
    }
  }
}
