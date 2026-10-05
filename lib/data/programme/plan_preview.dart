import 'content_catalog.dart';
import 'plan_input.dart';
import 'plan_selector.dart';

/// Eén dag in het voorbeeldplan.
class PreviewDay {
  const PreviewDay({required this.day, required this.title, required this.action});

  final int day;
  final String title;

  /// Wat de gebruiker die dag doet, met de eigen antwoorden ingevuld.
  final String action;
}

/// Het plan zoals het straks wordt gemaakt, om te tonen voordat het bestaat.
/// Gebruikt dezelfde selectie als [PlanService], dus wat je ziet is wat je krijgt.
class PlanPreview {
  const PlanPreview({required this.days, required this.reason});

  final List<PreviewDay> days;

  /// Waarom dit plan bij de gebruiker past ("We chose this because...").
  final String reason;

  /// De dagen van [first] tot en met [last].
  List<PreviewDay> daysIn(int first, int last) => [
        for (final d in days)
          if (d.day >= first && d.day <= last) d,
      ];

  static const _obstacleLabels = {
    'scrolling': 'scrolling',
    'availability': 'staying available',
    'thoughts': 'restless thoughts',
    'planning': 'planning',
    'alarm': 'using your phone as an alarm',
    'no_routine': 'not having a routine yet',
  };

  factory PlanPreview.build(PlanInput input, ContentCatalog catalog) {
    final plan = selectPlan(input, catalog);
    final goal = catalog.goals[input.goal]!.toLowerCase();
    final obstacle = _obstacleLabels[input.obstacle] ?? input.obstacle;
    return PlanPreview(
      days: [
        for (final day in plan)
          PreviewDay(
            day: day['day'] as int,
            title: day['title'] as String,
            action: day['action'] as String,
          ),
      ],
      reason: 'Chosen for your goal to $goal and your main obstacle: $obstacle.',
    );
  }
}
