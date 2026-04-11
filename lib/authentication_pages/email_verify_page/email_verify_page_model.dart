import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'email_verify_page_widget.dart' show EmailVerifyPageWidget;
import 'package:flutter/material.dart';

class EmailVerifyPageModel extends FlutterFlowModel<EmailVerifyPageWidget> {
  ///  State fields for stateful widgets in this page.

  final formKey = GlobalKey<FormState>();
  // State field(s) for Column widget.
  ScrollController? columnController;
  // State field(s) for EmailVerifyEmailField widget.
  FocusNode? emailVerifyEmailFieldFocusNode;
  TextEditingController? emailVerifyEmailFieldTextController;
  String? Function(BuildContext, String?)?
      emailVerifyEmailFieldTextControllerValidator;
  // Stores action output result for [Custom Action - emailVerifyContinue] action in EmailVerifyButton2 widget.
  String? emailVerifyResult;

  // Whether the continue action is in progress.
  bool isLoading = false;

  // Whether the resend verification link action is in progress.
  bool isResendLoading = false;

  @override
  void initState(BuildContext context) {
    columnController = ScrollController();
  }

  @override
  void dispose() {
    columnController?.dispose();
    emailVerifyEmailFieldFocusNode?.dispose();
    emailVerifyEmailFieldTextController?.dispose();
  }
}
