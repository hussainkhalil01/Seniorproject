import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'setting_model.dart';
export 'setting_model.dart';

class SettingWidget extends StatefulWidget {
  const SettingWidget({super.key});

  static String routeName = 'setting';
  static String routePath = '/setting';

  @override
  State<SettingWidget> createState() => _SettingWidgetState();
}

class _SettingWidgetState extends State<SettingWidget> {
  late SettingModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SettingModel());

    // Init dark mode toggle from persisted theme
    _model.switchValue2 = FlutterFlowTheme.themeMode == ThemeMode.dark;
    // Init notification toggle from SharedPreferences
    SharedPreferences.getInstance().then((prefs) {
      safeSetState(() {
        _model.switchValue1 = prefs.getBool('push_notifications') ?? true;
      });
    });
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          'Settings',
          style: GoogleFonts.ubuntu(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: theme.primaryText,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        controller: _model.columnController,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Preferences Card ─────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: theme.secondaryBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.notifications_outlined,
                    iconColor: const Color(0xFF5B8AF5),
                    label: 'Push Notifications',
                    subtitle: _model.switchValue1 == true
                        ? 'Enabled'
                        : 'Disabled',
                    value: _model.switchValue1 ?? true,
                    onChanged: (val) async {
                      safeSetState(() => _model.switchValue1 = val);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('push_notifications', val);
                    },
                    activeColor: theme.primary,
                  ),
                  Divider(
                      height: 1,
                      indent: 56,
                      color: theme.alternate.withOpacity(0.5)),
                  _SettingsTile(
                    icon: isDark
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    iconColor: isDark
                        ? const Color(0xFF7B61FF)
                        : const Color(0xFFFFA726),
                    label: 'Dark Mode',
                    subtitle: isDark ? 'Dark theme active' : 'Light theme active',
                    value: _model.switchValue2 ?? isDark,
                    onChanged: (val) {
                      safeSetState(() => _model.switchValue2 = val);
                      setDarkModeSetting(
                        context,
                        val ? ThemeMode.dark : ThemeMode.light,
                      );
                    },
                    activeColor: theme.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            // ── Privacy Policy Card ───────────────────────────
            Text(
              'Privacy Policy',
              style: GoogleFonts.ubuntu(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.secondaryText,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: theme.secondaryBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(16),
              child: MarkdownBody(
                data:
                    '''### 1. Information We Collect

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
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─── Reusable settings row ────────────────────────────────────────────────────
class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.activeColor,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.ubuntu(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: theme.primaryText,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.ubuntu(
                    fontSize: 12,
                    color: theme.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: activeColor,
          ),
        ],
      ),
    );
  }
}
