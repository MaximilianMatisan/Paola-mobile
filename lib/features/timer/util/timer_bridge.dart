
import 'package:flutter/services.dart';

class TimerBridge {
  static const _methodChannel = MethodChannel('interactivenotification/state');

  static Future<Map<String, dynamic>?> getState() =>
      _methodChannel.invokeMapMethod<String, dynamic>('getState');

  static Future<int?> consumeFinishedSeconds() => 
      _methodChannel.invokeMethod<int>('consumeFinishedSeconds');
  
  static Future<int?> consumeFinishedAtMs() =>
      _methodChannel.invokeMethod<int>('consumeFinishedAtMs');

  static Future<bool?> consumeBreakDiscarded() =>
      _methodChannel.invokeMethod<bool>('consumeBreakDiscarded');

  static Future<String?> consumeSelfAssessmentMoodString() =>
      _methodChannel.invokeMethod<String>('consumeSelfAssessmentMoodString');
}