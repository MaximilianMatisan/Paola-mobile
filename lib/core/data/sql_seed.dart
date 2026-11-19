// Splits assets/db/init-courses.sql (the app's counterpart to the web app's
// init-db.sql) into its statements: sqflite runs only one statement per
// call. LocalDatabase.applySeed runs them unchanged in a throwaway database.

/// A statement of init-courses.sql that SQLite refused (or a quote or
/// comment that isn't closed; then [number] is 0).
class SeedException implements Exception {
  final int number;
  final String statement;
  final Object error;

  const SeedException(this.number, this.statement, this.error);

  @override
  String toString() {
    final preview = statement.length > 80
        ? '${statement.substring(0, 80)}…'
        : statement;
    return number == 0
        ? 'init-courses.sql: $error'
        : 'init-courses.sql, statement $number ($preview): $error';
  }
}

/// The statements of [sql] without comments, split at `;` outside quotes.
/// Strings use '…' with '' for a quote, names `…` or "…".
List<String> splitSqlStatements(String sql) {
  final statements = <String>[];
  final current = StringBuffer();
  var i = 0;
  while (i < sql.length) {
    final c = sql[i];
    final next = i + 1 < sql.length ? sql[i + 1] : '';
    if (c == '-' && next == '-') {
      final end = sql.indexOf('\n', i);
      i = end == -1 ? sql.length : end;
      continue;
    }
    if (c == '/' && next == '*') {
      final end = sql.indexOf('*/', i + 2);
      if (end == -1) throw const SeedException(0, '', 'unclosed /* comment');
      i = end + 2;
      continue;
    }
    if (c == "'" || c == '"' || c == '`') {
      final start = i;
      i++;
      while (true) {
        if (i >= sql.length) {
          throw SeedException(0, '', 'unclosed $c quote');
        }
        if (sql[i] == c) {
          // Doubled quote = the quote character itself.
          if (i + 1 < sql.length && sql[i + 1] == c) {
            i += 2;
            continue;
          }
          break;
        }
        i++;
      }
      i++;
      current.write(sql.substring(start, i));
      continue;
    }
    if (c == ';') {
      final s = current.toString().trim();
      if (s.isNotEmpty) statements.add(s);
      current.clear();
      i++;
      continue;
    }
    current.write(c);
    i++;
  }
  final rest = current.toString().trim();
  if (rest.isNotEmpty) statements.add(rest);
  return statements;
}
