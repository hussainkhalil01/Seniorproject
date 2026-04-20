import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_util.dart';
import 'ai_chat_page_widget.dart' show AiChatPageWidget;

enum Sender { user, bot }

class ChatMsg {
  final Sender sender;
  final String text;
  final List<ContractorSuggestion>? suggestions;
  final List<String>? quickReplies;

  ChatMsg({
    required this.sender,
    required this.text,
    this.suggestions,
    this.quickReplies,
  });
}

class ContractorSuggestion {
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
  final String shortDescription;

  ContractorSuggestion({
    required this.uid,
    required this.ref,
    required this.name,
    required this.serviceType,
    required this.rating,
    required this.reviewCount,
    required this.photoUrl,
    required this.reason,
    required this.shortDescription,
    this.distKm,
    this.topReview,
  });

  Map<String, dynamic> toSafeJson() => {
        'name': name,
        'category': serviceType,
        'rating': rating,
        'review_count': reviewCount,
        if (distKm != null)
          'distance_km': double.parse(distKm!.toStringAsFixed(1)),
        if (topReview != null) 'top_review': topReview,
        if (shortDescription.trim().isNotEmpty)
          'profile_summary': shortDescription.trim(),
      };
}

class AiChatPageModel extends FlutterFlowModel<AiChatPageWidget> {
  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
