-- Kurse, die die App auch ohne Web-App kennt (das Gegenstück zu init-db.sql
-- der Web-App). Wer hier einen Kurscode eingibt, tritt dem Kurs auf dem Gerät
-- bei; sobald die Web-App verbunden ist, wird der Beitritt dort nachgeholt.
--
-- Die Datei ist SQLite und läuft bei jedem Start in einer eigenen, leeren
-- Datenbank mit den Tabellen course, course_activation_code, exercise_sheet
-- und exercise (Spalten wie in der Web-App). Die Zeilen, die danach in diesen
-- Tabellen stehen, übernimmt die App.
--
-- Regeln:
--  * INSERT-Blöcke aus init-db.sql können kopiert werden; nur ein
--    angehängtes "ON DUPLICATE KEY UPDATE ..." muss weg (gibt es in SQLite
--    nicht).
--  * Dieselben IDs wie in der Datenbank der Web-App verwenden, sonst passen
--    Kurse und Sitzungen nach dem Verbinden nicht zusammen.
--  * Kein CREATE TABLE: die Tabellen gibt es schon.
--  * valid_from / valid_until als 'YYYY-MM-DD'.
--  * Ein Fehler (z. B. eine unbekannte Spalte) bricht den Start der App mit
--    der Nummer der Anweisung ab.
--
-- Ist die Web-App verbunden, gelten für deren Kurse die Daten der Web-App.

INSERT INTO `course` (`id`, `owner_id`, `title`, `description`) VALUES
(1, 1, 'Test Kurs', 'Ein Testkurs für Entwicklung');

INSERT INTO `course_activation_code` (`id`, `course_id`, `code`, `role`) VALUES
(1, 1, 'kurs001', 'student'),
(2, 1, 'tutor001', 'tutor');

INSERT INTO `course` (`id`, `owner_id`, `title`, `description`) VALUES
(2, 1, 'EiP', 'Einführung in die Programmierung'),
(3, 1, 'Algo I', 'Algorithmen und Datenstrukturen'),
(4, 1, 'Analysis', 'Analysis I');

INSERT INTO `course_activation_code` (`id`, `course_id`, `code`, `role`) VALUES
(3, 2, 'eip001', 'student'),
(4, 3, 'algo001', 'student'),
(5, 4, 'ana001', 'tutor');

-- Blätter mit Zeitraum (eine Kalenderwoche): Sitzungen, die in ihm beginnen,
-- gehören zum Blatt. Blätter ohne Datum bekommen keine Sitzungen.
INSERT INTO `exercise_sheet` (`id`, `title`, `course_id`, `valid_from`, `valid_until`) VALUES
(5, 'Analysis Test-Blatt', 3, '2026-11-16', '2026-11-22');

INSERT INTO `exercise` (`id`, `sheet_id`, `title`, `description`, `solution`) VALUES
(30, 5, 'Aufgabe 1', 'Berechnen Sie den Grenzwert der Folge a_n = 1/n für n gegen unendlich.', 'Der Grenzwert ist 0.'),
(31, 5, 'Aufgabe 2', 'Zeigen Sie, dass die Reihe sum 1/n^2 konvergiert.', 'Konvergiert (Basler Problem, Grenzwert pi^2/6).'),
(32, 5, 'Aufgabe 3', 'Bestimmen Sie die Ableitung von f(x) = x^2.', 'f''(x) = 2x.');

-- EiP (Kurs 2): Blatt 1 wie in init-db.sql, dazu zwei weitere Wochen
INSERT INTO `exercise_sheet` (`id`, `title`, `course_id`, `valid_from`, `valid_until`) VALUES
(1, 'Übungsblatt 1', 2, '2026-11-09', '2026-11-15'),
(101, 'Übungsblatt 2', 2, '2026-11-16', '2026-11-22'),
(102, 'Übungsblatt 3', 2, '2026-11-23', '2026-11-29');

INSERT INTO `exercise` (`id`, `sheet_id`, `title`, `description`, `solution`) VALUES
(1, 1, 'Aufgabe 1', 'Beschreibung Aufgabe 1', 'Lösung 1'),
(2, 1, 'Aufgabe 2', 'Beschreibung Aufgabe 2', 'Lösung 2'),
(3, 1, 'Aufgabe 3', 'Beschreibung Aufgabe 3', 'Lösung 3'),
(101, 101, 'Schleifen', '', ''),
(102, 101, 'Rekursion', '', ''),
(103, 102, 'Listen', '', '');

-- Analysis (Kurs 4)
INSERT INTO `exercise_sheet` (`id`, `title`, `course_id`, `valid_from`, `valid_until`) VALUES
(110, 'Analysis Blatt 1', 4, '2026-11-16', '2026-11-22');

INSERT INTO `exercise` (`id`, `sheet_id`, `title`, `description`, `solution`) VALUES
(110, 110, 'Folgen', '', ''),
(111, 110, 'Grenzwerte', '', '');

-- Demo-Kurs: ohne Kurscode ist man in ihm, wie bei der Registrierung ohne
-- Code in der Web-App.
INSERT INTO `course` (`id`, `owner_id`, `title`, `description`) VALUES
(900, 1, 'Demo-Kurs', 'Beispielkurs zur Vorschau. Gib in den Einstellungen einen Kurscode ein, um einem echten Kurs beizutreten.');

INSERT INTO `exercise_sheet` (`id`, `title`, `course_id`, `valid_from`, `valid_until`) VALUES
(900, 'Demo-Übungsblatt', 900, '2026-11-16', '2026-11-22');

INSERT INTO `exercise` (`id`, `sheet_id`, `title`, `description`, `solution`) VALUES
(900, 900, 'Demo-Aufgabe 1', 'Dies ist eine Beispielaufgabe im Demo-Kurs.', 'Beispiellösung 1.'),
(901, 900, 'Demo-Aufgabe 2', 'Noch eine Beispielaufgabe zur Vorschau.', 'Beispiellösung 2.');
