// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_util.dart';
// Imports other custom actions
// Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

// Libraries:
import 'package:firebase_auth/firebase_auth.dart';
import '/pages/home_page/home_page_widget.dart';

Future<String> signInWithCustomError(
  BuildContext context,
  String email,
  String password,
) async {
  try {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (context.mounted) {
      context.goNamedAuth(HomePageWidget.routeName, context.mounted);
    }
    return 'success';
  } on FirebaseAuthException catch (ex) {
    if (ex.code == 'user-not-found' ||
        ex.code == 'invalid-email' ||
        ex.code == 'wrong-password' ||
        ex.code == 'invalid-credential') {
      return 'Incorrect email or password';
    } else if (ex.code == 'user-disabled') {
      return 'Your account has been suspended by the administrator. Please contact support for assistance';
    } else if (ex.code == 'too-many-requests') {
      return 'Too many attempts. Please try again';
    } else if (ex.code == 'network-request-failed') {
      return 'Network error. Please check your internet connection';
    } else {
      return 'Something went wrong. Please try again';
    }
  } catch (ex) {
    return 'Something went wrong. Please try again';
  }
}
