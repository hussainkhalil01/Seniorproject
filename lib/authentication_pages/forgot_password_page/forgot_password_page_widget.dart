import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'forgot_password_page_model.dart';
export 'forgot_password_page_model.dart';

class ForgotPasswordPageWidget extends StatefulWidget {
  const ForgotPasswordPageWidget({super.key});

  static String routeName = 'ForgotPasswordPage';
  static String routePath = '/forgotPasswordPage';

  @override
  State<ForgotPasswordPageWidget> createState() =>
      _ForgotPasswordPageWidgetState();
}

class _ForgotPasswordPageWidgetState extends State<ForgotPasswordPageWidget> {
  late ForgotPasswordPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ForgotPasswordPageModel());

    _model.forgotPasswordEmailFieldTextController ??= TextEditingController();
    _model.forgotPasswordEmailFieldFocusNode ??= FocusNode();
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
                            'Forgot Password?',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.ubuntu(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enter your email address to receive a reset link',
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
                                controller: _model
                                    .forgotPasswordEmailFieldTextController,
                                focusNode:
                                    _model.forgotPasswordEmailFieldFocusNode,
                                autofocus: false,
                                enabled: true,
                                autofillHints: const [AutofillHints.email],
                                textInputAction: TextInputAction.done,
                                obscureText: false,
                                decoration: InputDecoration(
                                  labelText: 'Email Address',
                                  labelStyle: GoogleFonts.ubuntu(
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                    fontSize: 16.0,
                                  ),
                                  errorStyle: GoogleFonts.ubuntu(
                                    color: FlutterFlowTheme.of(context).error,
                                    fontSize: 14.0,
                                  ),
                                  errorMaxLines: 3,
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
                                  color:
                                      FlutterFlowTheme.of(context).primaryText,
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
                                    .forgotPasswordEmailFieldTextControllerValidator
                                    .asValidator(context),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Send Reset Link button
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton.icon(
                                onPressed: FFAppState()
                                        .forgotPasswordCooldownActive
                                    ? null
                                    : () async {
                                        _model.forgotPasswordEmailFieldTextController
                                                .text =
                                            _model
                                                .forgotPasswordEmailFieldTextController
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

                                        _model.forgotPasswordResult =
                                            await actions
                                                .forgotPasswordCustomInfo(
                                          _model
                                              .forgotPasswordEmailFieldTextController
                                              .text,
                                        );
                                        await actions
                                            .forgotPasswordStartCooldown();

                                        messenger.clearSnackBars();
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              _model.forgotPasswordResult!,
                                              style: GoogleFonts.ubuntu(
                                                color: Colors.white,
                                                fontSize: 15.0,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            duration: const Duration(
                                                milliseconds: 4000),
                                            backgroundColor: FFAppState()
                                                    .forgotPasswordSent
                                                ? theme.success
                                                : theme.error,
                                            behavior:
                                                SnackBarBehavior.floating,
                                            margin:
                                                const EdgeInsets.fromLTRB(
                                                    16, 0, 16, 80),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        );

                                        safeSetState(() {});
                                      },
                                icon: Icon(
                                  FFAppState().forgotPasswordCooldownActive
                                      ? Icons.timer_outlined
                                      : Icons.add_link_rounded,
                                  size: 22,
                                ),
                                label: Text(
                                  FFAppState().forgotPasswordCooldownActive
                                      ? functions.cooldownText(FFAppState()
                                          .forgotPasswordCooldownSeconds)
                                      : 'Send Reset Link',
                                  style: GoogleFonts.ubuntu(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
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
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Back to Sign In
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Remembered your password?',
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
                                    context.goNamed(
                                      SignInPageWidget.routeName,
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
                                    'Sign In',
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
