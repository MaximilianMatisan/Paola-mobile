// Flowtime: study for as long as you can focus, then take a break whose
// length depends on how long the study block was. The thresholds follow
// Smits, Wenzel & de Bruin (2025), "Investigating the Effectiveness of
// Self-Regulated, Pomodoro, and Flowtime Break-Taking Techniques Among
// Students", Behavioral Sciences 15(7), 861.

/// Break length in minutes earned by a study block of [studied]:
/// up to 25 min → 5 min, up to 50 min → 8 min, longer → 10 min.
int flowtimeBreakMinutes(Duration studied) {
  final minutes = studied.inSeconds / 60;
  if (minutes <= 25) return 5;
  if (minutes <= 50) return 8;
  return 10;
}
