import 'package:flutter/material.dart';
import 'package:rest4more/l10n/app_localizations.dart';

const Color _background = Color(0xFFFCFAF7);
const Color _brown = Color(0xFF8B6043);
const Color _darkBrown = Color(0xFF5A4338);

/// Uitleg voordat het systeem om toestemming vraagt. True als de gebruiker
/// verder wil naar het venster van het systeem, false voor "niet nu", null als
/// het venster is weggeveegd.
Future<bool?> showNotificationRationale(
  BuildContext context, {
  required String time,
}) {
  final l10n = AppLocalizations.of(context);
  return _showSheet(
    context,
    icon: Icons.notifications_none_rounded,
    title: l10n.notifAllowTitle,
    body: l10n.notifAllowBody(time),
    primary: l10n.continueLabel,
    secondary: l10n.notNow,
  );
}

/// Na een weigering: wat dat betekent. Alleen een knop om verder te gaan.
Future<void> showNotificationDenied(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return _showSheet(
    context,
    icon: Icons.notifications_off_outlined,
    title: l10n.notifDeniedTitle,
    body: l10n.notifDeniedBody,
    primary: l10n.continueLabel,
  );
}

/// Het systeem vraagt het niet meer. True als de gebruiker de instellingen
/// wil openen, false om zonder herinnering verder te gaan, null als het
/// venster is weggeveegd.
Future<bool?> showNotificationBlocked(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return _showSheet(
    context,
    icon: Icons.notifications_off_outlined,
    title: l10n.notifBlockedTitle,
    body: l10n.notifBlockedBody,
    primary: l10n.openSettings,
    secondary: l10n.notifContinueWithout,
  );
}

Future<bool?> _showSheet(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String body,
  String? primary,
  String? secondary,
}) => showModalBottomSheet<bool>(
  context: context,
  backgroundColor: _background,
  isScrollControlled: true,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
  ),
  builder: (context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Color(0xFFFFE8AE),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _brown, size: 26),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              color: _darkBrown,
              fontSize: 24,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: const TextStyle(
              color: _darkBrown,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          if (primary != null)
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brown,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: Text(
                  primary,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          if (secondary != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  secondary,
                  style: const TextStyle(color: _brown, fontSize: 14),
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  ),
);
