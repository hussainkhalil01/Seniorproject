// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_util.dart';
// Imports other custom actions
// Imports custom functions
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

// Library:
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

Timer? _fpCooldownTimer;
const _kFpEndMs = 'fp_cooldown_end_ms';

Future<void> forgotPasswordStartCooldown() async {
  _fpCooldownTimer?.cancel();
  final endMs = DateTime.now()
      .add(const Duration(seconds: 60))
      .millisecondsSinceEpoch;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_kFpEndMs, endMs);
  _fpRunTimer(60);
}

Future<void> forgotPasswordRestoreCooldown() async {
  final prefs = await SharedPreferences.getInstance();
  final ms = prefs.getInt(_kFpEndMs);
  if (ms == null) return;
  final remaining =
      DateTime.fromMillisecondsSinceEpoch(ms).difference(DateTime.now()).inSeconds;
  if (remaining <= 0) {
    prefs.remove(_kFpEndMs);
    return;
  }
  _fpCooldownTimer?.cancel();
  _fpRunTimer(remaining);
}

void _fpRunTimer(int seconds) {
  FFAppState().update(() {
    FFAppState().forgotPasswordCooldownActive = true;
    FFAppState().forgotPasswordCooldownSeconds = seconds;
  });
  int remaining = seconds;
  _fpCooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
    remaining--;
    FFAppState().update(() {
      FFAppState().forgotPasswordCooldownSeconds = remaining;
    });
    if (remaining <= 0) {
      timer.cancel();
      SharedPreferences.getInstance().then((p) => p.remove(_kFpEndMs));
      FFAppState().update(() {
        FFAppState().forgotPasswordCooldownActive = false;
        FFAppState().forgotPasswordCooldownSeconds = 60;
      });
    }
  });
}
