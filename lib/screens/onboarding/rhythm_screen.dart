import 'package:rest4more/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rest4more/providers/intake_providers.dart';
import 'activities_screen.dart';

class RhythmScreen extends ConsumerStatefulWidget {
  const RhythmScreen({super.key});

  @override
  ConsumerState<RhythmScreen> createState() => _RhythmScreenState();
}

class _RhythmScreenState extends ConsumerState<RhythmScreen> {
  static const Color background = Color(0xFFFCFAF7);
  static const Color brown = Color(0xFF8B6043);
  static const Color darkBrown = Color(0xFF5A4338);
  static const Color cardBackground = Color(0xFFF5F0E8);
  static const Color borderColor = Color(0xFFE7DDD2);
  static const Color yellow = Color(0xFFFFB800);

  int selectedRhythm = 0;

  @override
  void initState() {
    super.initState();
    _showSavedAnswer();
  }

  /// Laat een eerder gegeven antwoord zien.
  Future<void> _showSavedAnswer() async {
    final saved = (await ref.read(intakeServiceProvider).load()).rhythm;
    if (saved != null && mounted) setState(() => selectedRhythm = saved);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back,
                      size: 18,
                      color: brown,
                    ),
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

              Text(
                AppLocalizations.of(context).stepOfFive(3),
                style: TextStyle(
                  color: brown,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                AppLocalizations.of(context).rhythmTitle,
                style: TextStyle(
                  color: darkBrown,
                  fontSize: 32,
                  height: 1.15,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 14),

              Text(
                AppLocalizations.of(context).rhythmIntro,
                style: TextStyle(
                  color: darkBrown,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 26),

              RhythmOptionCard(
                icon: Icons.wb_twilight_outlined,
                title: AppLocalizations.of(context).rhythmEarlyTitle,
                description: AppLocalizations.of(context).rhythmEarlyDesc,
                isSelected: selectedRhythm == 0,
                onTap: () {
                  setState(() {
                    selectedRhythm = 0;
                  });
                },
              ),

              const SizedBox(height: 14),

              RhythmOptionCard(
                icon: Icons.nightlight_outlined,
                title: AppLocalizations.of(context).rhythmMidTitle,
                description: AppLocalizations.of(context).rhythmMidDesc,
                isSelected: selectedRhythm == 1,
                onTap: () {
                  setState(() {
                    selectedRhythm = 1;
                  });
                },
              ),

              const SizedBox(height: 14),

              RhythmOptionCard(
                icon: Icons.bedtime_outlined,
                title: AppLocalizations.of(context).rhythmLateTitle,
                description: AppLocalizations.of(context).rhythmLateDesc,
                isSelected: selectedRhythm == 2,
                onTap: () {
                  setState(() {
                    selectedRhythm = 2;
                  });
                },
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () async {
                    await ref
                        .read(intakeServiceProvider)
                        .saveRhythm(selectedRhythm);
                    if (!context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ActivitiesScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brown,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context).continueLabel,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class RhythmOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const RhythmOptionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected
              ? _RhythmScreenState.cardBackground
              : _RhythmScreenState.background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? _RhythmScreenState.brown
                : _RhythmScreenState.borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isSelected
                    ? _RhythmScreenState.brown.withValues(alpha: 0.10)
                    : _RhythmScreenState.cardBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? _RhythmScreenState.yellow
                    : _RhythmScreenState.brown,
                size: 23,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _RhythmScreenState.darkBrown,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: const TextStyle(
                      color: _RhythmScreenState.brown,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? _RhythmScreenState.brown
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? _RhythmScreenState.brown
                      : _RhythmScreenState.borderColor,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 14,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}