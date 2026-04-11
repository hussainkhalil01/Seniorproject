import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'forgot_password_page_widget.dart' show ForgotPasswordPageWidget;
import 'package:flutter/material.dart';

class ForgotPasswordPageModel
    extends FlutterFlowModel<ForgotPasswordPageWidget> {
  ///  State fields for stateful widgets in this page.

  final formKey = GlobalKey<FormState>();
  // State field(s) for Column widget.
  ScrollController? columnController;
  // State field(s) for ForgotPasswordEmailField widget.
  FocusNode? forgotPasswordEmailFieldFocusNode;
  TextEditingController? forgotPasswordEmailFieldTextController;
  String? Function(BuildContext, String?)?
      forgotPasswordEmailFieldTextControllerValidator;
  String? _forgotPasswordEmailFieldTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Please enter your email address';
    }

    if (!RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$')
        .hasMatch(val)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  // Stores action output result for [Custom Action - forgotPasswordCustomInfo] action in ForgotPasswordButton widget.
  String? forgotPasswordResult;

  // Whether the send reset link action is in progress.
  bool isLoading = false;

  @override
  void initState(BuildContext context) {
    columnController = ScrollController();
    forgotPasswordEmailFieldTextControllerValidator =
        _forgotPasswordEmailFieldTextControllerValidator;
  }

  @override
  void dispose() {
    columnController?.dispose();
    forgotPasswordEmailFieldFocusNode?.dispose();
    forgotPasswordEmailFieldTextController?.dispose();
  }
}
