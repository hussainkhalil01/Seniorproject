import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'editname_widget.dart' show EditnameWidget;
import 'package:flutter/material.dart';

class EditnameModel extends FlutterFlowModel<EditnameWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
