import 'dart:io' as io;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/app_database.dart';
import '../data/database/enums.dart';
import '../data/moments/moment_blocking.dart';
import '../data/moments/moment_plans.dart';
import '../data/moments/session_runner.dart';
import '../data/moments/unblock_service.dart';
import '../data/moments/moment_profiles.dart';
import '../data/repositories/accessory_repository.dart';
import '../data/repositories/block_profile_repository.dart';
import '../data/repositories/entitlement_repository.dart';
import '../data/repositories/focus_session_repository.dart';
import '../data/repositories/local_notification_store.dart';
import '../data/repositories/moment_plan_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../data/repositories/programme_repository.dart';
import '../data/repositories/routine_repository.dart';
import 'database_providers.dart';

final profileRepositoryProvider =
    Provider((ref) => ProfileRepository(ref.watch(databaseProvider)));

final routineRepositoryProvider =
    Provider((ref) => RoutineRepository(ref.watch(databaseProvider)));

final blockProfileRepositoryProvider =
    Provider((ref) => BlockProfileRepository(ref.watch(databaseProvider)));

final iosSelectionStoreProvider =
    Provider((ref) => IosSelectionStore(ref.watch(databaseProvider)));

final momentProfileServiceProvider = Provider(
  (ref) => MomentProfileService(
    ref.watch(blockProfileRepositoryProvider),
    ref.watch(iosSelectionStoreProvider),
  ),
);

final momentPlanRepositoryProvider =
    Provider((ref) => MomentPlanRepository(ref.watch(databaseProvider)));

final momentPlanStoreProvider = Provider<MomentPlanStore>(
  (ref) => DbMomentPlanStore(
    ref.watch(momentPlanRepositoryProvider),
    legacy: PrefsMomentPlanStore(),
  ),
);

final unblockServiceProvider = Provider((ref) => UnblockService());

final sessionRunnerProvider = Provider(
  (ref) => SessionRunner(
    ref.watch(focusSessionRepositoryProvider),
    MomentBlocking(ref.watch(momentProfileServiceProvider)),
    platform: io.Platform.isIOS
        ? SessionPlatform.ios
        : io.Platform.isAndroid
            ? SessionPlatform.android
            : SessionPlatform.unknown,
  ),
);

final accessoryRepositoryProvider =
    Provider((ref) => AccessoryRepository(ref.watch(databaseProvider)));

final focusSessionRepositoryProvider =
    Provider((ref) => FocusSessionRepository(ref.watch(databaseProvider)));

final programmeRepositoryProvider =
    Provider((ref) => ProgrammeRepository(ref.watch(databaseProvider)));

final localNotificationStoreProvider =
    Provider((ref) => LocalNotificationStore(ref.watch(databaseProvider)));

final entitlementRepositoryProvider =
    Provider((ref) => EntitlementRepository(ref.watch(databaseProvider)));

final profileProvider = StreamProvider<Profile>(
  (ref) => ref.watch(profileRepositoryProvider).watch(),
);

final routinesProvider = StreamProvider<List<Routine>>(
  (ref) => ref.watch(routineRepositoryProvider).watchAll(),
);

final openSessionProvider = StreamProvider<FocusSession?>(
  (ref) => ref.watch(focusSessionRepositoryProvider).watchOpen(),
);

final activeEnrollmentProvider = StreamProvider<ProgrammeEnrollment?>(
  (ref) => ref.watch(programmeRepositoryProvider).watchActiveEnrollment(),
);

/// Dagen van de lopende deelname. Leeg als er geen deelname is.
final programmeDaysProvider = StreamProvider<List<ProgrammeDay>>((ref) {
  final enrollment = ref.watch(activeEnrollmentProvider).value;
  if (enrollment == null) return Stream.value(const []);
  return ref.watch(programmeRepositoryProvider).watchDays(enrollment.id);
});
