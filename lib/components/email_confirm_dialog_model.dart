import '/flutter_flow/flutter_flow_util.dart';
import 'email_confirm_dialog_widget.dart' show EmailConfirmDialogWidget;
import 'package:flutter/material.dart';

class EmailConfirmDialogModel
    extends FlutterFlowModel<EmailConfirmDialogWidget> {
  ///  State fields for stateful widgets in this component.

  // State field(s) for ForgotPasswordEmailField widget.
  FocusNode? forgotPasswordEmailFieldFocusNode;
  TextEditingController? forgotPasswordEmailFieldTextController;
  String? Function(BuildContext, String?)?
      forgotPasswordEmailFieldTextControllerValidator;
  // State field(s) for Row widget.
  ScrollController? rowController;

  @override
  void initState(BuildContext context) {
    rowController = ScrollController();
  }

  @override
  void dispose() {
    forgotPasswordEmailFieldFocusNode?.dispose();
    forgotPasswordEmailFieldTextController?.dispose();

    rowController?.dispose();
  }
}
