// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
// Imports other custom actions
// Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:firebase_auth/firebase_auth.dart';

/// Creates 20 sample contractor accounts in Firebase Auth + Firestore.
/// Each account gets role = 'service_provider' so they appear on the home page.
/// Returns a summary string.
Future<String> seedContractors() async {
  const defaultPassword = 'Testtest1@';

  // Each contractor with a unique profile image
  final contractors = [
    {'name': 'PrimeBuild', 'title': 'Plumber', 'email': 'PrimeBuildaman@gmail.com', 'color': '1565C0'},
    {'name': 'Serviq', 'title': 'Electrician', 'email': 'Serviqaman@gmail.com', 'color': 'E65100'},
    {'name': 'Ali Kareem', 'title': 'Painter', 'email': 'AliKareemaman@gmail.com', 'color': '2E7D32'},
    {'name': 'EliteWorks', 'title': 'HVAC Technician', 'email': 'EliteWorksaman@gmail.com', 'color': '6A1B9A'},
    {'name': 'SolidHands', 'title': 'Construction Worker', 'email': 'SolidHandsaman@gmail.com', 'color': 'D84315'},
    {'name': 'Omar Farooq', 'title': 'Electrician', 'email': 'OmarFarooqaman@gmail.com', 'color': '00838F'},
    {'name': 'Ibrahim Saeed', 'title': 'Plumber', 'email': 'IbrahimSaeedaman@gmail.com', 'color': '4527A0'},
    {'name': 'HandyFlow', 'title': 'Interior Painter', 'email': 'HandyFlowaman@gmail.com', 'color': 'AD1457'},
    {'name': 'Hassan Jaber', 'title': 'Maintenance Technician', 'email': 'HassanJaberaman@gmail.com', 'color': '283593'},
    {'name': 'Workora', 'title': 'General Contractor', 'email': 'Workoraaman@gmail.com', 'color': '00695C'},
    {'name': 'Tariq Al-Harthy', 'title': 'Roofer', 'email': 'TariqAlHarthyaman@gmail.com', 'color': 'BF360C'},
    {'name': 'FixHub', 'title': 'Electrical Engineer', 'email': 'FixHubaman@gmail.com', 'color': '0277BD'},
    {'name': 'MasterCrew', 'title': 'Tile Installer', 'email': 'MasterCrewaman@gmail.com', 'color': '558B2F'},
    {'name': 'Bilal Ahmad', 'title': 'Carpenter', 'email': 'BilalAhmadaman@gmail.com', 'color': '8D6E63'},
    {'name': 'Adnan Malik', 'title': 'Handyman', 'email': 'AdnanMalikaman@gmail.com', 'color': 'EF6C00'},
    {'name': 'Fixora', 'title': 'Smart Home Technician', 'email': 'Fixoraaman@gmail.com', 'color': '5E35B1'},
    {'name': 'Rami Haddad', 'title': 'Glass Installer', 'email': 'RamiHaddadaman@gmail.com', 'color': '00897B'},
    {'name': 'HandyFlow Pro', 'title': 'Waterproofing Specialist', 'email': 'HandyFlowProaman@gmail.com', 'color': 'C62828'},
    {'name': 'Sami Zidan', 'title': 'Solar Technician', 'email': 'SamiZidanaman@gmail.com', 'color': 'F9A825'},
    {'name': 'TaskMatch', 'title': 'Site Supervisor', 'email': 'TaskMatchaman@gmail.com', 'color': '37474F'},
  ];

  int created = 0;
  int skipped = 0;
  final errors = <String>[];

  for (final c in contractors) {
    final email = c['email']!;
    final name = c['name']!;
    final title = c['title']!;
    final color = c['color']!;

    // Generate a unique profile image for each contractor
    final encodedName = Uri.encodeComponent(name);
    final photoUrl =
        'https://ui-avatars.com/api/?name=$encodedName&size=256&background=$color&color=ffffff&bold=true&format=png';

    try {
      // Create Firebase Auth account (this auto-signs in as the new user)
      final cred =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: defaultPassword,
      );

      final user = cred.user!;
      await user.updateDisplayName(name);
      await user.updatePhotoURL(photoUrl);

      // Now signed in as this user — create the Firestore document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'uid': user.uid,
        'full_name': name,
        'display_name': name,
        'email': email,
        'role': 'service_provider',
        'title': title,
        'categories': [title],
        'photo_url': photoUrl,
        'short_description': 'Professional $title ready to help with your projects.',
        'phone_number': '',
        'created_time': FieldValue.serverTimestamp(),
        'last_active_time': FieldValue.serverTimestamp(),
        'is_online': false,
        'is_disabled': false,
        'preferred_language': 'en',
      });

      // Sign out so we can create the next account
      await FirebaseAuth.instance.signOut();
      created++;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        skipped++;
      } else {
        errors.add('$email: ${e.message}');
      }
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
    } catch (e) {
      errors.add('$email: $e');
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
    }
  }

  return 'Done! Created: $created, Skipped: $skipped, Errors: ${errors.length}\n${errors.join('\n')}';
}
