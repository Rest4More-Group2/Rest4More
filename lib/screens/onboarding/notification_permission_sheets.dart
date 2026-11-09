import 'package:flutter/material.dart';

const Color _background = Color(0xFFFCFAF7);
const Color _brown = Color(0xFF8B6043);
const Color _darkBrown = Color(0xFF5A4338);

/// Uitleg voordat het systeem om toestemming vraagt. True als de gebruiker
/// verder wil naar het venster van het systeem, false voor "niet nu", null als
/// het venster is weggeveegd.
Future<bool?> showNotificationRationale(BuildContext context,
        {required String time}) =>
    _showSheet(
      context,
      icon: Icons.notifications_none_rounded,
      title: 'Allow notifications?',
      body: 'To send your daily reminder at $time, Rest4More needs '
          'permission to show notifications. Your phone will ask you next.\n\n'
          'Reminders are optional. If you say no, you can still use '
          'everything in the app.',
      primary: 'Continue',
      secondary: 'Not now',
    );

/// Na een weigering: wat dat betekent. Alleen een knop om verder te gaan.
Future<void> showNotificationDenied(BuildContext context) => _showSheet(
      context,
      icon: Icons.notifications_off_outlined,
      title: 'No reminders for now',
      body: "That's okay. You can use Rest4More as usual, you just won't get "
          'a daily reminder.\n\n'
          "If you change your mind, you can allow notifications for "
          "Rest4More in your phone's settings.",
      primary: 'Continue',
    );

/// Het systeem vraagt het niet meer. True als de gebruiker de instellingen
/// wil openen, false om zonder herinnering verder te gaan, null als het
/// venster is weggeveegd.
Future<bool?> showNotificationBlocked(BuildContext context) => _showSheet(
      context,
      icon: Icons.notifications_off_outlined,
      title: 'Notifications are turned off',
      body: 'Rest4More is not allowed to send notifications on this phone, '
          "so we can't send your daily reminder.\n\n"
          'You can allow notifications in Settings, or continue without '
          'reminders. Everything else in the app works the same.',
      primary: 'Open settings',
      secondary: 'Continue without reminders',
    );

Future<bool?> _showSheet(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String body,
  String? primary,
  String? secondary,
}) =>
    showModalBottomSheet<bool>(
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
