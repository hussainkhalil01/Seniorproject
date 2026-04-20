import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/api_requests/openai_service.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'ai_chat_page_model.dart';
export 'ai_chat_page_model.dart';

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
  late AiChatPageModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<ChatMsg> _messages = [];
  bool _thinking = false;
  Position? _userPosition;

  final _ai = OpenAIService();

  static const double _maxDistanceKm = 50.0;
  static const double _reviewCountNorm = 20.0;
  static const double _veryCloseKm = 2.0;
  static const double _nearbyKm = 5.0;

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
    _model = createModel(context, () => AiChatPageModel());
    _tryGetLocation();
    _messages.add(ChatMsg(
      sender: Sender.bot,
      text:
          'Hi! 👋 I\'m your AI contractor assistant.\n\nDescribe your problem (e.g. "My AC is not cooling", "I need a cheap electrician near me") and I\'ll find the best contractors for you.',
      quickReplies: _quickReplies,
    ));

    if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleUserMessage(widget.initialQuery!);
      });
    }
  }

  @override
  void dispose() {
    _model.dispose();
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
          perm == LocationPermission.deniedForever) { return; }
      final pos = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.low));
      if (mounted) setState(() => _userPosition = pos);
    } catch (e) {
      debugPrint('[AiChat] location error: $e');
    }
  }

  double _computeScore(
    ContractorSuggestion s, {
    bool boostNearest = false,
    bool boostRating = false,
  }) {
    final ratingScore = s.rating / 5.0;
    double distScore;
    if (s.distKm != null) {
      distScore = math.max(0, 1.0 - (s.distKm! / _maxDistanceKm));
    } else {
      distScore = 0.3;
    }
    final countScore = math.min(1.0, s.reviewCount / _reviewCountNorm);

    double wRating, wDist, wCount;
    if (boostNearest) {
      wRating = 0.2;
      wDist = 0.6;
      wCount = 0.2;
    } else if (boostRating) {
      wRating = 0.6;
      wDist = 0.1;
      wCount = 0.3;
    } else {
      wRating = 0.4;
      wDist = 0.3;
      wCount = 0.3;
    }

    return (ratingScore * wRating) +
        (distScore * wDist) +
        (countScore * wCount);
  }

  String _generateReason(ContractorSuggestion s) {
    final parts = <String>[];
    if (s.rating >= 4.5 && s.reviewCount >= 5) {
      parts.add('Excellent rating (${s.rating.toStringAsFixed(1)})');
    } else if (s.rating >= 4.0 && s.reviewCount >= 3) {
      parts.add('Highly rated (${s.rating.toStringAsFixed(1)})');
    } else if (s.rating >= 3.5) {
      parts.add('Well rated');
    } else if (s.reviewCount == 0) {
      parts.add('New on the platform');
    }
    if (s.distKm != null) {
      if (s.distKm! < _veryCloseKm) {
        parts.add('very close to you');
      } else if (s.distKm! < _nearbyKm) {
        parts.add('nearby');
      }
    }
    if (s.reviewCount >= 10) {
      parts.add('${s.reviewCount} verified reviews');
    } else if (s.reviewCount >= 3) {
      parts.add('${s.reviewCount} reviews');
    }
    if (parts.isEmpty) return 'Available in your area';
    parts[0] = parts[0][0].toUpperCase() + parts[0].substring(1);
    return parts.join(' · ');
  }

  Future<List<String>> _fetchTopReviews(
      DocumentReference contractorRef, int limit) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('reviews')
          .where('contractor_ref', isEqualTo: contractorRef)
          .orderBy('rating', descending: true)
          .limit(limit)
          .get();
      return snap.docs
          .map((d) => (d.data()['comment'] as String?) ?? '')
          .where((c) => c.trim().length > 5)
          .map((c) {
        final t = c.trim();
        return t.length > 100 ? '${t.substring(0, 97)}...' : t;
      }).toList();
    } catch (e) {
      debugPrint('[AiChat] fetchTopReviews error: $e');
      return [];
    }
  }

  List<String> _mapAiCategoryToDbCategories(String category) {
    switch (category.trim()) {
      case 'HVAC (Air Conditioning)':
        return ['Air Conditioning', 'Heating'];
      case 'Electrical Services':
        return ['Electricians'];
      case 'Plumbing':
        return ['Plumbers'];
      case 'General Construction & Renovation':
        return ['Contractors & Handymen'];
      case 'Interior Finishing':
        return ['Painters'];
      case 'Tree Services':
        return ['Tree Services'];
      case 'Movers':
        return ['Movers'];
      case 'Locksmiths':
        return ['Locksmiths'];
      default:
        return [category];
    }
  }

  Future<List<ContractorSuggestion>> _fetchSuggestions({
    String? category,
    String sortBy = 'best_match',
    int limit = 3,
  }) async {
    Query q = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'service_provider')
        .where('is_disabled', isEqualTo: false);

    if (category != null && category.trim().isNotEmpty) {
      final mappedCategories = _mapAiCategoryToDbCategories(category);
      if (mappedCategories.length == 1) {
        q = q.where('categories', arrayContains: mappedCategories.first);
      } else {
        q = q.where('categories', arrayContainsAny: mappedCategories);
      }
    }

    final snap = await q.get();

    final suggestions = snap.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
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
      final shortDescription = (data['short_description'] as String?) ?? '';
      final lat = (data['latitude'] as num?)?.toDouble() ?? 0.0;
      final lng = (data['longitude'] as num?)?.toDouble() ?? 0.0;

      double? dist;
      if (_userPosition != null && (lat != 0.0 || lng != 0.0)) {
        dist = _haversineKm(
            _userPosition!.latitude, _userPosition!.longitude, lat, lng);
      }

      return ContractorSuggestion(
        uid: doc.id,
        ref: doc.reference,
        name: name,
        serviceType: cat,
        rating: rating,
        reviewCount: count,
        photoUrl: photo,
        distKm: dist,
        reason: '',
        shortDescription: shortDescription,
      );
    }).toList();

    final boostNearest = sortBy == 'nearest';
    final boostRating = sortBy == 'highest_rated';

    suggestions.sort((a, b) {
      final sa = _computeScore(a,
          boostNearest: boostNearest, boostRating: boostRating);
      final sb = _computeScore(b,
          boostNearest: boostNearest, boostRating: boostRating);
      return sb.compareTo(sa);
    });

    final top = suggestions.take(limit.clamp(1, 3)).toList();
    final enriched = <ContractorSuggestion>[];

    for (int i = 0; i < top.length; i++) {
      final s = top[i];
      final reason = _generateReason(s);
      final reviews = await _fetchTopReviews(s.ref, 3);
      enriched.add(ContractorSuggestion(
        uid: s.uid,
        ref: s.ref,
        name: s.name,
        serviceType: s.serviceType,
        rating: s.rating,
        reviewCount: s.reviewCount,
        photoUrl: s.photoUrl,
        distKm: s.distKm,
        reason: reason,
        shortDescription: s.shortDescription,
        topReview: reviews.isNotEmpty ? reviews.first : null,
      ));
    }

    return enriched;
  }

  Future<void> _handleUserMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    _textCtrl.clear();
    setState(() {
      _messages.add(ChatMsg(sender: Sender.user, text: trimmed));
      _thinking = true;
    });
    _scrollToBottom();

    try {
      final aiResponse = await _ai.sendMessage(trimmed);

      if (!mounted) return;

      if (aiResponse.type == AIResponseType.text) {
        setState(() {
          _thinking = false;
          _messages.add(ChatMsg(
            sender: Sender.bot,
            text: aiResponse.text ?? '',
            quickReplies: _quickReplies,
          ));
        });
        _scrollToBottom();
        return;
      }

      final results = await _fetchSuggestions(
        category: aiResponse.category,
        sortBy: aiResponse.sortBy ?? 'best_match',
        limit: aiResponse.limit ?? 3,
      );

      if (!mounted) return;

      if (results.isEmpty) {
        final noResultText = await _ai.sendToolResult(
          toolCallId: aiResponse.toolCallId!,
          contractorDataJson: jsonEncode({
            'results': [],
            'message': 'No contractors found matching the criteria.',
          }),
        );

        setState(() {
          _thinking = false;
          _messages.add(ChatMsg(
            sender: Sender.bot,
            text: noResultText,
            quickReplies: _quickReplies,
          ));
        });
        _scrollToBottom();
        return;
      }

      final contractorData = results.map((s) => s.toSafeJson()).toList();
      final aiText = await _ai.sendToolResult(
        toolCallId: aiResponse.toolCallId!,
        contractorDataJson: jsonEncode({
          'results': contractorData,
          'user_location_available': _userPosition != null,
        }),
      );

      if (!mounted) return;

      setState(() {
        _thinking = false;
        _messages.add(ChatMsg(
          sender: Sender.bot,
          text: aiText,
          suggestions: results,
          quickReplies: _quickReplies,
        ));
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _thinking = false;
        _messages.add(ChatMsg(
          sender: Sender.bot,
          text: 'Sorry, something went wrong. Please try again.',
          quickReplies: _quickReplies,
        ));
      });
      _scrollToBottom();
    }
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
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        backgroundColor: theme.primaryBackground,
        body: Column(
          children: [
            // ── Gradient header ──────────────────────────
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.primary, theme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: Row(
                    children: [
                      Material(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => context.pop(),
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(Icons.arrow_back_rounded,
                                color: Colors.white, size: 22),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        child: const Icon(Icons.smart_toy_rounded,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'AI Assistant',
                              style: GoogleFonts.ubuntu(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Find the best contractor for you',
                              style: GoogleFonts.ubuntu(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.8)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // ── Message list ──────────────────────────────
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
            // ── Input bar ─────────────────────────────────
            _buildInputBar(theme),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  Message bubble
  // ─────────────────────────────────────────────────────────

  Widget _buildMessage(
      BuildContext context, FlutterFlowTheme theme, ChatMsg msg) {
    final isUser = msg.sender == Sender.user;
    return Column(
      crossAxisAlignment:
          isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
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

        if (msg.suggestions != null)
          ...msg.suggestions!
              .map((s) => _buildSuggestionCard(context, theme, s)),

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
      BuildContext context, FlutterFlowTheme theme, ContractorSuggestion s) {
    return GestureDetector(
      onTap: () => context.pushNamed(
        ContractorProfilePageWidget.routeName,
        queryParameters: {
          'contractorRef':
              serializeParam(s.ref, ParamType.DocumentReference),
        }.withoutNulls,
        extra: <String, dynamic>{
          '__transition_info__': const TransitionInfo(
            hasTransition: true,
            transitionType: PageTransitionType.fade,
            duration: Duration(milliseconds: 150),
          ),
        },
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
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC107).withValues(alpha: 0.15),
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
            if (s.topReview != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.format_quote_rounded,
                        size: 14,
                        color: theme.secondaryText.withValues(alpha: 0.5)),
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
                  extra: <String, dynamic>{
                    '__transition_info__': const TransitionInfo(
                      hasTransition: true,
                      transitionType: PageTransitionType.fade,
                      duration: Duration(milliseconds: 150),
                    ),
                  },
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
    final icon = _quickReplyIcon(label);
    const iconColor = Color(0xFFF4A026);
    return GestureDetector(
      onTap: () => _handleUserMessage(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.alternate),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.ubuntu(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _quickReplyIcon(String label) {
    switch (label) {
      case 'AC not cooling':
        return Icons.ac_unit_rounded;
      case 'Water leak':
        return Icons.plumbing_rounded;
      case 'Electrical issue':
        return Icons.electrical_services_rounded;
      case 'Nearest contractors':
        return Icons.near_me_rounded;
      case 'Highest rated':
        return Icons.star_rounded;
      default:
        return Icons.chat_bubble_outline_rounded;
    }
  }

  Widget _buildTypingIndicator(FlutterFlowTheme theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        border: Border(
            top: BorderSide(
                color: theme.alternate.withValues(alpha: 0.5))),
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
