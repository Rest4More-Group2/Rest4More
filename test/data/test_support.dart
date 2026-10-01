import 'package:drift/native.dart';
import 'package:rest4more/data/database/app_database.dart';
import 'package:rest4more/data/database/enums.dart';
import 'package:rest4more/data/repositories/focus_session_repository.dart';
import 'package:rest4more/data/repositories/programme_repository.dart';

/// Klok die tests zelf laten lopen.
class TestClock {
  TestClock([DateTime? start]) : current = start ?? DateTime(2026, 3, 2, 10);

  DateTime current;

  DateTime call() => current;

  void advance([Duration by = const Duration(milliseconds: 1)]) {
    current = current.add(by);
  }
}

AppDatabase memoryDb() => AppDatabase(NativeDatabase.memory());

/// Brengt een sessie in de gevraagde toestand via legale overgangen.
Future<FocusSession> startSession(
  FocusSessionRepository repo, {
  SessionState upTo = SessionState.selecting,
}) async {
  final session = await repo.start(
    mode: 'focus',
    source: SessionSource.manual,
    platform: SessionPlatform.android,
  );
  const path = [
    SessionState.awaitingScan,
    SessionState.activating,
    SessionState.active,
  ];
  for (final step in path) {
    if (upTo == SessionState.selecting) break;
    await repo.transition(session.id, step);
    if (step == upTo) break;
  }
  return (await repo.findOpen())!;
}

Future<String> enrollWithDays(ProgrammeRepository repo) async {
  final enrollment = await repo.enroll(
    contentVersion: 'v1',
    selection: const {'goal': 'phone'},
    startedOn: DateTime(2026, 3, 2),
  );
  await repo.createDays(enrollment.id, [
    for (var i = 1; i <= 14; i++)
      DaySeed(
        dayNumber: i,
        contentId: 'day-$i',
        scheduledFor: DateTime(2026, 3, 1 + i),
      ),
  ]);
  return enrollment.id;
}
