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
  String get saving;
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
  String get loginSubtitle;
  String get loginUsername;
  String get loginPassword;
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
  String get breakLabel;
  String get breakLength;
  String get breakNone;
  String breakWithLength(String length);
  String ofWork(String work);
  String get unitMin;
  String get unitSec;
  String get more;
  String get less;
  String get start;
  String get pause;
  String get resume;
  String get finishAndSave;
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
  String settingsLoadFailed(String error);
  String get profile;
  String get loggedIn;
  String get nickname;
  String get nicknameSaved;
  String nicknameSaveFailed(String error);
  String get appearance;
  String get darkMode;
  String get darkModeDesc;
  String darkModeSaveFailed(String error);
  String get language;
  String get languageDesc;
  String languageSaveFailed(String error);
  String get notifications;
  String get timerNotifications;
  String get timerNotificationsOn;
  String get timerNotificationsOff;
  String get dataPrivacy;
  String get deleteMyData;
  String get deleteMyDataDesc;
  String get request;
  String get requesting;
  String get deleteDataTitle;
  String get deleteDataMessage;
  String get deletionRequested;
  String deletionRequestFailed(String error);
}

class TranslationsDe extends Translations {
  const TranslationsDe();

  // ---------- Allgemeines ----------
  final save = 'Speichern';
  final saving = 'Speichern…';
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
  final loginWelcome = 'Willkommen bei Paola';
  final loginSubtitle = 'Melde dich an, um fortzufahren';
  final loginUsername = 'Benutzername';
  final loginPassword = 'Passwort';
  final loginEnterUsername = 'Bitte gib deinen Benutzernamen ein';
  final loginEnterPassword = 'Bitte gib dein Passwort ein';
  final loginButton = 'ANMELDEN';
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
  final breakLabel = 'Pause';
  final breakLength = 'Pausenlänge';
  final breakNone = 'Keine';
  String breakWithLength(String length) => 'Pause, $length';
  String ofWork(String work) => 'von $work';
  final unitMin = 'Min';
  final unitSec = 'Sek';
  final more = 'Mehr';
  final less = 'Weniger';
  final start = 'Starten';
  final pause = 'Pausieren';
  final resume = 'Fortsetzen';
  final finishAndSave = 'Beenden und speichern';
  final discardSession = 'Sitzung verwerfen';
  final discardTitle = 'Diese Sitzung löschen?';
  final discardMessage = 'Die bisher erfasste Zeit wird verworfen.';
  final pausedPickedUp = 'Timer pausiert: Handy wurde hochgenommen';
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
  String phoneMoved(int seconds) => 'Handy bewegt. Pause in $seconds s';
  final history = 'Verlauf';
  String yesterdayMinutes(int minutes) => 'Gestern $minutes Min';

  // ---------- Timer-Benachrichtigungen ----------
  final notificationsOffApp = 'Benachrichtigungen sind für Paola ausgeschaltet';
  final notificationsOffTimer =
      'Timer-Benachrichtigungen sind für Paola ausgeschaltet';
  String pausedAt(String time) => 'Pausiert · $time';
  final channelTimer = 'Lern-Timer';
  final channelTimerDesc = 'Zeigt den laufenden Timer auf dem Sperrbildschirm';
  final channelAlerts = 'Timer beendet';
  final channelAlertsDesc = 'Hinweis, wenn ein Pomodoro oder eine Pause endet';

  // ---------- Selbsteinschätzung ----------
  final rateSession = 'Bewerte deine Lernsitzung!';

  // ---------- Reflexion ----------
  String reflectionTitle(String duration) => '$duration gelernt';
  final reflectionActivitiesQuestion =
      'Welche Tätigkeiten hast du in dieser Lernsession durchgeführt?';
  String reflectionHowWent(String activity) => 'Wie lief $activity?';
  final reflectionTimeTitle = 'Zeit verteilen';
  String reflectionSum(String duration) => 'Summe: $duration';
  final reflectionSplitEvenly = 'Gleichmäßig verteilen';
  final reflectionTimeHint =
      'Die Zeit ist zunächst gleichmäßig verteilt. Mit den Reglern kannst du '
      'sie anders auf die Tätigkeiten aufteilen, die Summe bleibt gleich. '
      'Gesichert wird mit „Sichern“.';
  final reflectionDiscard = 'Verwerfen';
  final reflectionContinue = 'Weiterlernen';
  final reflectionNext = 'Weiter';
  final reflectionSave = 'Sichern';
  final activityPrepareLecture = 'Vorlesung vorbereiten';
  final activityAttendLecture = 'Lehrveranstaltung besuchen / Video ansehen';
  final activityReviewLecture = 'Vorlesung nachbereiten';
  final activityExercises =
      'Übungsaufgaben bearbeiten (inkl. Hausaufgaben, Programmieren)';
  final activityQuizzes = 'Quizze / Selbsttests durchführen';
  final activityRepeatSummarize = 'Inhalte wiederholen und zusammenfassen';
  final activityPeerExchange = 'Mit Studierenden austauschen (Lerngruppe)';
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
  final pickedUp = 'Hochgenommen';
  final paused = 'Pausiert';
  String loadSessionsFailed(Object error) =>
      'Sitzungen konnten nicht geladen werden: $error';
  final noSessions = 'Noch keine Sitzungen. Beendete Timer erscheinen hier.';
  String deleteSessionMessage(String duration, String mode) =>
      '$duration ($mode) wird aus deinem Verlauf entfernt. Das kann nicht '
      'rückgängig gemacht werden.';
  String deletingFailed(Object error) => 'Löschen fehlgeschlagen: $error';
  final deleteSession = 'Sitzung löschen';
  final notPickedUp = 'Nicht hochgenommen';
  String pickedUpTimes(int count, String time) => '$count× hochgenommen, $time';
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
  String settingsLoadFailed(String error) =>
      'Einstellungen konnten nicht geladen werden: $error';
  final profile = 'Profil';
  final loggedIn = 'Angemeldet';
  final nickname = 'Spitzname';
  final nicknameSaved = 'Spitzname gespeichert';
  String nicknameSaveFailed(String error) =>
      'Spitzname konnte nicht gespeichert werden: $error';
  final appearance = 'Darstellung';
  final darkMode = 'Dark Mode';
  final darkModeDesc = 'Dunkles Farbschema verwenden';
  String darkModeSaveFailed(String error) =>
      'Dark Mode konnte nicht gespeichert werden: $error';
  final language = 'Sprache';
  final languageDesc = 'Sprache der App';
  String languageSaveFailed(String error) =>
      'Sprache konnte nicht gespeichert werden: $error';
  final notifications = 'Benachrichtigungen';
  final timerNotifications = 'Timer-Benachrichtigungen';
  final timerNotificationsOn = 'An: Timer auf dem Sperrbildschirm und Hinweise';
  final timerNotificationsOff =
      'Aus: Timer auf dem Sperrbildschirm und Hinweise werden nicht angezeigt';
  final dataPrivacy = 'Daten und Datenschutz';
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
}

class TranslationsEn extends Translations {
  const TranslationsEn();

  // ---------- General ----------
  final save = 'Save';
  final saving = 'Saving…';
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
  final loginWelcome = 'Welcome to Paola';
  final loginSubtitle = 'Log in to continue';
  final loginUsername = 'Username';
  final loginPassword = 'Password';
  final loginEnterUsername = 'Please enter your username';
  final loginEnterPassword = 'Please enter your password';
  final loginButton = 'LOG IN';
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
  final breakLabel = 'Break';
  final breakLength = 'Break length';
  final breakNone = 'None';
  String breakWithLength(String length) => 'Break, $length';
  String ofWork(String work) => 'of $work';
  final unitMin = 'min';
  final unitSec = 'sec';
  final more = 'More';
  final less = 'Less';
  final start = 'Start';
  final pause = 'Pause';
  final resume = 'Resume';
  final finishAndSave = 'Finish and save';
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
  String settingsLoadFailed(String error) => 'Could not load settings: $error';
  final profile = 'Profile';
  final loggedIn = 'Logged in';
  final nickname = 'Nickname';
  final nicknameSaved = 'Nickname saved';
  String nicknameSaveFailed(String error) => 'Could not save nickname: $error';
  final appearance = 'Appearance';
  final darkMode = 'Dark mode';
  final darkModeDesc = 'Use a dark color scheme';
  String darkModeSaveFailed(String error) => 'Could not save dark mode: $error';
  final language = 'Language';
  final languageDesc = 'Language of the app';
  String languageSaveFailed(String error) => 'Could not save language: $error';
  final notifications = 'Notifications';
  final timerNotifications = 'Timer notifications';
  final timerNotificationsOn = 'On: lock screen timer and end alerts';
  final timerNotificationsOff =
      "Off: the lock screen timer and end alerts won't show";
  final dataPrivacy = 'Data and privacy';
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
}
