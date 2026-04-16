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

  final contractors = [
    {
      'name': 'PrimeBuild',
      'email': 'PrimeBuildaman@gmail.com',
      'color': '1565C0',
      'title': 'Expert Plumber',
      'categories': ['Plumbers'],
      'description':
          'Specializing in pipe repairs, installations, and all plumbing needs for residential and commercial properties.',
    },
    {
      'name': 'Serviq',
      'email': 'Serviqaman@gmail.com',
      'color': 'E65100',
      'title': 'Licensed Electrician',
      'categories': ['Electricians'],
      'description':
          'Certified electrician offering wiring, panel upgrades, and electrical safety inspections.',
    },
    {
      'name': 'Ali Kareem',
      'email': 'AliKareemaman@gmail.com',
      'color': '2E7D32',
      'title': 'Professional Painter',
      'categories': ['Painters'],
      'description':
          'Skilled painter delivering premium interior and exterior painting with flawless finishes.',
    },
    {
      'name': 'EliteWorks',
      'email': 'EliteWorksaman@gmail.com',
      'color': '6A1B9A',
      'title': 'Heating & AC Specialist',
      'categories': ['Heating', 'Air Conditioning'],
      'description':
          'Full-service HVAC expert offering heating and air conditioning installation, repair, and maintenance.',
    },
    {
      'name': 'SolidHands',
      'email': 'SolidHandsaman@gmail.com',
      'color': 'D84315',
      'title': 'General Contractor',
      'categories': ['Contractors & Handymen'],
      'description':
          'Reliable contractor for all home repairs, renovations, and handyman tasks.',
    },
    {
      'name': 'Omar Farooq',
      'email': 'OmarFarooqaman@gmail.com',
      'color': '00838F',
      'title': 'Electrician',
      'categories': ['Electricians'],
      'description':
          'Experienced electrician with 10+ years handling residential and commercial electrical systems.',
    },
    {
      'name': 'Ibrahim Saeed',
      'email': 'IbrahimSaeedaman@gmail.com',
      'color': '4527A0',
      'title': 'Plumber',
      'categories': ['Plumbers'],
      'description':
          'Fast and dependable plumbing services including leak repairs, drain cleaning, and pipe installations.',
    },
    {
      'name': 'HandyFlow',
      'email': 'HandyFlowaman@gmail.com',
      'color': 'AD1457',
      'title': 'Painting Contractor',
      'categories': ['Painters'],
      'description':
          'Interior and exterior painting specialist with a keen eye for detail and lasting results.',
    },
    {
      'name': 'Hassan Jaber',
      'email': 'HassanJaberaman@gmail.com',
      'color': '283593',
      'title': 'Handyman',
      'categories': ['Contractors & Handymen'],
      'description':
          'Your go-to handyman for all household maintenance, repairs, and improvement projects.',
    },
    {
      'name': 'Workora',
      'email': 'Workoraaman@gmail.com',
      'color': '00695C',
      'title': 'General Contractor & Handyman',
      'categories': ['Contractors & Handymen'],
      'description':
          'Versatile contractor handling everything from minor fixes to full-scale home renovations.',
    },
    {
      'name': 'Tariq Al-Harthy',
      'email': 'TariqAlHarthyaman@gmail.com',
      'color': 'BF360C',
      'title': 'Tree Services Specialist',
      'categories': ['Tree Services'],
      'description':
          'Expert tree trimming, pruning, and removal. Keeping your property safe and looking its best.',
    },
    {
      'name': 'FixHub',
      'email': 'FixHubaman@gmail.com',
      'color': '0277BD',
      'title': 'Electrician & Handyman',
      'categories': ['Electricians', 'Contractors & Handymen'],
      'description':
          'Multi-skilled professional providing electrical repairs and handyman services for homes and businesses.',
    },
    {
      'name': 'MasterCrew',
      'email': 'MasterCrewaman@gmail.com',
      'color': '558B2F',
      'title': 'Professional Mover',
      'categories': ['Movers'],
      'description':
          'Reliable moving crew for residential and commercial relocations, handled with care and efficiency.',
    },
    {
      'name': 'Bilal Ahmad',
      'email': 'BilalAhmadaman@gmail.com',
      'color': '8D6E63',
      'title': 'HVAC Technician',
      'categories': ['Air Conditioning', 'Heating'],
      'description':
          'Skilled technician specializing in air conditioning and heating system installation, servicing, and repair.',
    },
    {
      'name': 'Adnan Malik',
      'email': 'AdnanMalikaman@gmail.com',
      'color': 'EF6C00',
      'title': 'Locksmith',
      'categories': ['Locksmiths'],
      'description':
          'Available 24/7 for lock installations, key cutting, and emergency lockout services.',
    },
    {
      'name': 'Fixora',
      'email': 'Fixoraaman@gmail.com',
      'color': '5E35B1',
      'title': 'AC & Heating Technician',
      'categories': ['Air Conditioning', 'Heating'],
      'description':
          'Expert in cooling and heating solutions. Fast diagnosis and reliable repairs for all HVAC systems.',
    },
    {
      'name': 'Rami Haddad',
      'email': 'RamiHaddadaman@gmail.com',
      'color': '00897B',
      'title': 'Locksmith',
      'categories': ['Locksmiths'],
      'description':
          'Trusted locksmith providing security upgrades, lock replacements, and smart lock installations.',
    },
    {
      'name': 'HandyFlow Pro',
      'email': 'HandyFlowProaman@gmail.com',
      'color': 'C62828',
      'title': 'Moving & Relocation Expert',
      'categories': ['Movers'],
      'description':
          'Full-service moving company offering packing, transport, and unpacking for stress-free moves.',
    },
    {
      'name': 'Sami Zidan',
      'email': 'SamiZidanaman@gmail.com',
      'color': 'F9A825',
      'title': 'Tree Care Professional',
      'categories': ['Tree Services'],
      'description':
          'Certified arborist offering tree pruning, removal, stump grinding, and landscape maintenance.',
    },
    {
      'name': 'TaskMatch',
      'email': 'TaskMatchaman@gmail.com',
      'color': '37474F',
      'title': 'Moving Coordinator',
      'categories': ['Movers'],
      'description':
          'Professional moving service for local and long-distance relocations with careful handling.',
    },
  ];

  int created = 0;
  int skipped = 0;
  final errors = <String>[];

  for (final c in contractors) {
    final email = c['email']! as String;
    final name = c['name']! as String;
    final title = c['title']! as String;
    final color = c['color']! as String;
    final categories = c['categories']! as List<String>;
    final description = c['description']! as String;

    final encodedName = Uri.encodeComponent(name);
    final photoUrl =
        'https://ui-avatars.com/api/?name=$encodedName&size=256&background=$color&color=ffffff&bold=true&format=png';

    try {
      final cred =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: defaultPassword,
      );

      final user = cred.user!;
      await user.updateDisplayName(name);
      await user.updatePhotoURL(photoUrl);

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
        'categories': categories,
        'photo_url': photoUrl,
        'short_description': description,
        'phone_number': '',
        'created_time': FieldValue.serverTimestamp(),
        'last_active_time': FieldValue.serverTimestamp(),
        'is_online': false,
        'is_disabled': false,
        'preferred_language': 'en',
      });

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
