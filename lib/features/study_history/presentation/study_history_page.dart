import 'package:flutter/material.dart';

class StudyHistoryPage extends StatefulWidget {
  const StudyHistoryPage({super.key});

  final String title = 'History';

  @override
  State<StudyHistoryPage> createState() => _StudyHistoryPageState();
}

class _StudyHistoryPageState extends State<StudyHistoryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: Column(
              mainAxisAlignment: .center,
              children: [
                Text( 'Future study history screen' ),
              ]
          )
      ),
    );
  }
}
