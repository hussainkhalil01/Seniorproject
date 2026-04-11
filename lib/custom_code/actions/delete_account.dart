// Automatic FlutterFlow imports
import '/backend/backend.dart';
// Imports other custom actions
// Imports custom functions
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<String> deleteAccount() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'No user is currently signed in';

    final userDocRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);

    // Read current data before deletion for rollback if needed
    final userDoc = await userDocRef.get();
    final userData = userDoc.data();

    // Delete Firestore document first while still authenticated
    await userDocRef.delete();

    // Now try to delete the Auth account
    try {
      await user.delete();
    } on FirebaseAuthException catch (ex) {
      // Auth deletion failed — rollback the Firestore document
      if (userData != null) {
        await userDocRef.set(userData);
      }
      switch (ex.code) {
        case 'requires-recent-login':
          return 'For security, please sign out and sign back in before deleting your account';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection';
        default:
          return 'Something went wrong. Please try again';
      }
    }

    return 'success';
  } on FirebaseException catch (ex) {
    if (ex.code == 'network-request-failed') {
      return 'Network error. Please check your internet connection';
    }
    return 'Something went wrong. Please try again';
  } catch (_) {
    return 'Something went wrong. Please try again';
  }
}
