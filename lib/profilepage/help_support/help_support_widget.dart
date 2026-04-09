import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'help_support_model.dart';
export 'help_support_model.dart';

class HelpSupportWidget extends StatefulWidget {
  const HelpSupportWidget({super.key});

  static String routeName = 'HelpSupport';
  static String routePath = '/helpSupport';

  @override
  State<HelpSupportWidget> createState() => _HelpSupportWidgetState();
}

class _HelpSupportWidgetState extends State<HelpSupportWidget> {
  late HelpSupportModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  // Tracks which FAQ item is expanded
  int? _expandedIndex;

  static const _faqs = [
    _Faq(
      question: 'How do I become a contractor?',
      answer:
          'To become a contractor, complete our verification process by submitting your identification documents, proof of skills or certifications, and passing a background check. Once approved, you can start accepting projects through the platform.',
    ),
    _Faq(
      question: 'How do I post a job or project?',
      answer:
          'Navigate to the Home tab and tap the "Post a Job" button. Fill in the project title, description, budget, and required skills, then submit. Contractors will be able to apply within minutes.',
    ),
    _Faq(
      question: 'How are payments handled?',
      answer:
          'Payments are processed securely through our platform. Funds are held in escrow and released to the contractor once you confirm the work is complete.',
    ),
    _Faq(
      question: 'How do I report an issue?',
      answer:
          'Use the Contact Support section below to reach our team via email or live chat. You can also report a user or project directly from their profile page.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HelpSupportModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: theme.primaryBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: theme.primaryText, size: 20),
          onPressed: () => context.safePop(),
        ),
        title: Text(
          'Help Center',
          style: GoogleFonts.ubuntu(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: theme.primaryText,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          // ── FAQ section label ─────────────────────────────
          Text(
            'Frequently Asked Questions',
            style: GoogleFonts.ubuntu(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.secondaryText,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          // ── FAQ accordion card ────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: theme.secondaryBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: List.generate(_faqs.length, (i) {
                final faq = _faqs[i];
                final isExpanded = _expandedIndex == i;
                final isLast = i == _faqs.length - 1;
                return Column(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.vertical(
                        top: i == 0
                            ? const Radius.circular(16)
                            : Radius.zero,
                        bottom: isLast && !isExpanded
                            ? const Radius.circular(16)
                            : Radius.zero,
                      ),
                      onTap: () => setState(
                          () => _expandedIndex = isExpanded ? null : i),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: theme.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.help_outline_rounded,
                                  color: theme.primary, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                faq.question,
                                style: GoogleFonts.ubuntu(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: theme.primaryText,
                                ),
                              ),
                            ),
                            Icon(
                              isExpanded
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              color: theme.secondaryText,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 220),
                      crossFadeState: isExpanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      firstChild: const SizedBox.shrink(),
                      secondChild: Container(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.primaryBackground,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          faq.answer,
                          style: GoogleFonts.ubuntu(
                            fontSize: 13,
                            color: theme.secondaryText,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ),
                    if (!isLast)
                      Divider(
                          height: 1,
                          indent: 60,
                          color: theme.alternate.withOpacity(0.5)),
                  ],
                );
              }),
            ),
          ),
          const SizedBox(height: 28),
          // ── Contact Support label ─────────────────────────
          Text(
            'Contact Support',
            style: GoogleFonts.ubuntu(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.secondaryText,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          // ── Contact Support card ──────────────────────────
          Container(
            decoration: BoxDecoration(
              color: theme.secondaryBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need additional help? Our support team is here to assist you.',
                  style: GoogleFonts.ubuntu(
                    fontSize: 14,
                    color: theme.secondaryText,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    // Email Support button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            launchURL('mailto:amabild9371@gmail.com'),
                        icon: Icon(Icons.email_outlined,
                            size: 16, color: theme.primaryText),
                        label: Text(
                          'Email Support',
                          style: GoogleFonts.ubuntu(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.primaryText,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(
                              color: theme.alternate, width: 1.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Live Chat button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.chat_bubble_outline_rounded,
                            size: 16, color: Colors.white),
                        label: Text(
                          'Live Chat',
                          style: GoogleFonts.ubuntu(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── FAQ data class ───────────────────────────────────────────────────────────
class _Faq {
  const _Faq({required this.question, required this.answer});
  final String question;
  final String answer;
}
