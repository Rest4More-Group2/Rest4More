import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rest4more/l10n/app_localizations.dart';
import 'package:rest4more/providers/locale_providers.dart';
import 'package:rest4more/data/tags/tag_service.dart';

import 'moments_widgets.dart';
import 'paired_tags_screen.dart';
import 'today_screen.dart' show RestPalette, RestType;

class ProfileTab extends ConsumerStatefulWidget {
  const ProfileTab({super.key});

  @override
  ConsumerState<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<ProfileTab> {
  int? _tagCount;

  @override
  void initState() {
    super.initState();
    _loadTagCount();
  }

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
                  Text(l10n.profileSubtitle,
                      style: RestType.sans(16, color: RestPalette.accent)),
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
                                  Expanded(child: Text(l10n.nfcTagsTitle,
                                      style: RestType.serif(27))),
                                  const RestMomentIcon(
                                      index: 4,
                                      color: RestPalette.primary,
                                      size: 22),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(summary, style: RestType.sans(16,
                                  color: RestPalette.accent)),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Text(l10n.manageTags, style: RestType.sans(15,
                                      color: RestPalette.primary,
                                      weight: FontWeight.w600)),
                                  const Spacer(),
                                  const Icon(Icons.chevron_right, size: 24,
                                      color: RestPalette.primary),
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
