// All user-facing texts of the app, in German and English. Same idea as
// utils/translations.ts of the paola web app.
//
// Adding a text: declare it in [Translations], then give it a value in both
// [TranslationsDe] and [TranslationsEn] (the compiler complains if one is
// missing). Texts with values are methods, e.g. `t.helloName(name)`.
//
// In widgets read them with `context.t.someKey` (see app_language.dart), so
// the widget rebuilds when the language changes. Code without a context
// (API errors, notifications) uses `AppLanguage.t`.

// The language classes override every key; marking each one is just noise.
// ignore_for_file: annotate_overrides

/// Values match the `language` preference of the web app (0 = DE, 1 = EN).
enum Language {
  de('Deutsch', TranslationsDe()),
  en('English', TranslationsEn());

  /// Name of the language in itself, shown in the language picker.
  final String label;
  final Translations translations;

  const Language(this.label, this.translations);

  int get flag => index;

  static Language fromFlag(Object? flag) => flag == 1 || flag == true ? Language.en : Language.de;
}

abstract class Translations {
  const Translations();

  // ---------- General ----------
  String get save;
  String get cancel;
  String get delete;
  String get ok;
  String get turnOn;
  String get logOut;
  String get noConnection;

  // ---------- Errors - core/network, features/auth/data ----------
  String get errorInvalidUrl;
  String get errorNoSessionCookie;
  String errorNoAccess(int status);
  String errorRequest(String path, int status);
  String get errorLogin;
  String get errorDeletionFailed;

  // ---------- Bottom bar - core/navigation/bottom_bar.dart ----------
  String get navHome;
  String get navTimer;
  String get navSettings;

  // ---------- Login - features/auth/presentation ----------
  String get loginWelcome;
  String get loginUsername;
  String get loginPassword;
  String get loginForgotPassword;
  String get loginEnterUsername;
  String get loginEnterPassword;
  String get loginButton;
  String get loginContact;
  String get serverTitle;
  String serverDefault(String url);
  String get serverReset;

  // ---------- Home - features/home/presentation/home_screen.dart ----------
  String get hello;
  String helloName(String name);

  // ---------- Timer - features/timer/presentation/timer_screen.dart ----------
  String get timerTitle;
  String get pomodoro;
  String get stopwatch;
  String get flowtime;
  String get tapForBreak;
  String get flowtimeHint;
  String flowtimeEarned(int minutes);
  String get breakLabel;
  String get breakLength;
  String get breakNone;
  String breakWithLength(String length);
  String ofWork(String work);
  String get unitMin;
  String get unitSec;
  String get tapToStart;
  String get tapToPause;
  String get tapToResume;
  String get start;
  String get finishAndSave;
  String get skipBreak;
  String get discardSession;
  String get discardTitle;
  String get discardMessage;
  String get pausedPickedUp;
  String saveSessionFailed(Object error);
  String get pomodoroFinished;
  String breakTime(int minutes);
  String get breakOver;
  String get nextRound;
  String get wellDone;
  String scheduleAlertFailed(Object error);
  String notificationsBlockedHint(Object error);
  String lockScreenFailed(Object error);
  String get phoneResting;
  String get sensorUnavailable;
  String phoneMoved(int seconds);
  String get history;
  String yesterdayMinutes(int minutes);

  // ---------- Timer notifications - features/timer/util ----------
  String get notificationsOffApp;
  String get notificationsOffTimer;
  String pausedAt(String time);
  String get channelTimer;
  String get channelTimerDesc;
  String get channelAlerts;
  String get channelAlertsDesc;

  // ---------- Self assessment - features/timer/presentation ----------
  String get rateSession;

  // ---------- Reflection - features/timer/presentation/reflection_dialog.dart ----------
  String reflectionTitle(String duration);
  String get reflectionActivitiesQuestion;
  String reflectionHowWent(String activity);
  String get reflectionTimeTitle;
  String reflectionSum(String duration);
  String get reflectionSplitEvenly;
  String get reflectionTimeHint;
  String get reflectionDiscard;
  String get reflectionContinue;
  String get reflectionNext;
  String get reflectionSave;
  String get reflectionAhaMoment;
  String get activityPrepareLecture;
  String get activityAttendLecture;
  String get activityReviewLecture;
  String get activityExercises;
  String get activityQuizzes;
  String get activityRepeatSummarize;
  String get activityPeerExchange;
  String get activityOrganize;
  String get activityOther;
  String get moodPerfect;
  String get moodGood;
  String get moodNormal;
  String get moodBad;
  String get moodMiserable;

  // ---------- History - features/study_history/presentation ----------
  String get thisWeek;
  String get sessions;
  String get pickedUp;
  String get paused;
  String loadSessionsFailed(Object error);
  String get noSessions;
  String deleteSessionMessage(String duration, String mode);
  String deletingFailed(Object error);
  String get deleteSession;
  String get notPickedUp;
  String pickedUpTimes(int count, String time);
  String get today;
  String get yesterday;
  List<String> get weekdays;

  // ---------- Settings - features/settings/presentation ----------
  String get settingsTitle;
  String get profile;
  String get loggedIn;
  String get savedOnDevice;
  String get webApp;
  String get webAppNotConnected;
  String webAppConnected(String server);
  String get setUp;
  String get disconnect;
  String get nickname;
  String get nicknameSaved;
  String get appearance;
  String get darkMode;
  String get darkModeDesc;
  String darkModeSaveFailed(String error);
  String get hideTime;
  String get hideTimeDesc;
  String get language;
  String get languageDesc;
  String get notifications;
  String get timerNotifications;
  String get timerNotificationsOn;
  String get timerNotificationsOff;
  String get deleteMyData;
  String get deleteMyDataDesc;
  String get request;
  String get requesting;
  String get deleteDataTitle;
  String get deleteDataMessage;
  String get deletionRequested;
  String deletionRequestFailed(String error);

  // ---------- Page help - core/widgets/page_help.dart ----------
  String get helpButtonTooltip;
  String get helpClose;
  String get helpPomodoroTitle;
  String get helpPomodoroIntro;
  List<String> get helpPomodoroBullets;
  String get helpStopwatchTitle;
  String get helpStopwatchIntro;
  List<String> get helpStopwatchBullets;
  String get helpFlowtimeTitle;
  String get helpFlowtimeIntro;
  List<String> get helpFlowtimeBullets;
  String get helpHistoryTitle;
  String get helpHistoryIntro;
  List<String> get helpHistoryBullets;
  String get helpSettingsTitle;
  String get helpSettingsIntro;
  List<String> get helpSettingsBullets;
}

class TranslationsDe extends Translations {
  const TranslationsDe();

  // ---------- Allgemeines ----------
  final save = 'Speichern';
  final cancel = 'Abbrechen';
  final delete = 'Löschen';
  final ok = 'OK';
  final turnOn = 'Einschalten';
  final logOut = 'Abmelden';
  final noConnection = 'Keine Verbindung zum Server';

  // ---------- Fehler ----------
  final errorInvalidUrl = 'Ungültige URL, z. B. http://192.168.1.20:3000';
  final errorNoSessionCookie = 'Kein Sitzungs-Cookie in der Serverantwort';
  String errorNoAccess(int status) =>
      'Nicht angemeldet oder kein Zugriff (HTTP $status)';
  String errorRequest(String path, int status) =>
      'Fehler bei $path (HTTP $status)';
  final errorLogin = 'Fehler bei der Anmeldung';
  final errorDeletionFailed = 'Löschanfrage fehlgeschlagen';

  // ---------- Navigationsleiste ----------
  final navHome = 'Home';
  final navTimer = 'Timer';
  final navSettings = 'Einstellungen';

  // ---------- Anmeldung ----------
  final loginWelcome = 'Bei Paola anmelden!';
  final loginUsername = 'Benutzername';
  final loginPassword = 'Passwort';
  final loginForgotPassword = 'Passwort vergessen';
  final loginEnterUsername = 'Bitte gib deinen Benutzernamen ein';
  final loginEnterPassword = 'Bitte gib dein Passwort ein';
  final loginButton = 'Anmelden';
  final loginContact = 'Kontakt';
  final serverTitle = 'Server';
  String serverDefault(String url) => 'Standard: $url';
  final serverReset = 'Zurücksetzen';

  // ---------- Home ----------
  final hello = 'Hallo!';
  String helloName(String name) => 'Hallo, $name!';

  // ---------- Timer ----------
  final timerTitle = 'Timer';
  final pomodoro = 'Pomodoro';
  final stopwatch = 'Stoppuhr';
  final flowtime = 'Flowtime';
  final tapForBreak = 'Tippe für deine Pause';
  final flowtimeHint = 'Lerne, solange du dich konzentrieren kannst. Die Pause richtet sich nach deiner Lernzeit: bis 25 Min → 5 Min, bis 50 Min → 8 Min, länger → 10 Min.';
  String flowtimeEarned(int minutes) => 'Pause: $minutes Min';
  final breakLabel = 'Pause';
  final breakLength = 'Pausenlänge';
  final breakNone = 'Keine';
  String breakWithLength(String length) => 'Pause, $length';
  String ofWork(String work) => 'von $work';
  final unitMin = 'Min';
  final unitSec = 'Sek';
  final tapToStart = 'Tippe zum Starten';
  final tapToPause = 'Tippe zum Pausieren';
  final tapToResume = 'Tippe zum Fortsetzen';
  final start = 'Starten';
  final finishAndSave = 'Beenden und speichern';
  final skipBreak = 'Pause überspringen';
  final discardSession = 'Sitzung verwerfen';
  final discardTitle = 'Diese Sitzung löschen?';
  final discardMessage = 'Die bisher erfasste Zeit wird verworfen.';
  final pausedPickedUp = 'Timer pausiert: Handy wurde aufgehoben';
  String saveSessionFailed(Object error) =>
      'Speichern der Sitzung fehlgeschlagen: $error';
  final pomodoroFinished = 'Pomodoro beendet';
  String breakTime(int minutes) => 'Zeit für $minutes Min Pause!';
  final breakOver = 'Pause vorbei';
  final nextRound = 'Bereit für die nächste Runde?';
  final wellDone = 'Gut gemacht!';
  String scheduleAlertFailed(Object error) =>
      'Erinnerung konnte nicht geplant werden: $error';
  String notificationsBlockedHint(Object error) =>
      '$error, daher können Sperrbildschirm-Timer und Ende-Hinweis nicht '
      'angezeigt werden.';
  String lockScreenFailed(Object error) =>
      'Sperrbildschirm-Timer fehlgeschlagen: $error';
  final phoneResting = 'Handy liegt still';
  final sensorUnavailable = 'Bewegungssensor nicht verfügbar';
  String phoneMoved(int seconds) => 'Handy bewegt. Pause beginnt in $seconds s';
  final history = 'Verlauf';
  String yesterdayMinutes(int minutes) => 'Gestern $minutes Min';

  // ---------- Timer-Benachrichtigungen ----------
  final notificationsOffApp = 'Benachrichtigungen sind für Paola ausgeschaltet';
  final notificationsOffTimer = 'Timer-Benachrichtigungen sind für Paola ausgeschaltet';
  String pausedAt(String time) => 'Pausiert - $time';
  final channelTimer = 'Lern-Timer';
  final channelTimerDesc = 'Zeigt den laufenden Timer auf dem Sperrbildschirm';
  final channelAlerts = 'Timer beendet';
  final channelAlertsDesc = 'Hinweis, wenn ein Pomodoro oder eine Pause endet';

  // ---------- Selbsteinschätzung ----------
  final rateSession = 'Bewerte deine Lernsitzung!';

  // ---------- Reflexion ----------
  String reflectionTitle(String duration) => '$duration gelernt';
  final reflectionActivitiesQuestion = 'Welche Aktivität(-en) hast du in dieser Lernsession durchgeführt?';
  String reflectionHowWent(String activity) => 'Wie lief $activity?';
  final reflectionTimeTitle = 'Zeit verteilen';
  String reflectionSum(String duration) => 'Summe: $duration';
  final reflectionSplitEvenly = 'Gleichmäßig verteilen';
  final reflectionTimeHint =
      'Die Zeit ist zunächst gleichmäßig verteilt. Mit den Reglern kannst du '
      'sie anders auf die Tätigkeiten aufteilen, die Summe bleibt gleich. '
      'Gespeichert wird mit „Sichern“.';
  final reflectionDiscard = 'Verwerfen';
  final reflectionContinue = 'Weiterlernen';
  final reflectionNext = 'Weiter';
  final reflectionSave = 'Sichern';
  final reflectionAhaMoment = 'Aha-Moment';
  final activityPrepareLecture = 'Vorlesung vorbereiten';
  final activityAttendLecture = 'Lehrveranstaltung besuchen / Video ansehen';
  final activityReviewLecture = 'Vorlesung nachbereiten';
  final activityExercises = 'Übungsaufgaben bearbeiten (inkl. Hausaufgaben, Programmieren)';
  final activityQuizzes = 'Quizze / Selbsttests durchführen';
  final activityRepeatSummarize = 'Inhalte wiederholen und zusammenfassen';
  final activityPeerExchange = 'Mit Kommilitonen austauschen (z.B. Lerngruppe)';
  final activityOrganize = 'Lernen organisieren (planen, Ziele setzen)';
  final activityOther = 'Weiteres';
  final moodPerfect = 'Perfekt';
  final moodGood = 'Gut';
  final moodNormal = 'Normal';
  final moodBad = 'Schlecht';
  final moodMiserable = 'Miserabel';

  // ---------- Verlauf ----------
  final thisWeek = 'Diese Woche';
  final sessions = 'Sitzungen';
  final pickedUp = 'Handy aufgehoben';
  final paused = 'Pausiert';
  String loadSessionsFailed(Object error) => 'Sitzungen konnten nicht geladen werden: $error';
  final noSessions = 'Noch keine Sitzungen. Beendete Timer erscheinen hier.';
  String deleteSessionMessage(String duration, String mode) => '$duration ($mode) wird aus deinem Verlauf entfernt. Das kann nicht rückgängig gemacht werden.';
  String deletingFailed(Object error) => 'Löschen fehlgeschlagen: $error';
  final deleteSession = 'Sitzung löschen';
  final notPickedUp = 'Nicht aufgehoben';
  String pickedUpTimes(int count, String time) => '$count× aufgehoben, $time';
  final today = 'Heute';
  final yesterday = 'Gestern';
  final weekdays = const [
    'Montag',
    'Dienstag',
    'Mittwoch',
    'Donnerstag',
    'Freitag',
    'Samstag',
    'Sonntag',
  ];

  // ---------- Einstellungen ----------
  final settingsTitle = 'Einstellungen';
  final profile = 'Profil';
  final loggedIn = 'Angemeldet';
  final savedOnDevice = 'Auf diesem Gerät gespeichert';
  final webApp = 'Web-App';
  final webAppNotConnected =
      'Nicht eingerichtet. Deine Daten bleiben auf diesem Gerät.';
  String webAppConnected(String server) => 'Verbunden mit $server';
  final setUp = 'Einrichten';
  final disconnect = 'Trennen';
  final nickname = 'Spitzname';
  final nicknameSaved = 'Spitzname gespeichert';
  final appearance = 'Darstellung';
  final darkMode = 'Dark Mode';
  final darkModeDesc = 'Dunkles Farbschema verwenden';
  String darkModeSaveFailed(String error) =>
      'Dark Mode konnte nicht gespeichert werden: $error';
  final hideTime = 'Zeit ausblenden';
  final hideTimeDesc =
      'Beim Lernen drei Punkte statt der Zeit zeigen. Pausen bleiben sichtbar.';
  final language = 'Sprache';
  final languageDesc = 'Sprache der App';
  final notifications = 'Benachrichtigungen';
  final timerNotifications = 'Timer-Benachrichtigungen';
  final timerNotificationsOn = 'An: Timer auf dem Sperrbildschirm und Hinweise';
  final timerNotificationsOff =
      'Aus: Timer auf dem Sperrbildschirm und Hinweise werden nicht angezeigt';
  final deleteMyData = 'Meine Daten löschen';
  final deleteMyDataDesc = 'Alle erfassten Daten entfernen.';
  final request = 'Anfragen';
  final requesting = 'Wird angefragt…';
  final deleteDataTitle = 'Deine Daten löschen?';
  final deleteDataMessage =
      'Dein Konto wird zur Löschung vorgemerkt und alle gespeicherten '
      'Lerndaten werden entfernt. Das kann nicht rückgängig gemacht werden.';
  final deletionRequested = 'Löschung angefragt';
  String deletionRequestFailed(String error) =>
      'Löschung konnte nicht angefragt werden: $error';

  // ---------- Seiten-Hilfe ----------
  final helpButtonTooltip = 'Hilfe zu dieser Seite';
  final helpClose = 'Hilfe schließen';
  final helpPomodoroTitle = 'Pomodoro-Timer';
  final helpPomodoroIntro = 'Lernen in festen Blöcken mit einer Pause danach.';
  final helpPomodoroBullets = const [
    'Lernzeit per Scrollen im Timer-Kreis einstellen und darunter die Pausenlänge wählen, dann „Starten“ oder auf den Kreis tippen.',
    'Auf den Kreis tippen, um zu pausieren bzw. fortzusetzen.',
    'Ist die Zeit um, kommt ein Hinweis und die Pause startet automatisch. Danach wirst du gefragt, was du gemacht hast und wie es lief.',
    'Leg das Handy währenddessen hin: Wird es länger als 10 Sekunden bewegt, pausiert der Timer.',
    '„Beenden und speichern“ legt die Sitzung im Verlauf ab, „Sitzung verwerfen“ löscht sie.',
  ];
  final helpStopwatchTitle = 'Stoppuhr';
  final helpStopwatchIntro = 'Misst einfach, wie lange du lernst - ohne Zeitvorgabe und ohne Pause.';
  final helpStopwatchBullets = const [
    '„Starten“ oder auf den Kreis tippen; der Ring füllt sich einmal pro Minute.',
    'Auf den Kreis tippen, um zu pausieren oder fortzusetzen.',
    'Leg das Handy währenddessen hin: Wird es länger als 10 Sekunden bewegt, pausiert der Timer.',
    '„Beenden und speichern“ legt die Sitzung im Verlauf ab, „Sitzung verwerfen“ löscht sie.',
  ];
  final helpFlowtimeTitle = 'Flowtime-Timer';
  final helpFlowtimeIntro = 'Lernen, solange die Konzentration reicht; die Pause richtet sich nach der Lernzeit.';
  final helpFlowtimeBullets = const [
    'Auf den Kreis tippen, um zu starten. Die Zeit läuft hoch, im Kreis steht die bis jetzt verdiente Pause.',
    'Lässt die Konzentration nach, erneut auf den Kreis tippen: Du gibst kurz an, was du gemacht hast, danach startet die Pause.',
    'Pausenlänge: \n bis 25 Min Lernzeit = 5 Min Pause, \n bis 50 Min = 8 Min Pause, länger = 10 Min Pause.',
    'Mit „Weiterlernen“ im Reflexionsfenster läuft derselbe Block ohne Pause weiter.',
    'Leg das Handy währenddessen hin: Wird es länger als 10 Sekunden bewegt, pausiert der Timer.',
  ];
  final helpHistoryTitle = 'Verlauf';
  final helpHistoryIntro = 'Deine gespeicherten Lernsitzungen.';
  final helpHistoryBullets = const [
    'Das Diagramm zeigt deine Lernzeit pro Tag in dieser Woche. Die roten Teile sind die Zeitabschnitte, wo das Handy aufgehoben wurde. Darunter die Gesamtzeit, Anzahl der Sitzungen und wie oft das Handy insgesamt aufgehoben wurde.',
    'Jede Sitzung hat eine Zeitleiste: grün, solange das Handy still lag, rot, wenn es aufgehoben wurde, grau für Pausen.',
    'Mit dem Papierkorb lässt sich eine Sitzung löschen.',
    'Nach unten ziehen lädt die Liste neu.',
  ];
  final helpSettingsTitle = 'Einstellungen';
  final helpSettingsIntro = 'Profil, Darstellung und die Verbindung zur Web-App.';
  final helpSettingsBullets = const [
    'Spitzname ändern und speichern.',
    'Deine Daten, Dark Mode und Sprache werden auf diesem Gerät gespeichert.',
    'Timer-Benachrichtigungen zeigen den laufenden Timer auf dem Sperrbildschirm und melden das Ende einer Pomodoro oder Pause.',
    'Unter „Web-App“ meldest du dich bei der Paola-Web-App an. Ist sie verbunden, kannst du dort auch die Löschung deiner Daten anfragen.',
  ];
}

class TranslationsEn extends Translations {
  const TranslationsEn();

  // ---------- General ----------
  final save = 'Save';
  final cancel = 'Cancel';
  final delete = 'Delete';
  final ok = 'OK';
  final turnOn = 'Turn on';
  final logOut = 'Log out';
  final noConnection = 'No connection to the server';

  // ---------- Errors ----------
  final errorInvalidUrl = 'Invalid URL, e.g. http://192.168.1.20:3000';
  final errorNoSessionCookie = 'No session cookie in server response';
  String errorNoAccess(int status) =>
      'Not logged in or no access (HTTP $status)';
  String errorRequest(String path, int status) =>
      'Error on $path (HTTP $status)';
  final errorLogin = 'Error while logging in';
  final errorDeletionFailed = 'Deletion request failed';

  // ---------- Bottom bar ----------
  final navHome = 'Home';
  final navTimer = 'Timer';
  final navSettings = 'Settings';

  // ---------- Login ----------
  final loginWelcome = 'Log in to Paola!';
  final loginUsername = 'Username';
  final loginPassword = 'Password';
  final loginForgotPassword = 'Forgot password';
  final loginEnterUsername = 'Please enter your username';
  final loginEnterPassword = 'Please enter your password';
  final loginButton = 'Log in';
  final loginContact = 'Contact';
  final serverTitle = 'Server';
  String serverDefault(String url) => 'Default: $url';
  final serverReset = 'Reset';

  // ---------- Home ----------
  final hello = 'Hello!';
  String helloName(String name) => 'Hello, $name!';

  // ---------- Timer ----------
  final timerTitle = 'Timer';
  final pomodoro = 'Pomodoro';
  final stopwatch = 'Stopwatch';
  final flowtime = 'Flowtime';
  final tapForBreak = 'Tap to take your break';
  final flowtimeHint = 'Study for as long as you can focus. Your break depends on how long you studied: up to 25 min → 5 min, up to 50 min → 8 min, longer → 10 min.';
  String flowtimeEarned(int minutes) => 'Break: $minutes min';
  final breakLabel = 'Break';
  final breakLength = 'Break length';
  final breakNone = 'None';
  String breakWithLength(String length) => 'Break, $length';
  String ofWork(String work) => 'of $work';
  final unitMin = 'min';
  final unitSec = 'sec';
  final tapToStart = 'Tap to start';
  final tapToPause = 'Tap to pause';
  final tapToResume = 'Tap to resume';
  final start = 'Start';
  final finishAndSave = 'Finish and save';
  final skipBreak = 'Skip break';
  final discardSession = 'Discard session';
  final discardTitle = 'Delete this session?';
  final discardMessage = "The time you've tracked so far will be discarded.";
  final pausedPickedUp = 'Timer paused: phone was picked up';
  String saveSessionFailed(Object error) => 'Saving the session failed: $error';
  final pomodoroFinished = 'Pomodoro finished';
  String breakTime(int minutes) => 'Time for a $minutes min break!';
  final breakOver = 'Break is over';
  final nextRound = 'Ready for the next round?';
  final wellDone = 'Well done!';
  String scheduleAlertFailed(Object error) =>
      'Could not schedule the alert: $error';
  String notificationsBlockedHint(Object error) =>
      "$error, so the lock screen timer and end alert can't show.";
  String lockScreenFailed(Object error) => 'Lock screen timer failed: $error';
  final phoneResting = 'Phone resting';
  final sensorUnavailable = 'Motion sensor unavailable';
  String phoneMoved(int seconds) => 'Phone moved. Pausing in $seconds s';
  final history = 'History';
  String yesterdayMinutes(int minutes) => 'Yesterday $minutes min';

  // ---------- Timer notifications ----------
  final notificationsOffApp = 'Notifications are turned off for Paola';
  final notificationsOffTimer = 'Timer notifications are turned off for Paola';
  String pausedAt(String time) => 'Paused · $time';
  final channelTimer = 'Study timer';
  final channelTimerDesc = 'Shows the running timer on the lock screen';
  final channelAlerts = 'Timer finished';
  final channelAlertsDesc = 'Alerts when a pomodoro or break is over';

  // ---------- Self assessment ----------
  final rateSession = 'Rate your study session!';

  // ---------- Reflection ----------
  String reflectionTitle(String duration) => '$duration studied';
  final reflectionActivitiesQuestion =
      'Which activities did you do in this study session?';
  String reflectionHowWent(String activity) => 'How did "$activity" go?';
  final reflectionTimeTitle = 'Split the time';
  String reflectionSum(String duration) => 'Total: $duration';
  final reflectionSplitEvenly = 'Split evenly';
  final reflectionTimeHint =
      'The time starts out split evenly. Use the sliders to divide it '
      'differently between the activities; the total stays the same. '
      'Tap "Save" to keep it.';
  final reflectionDiscard = 'Discard';
  final reflectionContinue = 'Keep studying';
  final reflectionNext = 'Next';
  final reflectionSave = 'Save';
  final reflectionAhaMoment = 'Aha moment';
  final activityPrepareLecture = 'Prepare a lecture';
  final activityAttendLecture = 'Attend a class / watch a video';
  final activityReviewLecture = 'Review a lecture';
  final activityExercises =
      'Work on exercises (incl. homework, programming)';
  final activityQuizzes = 'Take quizzes / self-tests';
  final activityRepeatSummarize = 'Revise and summarise content';
  final activityPeerExchange = 'Talk with fellow students (study group)';
  final activityOrganize = 'Organise studying (plan, set goals)';
  final activityOther = 'Other';
  final moodPerfect = 'Perfect';
  final moodGood = 'Good';
  final moodNormal = 'Okay';
  final moodBad = 'Bad';
  final moodMiserable = 'Miserable';

  // ---------- History ----------
  final thisWeek = 'This week';
  final sessions = 'Sessions';
  final pickedUp = 'Picked up';
  final paused = 'Paused';
  String loadSessionsFailed(Object error) => 'Could not load sessions: $error';
  final noSessions = 'No sessions yet. Finished timers show up here.';
  String deleteSessionMessage(String duration, String mode) =>
      "$duration ($mode) will be removed from your history. This can't be "
      'undone.';
  String deletingFailed(Object error) => 'Deleting failed: $error';
  final deleteSession = 'Delete session';
  final notPickedUp = 'Not picked up';
  String pickedUpTimes(int count, String time) => 'Picked up $count×, $time';
  final today = 'Today';
  final yesterday = 'Yesterday';
  final weekdays = const [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  // ---------- Settings ----------
  final settingsTitle = 'Settings';
  final profile = 'Profile';
  final loggedIn = 'Logged in';
  final savedOnDevice = 'Saved on this device';
  final webApp = 'Web app';
  final webAppNotConnected = 'Not set up. Your data stays on this device.';
  String webAppConnected(String server) => 'Connected to $server';
  final setUp = 'Set up';
  final disconnect = 'Disconnect';
  final nickname = 'Nickname';
  final nicknameSaved = 'Nickname saved';
  final appearance = 'Appearance';
  final darkMode = 'Dark mode';
  final darkModeDesc = 'Use a dark color scheme';
  String darkModeSaveFailed(String error) => 'Could not save dark mode: $error';
  final hideTime = 'Hide time';
  final hideTimeDesc =
      'Show three dots instead of the time while studying. Breaks stay visible.';
  final language = 'Language';
  final languageDesc = 'Language of the app';
  final notifications = 'Notifications';
  final timerNotifications = 'Timer notifications';
  final timerNotificationsOn = 'On: lock screen timer and end alerts';
  final timerNotificationsOff =
      "Off: the lock screen timer and end alerts won't show";
  final deleteMyData = 'Delete my data';
  final deleteMyDataDesc = 'Remove all recorded data.';
  final request = 'Request';
  final requesting = 'Requesting…';
  final deleteDataTitle = 'Delete your data?';
  final deleteDataMessage =
      'Your account will be marked for deletion and all your stored learning '
      "data will be removed. This can't be undone.";
  final deletionRequested = 'Deletion requested';
  String deletionRequestFailed(String error) =>
      'Could not request deletion: $error';

  // ---------- Page help ----------
  final helpButtonTooltip = 'Help for this page';
  final helpClose = 'Close help';
  final helpPomodoroTitle = 'Pomodoro timer';
  final helpPomodoroIntro = 'Study in fixed blocks with a break afterwards.';
  final helpPomodoroBullets = const [
    'Set the study time by scrolling in the timer circle and pick a break length below, then tap "Start" or the circle to start.',
    'Tap the circle to pause or resume.',
    "When the time is up you get an alert and the break starts automatically. Then you're asked what you did and how it went.",
    'Put your phone down: if it moves for more than 10 seconds, the timer pauses.',
    '"Finish and save" stores the session in your history, "Discard session" deletes it.',
  ];
  final helpStopwatchTitle = 'Stopwatch';
  final helpStopwatchIntro = 'Simply measures how long you study, no time limit and no break.';
  final helpStopwatchBullets = const [
    'Tap "Start" or the circle; the ring fills once per minute.',
    'Tap the circle to pause or resume.',
    'Put your phone down: if it moves for more than 10 seconds, the timer pauses.',
    '"Finish and save" stores the session in your history, "Discard session" deletes it.',
  ];
  final helpFlowtimeTitle = 'Flowtime timer';
  final helpFlowtimeIntro = 'Study for as long as you can focus; your break depends on how long you studied.';
  final helpFlowtimeBullets = const [
    'Tap the circle to start. The time counts up and the circle shows the break you have earned so far.',
    'When your focus fades, tap the circle again: you briefly note what you did, then the break starts.',
    'Break length: up to 25 min of study = 5 min break, up to 50 min = 8 min break, longer = 10 min break.',
    '"Keep studying" in the reflection carries on with the same block without a break.',
    'Put your phone down: if it moves for more than 10 seconds, the timer pauses.',
  ];
  final helpHistoryTitle = 'History';
  final helpHistoryIntro = 'Your saved study sessions.';
  final helpHistoryBullets = const [
    'The chart shows your study time per day this week; below it the total time, number of sessions and how often the phone was picked up.',
    'Each session has a timeline: green while the phone lay still, red when it was picked up, grey for pauses.',
    'Use the bin icon to delete a session.',
    'Pull down to reload the list.',
  ];
  final helpSettingsTitle = 'Settings';
  final helpSettingsIntro = 'Profile, appearance and the web app connection.';
  final helpSettingsBullets = const [
    'Change your nickname and save it.',
    'Your data, dark mode and language are stored on this device.',
    'Timer notifications show the running timer on the lock screen and alert you when a pomodoro or break ends.',
    'Under "Web app" you log in to the Paola web app. Once it is connected you can also request the deletion of your data there.',
  ];
}
