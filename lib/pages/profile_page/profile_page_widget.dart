import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_choice_chips.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/flutter_flow/upload_data.dart';
import 'dart:ui';
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'profile_page_model.dart';
export 'profile_page_model.dart';

class ProfilePageWidget extends StatefulWidget {
  const ProfilePageWidget({super.key});

  static String routeName = 'ProfilePage';
  static String routePath = '/profilePage';

  @override
  State<ProfilePageWidget> createState() => _ProfilePageWidgetState();
}

class _ProfilePageWidgetState extends State<ProfilePageWidget> {
  late ProfilePageModel _model;
  int _photoVersion = 0;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ProfilePageModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      await authManager.refreshUser();
      if (currentUserEmailVerified) {
        return;
      }

      context.goNamed(
        EmailVerifyPageWidget.routeName,
        extra: <String, dynamic>{
          '__transition_info__': const TransitionInfo(
            hasTransition: true,
            transitionType: PageTransitionType.fade,
            duration: Duration(milliseconds: 150),
          ),
        },
      );

      await authManager.sendEmailVerification();
      return;
    });

    _model.profileTitleFieldTextController ??= TextEditingController(
        text: valueOrDefault(currentUserDocument?.title, ''));
    _model.profileTitleFieldFocusNode ??= FocusNode();

    _model.profileShortDescriptionFieldTextController ??= TextEditingController(
        text: valueOrDefault(currentUserDocument?.shortDescription, ''));
    _model.profileShortDescriptionFieldFocusNode ??= FocusNode();

    _model.profilePhoneNumberFieldTextController ??=
        TextEditingController(text: currentPhoneNumber);
    _model.profilePhoneNumberFieldFocusNode ??= FocusNode();

    _model.profilePhoneNumberFieldMask =
        MaskTextInputFormatter(mask: '+973 #### ####');
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  Future<void> _uploadProfilePhoto() async {
    final selectedMedia = await selectMediaWithSourceBottomSheet(
      context: context,
      maxWidth: 512.00,
      maxHeight: 512.00,
      imageQuality: 85,
      allowPhoto: true,
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      textColor: FlutterFlowTheme.of(context).primaryText,
      pickerFontFamily: 'Ubuntu',
    );
    if (selectedMedia == null || selectedMedia.isEmpty) return;
    final media = selectedMedia.first;
    if (media.bytes.isEmpty) return;

    safeSetState(() => _model.isDataUploading_profileImage = true);

    ApiCallResponse? uploadResult;
    try {
      uploadResult = await UploadImageCloudinaryCall.call(
        file: FFUploadedFile(
          name: media.originalFilename.isNotEmpty
              ? media.originalFilename
              : 'profile.jpg',
          bytes: media.bytes,
          height: media.dimensions?.height,
          width: media.dimensions?.width,
          blurHash: media.blurHash,
          originalFilename: media.originalFilename,
        ),
        uploadPreset: 'aman_build',
        publicId: functions.uploadImageCloudinaryUserId(currentUserUid),
      );
    } catch (e) {
      safeSetState(() => _model.isDataUploading_profileImage = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text('Upload error: $e',
                style: GoogleFonts.ubuntu(
                    color: FlutterFlowTheme.of(context).error)),
          ));
      }
      return;
    }

    safeSetState(() => _model.isDataUploading_profileImage = false);

    debugPrint('=== CLOUDINARY UPLOAD DEBUG ===');
    debugPrint('Status: ${uploadResult?.statusCode}');
    debugPrint('Succeeded: ${uploadResult?.succeeded}');
    debugPrint('Body: ${uploadResult?.jsonBody}');
    debugPrint('==============================');

    if (!(uploadResult?.succeeded ?? false)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(
              'Upload failed (${uploadResult?.statusCode}): ${uploadResult?.jsonBody}',
              style: GoogleFonts.ubuntu(
                  color: FlutterFlowTheme.of(context).error),
            ),
            duration: const Duration(seconds: 8),
          ));
      }
      return;
    }

    final secureUrl =
        getJsonField(uploadResult!.jsonBody, r'''$.secure_url''')
                ?.toString() ??
            '';
    final cloudinaryVersion =
        getJsonField(uploadResult.jsonBody, r'''$.version''')?.toString() ??
            DateTime.now().millisecondsSinceEpoch.toString();

    if (secureUrl.isEmpty) return;

    try {
      await currentUserReference!
          .update(createUsersRecordData(photoUrl: secureUrl));
      if (context.mounted) {
        PaintingBinding.instance.imageCache.clear();
        safeSetState(() {
          _photoVersion =
              int.tryParse(cloudinaryVersion) ?? (_photoVersion + 1);
        });
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content:
                Text('Profile photo updated!', style: GoogleFonts.ubuntu()),
            backgroundColor: const Color(0xFF4CAF50),
            duration: const Duration(seconds: 2),
          ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text('Could not save photo: $e',
                style: GoogleFonts.ubuntu(
                    color: FlutterFlowTheme.of(context).error)),
          ));
      }
    }
  }

  Widget _sectionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, 2))
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: FlutterFlowTheme.of(context).primary, size: 20),
            const SizedBox(width: 8),
            Text(title,
                style: GoogleFonts.ubuntu(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: FlutterFlowTheme.of(context).primaryText)),
          ]),
          const SizedBox(height: 10),
          Divider(height: 1, color: FlutterFlowTheme.of(context).accent4),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              color: FlutterFlowTheme.of(context).secondaryText, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.ubuntu(
                        fontSize: 12,
                        color: FlutterFlowTheme.of(context).secondaryText)),
                const SizedBox(height: 2),
                Text(value,
                    style: GoogleFonts.ubuntu(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: FlutterFlowTheme.of(context).primaryText)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(label,
                      style: GoogleFonts.ubuntu(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color:
                              FlutterFlowTheme.of(context).primaryText)),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: FlutterFlowTheme.of(context).secondaryText,
                    size: 20),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(height: 1, color: FlutterFlowTheme.of(context).accent4),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: PopScope(
        canPop: false,
        child: Scaffold(
          key: scaffoldKey,
          backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
          body: (!loggedIn || currentUserDocument == null)
              ? const SizedBox.shrink()
              : SafeArea(
            top: true,
            child: SingleChildScrollView(
              controller: _model.columnController,
              child: Column(
                children: [
                  // â”€â”€ HERO HEADER â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
                      child: Column(
                        children: [
                          // Avatar with camera badge + loading overlay
                          AuthUserStreamWidget(
                            builder: (context) => GestureDetector(
                              onTap: _uploadProfilePhoto,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 110,
                                    height: 110,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 3),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x33000000),
                                          blurRadius: 16,
                                          offset: Offset(0, 4),
                                        )
                                      ],
                                      image: DecorationImage(
                                        fit: BoxFit.cover,
                                        image: NetworkImage(
                                          currentUserPhoto.isNotEmpty
                                              ? '${currentUserPhoto}?v=$_photoVersion'
                                              : 'https://storage.googleapis.com/flutterflow-io-6f20.appspot.com/projects/aman-build-0tehsj/assets/qvuky4xvjia3/user.png',
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (_model.isDataUploading_profileImage)
                                    Container(
                                      width: 110,
                                      height: 110,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.black.withOpacity(0.45),
                                      ),
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5),
                                      ),
                                    ),
                                  Positioned(
                                    bottom: 2,
                                    right: 2,
                                    child: Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                              color: Color(0x33000000),
                                              blurRadius: 6)
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.camera_alt_rounded,
                                        size: 15,
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          // Name + copy
                          AuthUserStreamWidget(
                            builder: (context) => Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    valueOrDefault(
                                        currentUserDocument?.fullName, ''),
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.ubuntu(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () => Clipboard.setData(ClipboardData(
                                      text: valueOrDefault(
                                          currentUserDocument?.fullName, ''))),
                                  child: const Icon(Icons.copy_rounded,
                                      color: Colors.white60, size: 17),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Role badge pill
                          AuthUserStreamWidget(
                            builder: (context) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white30),
                              ),
                              child: Text(
                                valueOrDefault(
                                            currentUserDocument?.role, '') ==
                                        'client'
                                    ? 'Client'
                                    : 'Service Provider',
                                style: GoogleFonts.ubuntu(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Email + copy
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.email_outlined,
                                  color: Colors.white60, size: 15),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(currentUserEmail,
                                    style: GoogleFonts.ubuntu(
                                        color: Colors.white70,
                                        fontSize: 14)),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => Clipboard.setData(
                                    ClipboardData(text: currentUserEmail)),
                                child: const Icon(Icons.copy_rounded,
                                    color: Colors.white54, size: 15),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // Member since
                          AuthUserStreamWidget(
                            builder: (context) => Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.calendar_today_rounded,
                                    color: Colors.white54, size: 13),
                                const SizedBox(width: 6),
                                Text(
                                  'Member since ${currentUserDocument?.createdTime != null ? dateTimeFormat("yMMMd", currentUserDocument!.createdTime!, locale: FFLocalizations.of(context).languageCode) : ''}',
                                  style: GoogleFonts.ubuntu(
                                      color: Colors.white54, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // â”€â”€ BODY CONTENT â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                    child: Column(
                      children: [
                        // About / Professional Info card
                        AuthUserStreamWidget(
                          builder: (context) {
                            final isProvider = valueOrDefault(
                                    currentUserDocument?.role, '') ==
                                'service_provider';
                            final title = valueOrDefault(
                                currentUserDocument?.title, '');
                            final desc = valueOrDefault(
                                currentUserDocument?.shortDescription, '');
                            return _sectionCard(
                              context: context,
                              title: isProvider
                                  ? 'Professional Info'
                                  : 'About You',
                              icon: isProvider
                                  ? Icons.work_rounded
                                  : Icons.person_rounded,
                              children: [
                                if (isProvider && title.isNotEmpty)
                                  _infoRow(
                                    context: context,
                                    icon: Icons.title_rounded,
                                    label: 'Title',
                                    value: title,
                                  ),
                                if (desc.isNotEmpty)
                                  _infoRow(
                                    context: context,
                                    icon: Icons.description_rounded,
                                    label: 'About',
                                    value: desc,
                                  ),
                                if (desc.isEmpty && !isProvider)
                                  Text('No description yet.',
                                      style: GoogleFonts.ubuntu(
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryText,
                                          fontSize: 14)),
                                if (isProvider) ...[
                                  const SizedBox(height: 4),
                                  FlutterFlowChoiceChips(
                                    options: const [
                                      ChipData('Contractor And Handymen',
                                          Icons.handyman_rounded),
                                      ChipData(
                                          'Plumber', Icons.plumbing_rounded),
                                      ChipData('Electrician',
                                          Icons.electrical_services_rounded),
                                      ChipData('Heating',
                                          Icons.local_fire_department_rounded),
                                      ChipData('Air Conditioning',
                                          Icons.ac_unit_rounded),
                                      ChipData(
                                          'Locksmith', Icons.vpn_key_rounded),
                                      ChipData('Painter',
                                          Icons.format_paint_rounded),
                                      ChipData(
                                          'Tree Services', Icons.park_rounded),
                                      ChipData('Mover',
                                          Icons.local_shipping_rounded),
                                    ],
                                    onChanged: (val) async {
                                      safeSetState(() =>
                                          _model.profileCategoriesValues =
                                              val);
                                      await currentUserReference!.update({
                                        ...mapToFirestore({
                                          'categories': _model
                                              .profileCategoriesValues,
                                        }),
                                      });
                                    },
                                    selectedChipStyle: ChipStyle(
                                      backgroundColor:
                                          FlutterFlowTheme.of(context).primary,
                                      textStyle: GoogleFonts.ubuntu(
                                          color: Colors.white, fontSize: 14),
                                      iconColor:
                                          FlutterFlowTheme.of(context).accent3,
                                      iconSize: 20.0,
                                      elevation: 2.0,
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    unselectedChipStyle: ChipStyle(
                                      backgroundColor:
                                          FlutterFlowTheme.of(context)
                                              .primaryBackground,
                                      textStyle: GoogleFonts.ubuntu(
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryText,
                                          fontSize: 14),
                                      iconColor:
                                          FlutterFlowTheme.of(context).accent3,
                                      iconSize: 20.0,
                                      elevation: 0.0,
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    chipSpacing: 8.0,
                                    rowSpacing: 8.0,
                                    multiselect: true,
                                    initialized:
                                        _model.profileCategoriesValues != null,
                                    alignment: WrapAlignment.start,
                                    controller: _model
                                            .profileCategoriesValueController ??=
                                        FormFieldController<List<String>>(
                                      (currentUserDocument?.categories
                                              .toList() ??
                                          []),
                                    ),
                                    wrapped: true,
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        // Contact card
                        _sectionCard(
                          context: context,
                          title: 'Contact',
                          icon: Icons.contacts_rounded,
                          children: [
                            _infoRow(
                              context: context,
                              icon: Icons.phone_rounded,
                              label: 'Phone',
                              value: currentPhoneNumber.isNotEmpty
                                  ? currentPhoneNumber
                                  : 'Not provided',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Language preference card
                        AuthUserStreamWidget(
                          builder: (context) {
                            const languages = [
                              {'code': '', 'label': 'No Translation', 'flag': '🌐'},
                              {'code': 'ar', 'label': 'Arabic', 'flag': '🇸🇦'},
                              {'code': 'en', 'label': 'English', 'flag': '🇬🇧'},
                              {'code': 'fr', 'label': 'French', 'flag': '🇫🇷'},
                              {'code': 'hi', 'label': 'Hindi', 'flag': '🇮🇳'},
                              {'code': 'ur', 'label': 'Urdu', 'flag': '🇵🇰'},
                              {'code': 'tl', 'label': 'Tagalog', 'flag': '🇵🇭'},
                              {'code': 'es', 'label': 'Spanish', 'flag': '🇪🇸'},
                            ];
                            final currentLang = valueOrDefault(
                                currentUserDocument?.preferredLanguage, '');
                            return _sectionCard(
                              context: context,
                              title: 'Chat Translation Language',
                              icon: Icons.translate_rounded,
                              children: [
                                Text(
                                  'Messages sent to you will be automatically translated into your chosen language.',
                                  style: GoogleFonts.ubuntu(
                                    fontSize: 12,
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  value: currentLang,
                                  decoration: InputDecoration(
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 10),
                                    border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                          color: FlutterFlowTheme.of(context)
                                              .accent4),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                          color: FlutterFlowTheme.of(context)
                                              .accent4),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                          color: FlutterFlowTheme.of(context)
                                              .primary,
                                          width: 1.5),
                                    ),
                                    filled: true,
                                    fillColor: FlutterFlowTheme.of(context)
                                        .primaryBackground,
                                  ),
                                  dropdownColor: FlutterFlowTheme.of(context)
                                      .secondaryBackground,
                                  style: GoogleFonts.ubuntu(
                                    fontSize: 14,
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                  ),
                                  items: languages
                                      .map((lang) =>
                                          DropdownMenuItem<String>(
                                            value: lang['code'],
                                            child: Text(
                                              '${lang['flag']}  ${lang['label']}',
                                              style: GoogleFonts.ubuntu(
                                                  fontSize: 14),
                                            ),
                                          ))
                                      .toList(),
                                  onChanged: (String? newLang) async {
                                    if (newLang == null) return;
                                    await currentUserReference!.update({
                                      'preferred_language': newLang,
                                    });
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                        ..hideCurrentSnackBar()
                                        ..showSnackBar(SnackBar(
                                          content: Text(
                                            newLang.isEmpty
                                                ? 'Translation disabled.'
                                                : 'Translation language saved.',
                                            style: GoogleFonts.ubuntu(),
                                          ),
                                          backgroundColor:
                                              const Color(0xFF4CAF50),
                                          duration:
                                              const Duration(seconds: 2),
                                        ));
                                    }
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        // Menu card
                        Container(
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context)
                                .secondaryBackground,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                  color: Color(0x0D000000),
                                  blurRadius: 10,
                                  offset: Offset(0, 2))
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Column(
                            children: [
                              _menuTile(
                                context: context,
                                icon: Icons.person_rounded,
                                label: 'Edit Profile',
                                color: FlutterFlowTheme.of(context).primary,
                                onTap: () => context.pushNamed(
                                  EditprofileWidget.routeName,
                                ),
                              ),
                              _menuTile(
                                context: context,
                                icon: Icons.settings_rounded,
                                label: 'Settings',
                                color: FlutterFlowTheme.of(context).primary,
                                onTap: () => context.pushNamed(
                                  SettingWidget.routeName,
                                  extra: <String, dynamic>{
                                    '__transition_info__':
                                        const TransitionInfo(
                                      hasTransition: true,
                                      transitionType: PageTransitionType.fade,
                                      duration: Duration(milliseconds: 150),
                                    ),
                                  },
                                ),
                              ),
                              _menuTile(
                                context: context,
                                icon: Icons.help_rounded,
                                label: 'Help & Support',
                                color: FlutterFlowTheme.of(context).primary,
                                showDivider: false,
                                onTap: () => context.pushNamed(
                                  HelpSupportWidget.routeName,
                                  extra: <String, dynamic>{
                                    '__transition_info__':
                                        const TransitionInfo(
                                      hasTransition: true,
                                      transitionType: PageTransitionType.fade,
                                      duration: Duration(milliseconds: 150),
                                    ),
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Sign Out
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final router = GoRouter.of(context);
                              router.prepareAuthEvent();
                              await authManager.signOut();
                              router.clearRedirectLocation();

                              if (context.mounted) {
                                context.goNamedAuth(
                                  SignInPageWidget.routeName,
                                  context.mounted,
                                  extra: <String, dynamic>{
                                    '__transition_info__':
                                        const TransitionInfo(
                                      hasTransition: true,
                                      transitionType: PageTransitionType.fade,
                                      duration: Duration(milliseconds: 150),
                                    ),
                                  },
                                );
                              }
                            },
                            icon: const Icon(Icons.logout_rounded),
                            label: Text('Sign Out',
                                style: GoogleFonts.ubuntu(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor:
                                  FlutterFlowTheme.of(context).tertiary,
                              side: BorderSide(
                                  color:
                                      FlutterFlowTheme.of(context).tertiary,
                                  width: 1.5),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Delete Account
                        TextButton.icon(
                          onPressed: () =>
                              print('ProfileDeleteAccountButton pressed ...'),
                          icon: Icon(Icons.delete_forever_rounded,
                              color: FlutterFlowTheme.of(context).error,
                              size: 18),
                          label: Text(
                            'Delete My Account',
                            style: GoogleFonts.ubuntu(
                              color: FlutterFlowTheme.of(context).error,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
