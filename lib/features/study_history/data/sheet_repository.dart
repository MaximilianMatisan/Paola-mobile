// Exercise sheets for the analysis tab. They come from the web app (when it
// is connected) and are kept on the device, so the sheets still show offline.
// The copy lives in shared preferences, the sessions database stays as is.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:paola_mobile/core/network/paola_api.dart';
import 'package:paola_mobile/features/study_history/models/exercise_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SheetRepository {
  SheetRepository._();
  static final SheetRepository instance = SheetRepository._();

  static const _prefsKey = 'exercise_sheets';

  /// Sheets from the web app if it can be reached, otherwise the last saved
  /// ones; empty if there are none.
  Future<List<ExerciseSheet>> sheets() async {
    final api = PaolaApi.instance;
    if (api.loggedIn) {
      try {
        final fresh = await api.sheets();
        await _save(fresh);
        return fresh;
      } catch (e) {
        debugPrint('Loading sheets failed, using saved ones: $e');
      }
    }
    return _saved();
  }

  Future<void> _save(List<ExerciseSheet> sheets) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode([for (final s in sheets) s.toJson()]),
    );
  }

  Future<List<ExerciseSheet>> _saved() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return [];
    try {
      return [
        for (final s in jsonDecode(raw) as List)
          ExerciseSheet.fromJson(s as Map<String, dynamic>),
      ];
    } catch (_) {
      return [];
    }
  }
}
