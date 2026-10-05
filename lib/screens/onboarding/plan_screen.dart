import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rest4more/providers/intake_providers.dart';
import 'reminder_screen.dart';

class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  static const Color background = Color(0xFFFCFAF7);
  static const Color brown = Color(0xFF8B6043);
  static const Color darkBrown = Color(0xFF5A4338);
  static const Color cardBackground = Color(0xFFF5F0E8);
  static const Color yellow = Color(0xFFFFB800);

  int selectedPhase = 0;

  final List<String> phases = [
    'Day 1–4',
    'Day 5–9',
    'Day 10–14',
  ];

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
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back, size: 18, color: brown),
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

              const Text(
                'STEP 5 OF 5',
                style: TextStyle(
                  color: brown,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Here’s your\npersonal plan',
                style: TextStyle(
                  color: darkBrown,
                  fontSize: 32,
                  height: 1.15,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'A gentle 14-day plan designed around your goals, '
                'rhythm and preferred activities.',
                style: TextStyle(
                  color: darkBrown,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 24),

              // Phase selector
              Row(
                children: List.generate(
                  phases.length,
                  (index) {
                    final bool selected = selectedPhase == index;

                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: index < phases.length - 1 ? 8 : 0,
                        ),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedPhase = index;
                            });
                          },
                          child: Container(
                            height: 42,
                            decoration: BoxDecoration(
                              color: selected ? brown : cardBackground,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              phases[index],
                              style: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : darkBrown,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: cardBackground,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: _buildPhaseContent(),
                ),
              ),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () async {
                    await ref.read(intakeServiceProvider).savePlanSeen();
                    if (!context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const ReminderScreen(),
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
                    'Start your plan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Center(
                child: TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Adjust plan settings',
                    style: TextStyle(
                      color: brown,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhaseContent() {
    if (selectedPhase == 0) {
      return const _PhaseContent(
        icon: Icons.spa_outlined,
        phase: 'PHASE 1',
        title: 'Create some space',
        description:
            'Start small by creating a little distance between you and your phone.',
        activities: [
          'Put your phone away for 10 minutes',
          'Take one quiet moment',
          'Notice how your evening feels',
        ],
      );
    }

    if (selectedPhase == 1) {
      return const _PhaseContent(
        icon: Icons.nightlight_outlined,
        phase: 'PHASE 2',
        title: 'Build your rhythm',
        description:
            'Turn your first small steps into a simple evening routine.',
        activities: [
          'Begin winding down earlier',
          'Choose a screen-free activity',
          'Repeat your evening routine',
        ],
      );
    }

    return const _PhaseContent(
      icon: Icons.auto_awesome_outlined,
      phase: 'PHASE 3',
      title: 'Make it yours',
      description:
          'Strengthen the habits that work best for you and your rest.',
      activities: [
        'Keep your preferred routine',
        'Reflect on what helped most',
        'Prepare for life after day 14',
      ],
    );
  }
}

class _PhaseContent extends StatelessWidget {
  final IconData icon;
  final String phase;
  final String title;
  final String description;
  final List<String> activities;

  const _PhaseContent({
    required this.icon,
    required this.phase,
    required this.title,
    required this.description,
    required this.activities,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: Color(0xFFFFE8AE),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: _PlanScreenState.brown,
          ),
        ),

        const SizedBox(height: 18),

        Text(
          phase,
          style: const TextStyle(
            color: _PlanScreenState.brown,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          title,
          style: const TextStyle(
            color: _PlanScreenState.darkBrown,
            fontSize: 23,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          description,
          style: const TextStyle(
            color: _PlanScreenState.brown,
            fontSize: 13,
            height: 1.5,
          ),
        ),

        const SizedBox(height: 20),

        ...activities.map(
          (activity) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: _PlanScreenState.brown,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    activity,
                    style: const TextStyle(
                      color: _PlanScreenState.darkBrown,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}