import 'package:rest4more/l10n/app_localizations.dart';
import 'package:rest4more/l10n/plan_labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rest4more/data/database/app_database.dart';
import 'package:rest4more/data/database/enums.dart';
import 'package:rest4more/data/intake/intake_service.dart';
import 'package:rest4more/data/programme/content_catalog.dart';
import 'package:rest4more/data/programme/plan_adjustment.dart';
import 'package:rest4more/data/programme/plan_explanation.dart';
import 'package:rest4more/data/programme/plan_input.dart';
import 'package:rest4more/data/programme/plan_preview.dart';
import 'package:rest4more/providers/intake_providers.dart';
import 'package:rest4more/providers/plan_adjustment_providers.dart';
import 'package:rest4more/providers/plan_providers.dart';
import 'package:rest4more/providers/repository_providers.dart';

import 'plan_why_card.dart';

/// Het plan aanpassen zonder de onboarding opnieuw te doen. Alleen wat de
/// gebruiker verandert wordt opgeslagen, en pas na bekijken en bevestigen.
/// Geeft `true` terug als er iets is veranderd.
class AdjustPlanScreen extends ConsumerStatefulWidget {
  const AdjustPlanScreen({super.key});

  @override
  ConsumerState<AdjustPlanScreen> createState() => _AdjustPlanScreenState();
}

class _AdjustPlanScreenState extends ConsumerState<AdjustPlanScreen> {
  static const Color background = Color(0xFFFCFAF7);
  static const Color brown = Color(0xFF8B6043);
  static const Color darkBrown = Color(0xFF5A4338);
  static const Color cardBackground = Color(0xFFF5F0E8);

  Profile? _profile;
  ContentCatalog? _catalog;

  PrimaryGoal? _goal;
  Obstacle? _obstacle;
  PreferredActivity? _activity;
  bool _smaller = false;

  bool _reviewing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await ref.read(profileRepositoryProvider).get();
    final catalog = await ref.read(contentCatalogLoaderProvider)();
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _catalog = catalog;
      _goal = profile.primaryGoal;
      _obstacle = profile.obstacle;
      _activity = profile.preferredActivity;
      _smaller = profile.stepSize == StepSize.short;
    });
  }

  PlanAdjustment get _adjustment => PlanAdjustment.between(
        _profile!,
        goal: _goal,
        obstacle: _obstacle,
        activity: _activity,
        smaller: _smaller,
      );

  bool get _canReview =>
      _goal != null && _goal != PrimaryGoal.unknown && !_adjustment.isEmpty;

  Future<void> _confirm() async {
    setState(() => _saving = true);
    try {
      await ref.read(planAdjustmentServiceProvider).confirm(_adjustment);
    } on Object {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).adjustSaveFailed),
        ),
      );
      return;
    }
    ref.invalidate(planPreviewProvider);
    ref.invalidate(planExplanationProvider);
    ref.invalidate(intakeProgressProvider);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final loaded = _profile != null && _catalog != null;
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: !loaded
            ? const Center(child: CircularProgressIndicator(color: brown))
            : Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () {
                        if (_reviewing) {
                          setState(() => _reviewing = false);
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back, size: 18, color: brown),
                          SizedBox(width: 6),
                          Text(
                            AppLocalizations.of(context).back,
                            style: TextStyle(
                              color: brown,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: _reviewing ? _buildReview() : _buildChoices(),
                    ),
                    const SizedBox(height: 18),
                    ..._buildButtons(),
                  ],
                ),
              ),
      ),
    );
  }

  List<Widget> _buildButtons() {
    if (!_reviewing) {
      return [
        _MainButton(
          label: AppLocalizations.of(context).reviewChanges,
          onPressed: _canReview ? () => setState(() => _reviewing = true) : null,
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context).keepCurrentPlan,
              style: TextStyle(
                color: brown,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ];
    }
    return [
      _MainButton(
        label: AppLocalizations.of(context).confirmChanges,
        onPressed: _saving ? null : _confirm,
      ),
      const SizedBox(height: 12),
      Center(
        child: TextButton(
          onPressed: _saving ? null : () => setState(() => _reviewing = false),
          child: Text(
            AppLocalizations.of(context).keepEditing,
            style: TextStyle(
              color: brown,
              fontSize: 13,
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildChoices() {
    return ListView(
      children: [
        Text(
          AppLocalizations.of(context).adjustEyebrow,
          style: TextStyle(
            color: brown,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          AppLocalizations.of(context).adjustTitle,
          style: TextStyle(
            color: darkBrown,
            fontSize: 32,
            height: 1.15,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          AppLocalizations.of(context).adjustIntro,
          style: TextStyle(
            color: darkBrown,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        _Section(
          title: AppLocalizations.of(context).stepSizeQuestion,
          child: Column(
            children: [
              _SizeOption(
                title: AppLocalizations.of(context).standardSteps,
                description: AppLocalizations.of(context).standardStepsDesc,
                selected: !_smaller,
                onTap: () => setState(() => _smaller = false),
              ),
              const SizedBox(height: 10),
              _SizeOption(
                title: AppLocalizations.of(context).smallerSteps,
                description:
                    AppLocalizations.of(context).smallerStepsDesc,
                selected: _smaller,
                onTap: () => setState(() => _smaller = true),
              ),
            ],
          ),
        ),
        _Section(
          title: AppLocalizations.of(context).yourGoal,
          child: _Chips<PrimaryGoal>(
            values: IntakeMapping.goals,
            label: (g) => goalLabel(AppLocalizations.of(context), g.id),
            selected: _goal,
            onTap: (g) => setState(() => _goal = g),
          ),
        ),
        _Section(
          title: AppLocalizations.of(context).obstacleQuestion,
          child: _Chips<Obstacle>(
            values: IntakeMapping.obstacles,
            label: (o) => obstacleLabel(AppLocalizations.of(context), o.id),
            selected: _obstacle,
            onTap: (o) => setState(() => _obstacle = o),
          ),
        ),
        _Section(
          title: AppLocalizations.of(context).calmActivity,
          child: _Chips<PreferredActivity>(
            values: IntakeMapping.activities,
            label: (a) => switch (a) {
              PreferredActivity.reading =>
                AppLocalizations.of(context).activityReadingTitle,
              PreferredActivity.breathing =>
                AppLocalizations.of(context).activityBreathingTitle,
              _ => AppLocalizations.of(context).activityQuietTitle,
            },
            selected: _activity,
            onTap: (a) => setState(() => _activity = a),
          ),
        ),
      ],
    );
  }

  Widget _buildReview() {
    final profile = _profile!;
    final adjustment = _adjustment;
    final l10n = AppLocalizations.of(context);
    final changes = adjustment.changesFrom(profile, l10n: l10n);
    final after = adjustment.applyTo(profile);
    final input = PlanInput.fromProfile(after, l10n: l10n)!;
    final preview = PlanPreview.build(input, _catalog!, l10n: l10n);
    final explanation = PlanExplanation.build(input, _catalog!,
        windDownStartMinutes: after.bedtimeMinutes, l10n: l10n);
    final running = ref.watch(activeEnrollmentProvider).value != null;

    return ListView(
      children: [
        Text(
          AppLocalizations.of(context).reviewYourChanges,
          style: TextStyle(
            color: darkBrown,
            fontSize: 28,
            height: 1.15,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          AppLocalizations.of(context).nothingSavedUntilConfirm,
          style: TextStyle(
            color: darkBrown,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        for (final change in changes)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    change.label,
                    style: const TextStyle(
                      color: brown,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${change.before}  →  ${change.after}',
                    style: const TextStyle(
                      color: darkBrown,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (running) ...[
          const SizedBox(height: 4),
          Text(
            adjustment.onlyStepSize
                ? AppLocalizations.of(context).adjustRunningStepSize
                : AppLocalizations.of(context).adjustRunningNewPlan,
            style: const TextStyle(
              color: brown,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
        const SizedBox(height: 20),
        Text(
          AppLocalizations.of(context).yourFirstDays,
          style: TextStyle(
            color: darkBrown,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        for (final day in preview.daysIn(1, 3))
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).dayWithTitle(day.day, day.title),
                  style: const TextStyle(
                    color: darkBrown,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  preview.actionFor(day),
                  style: const TextStyle(
                    color: darkBrown,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 6),
        PlanWhyCard(summary: preview.reason, explanation: explanation),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _AdjustPlanScreenState.darkBrown,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _Chips<T> extends StatelessWidget {
  const _Chips({
    required this.values,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final List<T> values;
  final String Function(T) label;
  final T? selected;
  final ValueChanged<T> onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final value in values)
          GestureDetector(
            onTap: () => onTap(value),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                color: value == selected
                    ? _AdjustPlanScreenState.brown
                    : _AdjustPlanScreenState.cardBackground,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Text(
                label(value),
                style: TextStyle(
                  color: value == selected
                      ? Colors.white
                      : _AdjustPlanScreenState.darkBrown,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SizeOption extends StatelessWidget {
  const _SizeOption({
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _AdjustPlanScreenState.cardBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? _AdjustPlanScreenState.brown : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: _AdjustPlanScreenState.brown,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _AdjustPlanScreenState.darkBrown,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      color: _AdjustPlanScreenState.darkBrown,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MainButton extends StatelessWidget {
  const _MainButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _AdjustPlanScreenState.brown,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              _AdjustPlanScreenState.brown.withValues(alpha: 0.35),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
