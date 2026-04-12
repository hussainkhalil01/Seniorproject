import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/backend.dart';
import '/components/connectivity_wrapper.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
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
      if (currentUserEmailVerified ||
          currentUserDocument?.role == 'service_provider') {
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
    final messenger = ScaffoldMessenger.of(context);
    final theme = FlutterFlowTheme.of(context);

    final selectedMedia = await selectMediaWithSourceBottomSheet(
      context: context,
      maxWidth: 512.00,
      maxHeight: 512.00,
      imageQuality: 85,
      allowPhoto: true,
      backgroundColor: theme.primaryBackground,
      textColor: theme.primaryText,
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
    } catch (_) {
      safeSetState(() => _model.isDataUploading_profileImage = false);
      messenger.clearSnackBars();
      messenger.showSnackBar(_errorSnackBar(
        'Upload failed. Please check your connection and try again',
        theme,
      ));
      return;
    }

    safeSetState(() => _model.isDataUploading_profileImage = false);

    if (!uploadResult.succeeded) {
      messenger.clearSnackBars();
      messenger.showSnackBar(_errorSnackBar(
        'Upload failed. Please try again',
        theme,
      ));
      return;
    }

    final secureUrl =
        getJsonField(uploadResult.jsonBody, r'''$.secure_url''')
                ?.toString() ??
            '';
    final cloudinaryVersion =
        getJsonField(uploadResult.jsonBody, r'''$.version''')?.toString() ??
            DateTime.now().millisecondsSinceEpoch.toString();

    if (secureUrl.isEmpty) {
      messenger.clearSnackBars();
      messenger.showSnackBar(_errorSnackBar(
        'Upload failed. Please try again',
        theme,
      ));
      return;
    }

    try {
      await currentUserReference!
          .update(createUsersRecordData(photoUrl: secureUrl));
      PaintingBinding.instance.imageCache.clear();
      safeSetState(() {
        _photoVersion =
            int.tryParse(cloudinaryVersion) ?? (_photoVersion + 1);
      });
      messenger.clearSnackBars();
      messenger.showSnackBar(_successSnackBar(
        'Profile photo updated successfully',
        theme,
      ));
    } catch (_) {
      messenger.clearSnackBars();
      messenger.showSnackBar(_errorSnackBar(
        'Photo uploaded but could not be saved. Please try again',
        theme,
      ));
    }
  }

  SnackBar _errorSnackBar(String message, FlutterFlowTheme theme) => SnackBar(
        content: Text(
          message,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );

  SnackBar _successSnackBar(String message, FlutterFlowTheme theme) => SnackBar(
        content: Text(
          message,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );

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
            Icon(icon, color: FlutterFlowTheme.of(context).secondary, size: 22),
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
    String? copyValue,
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
                Text(
                    value,
                    style: GoogleFonts.ubuntu(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: FlutterFlowTheme.of(context).primaryText)),
              ],
            ),
          ),
          if (copyValue != null && copyValue.isNotEmpty)
            GestureDetector(
              onTap: () => Clipboard.setData(ClipboardData(text: copyValue)),
              child: Icon(Icons.copy_rounded,
                  color: FlutterFlowTheme.of(context).secondaryText, size: 17),
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
                    color: FlutterFlowTheme.of(context).secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon,
                      color: FlutterFlowTheme.of(context).secondary,
                      size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(label,
                      style: GoogleFonts.ubuntu(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
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
          body: ConnectivityWrapper(
            child: (!loggedIn || currentUserDocument == null)
                ? const SizedBox.shrink()
                : SingleChildScrollView(
              controller: _model.columnController,
              child: Column(
                children: [
                  // HERO HEADER
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
                                              ? '$currentUserPhoto?v=$_photoVersion'
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
                                        color: Colors.black.withValues(alpha: 0.45),
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
                                color: Colors.white.withValues(alpha: 0.18),
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
                              const Icon(Icons.email_rounded,
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
                                  'Member since ${currentUserDocument?.createdTime != null ? dateTimeFormat("yMMMMd", currentUserDocument!.createdTime!, locale: FFLocalizations.of(context).languageCode) : ''}',
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
                  ),
                  // BODY CONTENT
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
                                  ? 'Professional Information'
                                  : 'About You',
                              icon: isProvider
                                  ? Icons.work_rounded
                                  : Icons.person_rounded,
                              children: [
                                if (isProvider && title.isNotEmpty)
                                  _infoRow(
                                    context: context,
                                    icon: Icons.title_rounded,
                                    label: 'Professional Title',
                                    value: title,
                                  ),
                                _infoRow(
                                  context: context,
                                  icon: Icons.description_rounded,
                                  label: 'About',
                                  value: (desc.isEmpty ||
                                          desc == 'No description yet')
                                      ? 'No description yet'
                                      : desc,
                                ),
                                if (isProvider) ...[
                                  const SizedBox(height: 4),
                                  // Categories row — same structure as _infoRow
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.category_rounded,
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryText,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Categories',
                                                style: GoogleFonts.ubuntu(
                                                  fontSize: 12,
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .secondaryText,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Builder(builder: (context) {
                                                const categoryIcons =
                                                    <String, IconData>{
                                                  'Contractors & Handymen':
                                                      Icons.handyman_rounded,
                                                  'Plumbers':
                                                      Icons.plumbing_rounded,
                                                  'Electricians':
                                                      Icons
                                                          .electrical_services_rounded,
                                                  'Heating':
                                                      Icons
                                                          .local_fire_department_rounded,
                                                  'Air Conditioning':
                                                      Icons.ac_unit_rounded,
                                                  'Locksmiths':
                                                      Icons.vpn_key_rounded,
                                                  'Painters':
                                                      Icons.format_paint_rounded,
                                                  'Tree Services':
                                                      Icons.park_rounded,
                                                  'Movers':
                                                      Icons.local_shipping_rounded,
                                                };
                                                final cats = currentUserDocument
                                                        ?.categories
                                                        .toList() ??
                                                    [];
                                                if (cats.isEmpty) {
                                                  return Text(
                                                    'No categories selected',
                                                    style: GoogleFonts.ubuntu(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .primaryText,
                                                    ),
                                                  );
                                                }
                                                return Wrap(
                                                  spacing: 8,
                                                  runSpacing: 8,
                                                  alignment: WrapAlignment.start,
                                                  children: cats
                                                      .map((cat) => Container(
                                                            padding: const EdgeInsets
                                                                .symmetric(
                                                                    horizontal:
                                                                        12,
                                                                    vertical: 6),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .primary,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8),
                                                            ),
                                                            child: Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                if (categoryIcons
                                                                    .containsKey(
                                                                        cat)) ...[
                                                                  Icon(
                                                                    categoryIcons[
                                                                        cat],
                                                                    size: 14,
                                                                    color: const Color(
                                                                        0xFFF4A026),
                                                                  ),
                                                                  const SizedBox(
                                                                      width: 5),
                                                                ],
                                                                Text(
                                                                  cat,
                                                                  style: GoogleFonts
                                                                      .ubuntu(
                                                                    color: Colors
                                                                        .white,
                                                                    fontSize: 13,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ))
                                                      .toList(),
                                                );
                                              }),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        // Contact card
                        AuthUserStreamWidget(
                          builder: (context) => _sectionCard(
                            context: context,
                            title: 'Contact',
                            icon: Icons.contacts_rounded,
                            children: [
                              _infoRow(
                                context: context,
                                icon: Icons.phone_rounded,
                                label: 'Phone Number',
                                value: currentPhoneNumber.isNotEmpty
                                    ? currentPhoneNumber
                                    : 'Not provided',
                                copyValue: currentPhoneNumber.isNotEmpty &&
                                        currentPhoneNumber != 'Not provided'
                                    ? currentPhoneNumber.replaceAll(' ', '')
                                    : null,
                              ),
                            ],
                          ),
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
                                label: 'Profile',
                                color: FlutterFlowTheme.of(context).primary,
                                onTap: () async {
                                  await context.pushNamed(
                                    EditprofileWidget.routeName,
                                    extra: <String, dynamic>{
                                      '__transition_info__':
                                          const TransitionInfo(
                                        hasTransition: true,
                                        transitionType:
                                            PageTransitionType.fade,
                                        duration: Duration(milliseconds: 150),
                                      ),
                                    },
                                  );
                                  await authManager.refreshUser();
                                  if (mounted) safeSetState(() {});
                                },
                              ),
                              _menuTile(
                                context: context,
                                icon: Icons.manage_accounts_rounded,
                                label: 'Account',
                                color: FlutterFlowTheme.of(context).primary,
                                onTap: () => context.pushNamed(
                                  EditpasswordWidget.routeName,
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
                              if (currentUserDocument?.role == 'admin')
                                _menuTile(
                                  context: context,
                                  icon: Icons.admin_panel_settings_rounded,
                                  label: 'Admin Dashboard',
                                  color: const Color(0xFF1F4F8B),
                                  onTap: () => context.pushNamed(
                                    AdminDashboardPage.routeName,
                                    extra: <String, dynamic>{
                                      '__transition_info__':
                                          const TransitionInfo(
                                        hasTransition: true,
                                        transitionType:
                                            PageTransitionType.rightToLeft,
                                        duration: Duration(milliseconds: 200),
                                      ),
                                    },
                                  ),
                                ),
                              _menuTile(
                                context: context,
                                icon: Icons.help_rounded,
                                label: 'Help & Support',
                                color: FlutterFlowTheme.of(context).primary,
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
                              _menuTile(
                                context: context,
                                icon: Icons.privacy_tip_rounded,
                                label: 'Privacy Policy',
                                color: FlutterFlowTheme.of(context).primary,
                                showDivider: false,
                                onTap: () => context.pushNamed(
                                  PrivacyPolicyWidget.routeName,
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

