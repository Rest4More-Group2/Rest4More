/// Opslag-enums. Elke enum bewaart een vaste tekst in de database en heeft een
/// `unknown`-lid. Een onbekende tekst (bijvoorbeeld een waarde die later is
/// ingetrokken) wordt daarmee `unknown` in plaats van een fout, zodat oude
/// rijen leesbaar blijven.
abstract interface class DbEnum {
  String get id;
}

enum AgeBand implements DbEnum {
  under16('under16'),
  age16To17('16_17'),
  age18To24('18_24'),
  age25To39('25_39'),
  age40To54('40_54'),
  age55Plus('55_plus'),
  unknown('unknown');

  const AgeBand(this.id);

  @override
  final String id;
}

enum PrimaryGoal implements DbEnum {
  phone('phone'),
  routine('routine'),
  social('social'),
  unknown('unknown');

  const PrimaryGoal(this.id);

  @override
  final String id;
}

enum Obstacle implements DbEnum {
  scrolling('scrolling'),
  availability('availability'),
  thoughts('thoughts'),
  planning('planning'),
  alarm('alarm'),
  noRoutine('no_routine'),
  unknown('unknown');

  const Obstacle(this.id);

  @override
  final String id;
}

enum Rhythm implements DbEnum {
  regular('regular'),
  variable('variable'),
  shifts('shifts'),
  unknown('unknown');

  const Rhythm(this.id);

  @override
  final String id;
}

enum StepSize implements DbEnum {
  short('short'),
  standard('standard'),
  custom('custom'),
  unknown('unknown');

  const StepSize(this.id);

  @override
  final String id;
}

enum PreferredActivity implements DbEnum {
  reading('reading'),
  preparation('preparation'),
  quietSitting('quiet_sitting'),
  breathing('breathing'),
  custom('custom'),
  unknown('unknown');

  const PreferredActivity(this.id);

  @override
  final String id;
}

enum RoutineEndRule implements DbEnum {
  cardScan('card_scan'),
  timer('timer'),
  manual('manual'),
  unknown('unknown');

  const RoutineEndRule(this.id);

  @override
  final String id;
}

enum BlockContext implements DbEnum {
  evening('evening'),
  study('study'),
  work('work'),
  sport('sport'),
  custom('custom'),
  unknown('unknown');

  const BlockContext(this.id);

  @override
  final String id;
}

enum BlockItemKind implements DbEnum {
  url('url'),
  androidPackage('android_package'),
  unknown('unknown');

  const BlockItemKind(this.id);

  @override
  final String id;
}

enum BlockItemRule implements DbEnum {
  block('block'),
  allow('allow'),
  unknown('unknown');

  const BlockItemRule(this.id);

  @override
  final String id;
}

enum AccessoryKind implements DbEnum {
  card('card'),
  restnest('restnest'),
  dock('dock'),
  unknown('unknown');

  const AccessoryKind(this.id);

  @override
  final String id;
}

enum AccessoryStatus implements DbEnum {
  active('active'),
  lost('lost'),
  retired('retired'),
  unknown('unknown');

  const AccessoryStatus(this.id);

  @override
  final String id;
}

enum SessionSource implements DbEnum {
  manual('manual'),
  schedule('schedule'),
  nfc('nfc'),
  notification('notification'),
  unknown('unknown');

  const SessionSource(this.id);

  @override
  final String id;
}

enum SessionPlatform implements DbEnum {
  ios('ios'),
  android('android'),
  unknown('unknown');

  const SessionPlatform(this.id);

  @override
  final String id;
}

enum SessionState implements DbEnum {
  selecting('selecting'),
  awaitingScan('awaiting_scan'),
  activating('activating'),
  active('active'),
  awaitingUnlock('awaiting_unlock'),
  releasing('releasing'),
  completed('completed'),
  emergency('emergency'),
  permissionLost('permission_lost'),
  unknown('unknown');

  const SessionState(this.id);

  @override
  final String id;
}

enum SessionOutcome implements DbEnum {
  completed('completed'),
  stoppedEarly('stopped_early'),
  emergencyRelease('emergency_release'),
  activationFailed('activation_failed'),
  releaseFailed('release_failed'),
  permissionLost('permission_lost'),
  cancelled('cancelled'),
  unknown('unknown');

  const SessionOutcome(this.id);

  @override
  final String id;
}

enum SessionFeeling implements DbEnum {
  good('good'),
  hard('hard'),
  tired('tired'),
  distracted('distracted'),
  unknown('unknown');

  const SessionFeeling(this.id);

  @override
  final String id;
}

enum SessionEventType implements DbEnum {
  transition('transition'),
  scanAccepted('scan_accepted'),
  scanRejected('scan_rejected'),
  reconciled('reconciled'),
  unknown('unknown');

  const SessionEventType(this.id);

  @override
  final String id;
}

enum EnrollmentStatus implements DbEnum {
  active('active'),
  paused('paused'),
  completed('completed'),
  stopped('stopped'),
  unknown('unknown');

  const EnrollmentStatus(this.id);

  @override
  final String id;
}

enum ProgrammeDirection implements DbEnum {
  keep('keep'),
  adjust('adjust'),
  repeat('repeat'),
  unknown('unknown');

  const ProgrammeDirection(this.id);

  @override
  final String id;
}

enum DayStatus implements DbEnum {
  planned('planned'),
  offered('offered'),
  opened('opened'),
  completed('completed'),
  skipped('skipped'),
  replaced('replaced'),
  unknown('unknown');

  const DayStatus(this.id);

  @override
  final String id;
}

enum DaySize implements DbEnum {
  standard('standard'),
  smaller('smaller'),
  unknown('unknown');

  const DaySize(this.id);

  @override
  final String id;
}

enum DayFit implements DbEnum {
  well('well'),
  partly('partly'),
  no('no'),
  skip('skip'),
  unknown('unknown');

  const DayFit(this.id);

  @override
  final String id;
}

enum DayBlocker implements DbEnum {
  time('time'),
  moment('moment'),
  task('task'),
  availability('availability'),
  technical('technical'),
  other('other'),
  unknown('unknown');

  const DayBlocker(this.id);

  @override
  final String id;
}

enum DayProtected implements DbEnum {
  yes('yes'),
  partly('partly'),
  no('no'),
  skip('skip'),
  unknown('unknown');

  const DayProtected(this.id);

  @override
  final String id;
}

enum NotificationKind implements DbEnum {
  programme('programme'),
  routineLead('routine_lead'),
  routineStart('routine_start'),
  unknown('unknown');

  const NotificationKind(this.id);

  @override
  final String id;
}

enum NotificationStatus implements DbEnum {
  scheduled('scheduled'),
  cancelled('cancelled'),
  opened('opened'),
  unknown('unknown');

  const NotificationStatus(this.id);

  @override
  final String id;
}

enum EntitlementSource implements DbEnum {
  free('free'),
  restnest('restnest'),
  storePurchase('store_purchase'),
  cardPurchase('card_purchase'),
  grant('grant'),
  unknown('unknown');

  const EntitlementSource(this.id);

  @override
  final String id;
}

enum EntitlementStatus implements DbEnum {
  active('active'),
  expired('expired'),
  revoked('revoked'),
  unknown('unknown');

  const EntitlementStatus(this.id);

  @override
  final String id;
}

enum ConsentPurpose implements DbEnum {
  cloudSync('cloud_sync'),
  unknown('unknown');

  const ConsentPurpose(this.id);

  @override
  final String id;
}

enum ConsentStatus implements DbEnum {
  granted('granted'),
  withdrawn('withdrawn'),
  unknown('unknown');

  const ConsentStatus(this.id);

  @override
  final String id;
}
