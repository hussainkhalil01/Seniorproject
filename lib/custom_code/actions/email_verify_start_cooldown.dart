// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_util.dart';
// Imports other custom actions
// Imports custom functions
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

// Library:
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

Timer? _evCooldownTimer;
const _kEvEndMs = 'ev_cooldown_end_ms';

Future<void> emailVerifyStartCooldown() async {
  _evCooldownTimer?.cancel();

  final prefs = await SharedPreferences.getInstance();
  final ms = prefs.getInt(_kEvEndMs);
  if (ms != null) {
    final remaining =
        DateTime.fromMillisecondsSinceEpoch(ms).difference(DateTime.now()).inSeconds;
    if (remaining > 0) {
      // Restore the persisted cooldown rather than resetting to 60s.
      _evRunTimer(remaining, prefs);
      return;
    }
    prefs.remove(_kEvEndMs);
  }

  // Start a fresh 60-second cooldown and persist the end time.
  final endMs = DateTime.now()
      .add(const Duration(seconds: 60))
      .millisecondsSinceEpoch;
  await prefs.setInt(_kEvEndMs, endMs);
  _evRunTimer(60, prefs);
}

void _evRunTimer(int seconds, SharedPreferences prefs) {
  FFAppState().update(() {
    FFAppState().emailVerifyCooldownActive = true;
    FFAppState().emailVerifyCooldownSeconds = seconds;
  });
  int remaining = seconds;
  _evCooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
    remaining--;
    FFAppState().update(() {
      FFAppState().emailVerifyCooldownSeconds = remaining;
    });
    if (remaining <= 0) {
      timer.cancel();
      prefs.remove(_kEvEndMs);
      FFAppState().update(() {
        FFAppState().emailVerifyCooldownActive = false;
        FFAppState().emailVerifyCooldownSeconds = 60;
      });
    }
  });
}
