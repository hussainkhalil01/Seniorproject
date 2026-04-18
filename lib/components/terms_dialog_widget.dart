import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';

class TermsDialogWidget extends StatefulWidget {
  const TermsDialogWidget({super.key});

  @override
  State<TermsDialogWidget> createState() => _TermsDialogWidgetState();
}

class _TermsDialogWidgetState extends State<TermsDialogWidget> {
  bool _agreedToTerms = false;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Align(
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 530, maxHeight: 620),
          decoration: BoxDecoration(
            color: theme.primaryBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                blurRadius: 20,
                color: Color(0x33000000),
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.primary, theme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined,
                        color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'Terms & Privacy Policy',
                      style: GoogleFonts.ubuntu(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle(theme, 'Terms and Conditions'),
                      const SizedBox(height: 8),
                      _bullet(theme,
                          'By creating an account, you agree to these Terms and Conditions and our Privacy Policy.'),
                      _bullet(theme,
                          'This platform enables communication between clients and contractors through in-app chat.'),
                      _bullet(theme,
                          'For safety, quality assurance, dispute resolution, and support purposes, administrators may access and review chat conversations when necessary.'),
                      _bullet(theme,
                          'By using the app, you acknowledge and consent to this access and monitoring.'),
                      _bullet(theme,
                          'If you do not agree with these terms, you must not create an account or use the platform.'),
                      const SizedBox(height: 16),
                      _sectionTitle(theme, 'Privacy Policy'),
                      const SizedBox(height: 8),
                      _bullet(theme,
                          'We respect your privacy and are committed to protecting your personal information.'),
                      _bullet(theme,
                          'When using our platform, messages between clients and contractors may be accessed by administrators for support, security, abuse prevention, complaint handling, and service improvement.'),
                      _bullet(theme,
                          'We collect and use your information only as necessary to provide and improve our services.'),
                      _bullet(theme,
                          'Our support team and administrators may access your chat content for support, safety, abuse prevention, and complaint handling purposes.'),
                      _bullet(theme,
                          'Your personal data and chat content will not be shared with third parties, except when required by law or to protect the rights, safety, and integrity of users and the platform.'),
                      _bullet(theme,
                          'By registering an account, you agree to the collection and use of your information as described in this Privacy Policy.'),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // Checkbox + buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  children: [
                    Divider(
                        height: 1, color: theme.alternate.withValues(alpha: 0.5)),
                    const SizedBox(height: 12),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () =>
                          setState(() => _agreedToTerms = !_agreedToTerms),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: Checkbox(
                              value: _agreedToTerms,
                              onChanged: (v) => setState(
                                  () => _agreedToTerms = v ?? false),
                              activeColor: theme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'I have read and agree to the Terms and Conditions and Privacy Policy',
                              style: GoogleFonts.ubuntu(
                                fontSize: 13,
                                color: theme.primaryText,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        // Decline button
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context, false),
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 13),
                              side: BorderSide(color: theme.alternate),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Decline',
                              style: GoogleFonts.ubuntu(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: theme.secondaryText,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Agree button
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _agreedToTerms
                                ? () => Navigator.pop(context, true)
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primary,
                              disabledBackgroundColor:
                                  theme.primary.withValues(alpha: 0.4),
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 13),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'I Agree',
                              style: GoogleFonts.ubuntu(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
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
        ),
      ),
    );
  }

  Widget _sectionTitle(FlutterFlowTheme theme, String title) {
    return Text(
      title,
      style: GoogleFonts.ubuntu(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: theme.primary,
      ),
    );
  }

  Widget _bullet(FlutterFlowTheme theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: theme.secondaryText,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.ubuntu(
                fontSize: 13,
                color: theme.primaryText,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
