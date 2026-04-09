// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_util.dart';
// Imports other custom actions
// Imports custom functions
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

// Library:
import 'dart:async';

Timer? _cooldownTimer;
Future<void> emailVerifyStartCooldown() async {
  _cooldownTimer?.cancel();
  FFAppState().update(() {
    FFAppState().emailVerifyCooldownActive = true;
    FFAppState().emailVerifyCooldownSeconds = 60;
  });
  int seconds = 60;
  _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
    seconds--;
    FFAppState().update(() {
      FFAppState().emailVerifyCooldownSeconds = seconds;
    });
    if (seconds <= 0) {
      timer.cancel();
      FFAppState().update(() {
        FFAppState().emailVerifyCooldownActive = false;
        FFAppState().emailVerifyCooldownSeconds = 60;
      });
    }
  });
}
