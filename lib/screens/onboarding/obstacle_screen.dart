import 'rhythm_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rest4more/providers/intake_providers.dart';

class ObstacleScreen extends ConsumerStatefulWidget {
  const ObstacleScreen({super.key});

  @override
  ConsumerState<ObstacleScreen> createState() => _ObstacleScreenState();
}

class _ObstacleScreenState extends ConsumerState<ObstacleScreen> {
  static const Color background = Color(0xFFFCFAF7);
  static const Color brown = Color(0xFF8B6043);
  static const Color darkBrown = Color(0xFF5A4338);
  static const Color cardBackground = Color(0xFFF5F0E8);
  static const Color borderColor = Color(0xFFE7DDD2);

  final Set<int> selectedObstacles = {};

  @override
  void initState() {
    super.initState();
    _showSavedAnswer();
  }

  /// Laat een eerder gegeven antwoord zien. Alleen de eerste keuze wordt bewaard.
  Future<void> _showSavedAnswer() async {
    final saved = (await ref.read(intakeServiceProvider).load()).obstacle;
    if (saved != null && mounted) setState(() => selectedObstacles.add(saved));
  }

  final List<Map<String, dynamic>> obstacles = [
    {
      'title': 'Scrolling',
      'icon': Icons.phone_android_rounded,
    },
    {
      'title': 'Availability',
      'icon': Icons.notifications_none_rounded,
    },
    {
      'title': 'Restless thoughts',
      'icon': Icons.psychology_outlined,
    },
    {
      'title': 'Planning',
      'icon': Icons.event_note_rounded,
    },
    {
      'title': 'Phone as alarm',
      'icon': Icons.alarm_rounded,
    },
    {
      'title': 'No routine',
      'icon': Icons.shuffle_rounded,
    },
  ];

  void toggleObstacle(int index) {
    setState(() {
      if (selectedObstacles.contains(index)) {
        selectedObstacles.remove(index);
      } else {
        selectedObstacles.add(index);
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
            vertical: 20,
          ),
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
                'STEP 2 OF 5',
                style: TextStyle(
                  color: brown,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 10),

              // Page title
              const Text(
                'What gets in the way\nof your rest?',
                style: TextStyle(
                  color: darkBrown,
                  fontSize: 32,
                  height: 1.15,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Select all that apply.',
                style: TextStyle(
                  color: brown,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 24),

              // Options
              Expanded(
                child: GridView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: obstacles.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.65,
                  ),
                  itemBuilder: (context, index) {
                    final obstacle = obstacles[index];
                    final isSelected =
                        selectedObstacles.contains(index);

                    return ObstacleCard(
                      title: obstacle['title'],
                      icon: obstacle['icon'],
                      isSelected: isSelected,
                      onTap: () {
                        toggleObstacle(index);
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 18),

              // Continue button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () async {
                    await ref
                        .read(intakeServiceProvider)
                        .saveObstacles(selectedObstacles);
                    if (!context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RhythmScreen(),
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

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class ObstacleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const ObstacleCard({
    super.key,
    required this.title,
    required this.icon,
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? _ObstacleScreenState.cardBackground
              : _ObstacleScreenState.background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? _ObstacleScreenState.brown
                : _ObstacleScreenState.borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: _ObstacleScreenState.brown,
                  size: 25,
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    color: _ObstacleScreenState.darkBrown,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? _ObstacleScreenState.brown
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? _ObstacleScreenState.brown
                        : _ObstacleScreenState.borderColor,
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
            ),
          ],
        ),
      ),
    );
  }
}