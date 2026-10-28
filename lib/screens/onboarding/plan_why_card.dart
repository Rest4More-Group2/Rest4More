import 'package:flutter/material.dart';
import 'package:rest4more/data/programme/plan_explanation.dart';

/// "Why we chose this for you": de samenvatting en per antwoord wat het met
/// het plan doet. Gebruikt op het planscherm en bij het aanpassen.
class PlanWhyCard extends StatelessWidget {
  const PlanWhyCard({super.key, this.summary, this.explanation});

  final String? summary;
  final PlanExplanation? explanation;

  static const Color brown = Color(0xFF8B6043);
  static const Color darkBrown = Color(0xFF5A4338);

  @override
  Widget build(BuildContext context) {
    final reasons = explanation?.reasons ?? const <PlanReason>[];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Why we chose this for you',
            style: TextStyle(
              color: darkBrown,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (summary != null) ...[
            const SizedBox(height: 6),
            Text(
              summary!,
              style: const TextStyle(
                color: brown,
                fontSize: 12,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ],
          for (final reason in reasons) ...[
            const SizedBox(height: 12),
            Text(
              reason.label,
              style: const TextStyle(
                color: darkBrown,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              reason.text,
              style: const TextStyle(
                color: darkBrown,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 14),
          const Text(
            PlanExplanation.disclaimer,
            style: TextStyle(
              color: brown,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
