import '/flutter_flow/flutter_flow_util.dart';
import 'edit_account_page_widget.dart' show EditAccountWidget;
import 'package:flutter/material.dart';

class EditAccountModel extends FlutterFlowModel<EditAccountWidget> {
  // Email
  FocusNode? emailFocusNode;
  TextEditingController? emailController;

  // Current password
  FocusNode? currentPasswordFocusNode;
  TextEditingController? currentPasswordController;
  bool currentPasswordVisible = false;
  final currentPasswordVisibilityFocusNode =
      FocusNode(skipTraversal: true);

  // New password
  FocusNode? newPasswordFocusNode;
  TextEditingController? newPasswordController;
  bool newPasswordVisible = false;
  final newPasswordVisibilityFocusNode =
      FocusNode(skipTraversal: true);

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
    currentPasswordVisibilityFocusNode.dispose();
    newPasswordFocusNode?.dispose();
    newPasswordController?.dispose();
    newPasswordVisibilityFocusNode.dispose();
  }
}
