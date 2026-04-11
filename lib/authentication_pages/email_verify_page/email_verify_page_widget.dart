import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'dart:ui';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'email_verify_page_model.dart';
export 'email_verify_page_model.dart';

class EmailVerifyPageWidget extends StatefulWidget {
  const EmailVerifyPageWidget({super.key});

  static String routeName = 'EmailVerifyPage';
  static String routePath = '/emailVerifyPage';

  @override
  State<EmailVerifyPageWidget> createState() => _EmailVerifyPageWidgetState();
}

class _EmailVerifyPageWidgetState extends State<EmailVerifyPageWidget> {
  late EmailVerifyPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EmailVerifyPageModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      await actions.emailVerifyStartCooldown();
    });

    _model.emailVerifyEmailFieldTextController ??=
        TextEditingController(text: currentUserEmail);
    _model.emailVerifyEmailFieldFocusNode ??= FocusNode();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

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
          body: SingleChildScrollView(
            controller: _model.columnController,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Gradient header
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
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16.0),
                            child: Image.asset(
                              'assets/images/trusted-contractors-marketplace-logo-tr.png',
                              width: 280.0,
                              height: 120.0,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Verify Your Email',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.ubuntu(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Check your inbox or Spam folder for the verification link',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.ubuntu(
                              color: Colors.white70,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Card
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                  child: Container(
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).secondaryBackground,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0D000000),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Read-only email field
                          SizedBox(
                            width: double.infinity,
                            child: TextFormField(
                              controller:
                                  _model.emailVerifyEmailFieldTextController,
                              focusNode: _model.emailVerifyEmailFieldFocusNode,
                              autofocus: false,
                              enabled: true,
                              readOnly: true,
                              obscureText: false,
                              decoration: InputDecoration(
                                labelText: 'Email Address',
                                labelStyle: GoogleFonts.ubuntu(
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryText,
                                  fontSize: 16.0,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color:
                                        FlutterFlowTheme.of(context).accent4,
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color:
                                        FlutterFlowTheme.of(context).primary,
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: FlutterFlowTheme.of(context).error,
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: FlutterFlowTheme.of(context).error,
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                filled: true,
                                fillColor: FlutterFlowTheme.of(context)
                                    .primaryBackground,
                                contentPadding:
                                    const EdgeInsetsDirectional.fromSTEB(
                                        16.0, 16.0, 16.0, 16.0),
                                prefixIcon: Icon(
                                  Icons.email_rounded,
                                  color:
                                      FlutterFlowTheme.of(context).secondary,
                                  size: 22.0,
                                ),
                              ),
                              style: GoogleFonts.ubuntu(
                                fontSize: 16.0,
                                color: FlutterFlowTheme.of(context).primaryText,
                              ),
                              maxLength: 254,
                              maxLengthEnforcement:
                                  MaxLengthEnforcement.enforced,
                              buildCounter: (context,
                                      {required currentLength,
                                      required isFocused,
                                      maxLength}) =>
                                  null,
                              keyboardType: TextInputType.emailAddress,
                              cursorColor:
                                  FlutterFlowTheme.of(context).primary,
                              enableInteractiveSelection: true,
                              validator: _model
                                  .emailVerifyEmailFieldTextControllerValidator
                                  .asValidator(context),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Resend Verification Link button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: (_model.isResendLoading ||
                                      FFAppState().emailVerifyCooldownActive)
                                  ? null
                                  : () async {
                                      final messenger =
                                          ScaffoldMessenger.of(context);
                                      final theme =
                                          FlutterFlowTheme.of(context);
                                      safeSetState(
                                          () => _model.isResendLoading = true);
                                      try {
                                        await authManager
                                            .sendEmailVerification();
                                        await actions
                                            .emailVerifyStartCooldown();
                                        messenger.clearSnackBars();
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Verification link sent. Please check your inbox or Spam folder',
                                              style: GoogleFonts.ubuntu(
                                                color: Colors.white,
                                                fontSize: 15.0,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            duration: const Duration(
                                                milliseconds: 4000),
                                            backgroundColor: theme.success,
                                            behavior:
                                                SnackBarBehavior.floating,
                                            margin: const EdgeInsets.fromLTRB(
                                                16, 0, 16, 80),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        );
                                      } catch (_) {
                                        messenger.clearSnackBars();
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Failed to send. Please try again',
                                              style: GoogleFonts.ubuntu(
                                                color: Colors.white,
                                                fontSize: 15.0,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            duration: const Duration(
                                                milliseconds: 4000),
                                            backgroundColor: theme.error,
                                            behavior:
                                                SnackBarBehavior.floating,
                                            margin: const EdgeInsets.fromLTRB(
                                                16, 0, 16, 80),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        );
                                      } finally {
                                        safeSetState(() =>
                                            _model.isResendLoading = false);
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    FlutterFlowTheme.of(context).primary,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    FlutterFlowTheme.of(context).accent4,
                                disabledForegroundColor: Colors.white70,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _model.isResendLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          FFAppState().emailVerifyCooldownActive
                                              ? Icons.timer_outlined
                                              : Icons.add_link_rounded,
                                          size: 22,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          FFAppState().emailVerifyCooldownActive
                                              ? functions.cooldownText(
                                                  FFAppState()
                                                      .emailVerifyCooldownSeconds)
                                              : 'Resend Verification Link',
                                          style: GoogleFonts.ubuntu(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Continue button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _model.isLoading ? null : () async {
                                final messenger =
                                    ScaffoldMessenger.of(context);
                                final theme = FlutterFlowTheme.of(context);
                                safeSetState(
                                    () => _model.isLoading = true);
                                _model.emailVerifyResult =
                                    await actions.emailVerifyContinue(context);
                                if (_model.emailVerifyResult == 'success') {
                                  return;
                                }
                                safeSetState(
                                    () => _model.isLoading = false);
                                messenger.clearSnackBars();
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      _model.emailVerifyResult!,
                                      style: GoogleFonts.ubuntu(
                                        color: Colors.white,
                                        fontSize: 15.0,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    duration:
                                        const Duration(milliseconds: 4000),
                                    backgroundColor: theme.error,
                                    behavior: SnackBarBehavior.floating,
                                    margin: const EdgeInsets.fromLTRB(
                                        16, 0, 16, 80),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    FlutterFlowTheme.of(context).secondary,
                                foregroundColor: Colors.white,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _model.isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 22),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Continue',
                                          style: GoogleFonts.ubuntu(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Back to Sign Up
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Wrong email?',
                                style: GoogleFonts.ubuntu(
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryText,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 4),
                              TextButton(
                                onPressed: () async {
                                  final router = GoRouter.of(context);
                                  router.prepareAuthEvent();
                                  await authManager.signOut();
                                  router.clearRedirectLocation();
                                  if (context.mounted) {
                                    context.goNamedAuth(
                                      SignUpPageWidget.routeName,
                                      context.mounted,
                                      extra: <String, dynamic>{
                                        '__transition_info__':
                                            const TransitionInfo(
                                          hasTransition: true,
                                          transitionType:
                                              PageTransitionType.fade,
                                          duration:
                                              Duration(milliseconds: 150),
                                        ),
                                      },
                                    );
                                  }
                                },
                                child: Text(
                                  'Back to Sign Up',
                                  style: GoogleFonts.ubuntu(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? FlutterFlowTheme.of(context).info
                                        : FlutterFlowTheme.of(context).primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
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

                // Footer
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Text(
                    '\u00a9 ${dateTimeFormat("y", getCurrentTimestamp, locale: FFLocalizations.of(context).languageCode)} Trusted Contractors Marketplace',
                    style: GoogleFonts.ubuntu(
                      color: FlutterFlowTheme.of(context).secondaryText,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
