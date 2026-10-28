import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/notifications/notification_permission.dart';
import '../data/notifications/reminder_scheduler.dart';
import '../data/notifications/reminder_service.dart';
import 'repository_providers.dart';

final notificationPermissionProvider = Provider<NotificationPermission>(
  (ref) => const MethodChannelNotificationPermission(),
);

final reminderSchedulerProvider =
    Provider<ReminderScheduler>((ref) => LocalReminderScheduler());

final reminderServiceProvider = Provider(
  (ref) => ReminderService(
    ref.watch(profileRepositoryProvider),
    ref.watch(notificationPermissionProvider),
    programme: ref.watch(programmeRepositoryProvider),
    scheduler: ref.watch(reminderSchedulerProvider),
    store: ref.watch(localNotificationStoreProvider),
  ),
);
