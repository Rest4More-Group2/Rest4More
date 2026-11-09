# Translations

How the app is translated, and how to add or change text and languages. The app ships in English and Dutch. English is the default and the source of truth.

**Read this first if you only want to change a sentence:** open `lib/l10n/app_en.arb` and `lib/l10n/app_nl.arb`, edit the text, run `flutter gen-l10n`. That is all. The rest of this page is for adding new text, new screens, and new languages.

## How it fits together

| What | Where |
|---|---|
| Config for the generator | `l10n.yaml` |
| English text (the template) | `lib/l10n/app_en.arb` |
| Dutch text | `lib/l10n/app_nl.arb` |
| Generated Dart code | `lib/l10n/app_localizations*.dart` (**committed**, do not edit by hand) |
| Helpers for weekdays, durations and similar | `lib/l10n/format.dart` |
| Names of goals and obstacles, English fallback | `lib/l10n/plan_labels.dart` |
| The language the user chose | `lib/providers/locale_providers.dart` |
| The language picker | the Language card in `lib/screens/profile_tab.dart` |
| Dutch plan content (14 days x 3 goals) | `assets/programme/programme_content_nl.json` |
| Android native text | `android/app/src/main/res/values*/strings.xml` |
| iOS native text | `ios/Runner/*.lproj/InfoPlist.strings` |

The user picks a language on the **Profile** tab: System default, English or Nederlands. The choice is saved in `shared_preferences` and applies immediately.

## Change existing text

1. Find the key in `lib/l10n/app_en.arb` (search for the English sentence).
2. Edit the text in `app_en.arb` and in `app_nl.arb`.
3. Run:

   ```bash
   flutter gen-l10n
   ```

4. Commit the `.arb` files **and** the regenerated `app_localizations*.dart` files.

Tests find widgets by their English text (for example `find.text('Start today’s step')`). If you change an English sentence, search `test/` for it and update the test.

## Add new text to a screen

1. Add the key to **both** ARB files. Use a descriptive camelCase key.

   ```json
   // app_en.arb
   "saveEvening": "Save evening",
   // app_nl.arb
   "saveEvening": "Avond opslaan",
   ```

2. Run `flutter gen-l10n`.
3. Use it in the widget:

   ```dart
   import 'package:rest4more/l10n/app_localizations.dart';

   Text(AppLocalizations.of(context).saveEvening)
   ```

Reuse an existing key when the English text is the same (`back`, `done`, `continueLabel`, `tryAgain`, `cancel`, `save` and so on). Check `app_en.arb` first.

### Text with values

Use placeholders. Declare the type in the **English** file only, in an `@key` entry:

```json
// app_en.arb
"dayIsDone": "Day {day} is done.",
"@dayIsDone": { "placeholders": { "day": { "type": "int" } } },
// app_nl.arb
"dayIsDone": "Dag {day} is voltooid.",
```

```dart
AppLocalizations.of(context).dayIsDone(today.day)
```

Do not build sentences by gluing strings together in Dart. Word order differs between languages.

### Plurals

```json
"tagsPaired": "{count, plural, =1{1 tag paired.} other{{count} tags paired.}}",
"@tagsPaired": { "placeholders": { "count": { "type": "int" } } }
```

Dutch uses the same syntax with its own words (`=1{1 tag gekoppeld.} other{{count} tags gekoppeld.}`).

### Dates, weekdays and durations

- Weekday names: `localizedWeekday(context, DateTime.monday)` from `lib/l10n/format.dart`.
- "5 min" / "1 h 05 min": `localizedDuration(l10n, minutes)`.
- Names of the moments (Focus, Evening and so on): `momentKindName(l10n, kind)`. **Never translate `MomentKind.profileName`.** It is the key of the block profile in the database.

## Gotchas

- **`const` widgets.** `AppLocalizations.of(context)` is not a constant. If the analyzer says "Methods can't be invoked in constant expressions", remove the `const` from the widget that contains the text.
- **Never call `AppLocalizations.of(context)` in `initState`**, or in a method that runs synchronously from `initState`. It throws, and the screen then hangs. Look the text up in `build`, or after an `await` with a `mounted` check. Before an `await`, store it in a local variable (`final l10n = AppLocalizations.of(context);`) so the lint about `BuildContext` across async gaps stays quiet.
- **No `BuildContext`?** In providers and services use `ref.watch(l10nProvider)` from `locale_providers.dart`. In plain Dart code that has no language, take an optional `AppLocalizations? l10n` parameter and fall back to `englishL10n()` from `plan_labels.dart`. That keeps existing tests on English.
- **Tests that build their own `MaterialApp`** need the delegates, or every `AppLocalizations.of(context)` throws:

  ```dart
  MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: ...,
  )
  ```

  The screen tests that use `pumpScreen` from `onboarding_test_support.dart` already have this.
- **Do not translate data that users own or that is a key**: saved routine step titles, block profile names, tag ids, channel names.
- **The English plan text must stay identical to the clients' reference** (`select_plan.py`, checked by `plan_core_test.dart`). Do not reword the English `planWhyThis` or the English `programme_content.json` without checking that test.

## The plan content

The daily steps live in a JSON file, not in the ARB files, because they are written copy that a copywriter or translator should be able to edit in one place.

- English: `assets/programme/programme_content.json`
- Dutch: `assets/programme/programme_content_nl.json`

The loader picks `programme_content_<language>.json` for the current language, and the English file when the language is `en`. Keep the Dutch file in step with the English one:

- same days, same goals, same keys;
- keep the placeholders `{anchor}`, `{activity}` and `{activity_material}` exactly as they are in the English version, because the plan fills them in. The sentence has to read well with the Dutch phrases from the ARB file (`phraseReadingActivity` and the other `phrase...` keys);
- content ids use the language code (`rfm-nl-v1-d01-phone`).

`test/programme/plan_nl_test.dart` checks that the Dutch file has the same days and placeholders as the English one. Run it after editing the JSON.

### What happens to a plan when the language changes

A plan stores the text it was created with in `programme_days.snapshot`. That record stays as the user first saw it. When the user switches language, Today does not read that text any more. `localizedPlanDaysProvider` (in `lib/providers/plan_providers.dart`) rebuilds the day from the content file in the current language and the user's profile answers. Nothing is written to the database. The language of a stored day is read from its `content_version` (`1.0-nl`).

## Add a new language

Say you want German (`de`).

1. **ARB file.** Copy `lib/l10n/app_en.arb` to `lib/l10n/app_de.arb`, set `"@@locale": "de"` and translate every value. Leave the `@key` metadata out of the copy. Run `flutter gen-l10n`. Any missing key falls back to English, but the analyzer will tell you which ones.
2. **Picker.** In `lib/screens/profile_tab.dart` add the language to the `options` list, and add a `languageGerman` key (the language's own name, for example "Deutsch") to every ARB file.
3. **Plan content.** Copy `programme_content_nl.json` or the English file to `assets/programme/programme_content_de.json`. Translate the text fields, keep the keys and placeholders, set `version` and `content_version` to `1.0-de`, and change the ids to `rfm-de-...`. Translate the activity phrases in the ARB file too (the `phrase...` keys); the plan inserts them in the middle of sentences. Add a test like `plan_nl_test.dart`.
4. **Android.** Add `android/app/src/main/res/values-de/strings.xml` with the same keys as `values/strings.xml`.
5. **iOS.** Add `ios/Runner/de.lproj/InfoPlist.strings`, add `de` to `CFBundleLocalizations` in `ios/Runner/Info.plist`, and register the file and the region in `ios/Runner.xcodeproj/project.pbxproj`. The easiest way is to open the project in Xcode, select the project, add the language under *Info > Localizations*, and tick `InfoPlist.strings`. Then check the `git diff` of the project file.
6. Run the app with the phone set to the new language, and walk through onboarding, Today, a Focus session, the unblock flow and the Profile tab. Look for text that does not fit.

## Native text (Android and iOS)

Only a few strings live outside Flutter:

- Android: the toasts shown when a tag is scanned outside the app, and the accessibility service description (`strings.xml`). `TagLinks.kt` reads them with `context.getString(R.string.…)`.
- iOS: the NFC permission text and the display name (`InfoPlist.strings`).

The block screen that appears over a blocked app runs in its own Flutter engine (`blockMain` in `lib/main.dart`). Its `MaterialApp` has the localization delegates too. It follows the system language and does not read the choice made in the Profile tab.

## Not translated on purpose

- The prototype screens behind the `/prototype` and `/nfcScan` routes.
- Developer-facing error messages, for example the "hot reload" hint in `moment_apps_section.dart`, and the error codes passed to Dart from native code.
- Default routine step titles ("Shower", "Brush your teeth"). They are saved as the user's own data.
- Local notifications. Nothing schedules them yet. When it does, the notification titles and bodies for the plan are already in the programme JSON files, and any other wording needs ARB keys.

## Checklist before you open a pull request

- [ ] New text is in **both** `app_en.arb` and `app_nl.arb`.
- [ ] `flutter gen-l10n` was run and the generated files are committed.
- [ ] `flutter analyze lib` shows no new issues.
- [ ] If you changed the programme JSON: `flutter test test/programme` passes.
- [ ] You looked at the screen in Dutch, not just English.
- [ ] Tests that build their own `MaterialApp` include the localization delegates.
