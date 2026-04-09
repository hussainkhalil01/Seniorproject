// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_util.dart';
// Imports other custom actions
// Imports custom functions
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

// Library:
import 'package:firebase_auth/firebase_auth.dart';

Future<String> forgotPasswordCustomInfo(String email) async {
  const successMsg =
      "If an account exists for this email, we have sent a reset link. Please check your inbox or Spam folder";
  try {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    FFAppState().forgotPasswordSent = true;
    return successMsg;
  } on FirebaseAuthException catch (ex) {
    if (ex.code == 'too-many-requests') {
      return 'Too many requests. Please try again later';
    }
    if (ex.code == 'network-request-failed') {
      return 'Network error. Please check your internet connection';
    }
    FFAppState().forgotPasswordSent = true;
    return successMsg;
  } catch (_) {
    FFAppState().forgotPasswordSent = false;
    return 'Something went wrong. Please try again';
  }
}
