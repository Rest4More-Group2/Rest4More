import 'package:flutter/material.dart';
import 'package:rest4more/data/tags/tag_service.dart';

import 'moments_widgets.dart';
import 'paired_tags_screen.dart';
import 'today_screen.dart' show RestPalette, RestType;

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
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
    final count = _tagCount;
    final summary = count == null
        ? 'Pair a tag to start and end moments with a tap.'
        : count == 0
            ? 'No tags paired yet.'
            : count == 1 ? '1 tag paired.' : '$count tags paired.';

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
                  Text('Profile', style: RestType.serif(40)),
                  const SizedBox(height: 8),
                  Text('Your settings and tags',
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
                                  Expanded(child: Text('NFC tags',
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
                                  Text('Manage tags', style: RestType.sans(15,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
