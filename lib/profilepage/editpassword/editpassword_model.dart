import '/flutter_flow/flutter_flow_util.dart';
import 'editpassword_widget.dart' show EditpasswordWidget;
import 'package:flutter/material.dart';

class EditpasswordModel extends FlutterFlowModel<EditpasswordWidget> {
  // Email (read-only)
  FocusNode? emailFocusNode;
  TextEditingController? emailController;

  // Current password
  FocusNode? currentPasswordFocusNode;
  TextEditingController? currentPasswordController;
  bool currentPasswordVisible = false;

  // New password
  FocusNode? newPasswordFocusNode;
  TextEditingController? newPasswordController;
  bool newPasswordVisible = false;

  bool isSaving = false;

  String? initialEmail;

  bool get hasChanges =>
      emailController?.text.trim().toLowerCase().replaceAll(' ', '') !=
          initialEmail ||
      newPasswordController?.text.trim().isNotEmpty == true;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    emailFocusNode?.dispose();
    emailController?.dispose();
    currentPasswordFocusNode?.dispose();
    currentPasswordController?.dispose();
    newPasswordFocusNode?.dispose();
    newPasswordController?.dispose();
  }
}
