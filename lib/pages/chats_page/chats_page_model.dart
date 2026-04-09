import '/flutter_flow/flutter_flow_util.dart';
import 'chats_page_widget.dart' show ChatsPageWidget;
import 'package:flutter/material.dart';

class ChatsPageModel extends FlutterFlowModel<ChatsPageWidget> {
  ScrollController? columnController;

  @override
  void initState(BuildContext context) {
    columnController = ScrollController();
  }

  @override
  void dispose() {
    columnController?.dispose();
  }
}
