import '/components/email_confirm_dialog_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/actions/index.dart' as actions;
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'sign_up_page_model.dart';
export 'sign_up_page_model.dart';

class SignUpPageWidget extends StatefulWidget {
  const SignUpPageWidget({super.key});

  static String routeName = 'SignUpPage';
  static String routePath = '/signUpPage';

  @override
  State<SignUpPageWidget> createState() => _SignUpPageWidgetState();
}

class _SignUpPageWidgetState extends State<SignUpPageWidget> {
  late SignUpPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SignUpPageModel());

    _model.signUpFullNameFieldTextController ??= TextEditingController();
    _model.signUpFullNameFieldFocusNode ??= FocusNode();

    _model.signUpEmailFieldTextController ??= TextEditingController();
    _model.signUpEmailFieldFocusNode ??= FocusNode();

    _model.signUpCreatePasswordFieldTextController ??= TextEditingController();
    _model.signUpCreatePasswordFieldFocusNode ??= FocusNode();

    _model.signUpConfirmPasswordFieldTextController ??= TextEditingController();
    _model.signUpConfirmPasswordFieldFocusNode ??= FocusNode();
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
                            'Create An Account',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.ubuntu(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Join to Trusted Contractors Marketplace',
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
                            // Full Name field
                            SizedBox(
                              width: double.infinity,
                              child: TextFormField(
                                controller:
                                    _model.signUpFullNameFieldTextController,
                                focusNode: _model.signUpFullNameFieldFocusNode,
                                autofocus: false,
                                enabled: true,
                                autofillHints: const [AutofillHints.name],
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                obscureText: false,
                                decoration: InputDecoration(
                                  labelText: 'Full Name',
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
                                    Icons.person_rounded,
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
                                maxLength: 30,
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
                                    .signUpFullNameFieldTextControllerValidator
                                    .asValidator(context),
                                inputFormatters: [
                                  // Allow English letters and spaces only
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[A-Za-z ]')),
                                  // Auto-capitalize words on desktop
                                  if (!isAndroid && !isiOS)
                                    TextInputFormatter.withFunction(
                                        (oldValue, newValue) {
                                      return TextEditingValue(
                                        selection: newValue.selection,
                                        text: newValue.text.toCapitalization(
                                            TextCapitalization.words),
                                      );
                                    }),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Email field
                            SizedBox(
                              width: double.infinity,
                              child: TextFormField(
                                controller:
                                    _model.signUpEmailFieldTextController,
                                focusNode: _model.signUpEmailFieldFocusNode,
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
                                    .signUpEmailFieldTextControllerValidator
                                    .asValidator(context),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Create Password field
                            SizedBox(
                              width: double.infinity,
                              child: TextFormField(
                                controller: _model
                                    .signUpCreatePasswordFieldTextController,
                                focusNode:
                                    _model.signUpCreatePasswordFieldFocusNode,
                                autofocus: false,
                                enabled: true,
                                autofillHints: const [AutofillHints.password],
                                textInputAction: TextInputAction.next,
                                obscureText: !_model
                                    .signUpCreatePasswordFieldVisibility,
                                decoration: InputDecoration(
                                  labelText: 'Create Password',
                                  labelStyle: GoogleFonts.ubuntu(
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                    fontSize: 16.0,
                                  ),
                                  alignLabelWithHint: false,
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
                                    Icons.lock_rounded,
                                    color:
                                        FlutterFlowTheme.of(context).secondary,
                                    size: 22.0,
                                  ),
                                  suffixIcon: InkWell(
                                    onTap: () async {
                                      safeSetState(() => _model
                                              .signUpCreatePasswordFieldVisibility =
                                          !_model
                                              .signUpCreatePasswordFieldVisibility);
                                    },
                                    focusNode: FocusNode(skipTraversal: true),
                                    child: Icon(
                                      _model.signUpCreatePasswordFieldVisibility
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color:
                                          FlutterFlowTheme.of(context).secondary,
                                      size: 20.0,
                                    ),
                                  ),
                                ),
                                style: GoogleFonts.ubuntu(
                                  fontSize: 16.0,
                                  color:
                                      FlutterFlowTheme.of(context).primaryText,
                                ),
                                maxLength: 256,
                                maxLengthEnforcement:
                                    MaxLengthEnforcement.enforced,
                                buildCounter: (context,
                                        {required currentLength,
                                        required isFocused,
                                        maxLength}) =>
                                    null,
                                keyboardType: TextInputType.visiblePassword,
                                cursorColor:
                                    FlutterFlowTheme.of(context).primary,
                                enableInteractiveSelection: true,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[A-Za-z0-9!@#$%^&*]')),
                                ],
                                validator: _model
                                    .signUpCreatePasswordFieldTextControllerValidator
                                    .asValidator(context),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Confirm Password field
                            SizedBox(
                              width: double.infinity,
                              child: TextFormField(
                                controller: _model
                                    .signUpConfirmPasswordFieldTextController,
                                focusNode:
                                    _model.signUpConfirmPasswordFieldFocusNode,
                                autofocus: false,
                                enabled: true,
                                autofillHints: const [AutofillHints.password],
                                textInputAction: TextInputAction.done,
                                obscureText: !_model
                                    .signUpConfirmPasswordFieldVisibility,
                                decoration: InputDecoration(
                                  labelText: 'Confirm Password',
                                  labelStyle: GoogleFonts.ubuntu(
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                    fontSize: 16.0,
                                  ),
                                  alignLabelWithHint: false,
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
                                    Icons.lock_rounded,
                                    color:
                                        FlutterFlowTheme.of(context).secondary,
                                    size: 22.0,
                                  ),
                                  suffixIcon: InkWell(
                                    onTap: () async {
                                      safeSetState(() => _model
                                              .signUpConfirmPasswordFieldVisibility =
                                          !_model
                                              .signUpConfirmPasswordFieldVisibility);
                                    },
                                    focusNode: FocusNode(skipTraversal: true),
                                    child: Icon(
                                      _model.signUpConfirmPasswordFieldVisibility
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color:
                                          FlutterFlowTheme.of(context).secondary,
                                      size: 20.0,
                                    ),
                                  ),
                                ),
                                style: GoogleFonts.ubuntu(
                                  fontSize: 16.0,
                                  color:
                                      FlutterFlowTheme.of(context).primaryText,
                                ),
                                maxLength: 256,
                                maxLengthEnforcement:
                                    MaxLengthEnforcement.enforced,
                                buildCounter: (context,
                                        {required currentLength,
                                        required isFocused,
                                        maxLength}) =>
                                    null,
                                keyboardType: TextInputType.visiblePassword,
                                cursorColor:
                                    FlutterFlowTheme.of(context).primary,
                                enableInteractiveSelection: true,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[A-Za-z0-9!@#$%^&*]')),
                                ],
                                validator: _model
                                    .signUpConfirmPasswordFieldTextControllerValidator
                                    .asValidator(context),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Sign Up button
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  var shouldSetState = false;

                                  String toTitleCase(String input) {
                                    final normalized = input
                                        .trim()
                                        .replaceAll(RegExp(r'\s+'), ' ');
                                    if (normalized.isEmpty) return normalized;
                                    return normalized.split(' ').map((w) {
                                      if (w.isEmpty) return w;
                                      final lower = w.toLowerCase();
                                      return lower[0].toUpperCase() +
                                          lower.substring(1);
                                    }).join(' ');
                                  }

                                  _model.signUpFullNameFieldTextController
                                      .text = toTitleCase(_model
                                      .signUpFullNameFieldTextController.text);

                                  _model.signUpEmailFieldTextController.text =
                                      _model.signUpEmailFieldTextController.text
                                          .trim()
                                          .toLowerCase()
                                          .replaceAll(' ', '');

                                  if (_model.formKey.currentState == null ||
                                      !_model.formKey.currentState!
                                          .validate()) {
                                    return;
                                  }

                                  final messenger =
                                      ScaffoldMessenger.of(context);
                                  final theme = FlutterFlowTheme.of(context);

                                  await showDialog(
                                    barrierColor: Colors.transparent,
                                    barrierDismissible: false,
                                    context: context,
                                    builder: (dialogContext) {
                                      return Dialog(
                                        elevation: 0,
                                        insetPadding: EdgeInsets.zero,
                                        backgroundColor: Colors.transparent,
                                        alignment:
                                            const AlignmentDirectional(0.0, 0.0)
                                                .resolve(
                                                    Directionality.of(context)),
                                        child: GestureDetector(
                                          onTap: () {
                                            FocusScope.of(dialogContext)
                                                .unfocus();
                                            FocusManager.instance.primaryFocus
                                                ?.unfocus();
                                          },
                                          child: SizedBox(
                                            width: double.infinity,
                                            child: EmailConfirmDialogWidget(
                                              email: _model
                                                  .signUpEmailFieldTextController
                                                  .text,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );

                                  if (FFAppState().confirmEmail) {
                                    _model.signUpResult =
                                        await actions.signUpWithCustomError(
                                      context, // ignore: use_build_context_synchronously
                                      _model.signUpFullNameFieldTextController
                                          .text,
                                      _model.signUpEmailFieldTextController
                                          .text,
                                      _model
                                          .signUpCreatePasswordFieldTextController
                                          .text,
                                      _model
                                          .signUpConfirmPasswordFieldTextController
                                          .text,
                                    );
                                    shouldSetState = true;
                                  } else {
                                    return;
                                  }

                                  if (_model.signUpResult == 'success') {
                                    if (shouldSetState) safeSetState(() {});
                                    if (context.mounted) {
                                      context.goNamed(
                                        EmailVerifyPageWidget.routeName,
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
                                    return;
                                  }

                                  messenger.clearSnackBars();
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        _model.signUpResult!,
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
                                  if (shouldSetState) safeSetState(() {});
                                },
                                icon: const Icon(Icons.person_add_rounded,
                                    size: 22),
                                label: Text(
                                  'Sign Up',
                                  style: GoogleFonts.ubuntu(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      FlutterFlowTheme.of(context).primary,
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Already have an account
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Already have an account?',
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
