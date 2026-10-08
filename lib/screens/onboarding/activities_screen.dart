import 'plan_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rest4more/providers/intake_providers.dart';

class ActivitiesScreen extends ConsumerStatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  ConsumerState<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends ConsumerState<ActivitiesScreen> {
  static const Color background = Color(0xFFFCFAF7);
  static const Color brown = Color(0xFF8B6043);
  static const Color darkBrown = Color(0xFF5A4338);
  static const Color cardBackground = Color(0xFFF5F0E8);
  static const Color borderColor = Color(0xFFE7DDD2);
  static const Color yellow = Color(0xFFFFB800);

  final Set<int> selectedActivities = {};

  @override
  void initState() {
    super.initState();
    _showSavedAnswer();
  }

  /// Laat een eerder gegeven antwoord zien. Alleen de eerste keuze wordt bewaard.
  Future<void> _showSavedAnswer() async {
    final saved = (await ref.read(intakeServiceProvider).load()).activity;
    if (saved != null && mounted) setState(() => selectedActivities.add(saved));
  }

  void toggleActivity(int index) {
    setState(() {
      if (selectedActivities.contains(index)) {
        selectedActivities.remove(index);
      } else {
        selectedActivities.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          // Scrolls when the content is taller than the screen; otherwise the
          // Spacer keeps the button at the bottom.
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back,
                      size: 18,
                      color: brown,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Back',
                      style: TextStyle(
                        color: brown,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Step indicator
              const Text(
                'STEP 4 OF 5',
                style: TextStyle(
                  color: brown,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 10),

              // Title
              const Text(
                'What kind of activities\nappeal to you?',
                style: TextStyle(
                  color: darkBrown,
                  fontSize: 32,
                  height: 1.15,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 14),

              const Text(
                'Choose the kinds of restful activities that feel '
                'natural to you. You can select more than one.',
                style: TextStyle(
                  color: darkBrown,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 18),

              // Quiet moments
              ActivityOptionCard(
                icon: Icons.self_improvement_rounded,
                title: 'Quiet moments',
                description:
                    'Slow down with a few peaceful minutes away from your screen.',
                isSelected: selectedActivities.contains(0),
                onTap: () {
                  toggleActivity(0);
                },
              ),

              const SizedBox(height: 12),

              // Paper reading
              ActivityOptionCard(
                icon: Icons.menu_book_rounded,
                title: 'Paper reading',
                description:
                    'Put the phone aside and spend some time with a physical book.',
                isSelected: selectedActivities.contains(1),
                onTap: () {
                  toggleActivity(1);
                },
              ),

              const SizedBox(height: 12),

              // Breathing
              ActivityOptionCard(
                icon: Icons.air_rounded,
                title: 'Evening breathing routines',
                description:
                    'Use simple breathing exercises to settle your body and mind.',
                isSelected: selectedActivities.contains(2),
                onTap: () {
                  toggleActivity(2);
                },
              ),

              // Minimum gap above the button; the Spacer grows it on tall screens.
              const SizedBox(height: 20),
              const Spacer(),

              // Continue button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () async {
                    await ref
                        .read(intakeServiceProvider)
                        .saveActivities(selectedActivities);
                    if (!context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PlanScreen(),
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
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),
            ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ActivityOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const ActivityOptionCard({
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? _ActivitiesScreenState.cardBackground
              : _ActivitiesScreenState.background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? _ActivitiesScreenState.brown
                : _ActivitiesScreenState.borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isSelected
                    ? _ActivitiesScreenState.brown.withValues(alpha: 0.10)
                    : _ActivitiesScreenState.cardBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? _ActivitiesScreenState.yellow
                    : _ActivitiesScreenState.brown,
                size: 23,
              ),
            ),

            const SizedBox(width: 14),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _ActivitiesScreenState.darkBrown,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: const TextStyle(
                      color: _ActivitiesScreenState.brown,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Selection indicator
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? _ActivitiesScreenState.brown
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? _ActivitiesScreenState.brown
                      : _ActivitiesScreenState.borderColor,
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