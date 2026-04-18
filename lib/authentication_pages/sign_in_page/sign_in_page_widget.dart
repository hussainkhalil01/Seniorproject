import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'dart:async';
import 'dart:ui';
import '/custom_code/actions/index.dart' as actions;
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'sign_in_page_model.dart';
export 'sign_in_page_model.dart';

class SignInPageWidget extends StatefulWidget {
  const SignInPageWidget({super.key});

  static String routeName = 'SignInPage';
  static String routePath = '/signInPage';

  @override
  State<SignInPageWidget> createState() => _SignInPageWidgetState();
}

class _SignInPageWidgetState extends State<SignInPageWidget> {
  late SignInPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  Timer? _lockoutTimer;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SignInPageModel());

    _model.signInEmailFieldTextController ??= TextEditingController();
    _model.signInEmailFieldFocusNode ??= FocusNode();

    _model.signInPasswordFieldTextController ??= TextEditingController();
    _model.signInPasswordFieldFocusNode ??= FocusNode();

    // Resume countdown if a lockout was already active before navigation
    if (_model.isLockedOut) _startLockoutTimer();
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    _model.dispose();
    super.dispose();
  }

  void _startLockoutTimer() {
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_model.isLockedOut) {
        _lockoutTimer?.cancel();
      }
      if (mounted) safeSetState(() {});
    });
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
                            'Welcome Back',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.ubuntu(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Login to Trusted Contractors Marketplace',
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

                // Form card
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          FlutterFlowTheme.of(context).secondaryBackground,
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
                      child: Form(
                        key: _model.formKey,
                        autovalidateMode: AutovalidateMode.disabled,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Email field
                            SizedBox(
                              width: double.infinity,
                              child: TextFormField(
                                controller:
                                    _model.signInEmailFieldTextController,
                                focusNode:
                                    _model.signInEmailFieldFocusNode,
                                autofocus: false,
                                enabled: true,
                                autofillHints: const [AutofillHints.email],
                                textInputAction: TextInputAction.next,
                                obscureText: false,
                                decoration: InputDecoration(
                                  labelText: 'Email Address',
                                  labelStyle: GoogleFonts.ubuntu(
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                    fontSize: 16.0,
                                  ),
                                  errorStyle: GoogleFonts.ubuntu(
                                    color:
                                        FlutterFlowTheme.of(context).error,
                                    fontSize: 14.0,
                                  ),
                                  errorMaxLines: 3,
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: FlutterFlowTheme.of(context)
                                          .accent4,
                                      width: 1.0,
                                    ),
                                    borderRadius:
                                        BorderRadius.circular(12.0),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: FlutterFlowTheme.of(context)
                                          .primary,
                                      width: 1.5,
                                    ),
                                    borderRadius:
                                        BorderRadius.circular(12.0),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: FlutterFlowTheme.of(context)
                                          .error,
                                      width: 1.0,
                                    ),
                                    borderRadius:
                                        BorderRadius.circular(12.0),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: FlutterFlowTheme.of(context)
                                          .error,
                                      width: 1.5,
                                    ),
                                    borderRadius:
                                        BorderRadius.circular(12.0),
                                  ),
                                  filled: true,
                                  fillColor: FlutterFlowTheme.of(context)
                                      .primaryBackground,
                                  contentPadding:
                                      const EdgeInsetsDirectional.fromSTEB(
                                          16.0, 16.0, 16.0, 16.0),
                                  prefixIcon: Icon(
                                    Icons.email_rounded,
                                    color: FlutterFlowTheme.of(context)
                                        .secondary,
                                    size: 22.0,
                                  ),
                                ),
                                style: GoogleFonts.ubuntu(
                                  fontSize: 16.0,
                                  color: FlutterFlowTheme.of(context)
                                      .primaryText,
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
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[a-zA-Z0-9@._+\-]')),
                                ],
                                validator: _model
                                    .signInEmailFieldTextControllerValidator
                                    .asValidator(context),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Password field
                            SizedBox(
                              width: double.infinity,
                              child: TextFormField(
                                controller: _model
                                    .signInPasswordFieldTextController,
                                focusNode:
                                    _model.signInPasswordFieldFocusNode,
                                autofocus: false,
                                enabled: true,
                                autofillHints: const [
                                  AutofillHints.password
                                ],
                                textInputAction: TextInputAction.done,
                                obscureText: !_model
                                    .signInPasswordFieldVisibility,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  labelStyle: GoogleFonts.ubuntu(
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                    fontSize: 16.0,
                                  ),
                                  alignLabelWithHint: false,
                                  errorStyle: GoogleFonts.ubuntu(
                                    color:
                                        FlutterFlowTheme.of(context).error,
                                    fontSize: 14.0,
                                  ),
                                  errorMaxLines: 3,
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: FlutterFlowTheme.of(context)
                                          .accent4,
                                      width: 1.0,
                                    ),
                                    borderRadius:
                                        BorderRadius.circular(12.0),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: FlutterFlowTheme.of(context)
                                          .primary,
                                      width: 1.5,
                                    ),
                                    borderRadius:
                                        BorderRadius.circular(12.0),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: FlutterFlowTheme.of(context)
                                          .error,
                                      width: 1.0,
                                    ),
                                    borderRadius:
                                        BorderRadius.circular(12.0),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: FlutterFlowTheme.of(context)
                                          .error,
                                      width: 1.5,
                                    ),
                                    borderRadius:
                                        BorderRadius.circular(12.0),
                                  ),
                                  filled: true,
                                  fillColor: FlutterFlowTheme.of(context)
                                      .primaryBackground,
                                  contentPadding:
                                      const EdgeInsetsDirectional.fromSTEB(
                                          16.0, 16.0, 16.0, 16.0),
                                  prefixIcon: Icon(
                                    Icons.lock_rounded,
                                    color: FlutterFlowTheme.of(context)
                                        .secondary,
                                    size: 22.0,
                                  ),
                                  suffixIcon: InkWell(
                                    onTap: () async {
                                      safeSetState(() => _model
                                              .signInPasswordFieldVisibility =
                                          !_model
                                              .signInPasswordFieldVisibility);
                                    },
                                    focusNode:
                                        FocusNode(skipTraversal: true),
                                    child: Icon(
                                      _model.signInPasswordFieldVisibility
                                          ? Icons.visibility_outlined
                                          : Icons
                                              .visibility_off_outlined,
                                      color: FlutterFlowTheme.of(context)
                                          .secondary,
                                      size: 20.0,
                                    ),
                                  ),
                                ),
                                style: GoogleFonts.ubuntu(
                                  fontSize: 16.0,
                                  color: FlutterFlowTheme.of(context)
                                      .primaryText,
                                ),
                                maxLength: 256,
                                maxLengthEnforcement:
                                    MaxLengthEnforcement.enforced,
                                buildCounter: (context,
                                        {required currentLength,
                                        required isFocused,
                                        maxLength}) =>
                                    null,
                                keyboardType:
                                    TextInputType.visiblePassword,
                                cursorColor:
                                    FlutterFlowTheme.of(context).primary,
                                enableInteractiveSelection: true,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[A-Za-z0-9!@#$%^&*]')),
                                ],
                                validator: _model
                                    .signInPasswordFieldTextControllerValidator
                                    .asValidator(context),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Lockout banner
                            if (_model.isLockedOut) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                margin:
                                    const EdgeInsets.only(bottom: 14),
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(context)
                                      .error
                                      .withValues(alpha: 0.1),
                                  borderRadius:
                                      BorderRadius.circular(10),
                                  border: Border.all(
                                    color: FlutterFlowTheme.of(context)
                                        .error
                                        .withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.lock_clock_rounded,
                                        color:
                                            FlutterFlowTheme.of(context)
                                                .error,
                                        size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: RichText(
                                        text: TextSpan(
                                          style: GoogleFonts.ubuntu(
                                            fontSize: 13,
                                            color: FlutterFlowTheme.of(
                                                    context)
                                                .primaryText,
                                            height: 1.4,
                                          ),
                                          children: [
                                            const TextSpan(
                                                text:
                                                    'Too many failed attempts. Try again in '),
                                            TextSpan(
                                              text: _model
                                                  .lockoutCountdown,
                                              style: GoogleFonts.ubuntu(
                                                fontWeight:
                                                    FontWeight.bold,
                                                color:
                                                    FlutterFlowTheme.of(
                                                            context)
                                                        .error,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // Sign In button
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: (_model.isLoading ||
                                        _model.isLockedOut)
                                    ? null
                                    : () async {
                                  _model.signInEmailFieldTextController
                                          .text =
                                      _model
                                          .signInEmailFieldTextController
                                          .text
                                          .trim()
                                          .toLowerCase()
                                          .replaceAll(' ', '');

                                  if (_model.formKey.currentState ==
                                          null ||
                                      !_model.formKey.currentState!
                                          .validate()) {
                                    return;
                                  }
                                  final messenger =
                                      ScaffoldMessenger.of(context);
                                  final theme =
                                      FlutterFlowTheme.of(context);
                                  safeSetState(
                                      () => _model.isLoading = true);
                                  _model.signInResult = await actions
                                      .signInWithCustomError(
                                    context,
                                    _model
                                        .signInEmailFieldTextController
                                        .text,
                                    _model
                                        .signInPasswordFieldTextController
                                        .text,
                                  );
                                  if (_model.signInResult == 'success') {
                                    _model.resetAttempts();
                                    return;
                                  }

                                  _model.recordFailedAttempt();
                                  if (_model.isLockedOut) {
                                    _startLockoutTimer();
                                  }

                                  safeSetState(
                                      () => _model.isLoading = false);
                                  messenger.clearSnackBars();
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        _model.isLockedOut
                                            ? 'Too many failed attempts. Please wait 2 minutes.'
                                            : '${_model.signInResult!} (${3 - _model.failedAttempts} attempt${3 - _model.failedAttempts == 1 ? '' : 's'} left)',
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
                                      behavior: SnackBarBehavior.floating,
                                      margin: const EdgeInsets.fromLTRB(
                                          16, 0, 16, 80),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      FlutterFlowTheme.of(context)
                                          .primary,
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(12),
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
                                          const Icon(Icons.login_rounded,
                                              size: 22),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Sign In',
                                            style: GoogleFonts.ubuntu(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Forgot Password
                            TextButton(
                              onPressed: _model.isLoading ? null : () async {
                                context.goNamed(
                                  ForgotPasswordPageWidget.routeName,
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
                              },
                              child: Text(
                                'Forgot Password?',
                                style: GoogleFonts.ubuntu(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? FlutterFlowTheme.of(context).info
                                      : FlutterFlowTheme.of(context)
                                          .primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Divider(
                              thickness: 0.5,
                              color:
                                  FlutterFlowTheme.of(context).accent4,
                            ),
                            // Create An Account
                            TextButton(
                              onPressed: _model.isLoading ? null : () async {
                                context.goNamed(
                                  SignUpPageWidget.routeName,
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
                              },
                              child: Text(
                                'Create An Account',
                                style: GoogleFonts.ubuntu(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? FlutterFlowTheme.of(context).info
                                      : FlutterFlowTheme.of(context)
                                          .primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
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
                      color:
                          FlutterFlowTheme.of(context).secondaryText,
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
