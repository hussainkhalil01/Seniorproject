import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'sign_in_page_widget.dart' show SignInPageWidget;
import 'package:flutter/material.dart';

class SignInPageModel extends FlutterFlowModel<SignInPageWidget> {
  ///  State fields for stateful widgets in this page.

  final formKey = GlobalKey<FormState>();
  // State field(s) for Column widget.
  ScrollController? columnController;
  // State field(s) for SignInEmailField widget.
  FocusNode? signInEmailFieldFocusNode;
  TextEditingController? signInEmailFieldTextController;
  String? Function(BuildContext, String?)?
      signInEmailFieldTextControllerValidator;
  String? _signInEmailFieldTextControllerValidator(
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

  // State field(s) for SignInPasswordField widget.
  FocusNode? signInPasswordFieldFocusNode;
  TextEditingController? signInPasswordFieldTextController;
  late bool signInPasswordFieldVisibility;
  String? Function(BuildContext, String?)?
      signInPasswordFieldTextControllerValidator;
  String? _signInPasswordFieldTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Please enter your password';
    }

    return null;
  }

  // Stores action output result for [Custom Action - signInWithCustomError] action in SignInButton widget.
  String? signInResult;

  @override
  void initState(BuildContext context) {
    columnController = ScrollController();
    signInEmailFieldTextControllerValidator =
        _signInEmailFieldTextControllerValidator;
    signInPasswordFieldVisibility = false;
    signInPasswordFieldTextControllerValidator =
        _signInPasswordFieldTextControllerValidator;
  }

  @override
  void dispose() {
    columnController?.dispose();
    signInEmailFieldFocusNode?.dispose();
    signInEmailFieldTextController?.dispose();

    signInPasswordFieldFocusNode?.dispose();
    signInPasswordFieldTextController?.dispose();
  }
}
