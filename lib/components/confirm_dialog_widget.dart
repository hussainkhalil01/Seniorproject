import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A reusable card-style confirmation dialog that matches the app's design
/// system (sign-out, delete-account, clear-chat pattern).
///
/// Usage:
/// ```dart
/// final confirmed = await showDialog<bool>(
///   context: context,
///   builder: (_) => ConfirmDialogWidget(
///     icon: Icons.delete_forever_rounded,
///     iconColor: theme.error,
///     title: 'Delete Account',
///     message: 'Are you sure you want to delete your account?',
///     confirmLabel: 'Delete',
///     confirmColor: theme.error,
///   ),
/// );
/// ```
class ConfirmDialogWidget extends StatelessWidget {
  const ConfirmDialogWidget({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.confirmColor,
    this.cancelLabel = 'Cancel',
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String confirmLabel;
  final Color confirmColor;
  final String cancelLabel;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Material(
      type: MaterialType.transparency,
      child: Align(
        alignment: AlignmentDirectional.center,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16.0, 12.0, 16.0, 12.0),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 530.0),
            decoration: BoxDecoration(
              color: theme.primaryBackground,
              boxShadow: const [
                BoxShadow(
                  blurRadius: 3.0,
                  color: Color(0x33000000),
                  offset: Offset(0.0, 1.0),
                ),
              ],
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: theme.primaryBackground, width: 1.0),
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 12.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(24.0, 16.0, 24.0, 16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(icon, size: 44.0, color: iconColor),
                        const SizedBox(height: 12.0),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: theme.headlineMedium.override(
                            fontFamily: 'Ubuntu',
                            letterSpacing: 0.0,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: theme.labelMedium.override(
                            fontFamily: 'Ubuntu',
                            letterSpacing: 0.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(thickness: 1.0),
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(24.0, 12.0, 24.0, 0.0),
                    child: FFButtonWidget(
                      onPressed: () => Navigator.of(context).pop(true),
                      text: confirmLabel,
                      options: FFButtonOptions(
                        width: double.infinity,
                        height: 44.0,
                        color: confirmColor,
                        textStyle: GoogleFonts.ubuntu(
                          color: Colors.white,
                          fontSize: 16.0,
                          fontWeight: FontWeight.w600,
                        ),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(24.0, 8.0, 24.0, 0.0),
                    child: FFButtonWidget(
                      onPressed: () => Navigator.of(context).pop(false),
                      text: cancelLabel,
                      options: FFButtonOptions(
                        width: double.infinity,
                        height: 44.0,
                        color: theme.secondaryBackground,
                        textStyle: GoogleFonts.ubuntu(
                          color: theme.primaryText,
                          fontSize: 16.0,
                          fontWeight: FontWeight.w600,
                        ),
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: theme.alternate),
                      ),
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
