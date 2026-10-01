import 'package:flutter/material.dart';
import 'goal_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const Color background = Color(0xFFFCFAF7);
  static const Color brown = Color(0xFF8B6043);
  static const Color darkBrown = Color(0xFF5A4338);
  static const Color softBeige = Color(0xFFF4F0E7);
  static const Color yellow = Color(0xFFFFB800);

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
              // RFM LOGO AREA
              Container(
                width: double.infinity,
                height: 190,
                decoration: BoxDecoration(
                  color: softBeige,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Container(
                    width: 210,
                    height: 160,
                    decoration: BoxDecoration(
                      color: background,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.nightlight_round,
                          color: yellow,
                          size: 55,
                        ),
                        Text(
                          'RFM',
                          style: TextStyle(
                            color: brown,
                            fontSize: 54,
                            height: 0.9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'S L E E P  &  R E C H A R G E',
                          style: TextStyle(
                            color: brown,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'WELCOME TO REST FOR MORE',
                style: TextStyle(
                  color: brown,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'A thoughtful path to\nintentional rest',
                style: TextStyle(
                  color: darkBrown,
                  fontSize: 32,
                  height: 1.2,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                "We believe that productivity is only half of life’s "
                "rhythm. Let us help you put the phone down, "
                "clear your thoughts, and create personal "
                "space for slow, deep recovery.",
                style: TextStyle(
                  color: darkBrown,
                  fontSize: 14,
                  height: 1.55,
                ),
              ),

              const SizedBox(height: 28),

              const _BenefitRow(
                text: 'No account needed to start your custom routine',
              ),

              const SizedBox(height: 14),

              const _BenefitRow(
                text: 'A gentle, guided 14-day progressive plan',
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GoalScreen(),
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
                    'Get started',
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

class _BenefitRow extends StatelessWidget {
  final String text;

  const _BenefitRow({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 7,
          height: 7,
          margin: const EdgeInsets.only(top: 7),
          decoration: const BoxDecoration(
            color: WelcomeScreen.yellow,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: WelcomeScreen.darkBrown,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}