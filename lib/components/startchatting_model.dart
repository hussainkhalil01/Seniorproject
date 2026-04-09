import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'startchatting_widget.dart' show StartchattingWidget;
import 'package:flutter/material.dart';

class StartchattingModel extends FlutterFlowModel<StartchattingWidget> {
  // Stores action output result for [Firestore Query] action in Start Chat button.
  List<ChatsRecord>? existingChats;
  // Stores action output result for [Backend Call - Create Document] action in Start Chat button.
  ChatsRecord? newchat;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
