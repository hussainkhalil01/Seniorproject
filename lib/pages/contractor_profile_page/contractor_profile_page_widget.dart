import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/components/startchatting_widget.dart';
import '/pages/contractors_map_page/contractors_map_page_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class ContractorProfilePageWidget extends StatefulWidget {
  const ContractorProfilePageWidget({
    super.key,
    required this.contractorRef,
  });

  final DocumentReference contractorRef;

  static String routeName = 'ContractorProfilePage';
  static String routePath = '/contractorProfilePage';

  @override
  State<ContractorProfilePageWidget> createState() =>
      _ContractorProfilePageWidgetState();
}

class _ContractorProfilePageWidgetState
    extends State<ContractorProfilePageWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isCurrentUserProvider =
        currentUserDocument?.role == 'service_provider';

    return Scaffold(
      backgroundColor: theme.primaryBackground,
      body: StreamBuilder<UsersRecord>(
        stream: UsersRecord.getDocument(widget.contractorRef),
        builder: (context, snap) {
          if (!snap.hasData) {
            return Center(
                child: CircularProgressIndicator(color: theme.primary));
          }
          final contractor = snap.data!;
          return _buildBody(context, theme, contractor, isCurrentUserProvider);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, FlutterFlowTheme theme,
      UsersRecord contractor, bool isCurrentUserProvider) {
    return CustomScrollView(
      slivers: [
        // App bar with cover + avatar
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          backgroundColor: theme.primary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [theme.primary, theme.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                // Avatar centered
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 30),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: contractor.photoUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: contractor.photoUrl,
                                width: 90,
                                height: 90,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.person_rounded,
                                    color: Colors.white, size: 44),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + verified badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        contractor.fullName.isNotEmpty
                            ? contractor.fullName
                            : contractor.displayName,
                        style: GoogleFonts.ubuntu(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryText,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.verified_rounded,
                              color: theme.primary, size: 14),
                          const SizedBox(width: 4),
                          Text('Verified',
                              style: GoogleFonts.ubuntu(
                                  fontSize: 12,
                                  color: theme.primary,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  contractor.title.isNotEmpty
                      ? contractor.title
                      : 'Service Provider',
                  style: GoogleFonts.ubuntu(
                      fontSize: 15, color: theme.secondaryText),
                ),
                const SizedBox(height: 12),

                // Live avg rating from reviews
                _RatingSummaryWidget(
                    contractorRef: widget.contractorRef,
                    cachedAvg: contractor.ratingAvg,
                    cachedCount: contractor.ratingCount),

                const SizedBox(height: 16),

                // Description
                if (contractor.shortDescription.isNotEmpty) ...[
                  Text('About',
                      style: GoogleFonts.ubuntu(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryText)),
                  const SizedBox(height: 6),
                  Text(contractor.shortDescription,
                      style: GoogleFonts.ubuntu(
                          fontSize: 14,
                          color: theme.secondaryText,
                          height: 1.5)),
                  const SizedBox(height: 20),
                ],

                // Chat Now + View on Map buttons
                if (!isCurrentUserProvider &&
                    contractor.reference != currentUserReference)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await showDialog(
                              barrierColor: Colors.transparent,
                              barrierDismissible: false,
                              context: context,
                              builder: (dialogContext) => Dialog(
                                elevation: 0,
                                insetPadding: EdgeInsets.zero,
                                backgroundColor: Colors.transparent,
                                child: GestureDetector(
                                  onTap: () {
                                    FocusScope.of(dialogContext).unfocus();
                                    FocusManager.instance.primaryFocus
                                        ?.unfocus();
                                  },
                                  child: SizedBox(
                                    height: 300,
                                    width: double.infinity,
                                    child: StartchattingWidget(
                                        contractorRecord: contractor),
                                  ),
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.chat_rounded,
                              size: 18, color: Colors.white),
                          label: Text('Chat Now',
                              style: GoogleFonts.ubuntu(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primary,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                        ),
                      ),
                      if (contractor.latitude != 0.0 ||
                          contractor.longitude != 0.0) ...[  
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final lat = contractor.latitude;
                            final lng = contractor.longitude;
                            final label = Uri.encodeComponent(
                                contractor.fullName.isNotEmpty
                                    ? contractor.fullName
                                    : contractor.displayName);
                            final uri = Uri.parse(
                                'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
                            if (!await launchUrl(uri,
                                mode: LaunchMode.externalApplication)) {
                              final fallback = Uri.parse(
                                  'geo:$lat,$lng?q=$lat,$lng($label)');
                              await launchUrl(fallback,
                                  mode: LaunchMode.externalApplication);
                            }
                          },
                          icon: const Icon(Icons.location_on_rounded,
                              size: 18, color: Colors.white),
                          label: Text('Location',
                              style: GoogleFonts.ubuntu(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF34A853),
                            padding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ],
                  ),

                const SizedBox(height: 28),

                // Reviews section header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Reviews',
                        style: GoogleFonts.ubuntu(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.primaryText)),
                  ],
                ),
                const SizedBox(height: 14),

                // Reviews list
                _ReviewsListWidget(contractorRef: widget.contractorRef),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Rating Summary Widget ─────────────────────────────────────────────────

class _RatingSummaryWidget extends StatelessWidget {
  const _RatingSummaryWidget({
    required this.contractorRef,
    this.cachedAvg = 0.0,
    this.cachedCount = 0,
  });
  final DocumentReference contractorRef;
  final double cachedAvg;
  final int cachedCount;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('contractor_ref', isEqualTo: contractorRef)
          .snapshots(),
      builder: (context, snap) {
        double avg = cachedAvg;
        int count = cachedCount;
        if (snap.hasData && snap.data!.docs.isNotEmpty) {
          count = snap.data!.docs.length;
          final total = snap.data!.docs
              .map((d) => (d.data() as Map<String, dynamic>)['rating'] as num? ?? 0)
              .fold<double>(0.0, (a, b) => a + b);
          avg = total / count;
        }

        return Row(
          children: [
            ...List.generate(5, (i) {
              final filled = i < avg.floor();
              final half = !filled && i < avg;
              return Icon(
                filled
                    ? Icons.star_rounded
                    : half
                        ? Icons.star_half_rounded
                        : Icons.star_outline_rounded,
                color: const Color(0xFFFFC107),
                size: 20,
              );
            }),
            const SizedBox(width: 8),
            Text(
              count > 0
                  ? '${avg.toStringAsFixed(1)} ($count ${count == 1 ? 'review' : 'reviews'})'
                  : 'No reviews yet',
              style: GoogleFonts.ubuntu(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.primaryText),
            ),
          ],
        );
      },
    );
  }
}

// ─── Reviews List ──────────────────────────────────────────────────────────

class _ReviewsListWidget extends StatelessWidget {
  const _ReviewsListWidget({required this.contractorRef});
  final DocumentReference contractorRef;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('contractor_ref', isEqualTo: contractorRef)
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
              child: Text('Could not load reviews.',
                  style: GoogleFonts.ubuntu(
                      color: theme.secondaryText, fontSize: 13)));
        }
        if (!snap.hasData) {
          return Center(
              child: CircularProgressIndicator(color: theme.primary));
        }
        final docs = List.of(snap.data!.docs)
          ..sort((a, b) {
            final ta = (a.data() as Map<String, dynamic>)['created_time'] as Timestamp?;
            final tb = (b.data() as Map<String, dynamic>)['created_time'] as Timestamp?;
            if (ta == null && tb == null) return 0;
            if (ta == null) return 1;
            if (tb == null) return -1;
            return tb.compareTo(ta);
          });
        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.secondaryBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.rate_review_outlined,
                      color: theme.secondaryText, size: 40),
                  const SizedBox(height: 10),
                  Text('No reviews yet. Be the first!',
                      style: GoogleFonts.ubuntu(
                          color: theme.secondaryText, fontSize: 14)),
                ],
              ),
            ),
          );
        }
        return Column(
          children: docs
              .map((d) =>
                  _ReviewCard(data: d.data() as Map<String, dynamic>, theme: theme))
              .toList(),
        );
      },
    );
  }
}

// ─── Single Review Card ────────────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.data, required this.theme});
  final Map<String, dynamic> data;
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    final rating = (data['rating'] as num?)?.toInt() ?? 5;
    final comment = data['comment'] as String? ?? '';
    final reviewerName = data['reviewer_name'] as String? ?? 'Anonymous';
    final reviewerPhoto = data['reviewer_photo'] as String? ?? '';
    final ts = data['created_time'] as Timestamp?;
    final date = ts != null
        ? dateTimeFormat('MMM d, y', ts.toDate())
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: reviewerPhoto.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: reviewerPhoto,
                        width: 38,
                        height: 38,
                        fit: BoxFit.cover)
                    : Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                            color: theme.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle),
                        child: Icon(Icons.person_rounded,
                            color: theme.primary, size: 20),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reviewerName,
                        style: GoogleFonts.ubuntu(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: theme.primaryText)),
                    Text(date,
                        style: GoogleFonts.ubuntu(
                            fontSize: 12, color: theme.secondaryText)),
                  ],
                ),
              ),
              // Stars
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: const Color(0xFFFFC107),
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(comment,
                style: GoogleFonts.ubuntu(
                    fontSize: 13,
                    color: theme.secondaryText,
                    height: 1.5)),
          ],
        ],
      ),
    );
  }
}
