// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

// Libraries:
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';

class _LifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userDoc =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    if (state == AppLifecycleState.resumed) {
      await userDoc.update({
        'is_online': true,
      });
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      await userDoc.update({
        'is_online': false,
        'last_active_time': FieldValue.serverTimestamp(),
      });
    }
  }
}

_LifecycleObserver? _observer;
Future<void> trackUserPresence() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  if (_observer != null) {
    WidgetsBinding.instance.removeObserver(_observer!);
  }
  await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
    'is_online': true,
  });
  _observer = _LifecycleObserver();
  WidgetsBinding.instance.addObserver(_observer!);
}
