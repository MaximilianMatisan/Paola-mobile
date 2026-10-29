// Connection to the Paola web app (Next.js API routes).
//
// paola web authenticates via cookie "paola_session" (JWT),
// issued by POST /api/auth/login
// store that cookie after login and send as a header on every api request
// -> mobile app works on the same database
//
// Used endpoints:
//   POST /api/auth/login    {username, password} -> Set-Cookie (AuthApi)
//   GET  /api/user/get      -> { user: {...} }
//   GET  /api/study_log/byOwner -> { logs: [{start, duration, ...}] }
//   POST /api/user/update   {id, nickname}
//   GET  /api/user/preferences -> { preferences: {dark_mode, language, ...} }
//   POST /api/user/preferences {all preference flags}
//   POST /api/user/request_deletion {reasons, comment}
//   POST /api/focus_period/create {session_start, is_pomodoro, periods, reflection}
//   GET  /api/focus_period/byOwner -> { sessions: [{session_start, periods, reflection}] }
//   POST /api/focus_period/delete {session_start}
//
// Login itself goes through AuthRepository (dio), which hands the session
// cookie over via [PaolaApi.takeSessionCookie].
//
// The server is API_URL from .env, or the address entered on the login
// screen (e.g. the dev machine's LAN IP). Requests go to it plus the Next.js
// basePath "/paola"; ApiClient (dio) is pointed at the same server.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:paola_mobile/core/l10n/app_language.dart';
import 'package:paola_mobile/core/l10n/translations.dart';
import 'package:paola_mobile/core/network/api_client.dart';
import 'package:paola_mobile/core/network/api_exception.dart';
import 'package:paola_mobile/features/timer/models/study_activity.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppUser {
  final int id;
  final String nickname;

  AppUser({required this.id, required this.nickname});

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] as int,
    nickname: (json['nickname'] ?? '') as String,
  );
}

/// Part of a timer session in which the phone layed still or was picked up
class FocusPeriod {
  final DateTime start;
  final DateTime end;
  final bool pickedUp;

  FocusPeriod({required this.start, required this.end, required this.pickedUp});

  Duration get duration => end.difference(start);

  factory FocusPeriod.fromJson(Map<String, dynamic> json) => FocusPeriod(
    start: DateTime.fromMillisecondsSinceEpoch((json['start'] as num).toInt()),
    end: DateTime.fromMillisecondsSinceEpoch((json['end'] as num).toInt()),
    pickedUp: json['picked_up'] == true,
  );

  Map<String, dynamic> toJson() => {
    'start': start.millisecondsSinceEpoch,
    'end': end.millisecondsSinceEpoch,
    'picked_up': pickedUp,
  };
}

/// A recorded timer session. Gaps between the periods are pauses.
class FocusSession {
  final DateTime start;
  final bool pomodoro;
  final List<FocusPeriod> periods;

  /// What was done in the session; null if the user gave no reflection.
  final List<ActivityReflection>? reflection;

  FocusSession({
    required this.start,
    required this.pomodoro,
    required this.periods,
    this.reflection,
  });

  FocusSession withReflection(List<ActivityReflection>? reflection) =>
      FocusSession(
        start: start,
        pomodoro: pomodoro,
        periods: periods,
        reflection: reflection,
      );

  Duration get duration =>
      periods.fold(Duration.zero, (sum, p) => sum + p.duration);

  factory FocusSession.fromJson(Map<String, dynamic> json) => FocusSession(
    start: DateTime.fromMillisecondsSinceEpoch(
      (json['session_start'] as num).toInt(),
    ),
    pomodoro: json['is_pomodoro'] == true,
    periods: [
      for (final p in json['periods'] as List)
        FocusPeriod.fromJson(p as Map<String, dynamic>),
    ],
    reflection: switch (json['reflection']) {
      final List list => [
        for (final r in list)
          ?ActivityReflection.fromJson(r as Map<String, dynamic>),
      ],
      _ => null,
    },
  );
}

class PaolaApi {
  PaolaApi._();
  static final PaolaApi instance = PaolaApi._();

  static const _cookieName = 'paola_session';
  static const _prefsCookie = 'api_session_cookie';
  static const _prefsServerUrl = 'api_server_url';
  static const _basePath = '/paola';
  static const _timeout = Duration(seconds: 10);

  /// Server from .env, e.g. http://localhost:3000.
  late final String defaultServerUrl;

  /// Server in use: [defaultServerUrl] or the one entered on the login screen.
  late String serverUrl;
  String? _sessionCookie;

  bool get loggedIn => _sessionCookie != null;

  String get _baseUrl => serverUrl + _basePath;

  /// Reads the server URL from .env (or the saved override) and restores a
  /// saved session.
  Future<void> init() async {
    final url = dotenv.maybeGet('API_URL');
    if (url == null || url.trim().isEmpty) {
      throw StateError('API_URL is missing in .env');
    }
    defaultServerUrl = _normalize(url);
    final prefs = await SharedPreferences.getInstance();
    _useServer(prefs.getString(_prefsServerUrl) ?? defaultServerUrl);
    _sessionCookie = prefs.getString(_prefsCookie);
  }

  static String _normalize(String url) =>
      url.trim().replaceAll(RegExp(r'/+$'), '');

  /// Uses [url] instead of the .env server; empty resets to the default.
  Future<void> setServerUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = _normalize(url);
    if (normalized.isEmpty || normalized == defaultServerUrl) {
      _useServer(defaultServerUrl);
      await prefs.remove(_prefsServerUrl);
      return;
    }
    final uri = Uri.tryParse(normalized);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw ApiException(message: AppLanguage.t.errorInvalidUrl);
    }
    _useServer(normalized);
    await prefs.setString(_prefsServerUrl, normalized);
  }

  void _useServer(String url) {
    serverUrl = url;
    ApiClient.instance.dio.options.baseUrl = url;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    if (_sessionCookie == null) {
      await prefs.remove(_prefsCookie);
    } else {
      await prefs.setString(_prefsCookie, _sessionCookie!);
    }
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_sessionCookie != null) 'Cookie': '$_cookieName=$_sessionCookie',
  };

  /// Appends the API path to the base URL, keeping its path prefix
  /// (Next.js basePath "/paola").
  Uri _uri(String path, [Map<String, String>? query]) {
    final base = Uri.parse(_baseUrl);
    return base.replace(path: '${base.path}$path', queryParameters: query);
  }

  Map<String, dynamic>? _decode(http.Response res) {
    try {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Stores the session from the Set-Cookie header of the login response.
  Future<void> takeSessionCookie(String? setCookie) async {
    final match = setCookie == null
        ? null
        : RegExp('$_cookieName=([^;]+)').firstMatch(setCookie);
    if (match == null) {
      throw ApiException(message: AppLanguage.t.errorNoSessionCookie);
    }
    _sessionCookie = match.group(1);
    await _persist();
  }

  Future<void> logout() async {
    _sessionCookie = null;
    await _persist();
  }

  Future<dynamic> _get(String path, [Map<String, String>? query]) async {
    final res = await http
        .get(_uri(path, query), headers: _headers)
        .timeout(_timeout);
    if (res.statusCode == 401 || res.statusCode == 403) {
      throw ApiException(message: AppLanguage.t.errorNoAccess(res.statusCode));
    }
    if (res.statusCode != 200) {
      throw ApiException(
        message: AppLanguage.t.errorRequest(path, res.statusCode),
      );
    }
    return jsonDecode(res.body);
  }

  Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    final res = await http
        .post(_uri(path), headers: _headers, body: jsonEncode(body))
        .timeout(_timeout);
    if (res.statusCode == 401 || res.statusCode == 403) {
      throw ApiException(message: AppLanguage.t.errorNoAccess(res.statusCode));
    }
    if (res.statusCode != 200) {
      throw ApiException(
        message:
            _decode(res)?['error']?.toString() ??
            AppLanguage.t.errorRequest(path, res.statusCode),
      );
    }
    return jsonDecode(res.body);
  }

  /// see /api/user/get of paola web app
  Future<AppUser?> currentUser() async {
    final body = await _get('/api/user/get');
    final u = body['user'];
    if (u == null) return null;
    return AppUser.fromJson(u as Map<String, dynamic>);
  }

  /// Total study time (from the web app's study_log) whose start falls on
  /// [day] in local time. see /api/study_log/byOwner of paola web app
  Future<Duration> studyTimeOn(DateTime day) async {
    final body = await _get('/api/study_log/byOwner');
    final logs = body['logs'];
    if (logs is! List) return Duration.zero;
    var seconds = 0;
    for (final log in logs) {
      final start = DateTime.tryParse('${log['start']}')?.toLocal();
      if (start == null ||
          start.year != day.year ||
          start.month != day.month ||
          start.day != day.day) {
        continue;
      }
      seconds += (log['duration'] as num?)?.toInt() ?? 0;
    }
    return Duration(seconds: seconds);
  }

  /// see /api/user/update of paola web app
  Future<void> updateNickname(int userId, String nickname) async {
    await _post('/api/user/update', {'id': userId, 'nickname': nickname});
  }

  /// Raw preference flags (dark_mode, data_sharing, …) as 0/1.
  /// see /api/user/preferences of paola web app
  Future<Map<String, dynamic>> preferences() async {
    final body = await _get('/api/user/preferences');
    return Map<String, dynamic>.from(body['preferences'] as Map);
  }

  Future<void> setDarkMode(bool enabled) =>
      _setPreference('dark_mode', enabled ? 1 : 0);

  Future<void> setLanguage(Language language) =>
      _setPreference('language', language.flag);

  /// The web app overwrites every flag on POST, so the current preferences
  /// are sent back with only [key] changed.
  Future<void> _setPreference(String key, int value) async {
    final prefs = await preferences()
      ..remove('user_id');
    prefs[key] = value;
    await _post('/api/user/preferences', prefs);
  }

  /// Marks the account for deletion; researchers then delete the data.
  /// see /api/user/request_deletion of paola web app
  Future<void> requestDeletion() async {
    final body = await _post('/api/user/request_deletion', {
      'reasons': <String>[],
      'comment': '',
    });
    if (body['success'] != true) {
      throw ApiException(
        message: body['error']?.toString() ?? AppLanguage.t.errorDeletionFailed,
      );
    }
  }

  /// Bumped whenever a session was saved, so the history can reload.
  final sessionsChanged = ValueNotifier(0);

  /// see /api/focus_period/create of paola web app
  Future<void> saveSession(FocusSession session) async {
    await _post('/api/focus_period/create', {
      'session_start': session.start.millisecondsSinceEpoch,
      'is_pomodoro': session.pomodoro,
      'periods': [for (final p in session.periods) p.toJson()],
      if (session.reflection case final reflection?)
        'reflection': [for (final r in reflection) r.toJson()],
    });
    sessionsChanged.value++;
  }

  /// Recorded sessions, newest first. see /api/focus_period/byOwner
  Future<List<FocusSession>> sessions() async {
    final body = await _get('/api/focus_period/byOwner');
    return [
      for (final s in body['sessions'] as List)
        FocusSession.fromJson(s as Map<String, dynamic>),
    ];
  }

  /// see /api/focus_period/delete of paola web app
  Future<void> deleteSession(FocusSession session) async {
    await _post('/api/focus_period/delete', {
      'session_start': session.start.millisecondsSinceEpoch,
    });
  }
}
