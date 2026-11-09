import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rest4more/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _localeKey = 'app_locale';

/// De gekozen taal. Null volgt de taal van het systeem.
final localeProvider = NotifierProvider<LocaleNotifier, Locale?>(
  LocaleNotifier.new,
);

class LocaleNotifier extends Notifier<Locale?> {
  @override
  Locale? build() {
    _load();
    return null;
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_localeKey);
      if (code != null) state = Locale(code);
    } catch (_) {
      // Zonder opslag blijft de taal van het systeem gelden.
    }
  }

  Future<void> set(Locale? locale) async {
    state = locale;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (locale == null) {
        await prefs.remove(_localeKey);
      } else {
        await prefs.setString(_localeKey, locale.languageCode);
      }
    } catch (_) {
      // De keuze geldt dan alleen tot de app sluit.
    }
  }
}

/// De teksten in de gekozen taal, ook voor code zonder `BuildContext`. Zonder
/// keuze volgt dit de taal van het systeem, en is het Engels als die er niet
/// bij zit.
final l10nProvider = Provider<AppLocalizations>((ref) {
  final locale = ref.watch(localeProvider) ?? PlatformDispatcher.instance.locale;
  final supported = AppLocalizations.supportedLocales
      .any((l) => l.languageCode == locale.languageCode);
  return lookupAppLocalizations(Locale(supported ? locale.languageCode : 'en'));
});
