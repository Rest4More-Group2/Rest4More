import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/database/app_database.dart';
import 'package:rest4more/data/database/enums.dart';

import 'test_support.dart';

/// De gedeeltelijke unieke indexen staan niet in de schemadump, want ze worden
/// in `onCreate` met SQL aangemaakt. Deze test dekt ze daarom apart af.
void main() {
  late AppDatabase db;
  final now = DateTime.utc(2026, 3, 2, 10);

  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  FocusSessionsCompanion session({DateTime? endedAt, DateTime? deletedAt}) =>
      FocusSessionsCompanion.insert(
        mode: 'focus',
        source: SessionSource.manual,
        platform: SessionPlatform.android,
        state: SessionState.selecting,
        startedAt: now,
        localDate: '2026-03-02',
        updatedAt: now,
        endedAt: Value(endedAt),
        deletedAt: Value(deletedAt),
      );

  test('beide indexen staan in sqlite_master', () async {
    final rows = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'index'")
        .get();
    final names = rows.map((r) => r.read<String>('name')).toSet();
    expect(names, containsAll(['one_open_session', 'one_live_enrollment']));
  });

  test('een tweede open sessie wordt geweigerd', () async {
    await db.into(db.focusSessions).insert(session());
    await expectLater(
      db.into(db.focusSessions).insert(session()),
      throwsA(isA<Exception>()),
    );
  });

  test('afgeronde of verwijderde sessies tellen niet mee', () async {
    await db.into(db.focusSessions).insert(session());
    await db.into(db.focusSessions).insert(session(endedAt: now));
    await db.into(db.focusSessions).insert(session(endedAt: now));
    await db.into(db.focusSessions).insert(session(deletedAt: now));
    expect(await db.select(db.focusSessions).get(), hasLength(4));
  });

  group('deelname', () {
    late String profileId;

    setUp(() async {
      profileId = 'p1';
      await db.into(db.profiles).insert(
            ProfilesCompanion.insert(id: Value(profileId), updatedAt: now),
          );
    });

    ProgrammeEnrollmentsCompanion enrollment(
      EnrollmentStatus status, {
      DateTime? deletedAt,
    }) =>
        ProgrammeEnrollmentsCompanion.insert(
          profileId: profileId,
          contentVersion: 'v1',
          startedOn: '2026-03-02',
          updatedAt: now,
          status: Value(status),
          deletedAt: Value(deletedAt),
        );

    test('een tweede lopende deelname wordt geweigerd', () async {
      await db
          .into(db.programmeEnrollments)
          .insert(enrollment(EnrollmentStatus.active));
      await expectLater(
        db
            .into(db.programmeEnrollments)
            .insert(enrollment(EnrollmentStatus.paused)),
        throwsA(isA<Exception>()),
      );
    });

    test('beeindigde of verwijderde deelnames tellen niet mee', () async {
      final repo = db.programmeEnrollments;
      await db.into(repo).insert(enrollment(EnrollmentStatus.active));
      await db.into(repo).insert(enrollment(EnrollmentStatus.completed));
      await db.into(repo).insert(enrollment(EnrollmentStatus.stopped));
      await db.into(repo).insert(
          enrollment(EnrollmentStatus.active, deletedAt: now));
      expect(await db.select(repo).get(), hasLength(4));
    });
  });
}
