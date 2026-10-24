// Movement detection via the accelerometer while the timer runs (adapted from
// focus_sensor.dart of testing_mobile_paola).
//
// Motion is the change of the acceleration vector between two samples
// (|a_now - a_before|), independent of how the phone lies. Sustained motion
// starts a 10 s countdown; if the phone settles again the countdown is
// cancelled, otherwise [onTimeout] fires (the timer then pauses).
//
// While monitoring, the running time is recorded as gapless periods
// (still / picked up), which are saved as the session's timeline.

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'package:paola_mobile/core/network/paola_api.dart';

class MovementSensor extends ChangeNotifier {
  MovementSensor({required this.onTimeout});

  /// Called when the countdown reached zero without the phone settling.
  final VoidCallback onTimeout;

  static const countdownSeconds = 10;

  /// Max change of the acceleration vector (m/s²) between two samples that
  /// still counts as "lying still"; small bumps on the table stay below it.
  static const double _threshold = 0.7;

  /// Motion must last this long before it counts as picking the phone up.
  static const _pickUpTime = Duration(seconds: 1);

  /// Gaps in the motion shorter than this don't interrupt it.
  static const _motionGap = Duration(milliseconds: 600);

  /// The phone counts as put down again after this long without motion.
  static const _settleTime = Duration(seconds: 2);

  StreamSubscription<AccelerometerEvent>? _sub;
  Timer? _countdownTimer;
  double? _prevX, _prevY, _prevZ;
  DateTime? _movingSince;
  DateTime? _lastMotion;

  final List<FocusPeriod> _periods = [];
  DateTime? _periodStart;

  bool get monitoring => _periodStart != null;

  /// False if the device has no (working) accelerometer.
  bool available = true;

  /// Seconds left before the timer pauses; null while the phone lies still.
  int? countdown;

  bool get pickedUp => countdown != null;

  /// Starts monitoring; the phone is assumed to lie still at first.
  void start() {
    if (monitoring) return;
    _periodStart = DateTime.now();
    // No accelerometer plugin on desktop (e.g. when testing on Linux).
    if (!Platform.isAndroid && !Platform.isIOS) {
      available = false;
      notifyListeners();
      return;
    }
    _sub =
        accelerometerEventStream(
          samplingPeriod: const Duration(milliseconds: 200),
        ).listen(
          _onEvent,
          onError: (Object _) {
            available = false;
            _sub?.cancel();
            notifyListeners();
          },
        );
    notifyListeners();
  }

  /// Stops monitoring and closes the current period.
  void stop() {
    if (!monitoring) return;
    _sub?.cancel();
    _sub = null;
    _countdownTimer?.cancel();
    _closePeriod(DateTime.now(), pickedUp: pickedUp);
    _periodStart = null;
    countdown = null;
    _prevX = _prevY = _prevZ = null;
    _movingSince = _lastMotion = null;
    notifyListeners();
  }

  /// Returns the periods recorded so far and forgets them.
  List<FocusPeriod> takePeriods() {
    final periods = List.of(_periods);
    _periods.clear();
    return periods;
  }

  void _closePeriod(DateTime end, {required bool pickedUp}) {
    final start = _periodStart!;
    if (end.isAfter(start)) {
      _periods.add(FocusPeriod(start: start, end: end, pickedUp: pickedUp));
    }
    _periodStart = end;
  }

  void _onEvent(AccelerometerEvent e) {
    final px = _prevX, py = _prevY, pz = _prevZ;
    _prevX = e.x;
    _prevY = e.y;
    _prevZ = e.z;
    if (px == null || py == null || pz == null) return;
    final dx = e.x - px, dy = e.y - py, dz = e.z - pz;
    final motion = math.sqrt(dx * dx + dy * dy + dz * dz);

    final now = DateTime.now();
    if (motion >= _threshold) {
      if (_lastMotion == null || now.difference(_lastMotion!) > _motionGap) {
        _movingSince = now;
      }
      _lastMotion = now;
      if (!pickedUp && now.difference(_movingSince!) >= _pickUpTime) {
        _startCountdown(_movingSince!);
      }
    }
  }

  void _startCountdown(DateTime since) {
    _closePeriod(since, pickedUp: false);
    countdown = countdownSeconds;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final lastMotion = _lastMotion!;
      if (DateTime.now().difference(lastMotion) >= _settleTime) {
        // Put down again in time: the pick-up ends with the last motion.
        _countdownTimer?.cancel();
        _closePeriod(lastMotion, pickedUp: true);
        countdown = null;
      } else {
        countdown = countdown! - 1;
        if (countdown! <= 0) {
          onTimeout();
          return;
        }
      }
      notifyListeners();
    });
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }
}
