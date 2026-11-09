import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rest4more/l10n/app_localizations.dart';
import 'package:rest4more/providers/locale_providers.dart';
import 'package:rest4more/data/notifications/notification_permission.dart';
import 'package:rest4more/data/tags/tag_service.dart';
import 'package:rest4more/providers/notification_providers.dart';
import 'package:rest4more/providers/repository_providers.dart';

import 'moments_widgets.dart';
import 'onboarding/notification_permission_flow.dart';
import 'paired_tags_screen.dart';
import 'today_screen.dart' show RestPalette, RestType;

/// Het profiel: de dagelijkse herinnering (aan of uit en hoe laat) en de
/// gekoppelde NFC-tags.
class ProfileTab extends ConsumerStatefulWidget {
  const ProfileTab({super.key});

  @override
  ConsumerState<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<ProfileTab>
    with WidgetsBindingObserver {
  /// Zelfde standaard als in de onboarding.
  static const _defaultMinutes = 22 * 60;

  /// Bezig met de toestemming, zodat een tweede tik niets dubbel doet.
  bool _busy = false;

  /// Naar de instellingen gestuurd om meldingen aan te zetten.
  bool _sentToSettings = false;

  int? _tagCount;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadTagCount();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Terug uit de instellingen met meldingen aan: dan staat de herinnering
  /// ook aan, zoals de gebruiker wilde.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !_sentToSettings) return;
    _sentToSettings = false;
    _enableIfGranted();
  }

  Future<void> _enableIfGranted() async {
    final status = await reminderPermissionStatus(ref);
    if (status != NotificationPermissionStatus.granted) return;
    await _save(enabled: true, minutes: _minutes);
  }

  int get _minutes =>
      ref.read(profileProvider).value?.notifyTimeMinutes ?? _defaultMinutes;

  Future<void> _save({required bool enabled, int? minutes}) async {
    await ref
        .read(profileRepositoryProvider)
        .setNotification(enabled: enabled, minutes: minutes);
    await ref.read(reminderServiceProvider).sync();
  }

  Future<void> _toggle(bool on) async {
    if (_busy) return;
    if (!on) return _save(enabled: false);
    setState(() => _busy = true);
    try {
      final minutes = _minutes;
      final outcome = await askReminderPermission(
        context,
        ref,
        time: _format(minutes),
      );
      switch (outcome) {
        case ReminderPermissionOutcome.granted:
          await _save(enabled: true, minutes: minutes);
        case ReminderPermissionOutcome.sentToSettings:
          _sentToSettings = true;
        case ReminderPermissionOutcome.declined:
        case ReminderPermissionOutcome.dismissed:
          break;
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickTime() async {
    final minutes = _minutes;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
    );
    if (picked == null) return;
    await _save(enabled: true, minutes: picked.hour * 60 + picked.minute);
  }

  String _format(int minutes) =>
      TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60).format(context);

  Future<void> _loadTagCount() async {
    try {
      final tags = await TagService.getKnownTags();
      if (mounted) setState(() => _tagCount = tags.length);
    } catch (e) {
      debugPrint('MethodChannel error: $e');
    }
  }

  Future<void> _openTags() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const PairedTagsScreen()),
    );
    if (mounted) await _loadTagCount();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(profileProvider).value;
    final enabled = profile?.notifyProgramme ?? false;
    final minutes = profile?.notifyTimeMinutes ?? _defaultMinutes;
    final count = _tagCount;
    final summary = count == null
        ? l10n.tagsPairPrompt
        : count == 0
        ? l10n.tagsNonePaired
        : l10n.tagsPaired(count);

    return Scaffold(
      backgroundColor: RestPalette.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.profileTitle, style: RestType.serif(40)),
                  const SizedBox(height: 8),
                  Text(
                    l10n.profileSubtitle,
                    style: RestType.sans(16, color: RestPalette.accent),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    l10n.reminders.toUpperCase(),
                    style: RestType.sans(
                      11,
                      color: RestPalette.accent,
                      weight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                    decoration: BoxDecoration(
                      color: RestPalette.surface,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.dailyReminderTitle,
                                    style: RestType.sans(
                                      16,
                                      weight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    l10n.dailyReminderSubtitle,
                                    style: RestType.sans(
                                      12,
                                      color: RestPalette.accent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: enabled,
                              activeThumbColor: Colors.white,
                              activeTrackColor: RestPalette.primary,
                              onChanged: _busy ? null : _toggle,
                            ),
                          ],
                        ),
                        if (enabled) ...[
                          const Divider(height: 24, color: RestPalette.border),
                          InkWell(
                            onTap: _pickTime,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.schedule_rounded,
                                    color: RestPalette.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      l10n.reminderTimeLabel,
                                      style: RestType.sans(14),
                                    ),
                                  ),
                                  Text(
                                    _format(minutes),
                                    style: RestType.sans(
                                      15,
                                      color: RestPalette.primary,
                                      weight: FontWeight.w600,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: RestPalette.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      enabled ? l10n.reminderOnNote : l10n.reminderOffNote,
                      style: RestType.sans(12, color: RestPalette.accent),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    decoration: BoxDecoration(
                      color: RestPalette.surface,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(22),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: _openTags,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      l10n.nfcTagsTitle,
                                      style: RestType.serif(27),
                                    ),
                                  ),
                                  const RestMomentIcon(
                                    index: 4,
                                    color: RestPalette.primary,
                                    size: 22,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                summary,
                                style: RestType.sans(
                                  16,
                                  color: RestPalette.accent,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Text(
                                    l10n.manageTags,
                                    style: RestType.sans(
                                      15,
                                      color: RestPalette.primary,
                                      weight: FontWeight.w600,
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(
                                    Icons.chevron_right,
                                    size: 24,
                                    color: RestPalette.primary,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _LanguageCard(l10n: l10n),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageCard extends ConsumerWidget {
  const _LanguageCard({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeProvider)?.languageCode;
    final options = <(String?, String)>[
      (null, l10n.languageSystem),
      ('en', l10n.languageEnglish),
      ('nl', l10n.languageDutch),
    ];
    return Container(
      decoration: BoxDecoration(
        color: RestPalette.surface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.languageTitle, style: RestType.serif(27)),
              const SizedBox(height: 8),
              RadioGroup<String?>(
                groupValue: current,
                onChanged: (code) => ref
                    .read(localeProvider.notifier)
                    .set(code == null ? null : Locale(code)),
                child: Column(
                  children: [
                    for (final (code, label) in options)
                      RadioListTile<String?>(
                        value: code,
                        title: Text(label, style: RestType.sans(16)),
                        activeColor: RestPalette.primary,
                        contentPadding: EdgeInsets.zero,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
