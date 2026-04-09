import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'dart:ui';
import '/index.dart';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EditpasswordModel());
    _model.textController1 ??= TextEditingController();
    _model.textFieldFocusNode1 ??= FocusNode();
    _model.textController2 ??= TextEditingController();
    _model.textFieldFocusNode2 ??= FocusNode();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration(
      BuildContext context, String label, IconData icon, bool visible,
      VoidCallback onToggle) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.ubuntu(
        color: FlutterFlowTheme.of(context).secondaryText,
        fontSize: 14,
      ),
      prefixIcon: Icon(icon,
          color: FlutterFlowTheme.of(context).secondaryText, size: 20),
      suffixIcon: InkWell(
        onTap: onToggle,
        focusNode: FocusNode(skipTraversal: true),
        child: Icon(
          visible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: FlutterFlowTheme.of(context).secondaryText,
          size: 20,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide:
            BorderSide(color: FlutterFlowTheme.of(context).accent4, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(
            color: FlutterFlowTheme.of(context).primary, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      errorBorder: OutlineInputBorder(
        borderSide:
            BorderSide(color: FlutterFlowTheme.of(context).error, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide:
            BorderSide(color: FlutterFlowTheme.of(context).error, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: FlutterFlowTheme.of(context).primaryBackground,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: Column(
          children: [
            // ── Gradient header ──────────────────────────────────────────
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
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 28),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Change Password',
                              style: GoogleFonts.ubuntu(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Keep your account secure',
                              style: GoogleFonts.ubuntu(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.lock_outline_rounded,
                            color: Colors.white, size: 22),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Form card ────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.fromLTRB(16, 24, 16, 32),
                child: Form(
                  key: _model.formKey,
                  autovalidateMode: AutovalidateMode.disabled,
                  child: Container(
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).secondaryBackground,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0D000000),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section header
                        Row(
                          children: [
                            Icon(Icons.security_rounded,
                                color: FlutterFlowTheme.of(context).primary,
                                size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'New Password',
                              style: GoogleFonts.ubuntu(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color:
                                    FlutterFlowTheme.of(context).primaryText,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Divider(
                            height: 1,
                            color: FlutterFlowTheme.of(context).accent4),
                        const SizedBox(height: 20),

                        // New password field
                        TextFormField(
                          controller: _model.textController1,
                          focusNode: _model.textFieldFocusNode1,
                          textInputAction: TextInputAction.next,
                          obscureText: !_model.passwordVisibility1,
                          style: GoogleFonts.ubuntu(
                            color: FlutterFlowTheme.of(context).primaryText,
                            fontSize: 15,
                          ),
                          decoration: _fieldDecoration(
                            context,
                            'New Password',
                            Icons.lock_outline_rounded,
                            _model.passwordVisibility1,
                            () => safeSetState(() => _model
                                .passwordVisibility1 =
                                !_model.passwordVisibility1),
                          ),
                          validator:
                              _model.textController1Validator.asValidator(context),
                        ),
                        const SizedBox(height: 16),

                        // Confirm password field
                        TextFormField(
                          controller: _model.textController2,
                          focusNode: _model.textFieldFocusNode2,
                          textInputAction: TextInputAction.done,
                          obscureText: !_model.passwordVisibility2,
                          style: GoogleFonts.ubuntu(
                            color: FlutterFlowTheme.of(context).primaryText,
                            fontSize: 15,
                          ),
                          decoration: _fieldDecoration(
                            context,
                            'Confirm New Password',
                            Icons.lock_reset_rounded,
                            _model.passwordVisibility2,
                            () => safeSetState(() => _model
                                .passwordVisibility2 =
                                !_model.passwordVisibility2),
                          ),
                          validator:
                              _model.textController2Validator.asValidator(context),
                        ),
                        const SizedBox(height: 24),

                        // Update button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final newPassword =
                                  _model.textController1.text.trim();
                              final confirmPassword =
                                  _model.textController2.text.trim();

                              if (newPassword.isEmpty ||
                                  confirmPassword.isEmpty) {
                                ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(SnackBar(
                                    content: Text('Please fill in both fields.',
                                        style: GoogleFonts.ubuntu()),
                                    backgroundColor:
                                        FlutterFlowTheme.of(context).error,
                                  ));
                                return;
                              }
                              if (newPassword.length < 8) {
                                ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(SnackBar(
                                    content: Text(
                                        'Password must be at least 8 characters.',
                                        style: GoogleFonts.ubuntu()),
                                    backgroundColor:
                                        FlutterFlowTheme.of(context).error,
                                  ));
                                return;
                              }
                              if (newPassword != confirmPassword) {
                                ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(SnackBar(
                                    content: Text('Passwords do not match.',
                                        style: GoogleFonts.ubuntu()),
                                    backgroundColor:
                                        FlutterFlowTheme.of(context).error,
                                  ));
                                return;
                              }

                              try {
                                await authManager.updatePassword(
                                  newPassword: newPassword,
                                  context: context,
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context)
                                    ..hideCurrentSnackBar()
                                    ..showSnackBar(SnackBar(
                                      content: Text('Password updated!',
                                          style: GoogleFonts.ubuntu()),
                                      backgroundColor:
                                          const Color(0xFF4CAF50),
                                      duration: const Duration(seconds: 2),
                                    ));
                                  context.pop();
                                }
                              } catch (_) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context)
                                    ..hideCurrentSnackBar()
                                    ..showSnackBar(SnackBar(
                                      content: Text(
                                          'Failed to update password. Please try again.',
                                          style: GoogleFonts.ubuntu()),
                                      backgroundColor:
                                          FlutterFlowTheme.of(context).error,
                                    ));
                                }
                              }
                            },
                            icon: const Icon(Icons.check_rounded,
                                color: Colors.white, size: 20),
                            label: Text(
                              'Update Password',
                              style: GoogleFonts.ubuntu(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: Colors.white,
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
                        const SizedBox(height: 16),

                        // Hint text
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline_rounded,
                                size: 14,
                                color: FlutterFlowTheme.of(context)
                                    .secondaryText),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'At least 8 characters with a mix of letters, numbers, and symbols.',
                                style: GoogleFonts.ubuntu(
                                  fontSize: 12,
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryText,
                                  height: 1.4,
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
    );
  }
}


