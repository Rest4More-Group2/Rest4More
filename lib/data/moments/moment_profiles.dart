import 'dart:typed_data';

import '../database/app_database.dart';
import '../database/converters.dart';
import '../database/enums.dart';
import '../repositories/block_profile_repository.dart';

/// De momenten die elk een eigen set geblokkeerde apps hebben.
enum MomentKind {
  focus('Focus', null),
  reading('Reading', null),
  evening('Evening', BlockContext.evening),
  morning('Morning', null);

  const MomentKind(this.profileName, this.context);

  /// Naam van het blokkeerprofiel van dit moment. Het profiel wordt op naam
  /// teruggevonden, dus hernoem het niet los van deze lijst.
  final String profileName;
  final BlockContext? context;
}

/// Eén blokkeerprofiel per moment, met de gekozen apps erin.
class MomentProfileService {
  MomentProfileService(this._profiles, this._ios);

  final BlockProfileRepository _profiles;
  final IosSelectionStore _ios;

  Stream<BlockProfile?> watch(MomentKind kind) =>
      _profiles.watchByName(kind.profileName);

  /// Geeft het profiel van dit moment, en maakt het aan als het nog niet er is.
  Future<BlockProfile> ensure(MomentKind kind) async {
    final existing = await _profiles.findByName(kind.profileName);
    if (existing != null) return existing;
    return _profiles.create(name: kind.profileName, context: kind.context);
  }

  /// Aantal gekozen Android-apps in [profile].
  static int androidAppCount(BlockProfile? profile) =>
      androidPackages(profile).length;

  static Set<String> androidPackages(BlockProfile? profile) => {
        for (final item in profile?.items ?? const <BlockItemData>[])
          if (item.kind == BlockItemKind.androidPackage &&
              item.rule == BlockItemRule.block)
            item.value,
      };

  /// Bewaart de gekozen Android-apps. Andere items (bijvoorbeeld sites)
  /// blijven staan.
  Future<void> saveAndroidPackages(
    MomentKind kind,
    Set<String> packages,
  ) async {
    final profile = await ensure(kind);
    final others = profile.items
        .where((i) => i.kind != BlockItemKind.androidPackage)
        .toList();
    final sorted = packages.toList()..sort();
    await _profiles.setItems(profile.id, [
      ...others,
      for (final p in sorted)
        BlockItemData(kind: BlockItemKind.androidPackage, value: p),
    ]);
  }

  /// Bewaart de opake iOS-selectie van dit moment.
  Future<void> saveIosSelection(MomentKind kind, Uint8List blob) async {
    final profile = await ensure(kind);
    await _ios.save(profile.id, blob);
  }

  /// Wist de iOS-selectie, bijvoorbeeld als de gebruiker niets heeft gekozen.
  Future<void> clearIosSelection(MomentKind kind) async {
    final profile = await _profiles.findByName(kind.profileName);
    if (profile != null) await _ios.delete(profile.id);
  }

  Future<Uint8List?> iosSelection(MomentKind kind) async {
    final profile = await _profiles.findByName(kind.profileName);
    return profile == null ? null : _ios.get(profile.id);
  }
}
