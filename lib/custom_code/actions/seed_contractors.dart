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
          'PrimeBuild specializes in residential and commercial plumbing services.\nBrings 8+ years of experience in pipe and fixture work.\nHandles leak repair, drain cleaning, and full plumbing installation.\nUses durable materials and clean installation methods.\nIdeal for urgent plumbing fixes and long-term maintenance.',
    },
    {
      'name': 'Serviq',
      'email': 'Serviqaman@gmail.com',
      'color': 'E65100',
      'title': 'Licensed Electrician',
      'categories': ['Electricians'],
      'description':
          'Serviq specializes in safe and reliable electrical solutions.\nBrings 9+ years of experience in wiring and panel upgrades.\nHandles lighting, outlets, breakers, and electrical troubleshooting.\nFollows strict safety standards on every project.\nIdeal for homes and businesses needing dependable electrical work.',
    },
    {
      'name': 'Ali Kareem',
      'email': 'AliKareemaman@gmail.com',
      'color': '2E7D32',
      'title': 'Professional Painter',
      'categories': ['Painters'],
      'description':
          'Ali Kareem specializes in interior and exterior painting projects.\nBrings 7+ years of experience in residential and commercial painting.\nHandles wall preparation, repainting, and finishing with precision.\nUses premium paints for smooth and durable results.\nIdeal for modern makeovers and complete color transformations.',
    },
    {
      'name': 'EliteWorks',
      'email': 'EliteWorksaman@gmail.com',
      'color': '6A1B9A',
      'title': 'Heating & AC Specialist',
      'categories': ['Heating', 'Air Conditioning'],
      'description':
          'EliteWorks specializes in heating and air conditioning services.\nBrings 10+ years of experience in HVAC installation and maintenance.\nHandles AC repair, heating diagnostics, and system optimization.\nUses efficient equipment and professional technical practices.\nIdeal for year-round indoor comfort and energy savings.',
    },
    {
      'name': 'SolidHands',
      'email': 'SolidHandsaman@gmail.com',
      'color': 'D84315',
      'title': 'General Contractor',
      'categories': ['Contractors & Handymen'],
      'description':
          'SolidHands specializes in construction and renovation projects.\nBrings 8+ years of experience in building and remodeling.\nManages projects from start to finish professionally.\nUses quality materials and skilled workers.\nIdeal for large-scale and complex jobs.',
    },
    {
      'name': 'Omar Farooq',
      'email': 'OmarFarooqaman@gmail.com',
      'color': '00838F',
      'title': 'Electrician',
      'categories': ['Electricians'],
      'description':
          'Omar Farooq specializes in residential and commercial electrical services.\nBrings 10+ years of experience in advanced electrical systems.\nHandles rewiring, load balancing, and panel troubleshooting.\nApplies safe and code-compliant installation standards.\nIdeal for reliable upgrades and long-term electrical performance.',
    },
    {
      'name': 'Ibrahim Saeed',
      'email': 'IbrahimSaeedaman@gmail.com',
      'color': '4527A0',
      'title': 'Plumber',
      'categories': ['Plumbers'],
      'description':
          'Ibrahim Saeed specializes in practical plumbing maintenance services.\nBrings 7+ years of experience in leak and drainage solutions.\nHandles pipe replacement, fixture fitting, and emergency repairs.\nWorks with clean methods and durable plumbing parts.\nIdeal for quick response and affordable plumbing work.',
    },
    {
      'name': 'HandyFlow',
      'email': 'HandyFlowaman@gmail.com',
      'color': 'AD1457',
      'title': 'Painting Contractor',
      'categories': ['Painters'],
      'description':
          'HandyFlow specializes in detailed interior and exterior painting.\nBrings 6+ years of experience in finishing and repainting projects.\nHandles wall correction, texture prep, and final coat application.\nUses quality paint systems for durable visual results.\nIdeal for homes needing a clean and fresh new look.',
    },
    {
      'name': 'Hassan Jaber',
      'email': 'HassanJaberaman@gmail.com',
      'color': '283593',
      'title': 'Handyman',
      'categories': ['Contractors & Handymen'],
      'description':
          'Hassan Jaber specializes in handyman and home maintenance services.\nBrings 8+ years of experience in repairs and installations.\nHandles fittings, minor renovations, and everyday household fixes.\nWorks efficiently with practical and cost-effective solutions.\nIdeal for fast and dependable home support tasks.',
    },
    {
      'name': 'Workora',
      'email': 'Workoraaman@gmail.com',
      'color': '00695C',
      'title': 'General Contractor & Handyman',
      'categories': ['Contractors & Handymen'],
      'description':
          'Workora specializes in contracting and all-around renovation work.\nBrings 9+ years of experience in property improvement projects.\nHandles repairs, upgrades, and full remodeling execution.\nMaintains structured workflow from planning to handover.\nIdeal for clients needing complete and organized project delivery.',
    },
    {
      'name': 'Tariq Al-Harthy',
      'email': 'TariqAlHarthyaman@gmail.com',
      'color': 'BF360C',
      'title': 'Tree Services Specialist',
      'categories': ['Tree Services'],
      'description':
          'Tariq Al-Harthy specializes in tree care and landscape safety services.\nBrings 8+ years of experience in pruning and tree removal.\nHandles shaping, trimming, and risk-control maintenance work.\nUses safe cutting methods and professional field tools.\nIdeal for healthy trees and secure outdoor environments.',
    },
    {
      'name': 'FixHub',
      'email': 'FixHubaman@gmail.com',
      'color': '0277BD',
      'title': 'Electrician & Handyman',
      'categories': ['Electricians', 'Contractors & Handymen'],
      'description':
          'FixHub specializes in electrical and handyman service solutions.\nBrings 8+ years of experience in maintenance and repair work.\nHandles wiring, lighting setup, and small property fixes.\nApplies safe methods with efficient task completion.\nIdeal for quick home and business maintenance needs.',
    },
    {
      'name': 'MasterCrew',
      'email': 'MasterCrewaman@gmail.com',
      'color': '558B2F',
      'title': 'Professional Mover',
      'categories': ['Movers'],
      'description':
          'MasterCrew specializes in residential and office moving services.\nBrings 9+ years of experience in relocation operations.\nHandles packing, transport, loading, and safe item placement.\nUses organized workflow and protective handling standards.\nIdeal for smooth and stress-free moving projects.',
    },
    {
      'name': 'Bilal Ahmad',
      'email': 'BilalAhmadaman@gmail.com',
      'color': '8D6E63',
      'title': 'HVAC Technician',
      'categories': ['Air Conditioning', 'Heating'],
      'description':
          'Bilal Ahmad specializes in air conditioning and heating systems.\nBrings 10+ years of experience in HVAC servicing and repair.\nHandles installation, diagnostics, and preventive maintenance.\nUses accurate testing tools for efficient system performance.\nIdeal for reliable climate control in all seasons.',
    },
    {
      'name': 'Adnan Malik',
      'email': 'AdnanMalikaman@gmail.com',
      'color': 'EF6C00',
      'title': 'Locksmith',
      'categories': ['Locksmiths'],
      'description':
          'Adnan Malik specializes in locksmith and access security services.\nBrings 9+ years of experience in lock systems and key work.\nHandles lock installation, replacement, and emergency lockout support.\nUses precise fitting methods for strong and reliable security.\nIdeal for homes and businesses requiring secure entry solutions.',
    },
    {
      'name': 'Fixora',
      'email': 'Fixoraaman@gmail.com',
      'color': '5E35B1',
      'title': 'AC & Heating Technician',
      'categories': ['Air Conditioning', 'Heating'],
      'description':
          'Fixora specializes in complete AC and heating system care.\nBrings 8+ years of experience in HVAC troubleshooting and repair.\nHandles diagnostics, installation, and performance upgrades.\nUses efficient practices to improve comfort and energy usage.\nIdeal for dependable residential and commercial HVAC support.',
    },
    {
      'name': 'Rami Haddad',
      'email': 'RamiHaddadaman@gmail.com',
      'color': '00897B',
      'title': 'Locksmith',
      'categories': ['Locksmiths'],
      'description':
          'Rami Haddad specializes in locksmith and security upgrade services.\nBrings 7+ years of experience in lock replacement and smart locks.\nHandles key duplication, lock repair, and access control setup.\nUses modern hardware with accurate installation methods.\nIdeal for secure and practical property protection needs.',
    },
    {
      'name': 'HandyFlow Pro',
      'email': 'HandyFlowProaman@gmail.com',
      'color': 'C62828',
      'title': 'Moving & Relocation Expert',
      'categories': ['Movers'],
      'description':
          'HandyFlow Pro specializes in full-service moving and relocation.\nBrings 10+ years of experience in coordinated transport operations.\nHandles packing, loading, delivery, and unpacking assistance.\nUses trained crews and protective methods for valuables.\nIdeal for complete relocation with minimal downtime.',
    },
    {
      'name': 'Sami Zidan',
      'email': 'SamiZidanaman@gmail.com',
      'color': 'F9A825',
      'title': 'Tree Care Professional',
      'categories': ['Tree Services'],
      'description':
          'Sami Zidan specializes in professional tree care services.\nBrings 9+ years of experience in pruning and removal operations.\nHandles stump work, tree shaping, and maintenance planning.\nUses safe equipment and controlled cutting techniques.\nIdeal for clean, healthy, and safe outdoor landscapes.',
    },
    {
      'name': 'TaskMatch',
      'email': 'TaskMatchaman@gmail.com',
      'color': '37474F',
      'title': 'Moving Coordinator',
      'categories': ['Movers'],
      'description':
          'TaskMatch specializes in organized moving and relocation coordination.\nBrings 8+ years of experience in local and distance moves.\nHandles planning, transport scheduling, and move-day logistics.\nUses structured processes for timely and safe delivery.\nIdeal for homes and companies needing reliable move management.',
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
