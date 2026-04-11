import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
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
  bool _isSaving = false;
  bool _languageInitialized = false;
  String? _initialLanguage;
  String? _selectedLanguage;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SettingModel());

    _model.switchValue2 = FlutterFlowTheme.themeMode == ThemeMode.dark;

    SharedPreferences.getInstance().then((prefs) {
      if (!mounted) return;
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

  bool get _hasChanges {
    final langCurrent =
        _selectedLanguage ?? valueOrDefault(currentUserDocument?.preferredLanguage, '');
    final langInitial = _initialLanguage ?? langCurrent;
    return langCurrent != langInitial;
  }

  Future<void> _save() async {
    if (_isSaving || !_hasChanges) return;

    final messenger = ScaffoldMessenger.of(context);
    final theme = FlutterFlowTheme.of(context);
    safeSetState(() => _isSaving = true);

    try {
      final String langValue = (_selectedLanguage ??
              valueOrDefault(currentUserDocument?.preferredLanguage, ''))
          .toString();

      if (currentUserReference != null) {
        await currentUserReference!.update({
          'preferred_language': langValue,
        });
      }

      safeSetState(() {
        _initialLanguage = langValue;
      });

      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text(
            langValue.isEmpty
                ? 'Translation disabled'
                : 'Translation language saved',
            style: GoogleFonts.ubuntu(
              color: Colors.white,
              fontSize: 15.0,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          duration: const Duration(milliseconds: 4000),
          backgroundColor: theme.success,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ));
    } catch (_) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text(
            'Something went wrong. Please try again',
            style: GoogleFonts.ubuntu(
              color: Colors.white,
              fontSize: 15.0,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          duration: const Duration(milliseconds: 4000),
          backgroundColor: theme.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ));
    } finally {
      if (mounted) {
        safeSetState(() => _isSaving = false);
      }
    }
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
    final isDark = _model.switchValue2 ??
        (Theme.of(context).brightness == Brightness.dark);

    return PopScope(
      canPop: !_isSaving,
      child: Scaffold(
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
                      Opacity(
                        opacity: _isSaving ? 0.4 : 1.0,
                        child: Material(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: _isSaving ? null : () => context.safePop(),
                            child: const Padding(
                              padding: EdgeInsets.all(8),
                              child: Icon(Icons.arrow_back_rounded,
                                  color: Colors.white, size: 22),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Settings',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.ubuntu(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      _isSaving
                          ? const SizedBox(
                              width: 40,
                              height: 40,
                              child: Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            )
                          : Opacity(
                              opacity: _hasChanges ? 1.0 : 0.4,
                              child: Material(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: _hasChanges ? _save : null,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    child: Text(
                                      'Save',
                                      style: GoogleFonts.ubuntu(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: AbsorbPointer(
                absorbing: _isSaving,
                child: SingleChildScrollView(
                  controller: _model.columnController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: theme.secondaryBackground,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            _SettingsTile(
                              icon: Icons.notifications_rounded,
                              iconColor: const Color(0xFF5B8AF5),
                              label: 'Push Notifications',
                              subtitle: _model.switchValue1 == true
                                  ? 'Enabled'
                                  : 'Disabled',
                              value: _model.switchValue1 ?? true,
                              onChanged: (val) async {
                                safeSetState(() => _model.switchValue1 = val);
                                final prefs =
                                    await SharedPreferences.getInstance();
                                await prefs.setBool(
                                    'push_notifications', val);
                              },
                              activeColor: theme.primary,
                            ),
                            Divider(
                              height: 1,
                              color: theme.accent4,
                            ),
                            _SettingsTile(
                              icon: isDark
                                  ? Icons.dark_mode_rounded
                                  : Icons.light_mode_rounded,
                              iconColor: isDark
                                  ? const Color(0xFF7B61FF)
                                  : const Color(0xFFFFA726),
                              label: 'Theme Mode',
                              subtitle: isDark
                                  ? 'Dark theme active'
                                  : 'Light theme active',
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
                      const SizedBox(height: 20),
                      AuthUserStreamWidget(
                        builder: (context) {
                          const languages = [
                            {
                              'code': '',
                              'label': 'No Translation',
                              'flag': '🌐'
                            },
                            {'code': 'ar', 'label': 'Arabic', 'flag': '🇸🇦'},
                            {'code': 'en', 'label': 'English', 'flag': '🇬🇧'},
                            {'code': 'hi', 'label': 'Hindi', 'flag': '🇮🇳'},
                            {'code': 'ur', 'label': 'Urdu', 'flag': '🇵🇰'},
                          ];

                          final currentLang = valueOrDefault(
                              currentUserDocument?.preferredLanguage, '');
                          if (!_languageInitialized) {
                            _selectedLanguage = currentLang;
                            _initialLanguage ??= currentLang;
                            _languageInitialized = true;
                          }

                          return _sectionCard(
                            context: context,
                            title: 'Chat Translation Language',
                            icon: Icons.translate_rounded,
                            children: [
                              Text(
                                'Messages sent to you will be automatically translated into your chosen language',
                                style: GoogleFonts.ubuntu(
                                  fontSize: 12,
                                  color: theme.secondaryText,
                                ),
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                key: ValueKey(_selectedLanguage ?? ''),
                                initialValue: _selectedLanguage ?? currentLang,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide:
                                        BorderSide(color: theme.accent4),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide:
                                        BorderSide(color: theme.accent4),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                        color: theme.primary, width: 1.5),
                                  ),
                                  filled: true,
                                  fillColor: theme.primaryBackground,
                                ),
                                dropdownColor: theme.secondaryBackground,
                                style: GoogleFonts.ubuntu(
                                  fontSize: 14,
                                  color: theme.primaryText,
                                ),
                                items: languages
                                    .map(
                                      (lang) => DropdownMenuItem<String>(
                                        value: lang['code'],
                                        child: Text(
                                          '${lang['flag']}  ${lang['label']}',
                                          style: GoogleFonts.ubuntu(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: _isSaving
                                    ? null
                                    : (String? newLang) {
                                        if (newLang == null) return;
                                        safeSetState(
                                          () => _selectedLanguage = newLang,
                                        );
                                      },
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
              color: iconColor.withValues(alpha: 0.12),
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
