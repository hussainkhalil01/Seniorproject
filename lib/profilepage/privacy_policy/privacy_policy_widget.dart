import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'privacy_policy_model.dart';
export 'privacy_policy_model.dart';

class PrivacyPolicyWidget extends StatefulWidget {
  const PrivacyPolicyWidget({super.key});

  static String routeName = 'PrivacyPolicy';
  static String routePath = '/privacyPolicy';

  @override
  State<PrivacyPolicyWidget> createState() => _PrivacyPolicyWidgetState();
}

class _PrivacyPolicyWidgetState extends State<PrivacyPolicyWidget> {
  late PrivacyPolicyModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PrivacyPolicyModel());
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
          'Privacy Policy',
          style: GoogleFonts.ubuntu(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: theme.primaryText,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        controller: _model.scrollController,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        child: Container(
          decoration: BoxDecoration(
            color: theme.secondaryBackground,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: MarkdownBody(
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
            onTapLink: (_, url, __) => launchURL(url!),
          ),
        ),
      ),
    );
  }
}
