import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/database/enums.dart';
import 'package:rest4more/providers/database_providers.dart';
import 'package:rest4more/providers/repository_providers.dart';

import 'test_support.dart';

void main() {
  test('providers lezen uit een enkele, te vervangen database', () async {
    final db = memoryDb();
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    addTearDown(db.close);

    // Riverpod 3 pauzeert streamproviders zonder luisteraar, dus luister mee.
    for (final provider in [
      openSessionProvider,
      activeEnrollmentProvider,
      routinesProvider,
      programmeDaysProvider,
      profileProvider,
    ]) {
      container.listen(provider, (_, _) {});
    }

    expect(container.read(databaseProvider), same(db));
    expect(await container.read(openSessionProvider.future), isNull);
    expect(await container.read(activeEnrollmentProvider.future), isNull);
    expect(await container.read(routinesProvider.future), isEmpty);
    expect(await container.read(programmeDaysProvider.future), isEmpty);
    expect(await container.read(profileProvider.future), isNotNull);

    await container.read(routineRepositoryProvider).create(
          mode: 'focus',
          name: 'Avond',
        );
    final session = await container.read(focusSessionRepositoryProvider).start(
          mode: 'focus',
          source: SessionSource.manual,
          platform: SessionPlatform.android,
        );
    container.invalidate(openSessionProvider);
    expect((await container.read(openSessionProvider.future))?.id, session.id);
  });
}
