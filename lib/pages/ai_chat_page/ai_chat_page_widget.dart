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
  });
}

// ─────────────────────────────────────────────────────────
//  Category keyword mapping
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
    'ac',
    'air conditioning',
    'hvac',
    'cooling',
    'air con',
    'heat',
    'heating',
    'thermostat',
    'duct',
    'ventilation',
    'fan coil',
    'split unit',
  ],
  'Electrical Services': [
    'electric',
    'electrician',
    'wiring',
    'outlet',
    'socket',
    'breaker',
    'fuse',
    'power',
    'light',
    'lighting',
    'voltage',
    'circuit',
    'panel',
    'switch',
  ],
  'Plumbing': [
    'plumb',
    'pipe',
    'leak',
    'water',
    'drain',
    'toilet',
    'sink',
    'faucet',
    'shower',
    'tap',
    'sewage',
    'heater tank',
    'water heater',
    'clog',
    'blockage',
  ],
  'General Construction & Renovation': [
    'construction',
    'renovation',
    'build',
    'remodel',
    'contractor',
    'cement',
    'concrete',
    'flooring',
    'tile',
    'roofing',
    'wall',
    'brick',
    'foundation',
    'structural',
    'carpentry',
    'wood',
    'door',
    'window',
  ],
  'Interior Finishing': [
    'interior',
    'finishing',
    'paint',
    'painting',
    'wallpaper',
    'ceiling',
    'gypsum',
    'partition',
    'decor',
    'decoration',
    'furniture',
    'cabinet',
    'wardrobe',
    'kitchen',
  ],
};

String? _detectCategory(String input) {
  final lower = input.toLowerCase();
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
  return bestScore > 0 ? bestCategory : null;
}

// ─────────────────────────────────────────────────────────
//  Helper
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

// ─────────────────────────────────────────────────────────
//  Widget
// ─────────────────────────────────────────────────────────

class AiChatPageWidget extends StatefulWidget {
  const AiChatPageWidget({super.key});

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

  static const _quickReplies = [
    'Find AC technician',
    'Find electrician',
    'Find plumber',
    'Nearest contractors',
    'Highest rated',
  ];

  @override
  void initState() {
    super.initState();
    _tryGetLocation();
    // Welcome message
    _messages.add(_Msg(
      sender: _Sender.bot,
      text:
          'Hi! 👋 I\'m your contractor assistant. Tell me what problem you\'re facing and I\'ll find the best contractors for you.\n\nOr tap a quick reply below:',
      quickReplies: _quickReplies,
    ));
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

  // ── Query Firestore for contractors ──────────────────────

  Future<List<_ContractorSuggestion>> _fetchSuggestions({
    String? category,
    bool nearestFirst = false,
  }) async {
    Query query = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'service_provider')
        .where('is_disabled', isEqualTo: false);

    if (category != null) {
      query = query.where('categories', arrayContains: category);
    }

    final snap = await query.get();

    // Build suggestion list
    final suggestions = snap.docs.map((doc) {
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

      String reason;
      if (rating >= 4.5) {
        reason = dist != null && dist < 5
            ? 'Top rated & close to you'
            : 'Excellent reviews & high rating';
      } else if (rating >= 3.5) {
        reason = dist != null && dist < 3
            ? 'Well rated & near your location'
            : 'Good rating with positive reviews';
      } else if (dist != null && dist < 2) {
        reason = 'Very close to your location';
      } else {
        reason = 'Available in your area';
      }

      return _ContractorSuggestion(
        uid: doc.id,
        ref: doc.reference,
        name: name,
        serviceType: cat,
        rating: rating,
        reviewCount: count,
        photoUrl: photo,
        distKm: dist,
        reason: reason,
      );
    }).toList();

    // Sort
    if (nearestFirst && _userPosition != null) {
      suggestions.sort((a, b) {
        if (a.distKm == null && b.distKm == null) {
          return b.rating.compareTo(a.rating);
        }
        if (a.distKm == null) return 1;
        if (b.distKm == null) return -1;
        return a.distKm!.compareTo(b.distKm!);
      });
    } else {
      suggestions.sort((a, b) => b.rating.compareTo(a.rating));
    }

    return suggestions.take(3).toList();
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

    // Small delay for natural feel
    await Future.delayed(const Duration(milliseconds: 800));

    final lower = trimmed.toLowerCase();
    final bool nearestFirst = lower.contains('nearest') ||
        lower.contains('near me') ||
        lower.contains('close') ||
        lower.contains('nearby');

    final category = _detectCategory(trimmed);

    List<_ContractorSuggestion> results;
    String intro;

    if (lower.contains('highest rated') ||
        lower.contains('best rated') ||
        lower.contains('top rated')) {
      results = await _fetchSuggestions(nearestFirst: false);
      intro =
          'Here are the highest-rated contractors across all categories:';
    } else if (nearestFirst && category == null) {
      results = await _fetchSuggestions(nearestFirst: true);
      intro = _userPosition != null
          ? 'Here are the nearest contractors to your location:'
          : 'Location not available. Showing top-rated contractors:';
    } else if (category != null) {
      results = await _fetchSuggestions(
          category: category, nearestFirst: nearestFirst);
      if (results.isEmpty) {
        // Fall back to all service providers
        results = await _fetchSuggestions(nearestFirst: nearestFirst);
        intro =
            'No exact match for "$category" found, but here are some great contractors who can help:';
      } else {
        intro = nearestFirst && _userPosition != null
            ? 'Found ${results.length} nearest contractor${results.length == 1 ? '' : 's'} for $category:'
            : 'Found ${results.length} top contractor${results.length == 1 ? '' : 's'} for $category:';
      }
    } else {
      results = await _fetchSuggestions(nearestFirst: false);
      intro =
          'I\'m not sure what service you need. Here are our top-rated contractors — tap one to view their profile:';
    }

    if (!mounted) return;

    if (results.isEmpty) {
      setState(() {
        _thinking = false;
        _messages.add(_Msg(
          sender: _Sender.bot,
          text:
              'Sorry, I couldn\'t find any contractors right now. Please try again later.',
          quickReplies: _quickReplies,
        ));
      });
    } else {
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
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
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
