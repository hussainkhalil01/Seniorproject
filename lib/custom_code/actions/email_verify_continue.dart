// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_util.dart';
// Imports other custom actions
// Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

// Libraries:
import 'package:firebase_auth/firebase_auth.dart';
import '/amanbuild/home_pages/home_page/home_page_widget.dart';

Future<String> emailVerifyContinue(BuildContext context) async {
  try {
    await FirebaseAuth.instance.currentUser?.reload();
    final isVerified =
        FirebaseAuth.instance.currentUser?.emailVerified ?? false;
    if (isVerified) {
      if (context.mounted) {
        context.goNamedAuth(HomePageWidget.routeName, context.mounted);
      }
      return 'success';
    } else {
      return 'Your email has not been verified yet. Please check your inbox or Spam folder';
    }
  } on FirebaseAuthException catch (ex) {
    switch (ex.code) {
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

