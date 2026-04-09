import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

Future initFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: const FirebaseOptions(
            apiKey: "AIzaSyC5koHsL0YF0vzSEcaCFgH1WlN0RhvbJTk",
            authDomain: "aman-build-0tehsj.firebaseapp.com",
            projectId: "aman-build-0tehsj",
            storageBucket: "aman-build-0tehsj.firebasestorage.app",
            messagingSenderId: "1037864788293",
            appId: "1:1037864788293:web:a3778dc72c14b79c101e2c"));
  } else {
    await Firebase.initializeApp();
  }
}
