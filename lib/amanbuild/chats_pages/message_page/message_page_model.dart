import '/flutter_flow/flutter_flow_util.dart';
import 'message_page_widget.dart' show MessagePageWidget;
import 'package:flutter/material.dart';

class MessagePageModel extends FlutterFlowModel<MessagePageWidget> {
  ///  Local state fields for this page.

  String messageTemp = '';

  ///  State fields for stateful widgets in this page.

  // State field(s) for TextField11 widget.
  FocusNode? textField11FocusNode;
  TextEditingController? textField11TextController;
  String? Function(BuildContext, String?)? textField11TextControllerValidator;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    textField11FocusNode?.dispose();
    textField11TextController?.dispose();
  }
}
