import 'package:flutter/material.dart';
import 'package:paola_mobile/core/l10n/app_language.dart';
import 'package:paola_mobile/core/navigation/main_environment.dart';
import 'package:paola_mobile/core/util/constants.dart';
import 'package:live_activities/live_activities.dart';

import 'widgets/self_assessment.dart';
import '../util/timer_bridge.dart';


class SelfAssessmentPage extends StatefulWidget {
  const SelfAssessmentPage({super.key});

  final String title = 'Self Assessment';

  @override
  State<SelfAssessmentPage> createState() => _SelfAssessmentPageState();
}

class _SelfAssessmentPageState extends State<SelfAssessmentPage> with WidgetsBindingObserver {

  final _liveActivityPlugin = LiveActivities();

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    _liveActivityPlugin.init(appGroupId: appGroupId);
    super.initState();
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkForNativeAssessment();
    }
    super.didChangeAppLifecycleState(state);
  }

  Future<void> _checkForNativeAssessment() async {
    String? moodString = await TimerBridge.consumeSelfAssessmentMoodString();

    if (moodString != null) {
      _rateStudySession();
      debugPrint('$moodString mood assessment');
    }
  }

  Future<void> _rateStudySession() async {
    await _liveActivityPlugin.endAllActivities();
    _switchToHomescreen();
  }
  void _switchToHomescreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MainEnvironment())
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [
            Text(context.t.rateSession),
            SelfAssessment(onPress: _rateStudySession,)
          ]
        )
      ),
    );
  }
}
