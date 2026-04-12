import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';

// ─────────────────────────────────────────────────────────
//  Data models
// ─────────────────────────────────────────────────────────

enum _Sender { user, bot }

class _Msg {
  final _Sender sender;
  final String text;
  final List<_ContractorSuggestion>? suggestions;
  final List<String>? quickReplies;

  _Msg({
    required this.sender,
    required this.text,
    this.suggestions,
    this.quickReplies,
  });
}

class _ContractorSuggestion {
  final String uid;
  final DocumentReference ref;
  final String name;
  final String serviceType;
  final double rating;
  final int reviewCount;
  final double? distKm;
  final String photoUrl;
  final String reason;
  final String? topReview;

  _ContractorSuggestion({
    required this.uid,
    required this.ref,
    required this.name,
    required this.serviceType,
    required this.rating,
    required this.reviewCount,
    required this.photoUrl,
    required this.reason,
    this.distKm,
    this.topReview,
  });
}

// ─────────────────────────────────────────────────────────
//  User intent
// ─────────────────────────────────────────────────────────

enum _Intent { findByProblem, nearest, highestRated, cheapest, general, greeting, thanks, help }

class _ParsedQuery {
  final _Intent intent;
  final String? category;
  final String? problemDescription;
  final bool wantsNearest;
  final bool wantsTopRated;

  _ParsedQuery({
    required this.intent,
    this.category,
    this.problemDescription,
    this.wantsNearest = false,
    this.wantsTopRated = false,
  });
}

// ─────────────────────────────────────────────────────────
//  Category keyword mapping (expanded)
// ─────────────────────────────────────────────────────────

const _kCategories = [
  'HVAC (Air Conditioning)',
  'Electrical Services',
  'Plumbing',
  'General Construction & Renovation',
  'Interior Finishing',
];

const _kKeywords = <String, List<String>>{
  'HVAC (Air Conditioning)': [
    'ac', 'a/c', 'air conditioning', 'air conditioner', 'hvac',
    'cooling', 'air con', 'heat', 'heating', 'thermostat',
    'duct', 'ventilation', 'fan coil', 'split unit',
    'not cooling', 'not cold', 'warm air', 'hot air',
    'compressor', 'refrigerant', 'freon', 'filter',
    'central air', 'mini split', 'window unit',
    'freezing', 'ice', 'defrost',
    'مكيف', 'تكييف', 'تبريد',
  ],
  'Electrical Services': [
    'electric', 'electrician', 'wiring', 'outlet', 'socket',
    'breaker', 'fuse', 'power', 'light', 'lighting',
    'voltage', 'circuit', 'panel', 'switch',
    'power outage', 'no power', 'short circuit', 'sparking',
    'tripping', 'flickering', 'dimming', 'buzzing',
    'generator', 'inverter', 'transformer', 'meter',
    'chandelier', 'ceiling fan', 'recessed light',
    'كهرباء', 'كهربائي',
  ],
  'Plumbing': [
    'plumb', 'plumber', 'pipe', 'leak', 'leaking', 'water',
    'drain', 'toilet', 'sink', 'faucet', 'shower', 'tap',
    'sewage', 'heater tank', 'water heater', 'clog', 'blockage',
    'dripping', 'overflow', 'flooding', 'backed up',
    'water pressure', 'low pressure', 'burst pipe',
    'garbage disposal', 'sump pump', 'water softener',
    'bathroom', 'bathtub', 'bidet',
    'سباكة', 'سباك', 'تسريب', 'ماء',
  ],
  'General Construction & Renovation': [
    'construction', 'renovation', 'build', 'remodel', 'rebuild',
    'contractor', 'cement', 'concrete', 'flooring', 'tile', 'tiling',
    'roofing', 'roof', 'wall', 'brick', 'foundation', 'structural',
    'carpentry', 'carpenter', 'wood', 'door', 'window', 'gate',
    'demolition', 'extension', 'addition', 'basement',
    'drywall', 'insulation', 'waterproof', 'crack', 'cracked',
    'pergola', 'deck', 'patio', 'fence', 'garden wall',
    'بناء', 'ترميم', 'مقاول',
  ],
  'Interior Finishing': [
    'interior', 'finishing', 'paint', 'painting', 'painter',
    'wallpaper', 'ceiling', 'gypsum', 'partition',
    'decor', 'decoration', 'decorator', 'design',
    'furniture', 'cabinet', 'wardrobe', 'kitchen', 'cupboard',
    'marble', 'granite', 'countertop', 'backsplash',
    'molding', 'trim', 'baseboard', 'crown molding',
    'parquet', 'laminate', 'vinyl', 'carpet',
    'دهان', 'ديكور', 'تشطيب',
  ],
};

// Problem ➜ category + explanation
const _kProblemMap = <String, Map<String, String>>{
  // HVAC problems
  'ac not cooling': {'cat': 'HVAC (Air Conditioning)', 'desc': 'AC cooling issue'},
  'ac not working': {'cat': 'HVAC (Air Conditioning)', 'desc': 'AC malfunction'},
  'air conditioner leaking': {'cat': 'HVAC (Air Conditioning)', 'desc': 'AC water leak'},
  'ac making noise': {'cat': 'HVAC (Air Conditioning)', 'desc': 'AC noise issue'},
  'ac smell': {'cat': 'HVAC (Air Conditioning)', 'desc': 'AC odor problem'},
  'ac dripping': {'cat': 'HVAC (Air Conditioning)', 'desc': 'AC condensation issue'},
  // Electrical problems
  'power outage': {'cat': 'Electrical Services', 'desc': 'power outage'},
  'no electricity': {'cat': 'Electrical Services', 'desc': 'electrical failure'},
  'lights flickering': {'cat': 'Electrical Services', 'desc': 'flickering lights'},
  'sparking outlet': {'cat': 'Electrical Services', 'desc': 'dangerous sparking'},
  'breaker tripping': {'cat': 'Electrical Services', 'desc': 'circuit breaker issue'},
  'short circuit': {'cat': 'Electrical Services', 'desc': 'short circuit'},
  // Plumbing problems
  'water leak': {'cat': 'Plumbing', 'desc': 'water leak'},
  'pipe burst': {'cat': 'Plumbing', 'desc': 'burst pipe emergency'},
  'toilet clogged': {'cat': 'Plumbing', 'desc': 'toilet blockage'},
  'drain blocked': {'cat': 'Plumbing', 'desc': 'drainage blockage'},
  'low water pressure': {'cat': 'Plumbing', 'desc': 'water pressure issue'},
  'no hot water': {'cat': 'Plumbing', 'desc': 'water heater problem'},
  'faucet dripping': {'cat': 'Plumbing', 'desc': 'dripping faucet'},
  // Construction problems
  'wall crack': {'cat': 'General Construction & Renovation', 'desc': 'wall cracking'},
  'roof leak': {'cat': 'General Construction & Renovation', 'desc': 'roof leak'},
  'foundation crack': {'cat': 'General Construction & Renovation', 'desc': 'foundation issue'},
  'door broken': {'cat': 'General Construction & Renovation', 'desc': 'door repair'},
  'window broken': {'cat': 'General Construction & Renovation', 'desc': 'window repair'},
  // Interior problems
  'paint peeling': {'cat': 'Interior Finishing', 'desc': 'paint damage'},
  'ceiling damage': {'cat': 'Interior Finishing', 'desc': 'ceiling repair'},
  'tile broken': {'cat': 'Interior Finishing', 'desc': 'tile replacement'},
};

// ─────────────────────────────────────────────────────────
//  Query parser
// ─────────────────────────────────────────────────────────

_ParsedQuery _parseQuery(String input) {
  final lower = input.toLowerCase().trim();

  // Greetings
  final greetings = ['hi', 'hello', 'hey', 'good morning', 'good evening',
    'good afternoon', 'assalam', 'salam', 'marhaba', 'السلام', 'مرحبا'];
  if (greetings.any((g) => lower == g || lower.startsWith('$g '))) {
    return _ParsedQuery(intent: _Intent.greeting);
  }

  // Thanks
  final thanks = ['thank', 'thanks', 'thx', 'appreciate', 'شكر'];
  if (thanks.any((t) => lower.contains(t))) {
    return _ParsedQuery(intent: _Intent.thanks);
  }

  // Help
  if (lower == 'help' || lower == 'what can you do' ||
      lower.contains('how do you work') || lower.contains('what do you do')) {
    return _ParsedQuery(intent: _Intent.help);
  }

  // Detect modifiers
  final wantsNearest = lower.contains('nearest') || lower.contains('near me') ||
      lower.contains('close') || lower.contains('nearby') ||
      lower.contains('closest') || lower.contains('قريب');
  final wantsTopRated = lower.contains('highest rated') ||
      lower.contains('best rated') || lower.contains('top rated') ||
      lower.contains('best') || lower.contains('أفضل');

  // Problem-based detection (most specific)
  for (final entry in _kProblemMap.entries) {
    if (lower.contains(entry.key)) {
      return _ParsedQuery(
        intent: _Intent.findByProblem,
        category: entry.value['cat'],
        problemDescription: entry.value['desc'],
        wantsNearest: wantsNearest,
        wantsTopRated: wantsTopRated,
      );
    }
  }

  // Category keyword detection (score-based)
  String? bestCategory;
  int bestScore = 0;
  for (final entry in _kKeywords.entries) {
    int score = 0;
    for (final kw in entry.value) {
      if (lower.contains(kw)) score++;
    }
    if (score > bestScore) {
      bestScore = score;
      bestCategory = entry.key;
    }
  }

  if (bestCategory != null) {
    return _ParsedQuery(
      intent: _Intent.findByProblem,
      category: bestCategory,
      wantsNearest: wantsNearest,
      wantsTopRated: wantsTopRated,
    );
  }

  // Intent-only queries
  if (wantsTopRated) {
    return _ParsedQuery(intent: _Intent.highestRated, wantsTopRated: true);
  }
  if (wantsNearest) {
    return _ParsedQuery(intent: _Intent.nearest, wantsNearest: true);
  }

  return _ParsedQuery(intent: _Intent.general);
}

// ─────────────────────────────────────────────────────────
//  Helpers
// ─────────────────────────────────────────────────────────

double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  final dLat = (lat2 - lat1) * math.pi / 180;
  final dLng = (lng2 - lng1) * math.pi / 180;
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1 * math.pi / 180) *
          math.cos(lat2 * math.pi / 180) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

String _distLabel(double km) {
  if (km < 1) return '${(km * 1000).toStringAsFixed(0)} m away';
  return '${km.toStringAsFixed(1)} km away';
}

String _shortCat(String cat) {
  switch (cat) {
    case 'HVAC (Air Conditioning)':
      return 'HVAC';
    case 'Electrical Services':
      return 'Electrical';
    case 'General Construction & Renovation':
      return 'Construction';
    case 'Interior Finishing':
      return 'Interior';
    default:
      return cat;
  }
}

// ─────────────────────────────────────────────────────────
//  Widget
// ─────────────────────────────────────────────────────────

class AiChatPageWidget extends StatefulWidget {
  const AiChatPageWidget({super.key, this.initialQuery});

  final String? initialQuery;

  static const String routeName = 'AiChatPage';
  static const String routePath = '/aiChatPage';

  @override
  State<AiChatPageWidget> createState() => _AiChatPageWidgetState();
}

class _AiChatPageWidgetState extends State<AiChatPageWidget> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<_Msg> _messages = [];
  bool _thinking = false;
  Position? _userPosition;
  String? _lastCategory; // Conversation context

  static const _quickReplies = [
    'AC not cooling',
    'Water leak',
    'Electrical issue',
    'Nearest contractors',
    'Highest rated',
  ];

  @override
  void initState() {
    super.initState();
    _tryGetLocation();
    _messages.add(_Msg(
      sender: _Sender.bot,
      text:
          'Hi! 👋 I\'m your contractor assistant.\n\nDescribe your problem (e.g. "AC not cooling", "water leak in bathroom") and I\'ll find the best contractors near you.',
      quickReplies: _quickReplies,
    ));

    // Auto-process initial query from Quick Service Request
    if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleUserMessage(widget.initialQuery!);
      });
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _tryGetLocation() async {
    try {
      final svc = await Geolocator.isLocationServiceEnabled();
      if (!svc) return;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.low));
      if (mounted) setState(() => _userPosition = pos);
    } catch (_) {}
  }

  // ── Composite scoring ────────────────────────────────────

  double _computeScore(_ContractorSuggestion s, {bool boostNearest = false, bool boostRating = false}) {
    // Rating score: 0-1 (normalized from 0-5)
    final ratingScore = s.rating / 5.0;

    // Distance score: 0-1 (closer = higher), fallback 0.3 if no distance
    double distScore;
    if (s.distKm != null) {
      distScore = math.max(0, 1.0 - (s.distKm! / 50.0)); // 50km = 0 score
    } else {
      distScore = 0.3;
    }

    // Review count score: 0-1 (more reviews = more trustworthy)
    final countScore = math.min(1.0, s.reviewCount / 20.0);

    // Weights adjust based on intent
    double wRating, wDist, wCount;
    if (boostNearest) {
      wRating = 0.2; wDist = 0.6; wCount = 0.2;
    } else if (boostRating) {
      wRating = 0.6; wDist = 0.1; wCount = 0.3;
    } else {
      wRating = 0.4; wDist = 0.3; wCount = 0.3;
    }

    return (ratingScore * wRating) + (distScore * wDist) + (countScore * wCount);
  }

  String _generateReason(_ContractorSuggestion s, _ParsedQuery query) {
    final parts = <String>[];

    // Rating comment
    if (s.rating >= 4.5 && s.reviewCount >= 5) {
      parts.add('Excellent rating (${s.rating.toStringAsFixed(1)})');
    } else if (s.rating >= 4.0 && s.reviewCount >= 3) {
      parts.add('Highly rated (${s.rating.toStringAsFixed(1)})');
    } else if (s.rating >= 3.5) {
      parts.add('Well rated');
    } else if (s.reviewCount == 0) {
      parts.add('New on the platform');
    }

    // Distance comment
    if (s.distKm != null) {
      if (s.distKm! < 2) {
        parts.add('very close to you');
      } else if (s.distKm! < 5) {
        parts.add('nearby');
      }
    }

    // Review count
    if (s.reviewCount >= 10) {
      parts.add('${s.reviewCount} verified reviews');
    } else if (s.reviewCount >= 3) {
      parts.add('${s.reviewCount} reviews');
    }

    if (parts.isEmpty) return 'Available in your area';
    // Capitalize first part
    parts[0] = parts[0][0].toUpperCase() + parts[0].substring(1);
    return parts.join(' · ');
  }

  // ── Fetch top review for a contractor ────────────────────

  Future<String?> _fetchTopReview(DocumentReference contractorRef) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('reviews')
          .where('contractor_ref', isEqualTo: contractorRef)
          .orderBy('rating', descending: true)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        final comment = snap.docs.first.data()['comment'] as String?;
        if (comment != null && comment.trim().length > 5) {
          final trimmed = comment.trim();
          return trimmed.length > 80 ? '${trimmed.substring(0, 77)}...' : trimmed;
        }
      }
    } catch (_) {}
    return null;
  }

  // ── Query Firestore for contractors ──────────────────────

  Future<List<_ContractorSuggestion>> _fetchSuggestions({
    String? category,
    required _ParsedQuery query,
  }) async {
    Query q = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'service_provider')
        .where('is_disabled', isEqualTo: false);

    if (category != null) {
      q = q.where('categories', arrayContains: category);
    }

    final snap = await q.get();

    final suggestions = snap.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      // Filter out paused/deleted contractors
      if (data['paused'] == true || data['deleted'] == true) return false;
      return true;
    }).map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final name = (data['display_name'] as String?) ??
          (data['full_name'] as String?) ??
          'Contractor';
      final cat = (data['categories'] as List?)?.isNotEmpty == true
          ? (data['categories'] as List).first as String
          : (data['title'] as String?) ?? 'Service Provider';
      final rating = (data['rating_avg'] as num?)?.toDouble() ?? 0.0;
      final count = (data['rating_count'] as num?)?.toInt() ?? 0;
      final photo = (data['photo_url'] as String?) ?? '';
      final lat = (data['latitude'] as num?)?.toDouble() ?? 0.0;
      final lng = (data['longitude'] as num?)?.toDouble() ?? 0.0;

      double? dist;
      if (_userPosition != null && (lat != 0.0 || lng != 0.0)) {
        dist = _haversineKm(
            _userPosition!.latitude, _userPosition!.longitude, lat, lng);
      }

      final s = _ContractorSuggestion(
        uid: doc.id,
        ref: doc.reference,
        name: name,
        serviceType: cat,
        rating: rating,
        reviewCount: count,
        photoUrl: photo,
        distKm: dist,
        reason: '', // Will be set after scoring
      );
      return s;
    }).toList();

    // Score & sort
    suggestions.sort((a, b) {
      final sa = _computeScore(a, boostNearest: query.wantsNearest, boostRating: query.wantsTopRated);
      final sb = _computeScore(b, boostNearest: query.wantsNearest, boostRating: query.wantsTopRated);
      return sb.compareTo(sa);
    });

    // Take top 3 and generate reasons + fetch reviews
    final top = suggestions.take(3).toList();
    final enriched = <_ContractorSuggestion>[];

    for (int i = 0; i < top.length; i++) {
      final s = top[i];
      final reason = _generateReason(s, query);
      String? review;
      if (i == 0) {
        // Only fetch review for top pick to keep it fast
        review = await _fetchTopReview(s.ref);
      }
      enriched.add(_ContractorSuggestion(
        uid: s.uid,
        ref: s.ref,
        name: s.name,
        serviceType: s.serviceType,
        rating: s.rating,
        reviewCount: s.reviewCount,
        photoUrl: s.photoUrl,
        distKm: s.distKm,
        reason: reason,
        topReview: review,
      ));
    }

    return enriched;
  }

  // ── Process user input ───────────────────────────────────

  Future<void> _handleUserMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    _textCtrl.clear();
    setState(() {
      _messages.add(_Msg(sender: _Sender.user, text: trimmed));
      _thinking = true;
    });
    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 600));

    final query = _parseQuery(trimmed);

    // Handle non-search intents
    if (query.intent == _Intent.greeting) {
      if (!mounted) return;
      setState(() {
        _thinking = false;
        _messages.add(_Msg(
          sender: _Sender.bot,
          text: 'Hello! 👋 How can I help you today? Describe your problem or tap a quick option below.',
          quickReplies: _quickReplies,
        ));
      });
      _scrollToBottom();
      return;
    }

    if (query.intent == _Intent.thanks) {
      if (!mounted) return;
      setState(() {
        _thinking = false;
        _messages.add(_Msg(
          sender: _Sender.bot,
          text: 'You\'re welcome! Let me know if you need anything else. 😊',
          quickReplies: _quickReplies,
        ));
      });
      _scrollToBottom();
      return;
    }

    if (query.intent == _Intent.help) {
      if (!mounted) return;
      setState(() {
        _thinking = false;
        _messages.add(_Msg(
          sender: _Sender.bot,
          text: 'I can help you find the right contractor! Here\'s what I can do:\n\n'
              '• Describe a problem (e.g. "AC not cooling") and I\'ll find specialists\n'
              '• Ask for "nearest contractors" to find those close to you\n'
              '• Ask for "highest rated" to see top-rated pros\n'
              '• Specify a category like "plumber" or "electrician"\n\n'
              'Try one of the options below:',
          quickReplies: _quickReplies,
        ));
      });
      _scrollToBottom();
      return;
    }

    // Search intents
    final effectiveCategory = query.category ?? _lastCategory;
    if (query.category != null) _lastCategory = query.category;

    List<_ContractorSuggestion> results;
    String intro;

    switch (query.intent) {
      case _Intent.highestRated:
        results = await _fetchSuggestions(category: effectiveCategory, query: query);
        if (effectiveCategory != null) {
          intro = 'Here are the top-rated ${_shortCat(effectiveCategory)} contractors:';
        } else {
          intro = 'Here are the highest-rated contractors across all categories:';
        }
        break;

      case _Intent.nearest:
        results = await _fetchSuggestions(category: effectiveCategory, query: query);
        if (_userPosition == null) {
          intro = '📍 Location not available — showing top-rated contractors instead:';
        } else if (effectiveCategory != null) {
          intro = 'Here are the nearest ${_shortCat(effectiveCategory)} contractors to you:';
        } else {
          intro = 'Here are the nearest contractors to your location:';
        }
        break;

      case _Intent.findByProblem:
        results = await _fetchSuggestions(category: query.category, query: query);
        if (results.isEmpty && query.category != null) {
          // Fallback: search all categories
          results = await _fetchSuggestions(query: query);
          intro = 'No exact ${_shortCat(query.category!)} specialists found, but these contractors can help:';
        } else if (query.problemDescription != null) {
          intro = 'For your ${query.problemDescription}, here are the best contractors:';
        } else {
          intro = 'Here are the best ${_shortCat(query.category!)} contractors for you:';
        }
        break;

      default: // general
        if (_lastCategory != null) {
          results = await _fetchSuggestions(category: _lastCategory, query: query);
          intro = 'Here are more ${_shortCat(_lastCategory!)} contractors:';
        } else {
          results = await _fetchSuggestions(query: query);
          intro = 'I\'d love to help! Can you describe your problem in more detail?\n\n'
              'In the meantime, here are our top-rated contractors:';
        }
        break;
    }

    if (!mounted) return;

    if (results.isEmpty) {
      setState(() {
        _thinking = false;
        _messages.add(_Msg(
          sender: _Sender.bot,
          text:
              'Sorry, I couldn\'t find any contractors matching your request right now. Try a different category or check back later.',
          quickReplies: _quickReplies,
        ));
      });
    } else {
      // Build summary line
      final summaryParts = <String>[];
      for (int i = 0; i < results.length; i++) {
        final s = results[i];
        final r = s.rating > 0 ? '${s.rating.toStringAsFixed(1)}★' : 'New';
        final d = s.distKm != null ? ' · ${_distLabel(s.distKm!)}' : '';
        summaryParts.add('${i + 1}. ${s.name} — $r$d');
      }

      setState(() {
        _thinking = false;
        _messages.add(_Msg(
          sender: _Sender.bot,
          text: intro,
          suggestions: results,
          quickReplies: _quickReplies,
        ));
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ─────────────────────────────────────────────────────────
  //  Build
  // ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: theme.primaryBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: theme.primaryText),
          onPressed: () => context.pop(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [theme.primary, theme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(Icons.smart_toy_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'AI Assistant',
                  style: GoogleFonts.ubuntu(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: theme.primaryText,
                  ),
                ),
                Text(
                  'Find the best contractor for you',
                  style: GoogleFonts.ubuntu(
                    fontSize: 11,
                    color: theme.secondaryText,
                  ),
                ),
              ],
            )
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
              height: 1, thickness: 1, color: theme.alternate.withOpacity(.5)),
        ),
      ),
      body: Column(
        children: [
          // ── Message list ──────────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length + (_thinking ? 1 : 0),
              itemBuilder: (context, i) {
                if (_thinking && i == _messages.length) {
                  return _buildTypingIndicator(theme);
                }
                return _buildMessage(context, theme, _messages[i]);
              },
            ),
          ),

          // ── Input bar ─────────────────────────────────────
          _buildInputBar(theme),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  Message bubble
  // ─────────────────────────────────────────────────────────

  Widget _buildMessage(
      BuildContext context, FlutterFlowTheme theme, _Msg msg) {
    final isUser = msg.sender == _Sender.user;
    return Column(
      crossAxisAlignment:
          isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        // Sender label for bot
        if (!isUser)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [theme.primary, theme.secondary],
                    ),
                  ),
                  child: const Icon(Icons.smart_toy_rounded,
                      color: Colors.white, size: 13),
                ),
                const SizedBox(width: 5),
                Text(
                  'Assistant',
                  style: GoogleFonts.ubuntu(
                    fontSize: 11,
                    color: theme.secondaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

        // Text bubble
        if (msg.text.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * .78),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isUser ? theme.primary : theme.secondaryBackground,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isUser ? 18 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 18),
              ),
            ),
            child: Text(
              msg.text,
              style: GoogleFonts.ubuntu(
                fontSize: 14,
                color: isUser ? Colors.white : theme.primaryText,
                height: 1.45,
              ),
            ),
          ),

        // Contractor suggestion cards
        if (msg.suggestions != null)
          ...msg.suggestions!.map((s) => _buildSuggestionCard(context, theme, s)),

        // Quick reply chips
        if (msg.quickReplies != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: msg.quickReplies!
                  .map((qr) => _buildQuickReply(theme, qr))
                  .toList(),
            ),
          ),

        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildSuggestionCard(
      BuildContext context, FlutterFlowTheme theme, _ContractorSuggestion s) {
    return GestureDetector(
      onTap: () => context.pushNamed(
        ContractorProfilePageWidget.routeName,
        queryParameters: {
          'contractorRef':
              serializeParam(s.ref, ParamType.DocumentReference),
        }.withoutNulls,
      ),
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .78),
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.alternate, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: avatar + name + rating
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: s.photoUrl.isNotEmpty
                        ? Image.network(s.photoUrl,
                            width: 44, height: 44, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _defaultAvatar(theme, s.name))
                        : _defaultAvatar(theme, s.name),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.name,
                          style: GoogleFonts.ubuntu(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.primaryText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s.serviceType,
                          style: GoogleFonts.ubuntu(
                            fontSize: 11,
                            color: theme.secondaryText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Rating badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC107).withOpacity(.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Color(0xFFFFC107), size: 14),
                        const SizedBox(width: 3),
                        Text(
                          s.rating > 0
                              ? s.rating.toStringAsFixed(1)
                              : 'New',
                          style: GoogleFonts.ubuntu(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.primaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Distance + reason row
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
              child: Row(
                children: [
                  if (s.distKm != null) ...[
                    Icon(Icons.location_on_rounded,
                        size: 12, color: theme.primary),
                    const SizedBox(width: 3),
                    Text(
                      _distLabel(s.distKm!),
                      style: GoogleFonts.ubuntu(
                          fontSize: 11,
                          color: theme.primary,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 8),
                    Container(
                        width: 3,
                        height: 3,
                        decoration: BoxDecoration(
                          color: theme.secondaryText,
                          shape: BoxShape.circle,
                        )),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      s.reason,
                      style: GoogleFonts.ubuntu(
                          fontSize: 11, color: theme.secondaryText),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // Top review quote
            if (s.topReview != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.format_quote_rounded,
                        size: 14, color: theme.secondaryText.withOpacity(0.5)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        s.topReview!,
                        style: GoogleFonts.ubuntu(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: theme.secondaryText,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            // View profile button
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: theme.alternate)),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
              ),
              child: TextButton(
                onPressed: () => context.pushNamed(
                  ContractorProfilePageWidget.routeName,
                  queryParameters: {
                    'contractorRef':
                        serializeParam(s.ref, ParamType.DocumentReference),
                  }.withoutNulls,
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(14),
                      bottomRight: Radius.circular(14),
                    ),
                  ),
                ),
                child: Text(
                  'View Profile',
                  style: GoogleFonts.ubuntu(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _defaultAvatar(FlutterFlowTheme theme, String name) {
    final initials = name.isNotEmpty
        ? name.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join()
        : '?';
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [theme.primary, theme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(initials,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
      ),
    );
  }

  Widget _buildQuickReply(FlutterFlowTheme theme, String label) {
    return GestureDetector(
      onTap: () => _handleUserMessage(label),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: theme.primary.withOpacity(.09),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.primary.withOpacity(.3)),
        ),
        child: Text(
          label,
          style: GoogleFonts.ubuntu(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: theme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(FlutterFlowTheme theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.secondaryBackground,
              borderRadius: BorderRadius.circular(18),
            ),
            child: SpinKitThreeBounce(
              color: theme.primary,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  Input bar
  // ─────────────────────────────────────────────────────────

  Widget _buildInputBar(FlutterFlowTheme theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        border:
            Border(top: BorderSide(color: theme.alternate.withOpacity(.5))),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 10,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.secondaryBackground,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _textCtrl,
                style: GoogleFonts.ubuntu(
                    fontSize: 14, color: theme.primaryText),
                maxLines: 3,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Describe your problem...',
                  hintStyle: GoogleFonts.ubuntu(
                      fontSize: 14, color: theme.secondaryText),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
                onSubmitted: _handleUserMessage,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _handleUserMessage(_textCtrl.text),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [theme.primary, theme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
