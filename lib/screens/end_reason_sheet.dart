import 'package:flutter/material.dart';
import 'package:rest4more/data/database/enums.dart';
import 'package:rest4more/l10n/app_localizations.dart';

import 'moments_form_widgets.dart' show ChoiceChips;
import 'today_screen.dart' show RestPalette, RestType;

/// Wat de gebruiker koos: stoppen of doorgaan, en eventueel een reden.
typedef EndReasonChoice = ({bool end, EndReason? reason});

/// Vraagt waarom een moment eerder stopt. De reden is optioneel: stoppen
/// zonder reden werkt altijd. Sluiten (vegen of terug) betekent doorgaan.
///
/// Met [afterEnd] is het moment al voorbij (een strakke avond, gestopt met de
/// kaart): dan is er geen "Keep going", alleen bewaren of overslaan, en geeft
/// sluiten `end: true` zonder reden.
Future<EndReasonChoice> showEndReasonSheet(
  BuildContext context, {
  bool afterEnd = false,
}) async {
  final result = await showModalBottomSheet<EndReasonChoice>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: RestPalette.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => EndReasonSheet(afterEnd: afterEnd),
  );
  return result ?? (end: afterEnd, reason: null);
}

class EndReasonSheet extends StatefulWidget {
  const EndReasonSheet({super.key, this.afterEnd = false});

  final bool afterEnd;

  @override
  State<EndReasonSheet> createState() => _EndReasonSheetState();
}

class _EndReasonSheetState extends State<EndReasonSheet> {
  EndReason? _reason;

  String _label(AppLocalizations l10n, EndReason? r) => switch (r) {
    EndReason.couldntSleep => l10n.endReasonCouldntSleep,
    EndReason.neededPhone => l10n.endReasonNeededPhone,
    EndReason.notification => l10n.endReasonNotification,
    EndReason.justWanted => l10n.endReasonJustWanted,
    EndReason.other || EndReason.unknown || null => l10n.endReasonOther,
  };

  void _close(bool end, EndReason? reason) =>
      Navigator.of(context).pop<EndReasonChoice>((end: end, reason: reason));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                widget.afterEnd ? l10n.endReasonStrictTitle : l10n.endReasonTitle,
                style: RestType.serif(32),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.endReasonBody,
              style: RestType.sans(15, color: RestPalette.accent),
            ),
            const SizedBox(height: 20),
            // Eén keuze; nog een keer tikken maakt de keuze weer leeg.
            ChoiceChips<EndReason?>(
              options: EndReason.choices,
              selected: _reason,
              labelOf: (r) => _label(l10n, r),
              onSelected: (r) =>
                  setState(() => _reason = _reason == r ? null : r),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => _close(true, _reason),
              style: FilledButton.styleFrom(
                backgroundColor: RestPalette.primary,
                foregroundColor: RestPalette.background,
                elevation: 0,
                shape: const StadiumBorder(),
                minimumSize: const Size(double.infinity, 58),
              ),
              child: Text(
                widget.afterEnd ? l10n.endReasonSave : l10n.endReasonEnd,
                textAlign: TextAlign.center,
                style: RestType.sans(
                  17,
                  color: RestPalette.background,
                  weight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => widget.afterEnd
                  ? _close(true, null)
                  : _close(false, null),
              style: OutlinedButton.styleFrom(
                foregroundColor: RestPalette.primary,
                side: const BorderSide(color: RestPalette.border),
                shape: const StadiumBorder(),
                minimumSize: const Size(double.infinity, 58),
              ),
              child: Text(
                widget.afterEnd ? l10n.endReasonSkip : l10n.keepGoing,
                textAlign: TextAlign.center,
                style: RestType.sans(
                  17,
                  color: RestPalette.ink,
                  weight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.endReasonPrivacy,
              textAlign: TextAlign.center,
              style: RestType.sans(13, color: RestPalette.accent),
            ),
          ],
        ),
      ),
    );
  }
}
