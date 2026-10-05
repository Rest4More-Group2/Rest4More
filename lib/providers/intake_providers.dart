import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/intake/intake_service.dart';
import 'repository_providers.dart';

final intakeServiceProvider =
    Provider((ref) => IntakeService(ref.watch(profileRepositoryProvider)));

/// Waar de onboarding staat. Laadt opnieuw met `ref.invalidate` na een wijziging.
final intakeProgressProvider = FutureProvider<IntakeProgress>(
  (ref) => ref.watch(intakeServiceProvider).load(),
);
