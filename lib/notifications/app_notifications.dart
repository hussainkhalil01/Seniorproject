import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/auth/firebase_auth/auth_util.dart';

const kPushNotificationsPrefKey = 'push_notifications';

Future<bool> arePushNotificationsEnabled() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(kPushNotificationsPrefKey) ?? true;
}

Future<void> createAppNotification({
  required String recipientUid,
  required String title,
  required String body,
  required String type,
  DocumentReference? chatRef,
  String? orderId,
}) async {
  if (recipientUid.trim().isEmpty || recipientUid == currentUserUid) {
    return;
  }

  await FirebaseFirestore.instance.collection('app_notifications').add({
    'recipient_uid': recipientUid,
    'sender_uid': currentUserUid,
    'sender_name': currentUserDocument?.fullName ?? '',
    'sender_photo': currentUserPhoto,
    'title': title,
    'body': body,
    'type': type,
    'chat_ref': chatRef,
    'order_id': orderId,
    'created_at': FieldValue.serverTimestamp(),
    'in_app_shown': false,
  });
}
