import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import '/amanbuild/profile_pages/profile_section_card.dart';

class PrivacyPolicyPageWidget extends StatefulWidget {
  const PrivacyPolicyPageWidget({super.key});

  static String routeName = 'PrivacyPolicy';
  static String routePath = '/privacyPolicy';

  @override
  State<PrivacyPolicyPageWidget> createState() =>
      _PrivacyPolicyPageWidgetState();
}

class _PrivacyPolicyPageWidgetState extends State<PrivacyPolicyPageWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
                        'Privacy Policy',
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
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              child: ProfileSectionCard(
                shadow: false,
                title: 'Privacy Policy',
                icon: Icons.privacy_tip_rounded,
                children: [
                  MarkdownBody(
                    data: '''### 1. Information We Collect

*We collect information to provide better services to all our users. This includes:*

**Account Information:** *When you register, we collect your full name, email address, and phone number.*

**Profile Media:** *If you choose to upload a profile picture, it is stored securely in our database.*

**Usage Data:** *We may collect information about how you interact with our services, such as button clicks and page views.*

### 2. How We Use Information

**Service Provision:** *We use your data to maintain and improve the application\'s core functions.*

**User Communication:** *We use your contact details to facilitate support via the Help Center.*

**App Notifications:** *We send alerts based on your preferences in the Settings menu.*

### 3. Information Sharing

**Explicit Consent:** *We only share personal data with third parties when you give us direct permission.*

**Legal Compliance:** *We may disclose information if required by law to meet regulatory obligations.*

### 4. Data Security

**Firebase Infrastructure:** *Your account credentials and profile media are encrypted and stored using Firebase Authentication and Storage.*

### 5. Your Rights

**Data Management:** *You can modify your name and phone number at any time in the Edit Profile section.*

**Account Removal:** *You have the right to request account deletion through our support team.*''',
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                      h3: GoogleFonts.ubuntu(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: theme.primaryText,
                      ),
                      p: GoogleFonts.ubuntu(
                        fontSize: 13,
                        color: theme.secondaryText,
                        height: 1.55,
                      ),
                      strong: GoogleFonts.ubuntu(
                        fontWeight: FontWeight.w600,
                        color: theme.primaryText,
                        fontSize: 13,
                      ),
                    ),
                    onTapLink: (_, url, __) {
                      if (url != null) launchURL(url);
                    },
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

