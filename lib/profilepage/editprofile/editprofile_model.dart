import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import 'editprofile_widget.dart' show EditprofileWidget;
import 'package:flutter/material.dart';

class EditprofileModel extends FlutterFlowModel<EditprofileWidget> {
  // Full name
  FocusNode? nameFocusNode;
  TextEditingController? nameController;
  String? Function(BuildContext, String?)? nameValidator;

  // About / short description
  FocusNode? aboutFocusNode;
  TextEditingController? aboutController;
  String? Function(BuildContext, String?)? aboutValidator;

  // Phone number
  FocusNode? phoneFocusNode;
  TextEditingController? phoneController;
  String? Function(BuildContext, String?)? phoneValidator;

  // Service provider: professional title
  FocusNode? titleFocusNode;
  TextEditingController? titleController;
  String? Function(BuildContext, String?)? titleValidator;

  // Service provider: categories
  List<String>? categoriesValues;
  FormFieldController<List<String>>? categoriesController;

  bool isSaving = false;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    nameFocusNode?.dispose();
    nameController?.dispose();
    aboutFocusNode?.dispose();
    aboutController?.dispose();
    phoneFocusNode?.dispose();
    phoneController?.dispose();
    titleFocusNode?.dispose();
    titleController?.dispose();
  }
}
