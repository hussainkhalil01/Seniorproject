import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'sign_up_page_widget.dart' show SignUpPageWidget;
import 'package:flutter/material.dart';

class SignUpPageModel extends FlutterFlowModel<SignUpPageWidget> {
  ///  State fields for stateful widgets in this page.

  final formKey = GlobalKey<FormState>();
  // State field(s) for Column widget.
  ScrollController? columnController;
  // State field(s) for SignUpFullNameField widget.
  FocusNode? signUpFullNameFieldFocusNode;
  TextEditingController? signUpFullNameFieldTextController;
  String? Function(BuildContext, String?)?
      signUpFullNameFieldTextControllerValidator;
  String? _signUpFullNameFieldTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Please enter your full name';
    }

    if (val.length < 3) {
      return 'Full name is too short';
    }

    return null;
  }

  // State field(s) for SignUpEmailField widget.
  FocusNode? signUpEmailFieldFocusNode;
  TextEditingController? signUpEmailFieldTextController;
  String? Function(BuildContext, String?)?
      signUpEmailFieldTextControllerValidator;
  String? _signUpEmailFieldTextControllerValidator(
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

  // State field(s) for SignUpCreatePasswordField widget.
  // Validation mirrors PasswordValidator.java in the Administration Dashboard
  // so that allowed characters are identical across mobile and desktop.
  // Allowed symbols: ! @ # $ % ^ & * only.
  FocusNode? signUpCreatePasswordFieldFocusNode;
  TextEditingController? signUpCreatePasswordFieldTextController;
  late bool signUpCreatePasswordFieldVisibility;
  String? Function(BuildContext, String?)?
      signUpCreatePasswordFieldTextControllerValidator;
  String? _signUpCreatePasswordFieldTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Please create a password';
    }

    if (val.length < 8) {
      return 'Password must be at least 8 characters';
    }

    if (!RegExp(r'^[A-Za-z0-9!@#$%^&*]{8,256}$').hasMatch(val)) {
      return 'Only A-Z, a-z, 0-9, !@#\$%^&* allowed';
    }

    if (!RegExp(r'[a-z]').hasMatch(val)) {
      return 'Password must include a lowercase letter';
    }

    if (!RegExp(r'[A-Z]').hasMatch(val)) {
      return 'Password must include an uppercase letter';
    }

    if (!RegExp(r'[0-9]').hasMatch(val)) {
      return 'Password must include a number';
    }

    if (!RegExp(r'[!@#$%^&*]').hasMatch(val)) {
      return 'Password must include a symbol (!@#\$%^&*)';
    }

    return null;
  }

  // State field(s) for SignUpConfirmPasswordField widget.
  FocusNode? signUpConfirmPasswordFieldFocusNode;
  TextEditingController? signUpConfirmPasswordFieldTextController;
  late bool signUpConfirmPasswordFieldVisibility;
  String? Function(BuildContext, String?)?
      signUpConfirmPasswordFieldTextControllerValidator;
  String? _signUpConfirmPasswordFieldTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Please confirm your password';
    }

    if (val.length < 8) {
      return 'Password must be at least 8 characters';
    }

    if (!RegExp(r'^[A-Za-z0-9!@#$%^&*]{8,256}$').hasMatch(val)) {
      return 'Only A-Z, a-z, 0-9, !@#\$%^&* allowed';
    }

    if (!RegExp(r'[a-z]').hasMatch(val)) {
      return 'Password must include a lowercase letter';
    }

    if (!RegExp(r'[A-Z]').hasMatch(val)) {
      return 'Password must include an uppercase letter';
    }

    if (!RegExp(r'[0-9]').hasMatch(val)) {
      return 'Password must include a number';
    }

    if (!RegExp(r'[!@#$%^&*]').hasMatch(val)) {
      return 'Password must include a symbol (!@#\$%^&*)';
    }

    if (val != signUpCreatePasswordFieldTextController?.text) {
      return 'Passwords do not match';
    }

    return null;
  }

  // Stores action output result for [Custom Action - signUpWithCustomError] action in SignUpButton widget.
  String? signUpResult;

  @override
  void initState(BuildContext context) {
    columnController = ScrollController();
    signUpFullNameFieldTextControllerValidator =
        _signUpFullNameFieldTextControllerValidator;
    signUpEmailFieldTextControllerValidator =
        _signUpEmailFieldTextControllerValidator;
    signUpCreatePasswordFieldVisibility = false;
    signUpCreatePasswordFieldTextControllerValidator =
        _signUpCreatePasswordFieldTextControllerValidator;
    signUpConfirmPasswordFieldVisibility = false;
    signUpConfirmPasswordFieldTextControllerValidator =
        _signUpConfirmPasswordFieldTextControllerValidator;
  }

  @override
  void dispose() {
    columnController?.dispose();
    signUpFullNameFieldFocusNode?.dispose();
    signUpFullNameFieldTextController?.dispose();

    signUpEmailFieldFocusNode?.dispose();
    signUpEmailFieldTextController?.dispose();

    signUpCreatePasswordFieldFocusNode?.dispose();
    signUpCreatePasswordFieldTextController?.dispose();

    signUpConfirmPasswordFieldFocusNode?.dispose();
    signUpConfirmPasswordFieldTextController?.dispose();
  }
}
