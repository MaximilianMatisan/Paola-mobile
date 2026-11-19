import 'package:flutter_dotenv/flutter_dotenv.dart';

const appGroupId = 'group.maxi.test.interactivenotification.a';

const double defaultIconPixelSize = 25.0;

/// Receives the mails written via the contact button. It is CONTACT_EMAIL in .env
/// Null if it isn't set; the contact button is hidden then.
String? get contactEmail {
  final email = dotenv.maybeGet('CONTACT_EMAIL')?.trim();
  return email == null || email.isEmpty ? null : email;
}

/// The web app's fixed demo course (DEMO_COURSE_ID in utils/constants.ts):
/// users who registered without a code see a read-only preview in it.
const demoCourseId = 900;
