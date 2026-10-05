import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/common.dart';
import 'package:sqlite3/sqlite3.dart' show sqlite3;

import '../sync/sync_scheduler.dart';

/// Bewaart de databasesleutel buiten de database zelf.
abstract interface class DatabaseKeyStore {
  /// De sleutel als hex (64 tekens), nieuw aangemaakt als er nog geen is.
  Future<String> loadOrCreateHexKey();
}

/// Bewaart de sleutel in de Keychain (iOS) of de Keystore (Android). De sleutel
/// komt nooit in een back-up of in de database zelf.
class SecureDatabaseKeyStore implements DatabaseKeyStore {
  SecureDatabaseKeyStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  static const _keyName = 'restformore_db_key';
  final FlutterSecureStorage _storage;

  @override
  Future<String> loadOrCreateHexKey() async {
    final existing = await _storage.read(key: _keyName);
    if (existing != null && existing.length == 64) return existing;
    final random = Random.secure();
    final key = [
      for (var i = 0; i < 32; i++)
        random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ].join();
    await _storage.write(key: _keyName, value: key);
    return key;
  }
}

/// Zet de sleutel op een geopende verbinding.
///
/// - Een bestaande niet-versleutelde database (of een nieuw leeg bestand) wordt
///   ter plekke versleuteld.
/// - Een versleutelde database wordt met de sleutel geopend.
/// - Klopt de sleutel niet, dan gooit dit.
///
/// Draait in de achtergrond-isolate van Drift, dus alleen simpele waarden.
void applyDatabaseKey(CommonDatabase db, String hexKey) {
  bool readable() {
    try {
      db.select('SELECT count(*) FROM sqlite_master');
      return true;
    } on SqliteException {
      return false;
    }
  }

  if (readable()) {
    // Versleutelen vraagt geen WAL-bestand dat nog gegevens bevat.
    db.execute('PRAGMA journal_mode = DELETE');
    db.execute("PRAGMA hexrekey = '$hexKey'");
  } else {
    db.execute("PRAGMA hexkey = '$hexKey'");
  }
  if (!readable()) {
    throw StateError('De databasesleutel past niet bij dit bestand.');
  }
  db.execute('PRAGMA journal_mode = WAL');
  // Wacht op een lock in plaats van meteen te falen. Bij een hot restart in
  // de ontwikkeling leeft de oude verbinding nog even naast de nieuwe.
  db.execute('PRAGMA busy_timeout = 5000');
}

/// Opent (of maakt) de versleutelde database op [file].
///
/// Eerst een korte controle met een gewone verbinding: die versleutelt een
/// oud niet-versleuteld bestand ter plekke, en laat zien of de sleutel past.
/// Past de sleutel niet en is het bestand dus onleesbaar, dan wordt het
/// verwijderd en opnieuw aangemaakt: zonder sleutel zijn de gegevens toch
/// verloren, en bij synchronisatie komen ze terug van de server.
Future<QueryExecutor> openEncryptedFile(
  File file,
  String hexKey, {
  Future<void> Function()? onRecreated,
}) async {
  if (!_keyFits(file, hexKey)) {
    await deleteDatabaseFiles(file);
    _keyFits(file, hexKey);
    await onRecreated?.call();
  }
  return NativeDatabase.createInBackground(
    file,
    setup: (db) => applyDatabaseKey(db, hexKey),
  );
}

bool _keyFits(File file, String hexKey) {
  final db = sqlite3.open(file.path);
  try {
    applyDatabaseKey(db, hexKey);
    return true;
  } on Object {
    return false;
  } finally {
    db.close();
  }
}

/// Verwijdert het databasebestand en de bijbehorende journal- en wal-bestanden.
Future<void> deleteDatabaseFiles(File file) async {
  for (final suffix in ['', '-wal', '-shm', '-journal']) {
    final f = File('${file.path}$suffix');
    if (await f.exists()) await f.delete();
  }
}

/// De standaard database van de app: versleuteld, in Application Support (op
/// iOS niet in back-ups, op Android is back-up uitgezet).
QueryExecutor openAppDatabase({DatabaseKeyStore? keyStore}) {
  return LazyDatabase(() async {
    final key = await (keyStore ?? SecureDatabaseKeyStore()).loadOrCreateHexKey();
    final dir = await getApplicationSupportDirectory();
    await dir.create(recursive: true);
    final file = File(p.join(dir.path, 'restformore.sqlite'));
    await _moveLegacyFile(file);
    return openEncryptedFile(
      file,
      key,
      // De gegevens zijn weg, het serveraccount niet. Vergeet dat account niet
      // als "openstaande verwijdering": de cloudgegevens zijn juist de kans om
      // alles terug te halen met de pull.
      onRecreated: PreferencesSyncStateStore().clearUserId,
    );
  });
}

/// Eerdere versies stonden in Documents, dat wel in back-ups komt. Verplaats
/// het bestand eenmalig, dan wordt het bij het openen meteen versleuteld.
Future<void> _moveLegacyFile(File target) async {
  if (await target.exists()) return;
  final docs = await getApplicationDocumentsDirectory();
  final legacy = File(p.join(docs.path, 'restformore.sqlite'));
  if (!await legacy.exists()) return;
  for (final suffix in ['', '-wal', '-shm']) {
    final source = File('${legacy.path}$suffix');
    if (await source.exists()) {
      await source.copy('${target.path}$suffix');
      await source.delete();
    }
  }
}
