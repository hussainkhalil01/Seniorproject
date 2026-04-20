import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_notifications.dart';

class InAppNotificationCenter {
  InAppNotificationCenter._();
  static final InAppNotificationCenter instance = InAppNotificationCenter._();

  final Set<String> _shownIds = <String>{};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  GlobalKey<ScaffoldMessengerState>? _messengerKey;
  DateTime _sessionStartedAt = DateTime.now();

  void configure(GlobalKey<ScaffoldMessengerState> messengerKey) {
    _messengerKey = messengerKey;
  }

  Future<void> onAuthChanged(String? uid) async {
    await _sub?.cancel();
    _sub = null;
    _shownIds.clear();
    _sessionStartedAt = DateTime.now().subtract(const Duration(seconds: 2));

    if (uid == null || uid.isEmpty) {
      return;
    }

    _sub = FirebaseFirestore.instance
        .collection('app_notifications')
        .where('recipient_uid', isEqualTo: uid)
        .orderBy('created_at', descending: true)
        .limit(30)
        .snapshots()
        .listen(_onSnapshot, onError: (_) {});
  }

  Future<void> _onSnapshot(QuerySnapshot<Map<String, dynamic>> snap) async {
    final enabled = await arePushNotificationsEnabled();
    if (!enabled) {
      return;
    }

    for (final change in snap.docChanges) {
      if (change.type != DocumentChangeType.added) continue;

      final doc = change.doc;
      if (_shownIds.contains(doc.id)) continue;

      final data = doc.data();
      if (data == null) continue;

      final shown = data['in_app_shown'] == true;
      if (shown) continue;

      final createdAtTs = data['created_at'] as Timestamp?;
      final createdAt = createdAtTs?.toDate();
      if (createdAt == null || createdAt.isBefore(_sessionStartedAt)) {
        continue;
      }

      final title = (data['title'] as String? ?? '').trim();
      final body = (data['body'] as String? ?? '').trim();
      if (title.isEmpty && body.isEmpty) continue;

      final messenger = _messengerKey?.currentState;
      if (messenger == null) continue;
      _shownIds.add(doc.id);

      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              body.isEmpty ? title : '$title\n$body',
              style: GoogleFonts.ubuntu(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            duration: const Duration(milliseconds: 3500),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF1F4F8B),
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 84),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

      unawaited(doc.reference.update({'in_app_shown': true}));
    }
  }
}
