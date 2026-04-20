import '/flutter_flow/flutter_flow_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

InputDecoration profileFieldDecoration({
  required BuildContext context,
  required String label,
  required IconData icon,
  Widget? prefixWidget,
  Widget? suffixIcon,
  String? errorText,
  bool readOnly = false,
}) {
  final theme = FlutterFlowTheme.of(context);
  return InputDecoration(
    labelText: label,
    errorText: errorText,
    labelStyle: GoogleFonts.ubuntu(color: theme.secondaryText, fontSize: 14),
    prefixIcon: prefixWidget ?? Icon(icon, color: theme.secondary, size: 22),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: theme.primaryBackground,
    counterText: '',
    errorStyle: GoogleFonts.ubuntu(color: theme.error, fontSize: 12),
    errorMaxLines: 3,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(
        color: readOnly
            ? theme.accent4.withValues(alpha: 0.5)
            : theme.accent4,
        width: 1,
      ),
      borderRadius: BorderRadius.circular(12),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: theme.primary, width: 1.5),
      borderRadius: BorderRadius.circular(12),
    ),
    errorBorder: OutlineInputBorder(
      borderSide: BorderSide(color: theme.error, width: 1),
      borderRadius: BorderRadius.circular(12),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderSide: BorderSide(color: theme.error, width: 1.5),
      borderRadius: BorderRadius.circular(12),
    ),
  );
}
