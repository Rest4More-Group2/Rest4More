import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/database/app_database.dart';
import 'package:rest4more/data/database/converters.dart';
import 'package:rest4more/data/database/enums.dart';
import 'package:rest4more/data/moments/moment_plans.dart';
import 'package:rest4more/data/moments/moment_schedule.dart';
import 'package:rest4more/data/repositories/moment_plan_repository.dart';
import 'package:rest4more/data/sync/pull_engine.dart';
import 'package:rest4more/data/sync/sync_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'sync_engine_test.dart' show FakeRemote, FakeServer;
import 'test_support.dart';

void main() {
  late FakeServer server;
  late AppDatabase a;
  late AppDatabase b;
  late FakeRemote remoteA;
  late FakeRemote remoteB;
  late TestClock clock;
  late DbMomentPlanStore storeA;
  late DbMomentPlanStore storeB;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    server = FakeServer();
    a = memoryDb();
    b = memoryDb();
    remoteA = FakeRemote(server: server);
    remoteB = FakeRemote(server: server);
    clock = TestClock(DateTime(2026, 10, 12, 9));
    storeA = DbMomentPlanStore(MomentPlanRepository(a, now: clock.call));
    storeB = DbMomentPlanStore(MomentPlanRepository(b, now: clock.call));
    await grantConsent(a);
    await grantConsent(b);
  });
  tearDown(() async {
    await a.close();
    await b.close();
  });

  EveningPlan custom({int bedtime = 23 * 60}) => EveningPlan.initial().copyWith(
        days: [
          for (final d in EveningPlan.initial().days)
            d.copyWith(bedtimeMinutes: bedtime),
        ],
        steps: const [RoutineStepData(title: 'Read', durationMin: 40)],
        end: EveningEnd.atNextScan,
      );

  Future<List<Map<String, Object?>>> rows(AppDatabase db) async => (await db
          .customSelect('SELECT * FROM moment_plans ORDER BY updated_at, id')
          .get())
      .map((r) => r.data)
      .toList();

  test('bewaren maakt een rij en bewaren opnieuw werkt die bij', () async {
    await storeA.saveEvening(custom());
    clock.advance(const Duration(minutes: 1));
    await storeA.saveEvening(custom(bedtime: 22 * 60));
    final all = await rows(a);
    expect(all, hasLength(1));
    expect(all.single['kind'], 'evening');
    expect(all.single['dirty'], 1);
    expect((await storeA.loadEvening())!.days.first.bedtimeMinutes, 22 * 60);
  });

  test('avond en ochtend zijn aparte rijen', () async {
    await storeA.saveEvening(custom());
    await storeA.saveMorning(MorningPlan.initial());
    expect((await rows(a)).map((r) => r['kind']).toSet(), {'evening', 'morning'});
    expect(await rows(a), hasLength(2));
  });

  test('het plan gaat naar de server en komt op een ander toestel terug',
      () async {
    await storeA.saveEvening(custom());
    expect((await SyncEngine(a, remoteA).pushDirty()).ok, isTrue);
    expect(remoteA.tables, contains('moment_plans'));
    expect((await rows(a)).single['dirty'], 0);

    // Het plan gaat als json-object naar de server, niet als tekst.
    final sent = remoteA.rowsOf('moment_plans').single;
    expect(sent['plan'], isA<Map>());
    expect(sent, isNot(contains('dirty')));

    expect((await PullEngine(b, remoteB).pull()).ok, isTrue);
    final plan = (await storeB.loadEvening())!;
    expect(plan.steps.single.title, 'Read');
    expect(plan.steps.single.durationMin, 40);
    expect(plan.days.first.bedtimeMinutes, 23 * 60);
    expect(plan.end, EveningEnd.atNextScan);
    expect((await rows(b)).single['dirty'], 0, reason: 'pull veroorzaakt geen push');
  });

  test('een wijziging op het ene toestel komt bij het andere aan', () async {
    await storeA.saveMorning(MorningPlan.initial());
    await SyncEngine(a, remoteA).pushDirty();
    await PullEngine(b, remoteB).pull();

    clock.advance(const Duration(minutes: 5));
    await storeB.saveMorning(MorningPlan.initial().copyWith(steps: const []));
    await SyncEngine(b, remoteB).pushDirty();
    await PullEngine(a, remoteA).pull();

    expect((await storeA.loadMorning())!.steps, isEmpty);
  });

  test('twee toestellen die elk een plan maakten: het nieuwste wint en de '
      'dubbele rij wordt opgeruimd', () async {
    await storeA.saveEvening(custom(bedtime: 22 * 60));
    clock.advance(const Duration(minutes: 10));
    await storeB.saveEvening(custom(bedtime: 23 * 60 + 30));
    await SyncEngine(a, remoteA).pushDirty();
    await SyncEngine(b, remoteB).pushDirty();
    await PullEngine(a, remoteA).pull();

    expect(await rows(a), hasLength(2));
    final seen = (await storeA.loadEvening())!;
    expect(seen.days.first.bedtimeMinutes, 23 * 60 + 30);

    clock.advance(const Duration(minutes: 1));
    await storeA.saveEvening(seen);
    final live = (await rows(a)).where((r) => r['deleted_at'] == null);
    expect(live, hasLength(1));
    // De zachte verwijdering gaat ook naar de server.
    await SyncEngine(a, remoteA).pushDirty();
    final onServer = server.tables['moment_plans']!.values
        .where((r) => r['deleted_at'] == null);
    expect(onServer, hasLength(1));
  });

  test('zonder toestemming gaat er niets naar de server', () async {
    final solo = memoryDb();
    addTearDown(solo.close);
    await DbMomentPlanStore(MomentPlanRepository(solo)).saveEvening(custom());
    final result = await SyncEngine(solo, FakeRemote(server: server)).pushDirty();
    expect(result.skippedNoConsent, isTrue);
    expect(server.tables['moment_plans'], isNull);
  });

  test('een plan uit de oude opslag wordt overgenomen en gesynchroniseerd',
      () async {
    final legacy = PrefsMomentPlanStore();
    await legacy.saveEvening(custom());
    final store = DbMomentPlanStore(MomentPlanRepository(a), legacy: legacy);

    final plan = (await store.loadEvening())!;
    expect(plan.steps.single.title, 'Read');
    expect(await rows(a), hasLength(1), reason: 'staat nu in de database');
    expect((await rows(a)).single['dirty'], 1);

    // De tweede keer komt het uit de database, niet nog eens uit de oude opslag.
    await legacy.saveEvening(EveningPlan.initial());
    expect((await store.loadEvening())!.steps.single.title, 'Read');
  });

  test('beschadigde of onbekende opgeslagen tekst geeft geen plan', () async {
    final repo = MomentPlanRepository(a);
    await repo.save(MomentPlanKind.evening, '{kapot');
    expect(await DbMomentPlanStore(repo).loadEvening(), isNull);
    await repo.save(MomentPlanKind.evening, '{"version": 99}');
    expect(await DbMomentPlanStore(repo).loadEvening(), isNull);
  });
}
