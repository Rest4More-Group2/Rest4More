/// Klok die tests kunnen vervangen.
typedef Clock = DateTime Function();

/// Fout voor een waarde die de repository niet accepteert.
class InvalidValueError implements Exception {
  const InvalidValueError(this.message);

  final String message;

  @override
  String toString() => 'InvalidValueError: $message';
}

/// Fout als de gevraagde rij niet (meer) bestaat.
class RowNotFoundError implements Exception {
  const RowNotFoundError(this.table, this.id);

  final String table;
  final String id;

  @override
  String toString() => 'RowNotFoundError: $table $id';
}

/// Controleert minuten sinds middernacht (0 tot 1439).
int? checkedMinutes(int? minutes, String name) {
  if (minutes != null && (minutes < 0 || minutes > 1439)) {
    throw InvalidValueError('$name moet tussen 0 en 1439 liggen: $minutes');
  }
  return minutes;
}
