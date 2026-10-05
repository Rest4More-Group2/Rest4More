
import 'obstacle_screen.dart';
import 'package:flutter/material.dart';

class GoalScreen extends StatefulWidget {
  const GoalScreen({super.key});

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  static const Color background = Color(0xFFFCFAF7);
  static const Color brown = Color(0xFF8B6043);
  static const Color darkBrown = Color(0xFF5A4338);
  static const Color cardBackground = Color(0xFFF5F0E8);
  static const Color borderColor = Color(0xFFE7DDD2);

  int selectedGoal = 0;

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
                'STEP 1 OF 5',
                style: TextStyle(
                  color: brown,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 10),

              // Page title
              const Text(
                'What would you like to\nfocus on?',
                style: TextStyle(
                  color: darkBrown,
                  fontSize: 32,
                  height: 1.15,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 28),

              GoalOptionCard(
                title: 'Put the phone away earlier',
                description:
                    'Build a comforting boundary between your screen and your evening sleep cycle.',
                isSelected: selectedGoal == 0,
                onTap: () {
                  setState(() {
                    selectedGoal = 0;
                  });
                },
              ),

              const SizedBox(height: 16),

              GoalOptionCard(
                title: 'Build a routine',
                description:
                    'Create small, nourishing daily rituals that signal your nervous system to recover.',
                isSelected: selectedGoal == 1,
                onTap: () {
                  setState(() {
                    selectedGoal = 1;
                  });
                },
              ),

              const SizedBox(height: 16),

              GoalOptionCard(
                title: 'Use less social media',
                description:
                    'Step back from hyper-stimulating feeds and recapture your focus.',
                isSelected: selectedGoal == 2,
                onTap: () {
                  setState(() {
                    selectedGoal = 2;
                  });
                },
              ),

              const Spacer(),

              // Continue button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                 Navigator.push(
                   context,
                 MaterialPageRoute(
                builder: (context) => const ObstacleScreen(),
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

class GoalOptionCard extends StatelessWidget {
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const GoalOptionCard({
    super.key,
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
              ? _GoalScreenState.cardBackground
              : _GoalScreenState.background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? _GoalScreenState.brown
                : _GoalScreenState.borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _GoalScreenState.darkBrown,
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    description,
                    style: TextStyle(
                      color: isSelected
                          ? _GoalScreenState.darkBrown
                          : _GoalScreenState.brown,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? _GoalScreenState.brown
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? _GoalScreenState.brown
                      : _GoalScreenState.borderColor,
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