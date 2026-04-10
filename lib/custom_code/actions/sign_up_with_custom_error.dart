// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
// Imports other custom actions
// Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

// Library:
import 'package:firebase_auth/firebase_auth.dart';

Future<String> signUpWithCustomError(
  BuildContext context,
  String fullName,
  String email,
  String password,
  String confirmPassword,
) async {
  if (password != confirmPassword) {
    return 'Passwords do not match. Please try again';
  }
  try {
    GoRouter.of(context).prepareAuthEvent();
    final userCredential =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = userCredential.user;
    await user!.updateDisplayName(fullName);
    await user.reload();
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'full_name': fullName,
      'email': email,
      'role': 'client',
      'created_time': FieldValue.serverTimestamp(),
      'is_disabled': false,
      'photo_url':
          'https://res.cloudinary.com/dxjzonvxd/image/upload/v1774901264/user-icon.png',
    });
    await user.sendEmailVerification();
    return 'success';
  } on FirebaseAuthException catch (ex) {
    switch (ex.code) {
      case 'email-already-in-use':
        return 'Email already exists. Please try a different email';
      case 'too-many-requests':
        return 'Too many attempts. Please try again';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection';
      default:
        return 'Something went wrong. Please try again';
    }
  } catch (_) {
    return 'Something went wrong. Please try again';
  }
}
