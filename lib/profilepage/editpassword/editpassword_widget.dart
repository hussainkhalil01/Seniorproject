import '/auth/firebase_auth/auth_util.dart';
import '/components/delete_account_confirm_dialog_widget.dart';
import '/components/sign_out_confirm_dialog_widget.dart';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'editpassword_model.dart';
export 'editpassword_model.dart';

class EditpasswordWidget extends StatefulWidget {
  const EditpasswordWidget({super.key});

  static String routeName = 'editpassword';
  static String routePath = '/editpassword';

  @override
  State<EditpasswordWidget> createState() => _EditpasswordWidgetState();
}

class _EditpasswordWidgetState extends State<EditpasswordWidget> {
  late EditpasswordModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  String? _emailError;
  String? _currentPasswordError;
  String? _newPasswordError;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EditpasswordModel());
    _model.emailController ??=
        TextEditingController(text: currentUserEmail);
    _model.emailFocusNode ??= FocusNode();
    _model.initialEmail ??= currentUserEmail;
    _model.currentPasswordController ??= TextEditingController();
    _model.currentPasswordFocusNode ??= FocusNode();
    _model.newPasswordController ??= TextEditingController();
    _model.newPasswordFocusNode ??= FocusNode();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    // Clear previous inline errors
    safeSetState(() {
      _emailError = null;
      _currentPasswordError = null;
      _newPasswordError = null;
    });

    final newEmail =
        _model.emailController!.text.trim().toLowerCase().replaceAll(' ', '');
    final currentPwd = _model.currentPasswordController!.text.trim();
    final newPwd = _model.newPasswordController!.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    final theme = FlutterFlowTheme.of(context);
    final emailChanged = newEmail != _model.initialEmail;
    final passwordChange = newPwd.isNotEmpty;

    void showSnackError(String msg) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text(msg,
              style: GoogleFonts.ubuntu(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600),
              textAlign: TextAlign.center),
          duration: const Duration(milliseconds: 4000),
          backgroundColor: theme.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
    }

    // Email validation
    if (emailChanged) {
      if (newEmail.isEmpty) {
        safeSetState(() => _emailError = 'Please enter your email address');
        return;
      }
      if (!RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$')
          .hasMatch(newEmail)) {
        safeSetState(() => _emailError = 'Please enter a valid email address');
        return;
      }
    }

    // Password validation
    if (passwordChange) {
      if (newPwd.length < 8) {
        safeSetState(
            () => _newPasswordError = 'New password must be at least 8 characters');
        return;
      }
      if (!RegExp(r'^[A-Za-z0-9!@#$%^&*]{8,256}$').hasMatch(newPwd)) {
        safeSetState(
            () => _newPasswordError = 'Only A-Z, a-z, 0-9, !@#\$%^&* allowed');
        return;
      }
      if (!RegExp(r'[a-z]').hasMatch(newPwd)) {
        safeSetState(
            () => _newPasswordError = 'Password must include a lowercase letter');
        return;
      }
      if (!RegExp(r'[A-Z]').hasMatch(newPwd)) {
        safeSetState(
            () => _newPasswordError = 'Password must include an uppercase letter');
        return;
      }
      if (!RegExp(r'[0-9]').hasMatch(newPwd)) {
        safeSetState(() => _newPasswordError = 'Password must include a number');
        return;
      }
      if (!RegExp(r'[!@#$%^&*]').hasMatch(newPwd)) {
        safeSetState(
            () => _newPasswordError = 'Password must include a symbol (!@#\$%^&*)');
        return;
      }
    }

    // Current password required for any change
    if (currentPwd.isEmpty) {
      safeSetState(() => _currentPasswordError =
          'Please enter your current password to save changes');
      return;
    }

    safeSetState(() => _model.isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPwd,
      );
      await user.reauthenticateWithCredential(credential);

      if (emailChanged) {
        await user.verifyBeforeUpdateEmail(newEmail);
        await currentUserReference!.update({'email': newEmail});
      }
      if (passwordChange) {
        await user.updatePassword(newPwd);
      }

      _model.currentPasswordController!.clear();
      _model.newPasswordController!.clear();

      final successMsg = emailChanged && passwordChange
          ? 'Password updated. Verify your new email to complete the email change'
          : emailChanged
              ? 'A verification link has been sent to $newEmail'
              : 'Password updated successfully';

      if (mounted) {
        messenger
          ..clearSnackBars()
          ..showSnackBar(SnackBar(
            content: Text(successMsg,
                style: GoogleFonts.ubuntu(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
            duration: const Duration(milliseconds: 5000),
            backgroundColor: theme.success,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ));
      }
    } on FirebaseAuthException catch (ex) {
      if (!mounted) return;
      switch (ex.code) {
        case 'wrong-password':
        case 'invalid-credential':
          safeSetState(
              () => _currentPasswordError = 'Current password is incorrect');
          break;
        case 'email-already-in-use':
          safeSetState(() => _emailError = 'This email is already in use');
          break;
        case 'weak-password':
          safeSetState(() => _newPasswordError = 'New password is too weak');
          break;
        case 'too-many-requests':
          showSnackError('Too many attempts. Please try again later');
          break;
        case 'network-request-failed':
          showSnackError('Network error. Please check your connection');
          break;
        default:
          showSnackError('Something went wrong. Please try again');
      }
    } finally {
      safeSetState(() => _model.isSaving = false);
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
          BoxShadow(
              color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, 2))
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon,
                color: FlutterFlowTheme.of(context).secondary, size: 22),
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

  InputDecoration _fieldDecoration({
    required BuildContext context,
    required String label,
    required IconData icon,
    Widget? suffixIcon,
    bool readOnly = false,
    String? errorText,
  }) {
    return InputDecoration(
      labelText: label,
      errorText: errorText,
      labelStyle: GoogleFonts.ubuntu(
          color: FlutterFlowTheme.of(context).secondaryText, fontSize: 14),
      prefixIcon:
          Icon(icon, color: FlutterFlowTheme.of(context).secondary, size: 22),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: FlutterFlowTheme.of(context).primaryBackground,
      counterText: '',
      errorStyle: GoogleFonts.ubuntu(
          color: FlutterFlowTheme.of(context).error, fontSize: 12),
      errorMaxLines: 3,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
            color: readOnly
                ? FlutterFlowTheme.of(context).accent4.withValues(alpha: 0.5)
                : FlutterFlowTheme.of(context).accent4,
            width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(
            color: FlutterFlowTheme.of(context).primary, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(
            color: FlutterFlowTheme.of(context).error, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: BorderSide(
            color: FlutterFlowTheme.of(context).error, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
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
        canPop: !_model.isSaving,
        child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: Column(
          children: [
            // ── Gradient header ──────────────────────────────────
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
                      // Back button
                      Opacity(
                        opacity: _model.isSaving ? 0.4 : 1.0,
                        child: Material(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: _model.isSaving ? null : () => context.pop(),
                            child: const Padding(
                              padding: EdgeInsets.all(8),
                              child: Icon(Icons.arrow_back_rounded,
                                  color: Colors.white, size: 22),
                            ),
                          ),
                        ),
                      ),
                      // Title
                      Expanded(
                        child: Text(
                          'Edit Account',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.ubuntu(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                      ),
                      // Save button / spinner
                      _model.isSaving
                          ? const SizedBox(
                              width: 40,
                              height: 40,
                              child: Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white),
                                ),
                              ),
                            )
                          : Opacity(
                              opacity: _model.hasChanges ? 1.0 : 0.4,
                              child: Material(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: _model.hasChanges ? _save : null,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    child: Text('Save',
                                        style: GoogleFonts.ubuntu(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                            color: Colors.white)),
                                  ),
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Scrollable content ───────────────────────────────
            Expanded(
              child: AbsorbPointer(
              absorbing: _model.isSaving,
              child: Opacity(
              opacity: _model.isSaving ? 0.5 : 1.0,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                child: Column(
                  children: [
                    // Account Information
                    _sectionCard(
                      context: context,
                      title: 'Account Information',
                      icon: Icons.manage_accounts_rounded,
                      children: [
                        // Email
                        TextFormField(
                          controller: _model.emailController,
                          focusNode: _model.emailFocusNode,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          maxLength: 254,
                          maxLengthEnforcement:
                              MaxLengthEnforcement.enforced,
                          onChanged: (_) => safeSetState(() {
                            _emailError = null;
                          }),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[a-zA-Z0-9@._+\-]')),
                          ],
                          style: GoogleFonts.ubuntu(
                              fontSize: 15,
                              color:
                                  FlutterFlowTheme.of(context).primaryText),
                          decoration: _fieldDecoration(
                            context: context,
                            label: 'Email Address',
                            icon: Icons.email_rounded,
                            errorText: _emailError,
                          ),
                          cursorColor: FlutterFlowTheme.of(context).primary,
                        ),
                        const SizedBox(height: 12),
                        // Current Password
                        TextFormField(
                          controller: _model.currentPasswordController,
                          focusNode: _model.currentPasswordFocusNode,
                          obscureText: !_model.currentPasswordVisible,
                          onChanged: (_) => safeSetState(() {
                            _currentPasswordError = null;
                          }),
                          textInputAction: TextInputAction.next,
                          style: GoogleFonts.ubuntu(
                              fontSize: 15,
                              color:
                                  FlutterFlowTheme.of(context).primaryText),
                          decoration: _fieldDecoration(
                            context: context,
                            label: 'Current Password',
                            icon: Icons.lock_outline_rounded,
                            errorText: _currentPasswordError,
                            suffixIcon: InkWell(
                              onTap: () => safeSetState(() =>
                                  _model.currentPasswordVisible =
                                      !_model.currentPasswordVisible),
                              focusNode: FocusNode(skipTraversal: true),
                              child: Icon(
                                _model.currentPasswordVisible
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: FlutterFlowTheme.of(context)
                                    .secondary,
                                size: 20,
                              ),
                            ),
                          ),
                          cursorColor: FlutterFlowTheme.of(context).primary,
                        ),
                        const SizedBox(height: 12),
                        // New Password
                        TextFormField(
                          controller: _model.newPasswordController,
                          focusNode: _model.newPasswordFocusNode,
                          obscureText: !_model.newPasswordVisible,
                          onChanged: (_) => safeSetState(() {
                            _newPasswordError = null;
                          }),
                          textInputAction: TextInputAction.done,
                          style: GoogleFonts.ubuntu(
                              fontSize: 15,
                              color:
                                  FlutterFlowTheme.of(context).primaryText),
                          decoration: _fieldDecoration(
                            context: context,
                            label: 'New Password',
                            icon: Icons.lock_reset_rounded,
                            errorText: _newPasswordError,
                            suffixIcon: InkWell(
                              onTap: () => safeSetState(() =>
                                  _model.newPasswordVisible =
                                      !_model.newPasswordVisible),
                              focusNode: FocusNode(skipTraversal: true),
                              child: Icon(
                                _model.newPasswordVisible
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: FlutterFlowTheme.of(context)
                                    .secondary,
                                size: 20,
                              ),
                            ),
                          ),
                          cursorColor: FlutterFlowTheme.of(context).primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Account Actions
                    _sectionCard(
                      context: context,
                      title: 'Account Actions',
                      icon: Icons.settings_rounded,
                      children: [
                        // Sign Out
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final router = GoRouter.of(context);
                              final confirmed = await showDialog<bool>(
                                barrierColor: Colors.transparent,
                                barrierDismissible: false,
                                context: context,
                                builder: (dialogContext) => GestureDetector(
                                  onTap: () {
                                    FocusScope.of(dialogContext).unfocus();
                                    FocusManager.instance.primaryFocus
                                        ?.unfocus();
                                  },
                                  child: const SizedBox(
                                    width: double.infinity,
                                    child: SignOutConfirmDialogWidget(),
                                  ),
                                ),
                              );
                              if (confirmed != true) return;
                              await authManager.signOut();
                              router.clearRedirectLocation();
                              if (mounted) {
                                router.goNamed(
                                  SignInPageWidget.routeName,
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
                            icon: const Icon(Icons.logout_rounded, size: 22),
                            label: Text('Sign Out',
                                style: GoogleFonts.ubuntu(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  FlutterFlowTheme.of(context).tertiary,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Delete My Account
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final router = GoRouter.of(context);
                              final confirmed = await showDialog<bool>(
                                barrierColor: Colors.transparent,
                                barrierDismissible: false,
                                context: context,
                                builder: (dialogContext) => GestureDetector(
                                  onTap: () {
                                    FocusScope.of(dialogContext).unfocus();
                                    FocusManager.instance.primaryFocus
                                        ?.unfocus();
                                  },
                                  child: const SizedBox(
                                    width: double.infinity,
                                    child: DeleteAccountConfirmDialogWidget(),
                                  ),
                                ),
                              );
                              if (confirmed != true) return;
                              final result = await actions.deleteAccount();
                              if (result == 'success') {
                                await authManager.signOut();
                                router.clearRedirectLocation();
                                if (mounted) {
                                  router.goNamed(
                                    SignInPageWidget.routeName,
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
                                }
                                return;
                              }
                              if (context.mounted) {
                                ScaffoldMessenger.of(context)
                                  ..clearSnackBars()
                                  ..showSnackBar(SnackBar(
                                    content: Text(result,
                                        style: GoogleFonts.ubuntu(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600),
                                        textAlign: TextAlign.center),
                                    duration:
                                        const Duration(milliseconds: 4000),
                                    backgroundColor:
                                        FlutterFlowTheme.of(context).error,
                                    behavior: SnackBarBehavior.floating,
                                    margin: const EdgeInsets.fromLTRB(
                                        16, 0, 16, 80),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ));
                              }
                            },
                            icon: const Icon(Icons.delete_forever_rounded,
                                size: 22),
                            label: Text('Delete My Account',
                                style: GoogleFonts.ubuntu(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  FlutterFlowTheme.of(context).error,
                              foregroundColor: Colors.white,
                              elevation: 2,
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
              ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
