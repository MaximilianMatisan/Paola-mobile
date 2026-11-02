import 'package:flutter_test/flutter_test.dart';
import 'package:paola_mobile/features/timer/util/flowtime.dart';

void main() {
  test('break length follows Smits et al. (2025)', () {
    expect(flowtimeBreakMinutes(const Duration(minutes: 3)), 5);
    expect(flowtimeBreakMinutes(const Duration(minutes: 25)), 5);
    expect(flowtimeBreakMinutes(const Duration(minutes: 25, seconds: 1)), 8);
    expect(flowtimeBreakMinutes(const Duration(minutes: 50)), 8);
    expect(flowtimeBreakMinutes(const Duration(minutes: 50, seconds: 1)), 10);
    expect(flowtimeBreakMinutes(const Duration(hours: 2)), 10);
  });
}
