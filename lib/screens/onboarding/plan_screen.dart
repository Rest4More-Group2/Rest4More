import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rest4more/providers/intake_providers.dart';
import 'package:rest4more/providers/plan_providers.dart';
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

  /// Dagen per fase, zoals op de tabbladen.
  static const _ranges = [(1, 4), (5, 9), (10, 14)];

  Widget _buildPhaseContent() {
    // Het echte plan als dat er is, anders de vaste tekst van het ontwerp.
    final preview = ref.watch(planPreviewProvider).value;
    final (first, last) = _ranges[selectedPhase];
    final items = preview == null
        ? null
        : [
            for (final d in preview.daysIn(first, last))
              _PlanItem('Day ${d.day}: ${d.title}', d.action),
          ];
    final reason = preview?.reason;

    if (selectedPhase == 0) {
      return _PhaseContent(
        icon: Icons.spa_outlined,
        phase: 'PHASE 1',
        title: 'Create some space',
        description:
            'Start small by creating a little distance between you and your phone.',
        items: items ??
            const [
              _PlanItem('Put your phone away for 10 minutes'),
              _PlanItem('Take one quiet moment'),
              _PlanItem('Notice how your evening feels'),
            ],
        reason: reason,
      );
    }

    if (selectedPhase == 1) {
      return _PhaseContent(
        icon: Icons.nightlight_outlined,
        phase: 'PHASE 2',
        title: 'Build your rhythm',
        description:
            'Turn your first small steps into a simple evening routine.',
        items: items ??
            const [
              _PlanItem('Begin winding down earlier'),
              _PlanItem('Choose a screen-free activity'),
              _PlanItem('Repeat your evening routine'),
            ],
        reason: reason,
      );
    }

    return _PhaseContent(
      icon: Icons.auto_awesome_outlined,
      phase: 'PHASE 3',
      title: 'Make it yours',
      description:
          'Strengthen the habits that work best for you and your rest.',
      items: items ??
          const [
            _PlanItem('Keep your preferred routine'),
            _PlanItem('Reflect on what helped most'),
            _PlanItem('Prepare for life after day 14'),
          ],
      reason: reason,
    );
  }
}

/// Eén regel in een fase: een titel en eventueel wat de gebruiker die dag doet.
class _PlanItem {
  const _PlanItem(this.title, [this.detail]);

  final String title;
  final String? detail;
}

class _PhaseContent extends StatelessWidget {
  final IconData icon;
  final String phase;
  final String title;
  final String description;
  final List<_PlanItem> items;

  /// Waarom dit plan bij de gebruiker past, als het echte plan bekend is.
  final String? reason;

  const _PhaseContent({
    required this.icon,
    required this.phase,
    required this.title,
    required this.description,
    required this.items,
    this.reason,
  });

  @override
  Widget build(BuildContext context) {
    // Scrollen, want een fase met echte dagen is langer dan de vaste tekst.
    return SingleChildScrollView(
      child: Column(
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

        if (reason != null) ...[
          Text(
            reason!,
            style: const TextStyle(
              color: _PlanScreenState.brown,
              fontSize: 12,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
        ],

        ...items.map(
          (item) => Padding(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          color: _PlanScreenState.darkBrown,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (item.detail != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.detail!,
                          style: const TextStyle(
                            color: _PlanScreenState.darkBrown,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      ),
    );
  }
}
