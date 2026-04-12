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

  Widget _sectionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.secondary, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.ubuntu(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: theme.primaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: theme.accent4),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: theme.primaryBackground,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  FlutterFlowTheme.of(context).primary,
                  FlutterFlowTheme.of(context).secondary,
                ],
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
                        onTap: () => context.safePop(),
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(Icons.arrow_back_rounded,
                              color: Colors.white, size: 22),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Help Center',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.ubuntu(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 40, height: 40),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: Column(
                children: [
                  _sectionCard(
                    context: context,
                    title: 'Frequently Asked Questions',
                    icon: Icons.help_center_rounded,
                    children: List.generate(_faqs.length, (i) {
                      final faq = _faqs[i];
                      final isExpanded = _expandedIndex == i;
                      final isLast = i == _faqs.length - 1;

                      return Column(
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => setState(
                              () => _expandedIndex = isExpanded ? null : i,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: theme.primary.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.help_rounded,
                                      color: theme.secondary,
                                      size: 18,
                                    ),
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
                          ClipRect(
                            child: AnimatedCrossFade(
                              duration: const Duration(milliseconds: 220),
                              crossFadeState: isExpanded
                                  ? CrossFadeState.showSecond
                                  : CrossFadeState.showFirst,
                              firstChild: const SizedBox.shrink(),
                              secondChild: Container(
                                margin: const EdgeInsets.fromLTRB(4, 0, 4, 12),
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
                          ),
                          if (!isLast)
                            Divider(height: 1, color: theme.accent4),
                        ],
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  _sectionCard(
                    context: context,
                    title: 'Contact Support',
                    icon: Icons.support_agent_rounded,
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                side: BorderSide(
                                    color: theme.alternate, width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Faq {
  const _Faq({required this.question, required this.answer});
  final String question;
  final String answer;
}
