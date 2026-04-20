import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import '/components/delete_account_confirm_dialog_widget.dart';
import '/components/sign_out_confirm_dialog_widget.dart';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/amanbuild/profile_pages/profile_section_card.dart';
import '/amanbuild/profile_pages/profile_field_decoration.dart';
import '/index.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'edit_account_page_model.dart';
export 'edit_account_page_model.dart';

class EditAccountWidget extends StatefulWidget {
  const EditAccountWidget({super.key});

  static String routeName = 'editAccountPage';
  static String routePath = '/editAccountPage';

  @override
  State<EditAccountWidget> createState() => _EditAccountWidgetState();
}

class _EditAccountWidgetState extends State<EditAccountWidget> {
  late EditAccountModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  String? _emailError;
  String? _currentPasswordError;
  String? _newPasswordError;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EditAccountModel());
    _model.emailController ??=
        TextEditingController(text: currentUserEmail);
    _model.emailFocusNode ??= FocusNode();
    _model.initialEmail ??= currentUserEmail.trim().toLowerCase();
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
    final router = GoRouter.of(context);
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

    if (emailChanged) {
      if (newEmail.isEmpty) {
        safeSetState(() => _emailError = 'Please enter your email address');
        return;
      }
      if (!functions.emailRegex.hasMatch(newEmail)) {
        safeSetState(() => _emailError = 'Please enter a valid email address');
        return;
      }
    }

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

    if (currentPwd.isEmpty) {
      safeSetState(() => _currentPasswordError =
          'Please enter your current password to save changes');
      return;
    }

    safeSetState(() => _model.isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        showSnackError('Something went wrong. Please try again');
        return;
      }
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPwd,
      );
      await user.reauthenticateWithCredential(credential);

      if (emailChanged) {
        await user.verifyBeforeUpdateEmail(newEmail);
        if (currentUserReference != null) {
          await currentUserReference!.update({'email': newEmail});
        }
      }
      if (passwordChange) {
        await user.updatePassword(newPwd);
      }

      _model.currentPasswordController!.clear();
      _model.newPasswordController!.clear();

      if (passwordChange) {
        await authManager.signOut();
        if (mounted) {
          router.clearRedirectLocation();
          router.goNamed(
            SignInPageWidget.routeName,
            extra: <String, dynamic>{
              '__transition_info__': const TransitionInfo(
                hasTransition: true,
                transitionType: PageTransitionType.fade,
                duration: Duration(milliseconds: 150),
              ),
            },
          );
        }
      } else {
        // Email-only change: verifyBeforeUpdateEmail keeps current session valid
        final successMsg = 'A verification link has been sent to $newEmail';
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
              duration: const Duration(milliseconds: 4000),
              backgroundColor: theme.success,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ));
          await authManager.refreshUser();
          if (mounted) context.pop();
        }
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
    } catch (_) {
      if (mounted) showSnackError('Something went wrong. Please try again');
    } finally {
      if (mounted) safeSetState(() => _model.isSaving = false);
    }
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
            Expanded(
              child: AbsorbPointer(
              absorbing: _model.isSaving,
              child: Opacity(
              opacity: _model.isSaving ? 0.5 : 1.0,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                child: Column(
                  children: [
                    ProfileSectionCard(
                      title: 'Account Information',
                      icon: Icons.manage_accounts_rounded,
                      children: [
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
                          decoration: profileFieldDecoration(
                            context: context,
                            label: 'Email Address',
                            icon: Icons.email_rounded,
                            errorText: _emailError,
                          ),
                          cursorColor: FlutterFlowTheme.of(context).primary,
                        ),
                        const SizedBox(height: 12),
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
                          decoration: profileFieldDecoration(
                            context: context,
                            label: 'Current Password',
                            icon: Icons.lock_outline_rounded,
                            errorText: _currentPasswordError,
                            suffixIcon: InkWell(
                              onTap: () => safeSetState(() =>
                                  _model.currentPasswordVisible =
                                      !_model.currentPasswordVisible),
                              focusNode: _model.currentPasswordVisibilityFocusNode,
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
                          decoration: profileFieldDecoration(
                            context: context,
                            label: 'New Password',
                            icon: Icons.lock_reset_rounded,
                            errorText: _newPasswordError,
                            suffixIcon: InkWell(
                              onTap: () => safeSetState(() =>
                                  _model.newPasswordVisible =
                                      !_model.newPasswordVisible),
                              focusNode: _model.newPasswordVisibilityFocusNode,
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
                    ProfileSectionCard(
                      title: 'Account Actions',
                      icon: Icons.settings_rounded,
                      children: [
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

